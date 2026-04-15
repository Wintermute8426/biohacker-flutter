#!/usr/bin/env python3
"""
BIOHACKER App Icon v4c - Cinematic Neon Pixel Art
Work at 256×256, 4× NEAREST upscale to 1024×1024
Waneella/Kirokaze aesthetic: atmospheric neon, dithering, proper anatomy
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageChops
import math
import os

SIZE     = 1024
WORK     = 256
SCALE    = SIZE // WORK  # 4×
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"
OUT_PATH = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"

# ── PIXEL GRID ─────────────────────────────────────────────────────────────
PX = 1   # pixel grid at WORK resolution

# ── PALETTE ────────────────────────────────────────────────────────────────
# Magenta (left brain) - 5 values
M0 = (255, 30,  235)   # brightest (hottest highlight)
M1 = (220, 0,   180)   # crown
M2 = (170, 0,   130)   # mid-tone
M3 = ( 90, 0,    65)   # shadow
M4 = ( 35, 0,    25)   # deep shadow

# Green (right brain) - 5 values  
G0 = ( 60, 255, 100)   # brightest
G1 = (  0, 210,  70)   # crown
G2 = (  0, 155,  48)   # mid-tone
G3 = (  0,  75,  22)   # shadow
G4 = (  0,  28,   8)   # deep shadow

# Gold (Bitcoin)
B0 = (255, 240,  70)   # hotspot
B1 = (240, 195,   5)   # main gold
B2 = (185, 140,   0)   # shadow gold
B3 = (110,  75,   0)   # deep shadow

# Cyan (text)
C0 = (  0, 255, 255)   # bright
C1 = (  0, 215, 235)   # main
C2 = (  0, 130, 150)   # shadow

# BG / ambient
BLACK  = (  0,   0,   0)
CKTRACE = (0, 22, 18)

# ── HELPERS ────────────────────────────────────────────────────────────────

def px(img, x, y, col):
    """Plot one pixel"""
    img.putpixel((int(x), int(y)), col + (255,))

def hline(d, x1, x2, y, col):
    if x1 > x2: x1, x2 = x2, x1
    d.line([(x1, y), (x2, y)], fill=col + (255,), width=1)

def vline(d, x, y1, y2, col):
    if y1 > y2: y1, y2 = y2, y1
    d.line([(x, y1), (x, y2)], fill=col + (255,), width=1)

def rect(d, x1, y1, x2, y2, col):
    d.rectangle([x1, y1, x2, y2], fill=col + (255,))

def composite(base, over):
    return Image.alpha_composite(base, over)

def make_glow_stack(layer, blurs_alphas):
    """Returns (glows composited, no sharp on top)"""
    acc = Image.new("RGBA", layer.size, (0,0,0,0))
    for blur, alpha in blurs_alphas:
        g = layer.filter(ImageFilter.GaussianBlur(blur))
        a = np.array(g, dtype=np.float32)
        a[...,3] = (a[...,3] * alpha).clip(0,255)
        acc = composite(acc, Image.fromarray(a.astype(np.uint8)))
    return acc

def add_glow(base, layer, blurs_alphas):
    base = composite(base, make_glow_stack(layer, blurs_alphas))
    return composite(base, layer)

# ── BRAIN SHAPE ─────────────────────────────────────────────────────────────

def brain_mask_pts(cx, cy, rw, rh):
    """
    Returns outline polygon points for a brain-like silhouette.
    Anatomically inspired: bumpy top (gyri), temporal bulges on sides,
    flat-ish bottom.
    """
    pts = []
    N = 500
    for i in range(N):
        t = 2*math.pi * i / N
        bx = rw * math.cos(t)
        by = rh * math.sin(t)
        
        # Primary gyral bumps on top (t near pi/2 = top of ellipse)
        # t=0 → right, t=pi/2 → bottom (because y increases down), t=pi → left, t=3pi/2 → top
        # In PIL coords, y increases downward
        # So t=3pi/2 is the top of the brain
        
        # Gyral bumps: add wave mostly on the top half
        top_factor = max(0, -math.sin(t))  # 1 at top (t=3pi/2), 0 at bottom
        
        bump = (
            top_factor * 0.09 * math.sin(4 * t + 0.3) +   # main gyri
            top_factor * 0.05 * math.sin(8 * t + 1.0) +   # smaller folds
            top_factor * 0.03 * math.sin(12 * t + 0.7) +  # micro folds
                         0.03 * math.sin(3 * t + 0.5) +   # general form
                         0.02 * math.sin(5 * t + 1.2)     # side detail
        )
        
        # Temporal lobe bulge on sides (mid-lower)
        side_factor = abs(math.cos(t)) * max(0, math.sin(t))  # sides + lower half
        bump += side_factor * 0.07
        
        # Flatten the bottom (brainstem exit)
        if by > rh * 0.6:
            by = rh * 0.6 + (by - rh * 0.6) * 0.5
        
        r = 1.0 + bump
        pts.append((cx + r*bx, cy + r*by))
    return pts

# ── GYRI TEXTURE ─────────────────────────────────────────────────────────────

def draw_gyri(work_img, brain_pts_list, cx, cy, rw, rh, side):
    """
    Draw pixel-art gyri (brain folds) on the given side ('left' or 'right').
    Uses scan-line approach with anatomical band structure.
    """
    d = ImageDraw.Draw(work_img)
    
    # Create brain mask
    brain_mask = Image.new("L", (WORK, WORK), 0)
    bm_d = ImageDraw.Draw(brain_mask)
    bm_d.polygon([(int(x), int(y)) for x,y in brain_pts_list], fill=255)
    bm = np.array(brain_mask)
    
    # Build a distance-from-center map for shading
    # We'll use parametric distance from edge to center
    # Scan line by line
    arr = np.array(work_img)
    
    # Color palettes
    if side == 'left':
        # [outermost → innermost]
        gyrus_colors = [M0, M1, M2, M1, M3, M2, M3, M2, M3, M4]
        sulcus_color = M3
    else:
        gyrus_colors = [G0, G1, G2, G1, G3, G2, G3, G2, G3, G4]
        sulcus_color = G3
    
    # Find brain bounds
    rows = np.where(bm.max(axis=1) > 0)[0]
    if len(rows) == 0:
        return work_img
    
    y_top = rows[0]
    y_bot = rows[-1]
    total_h = y_bot - y_top
    
    # Number of gyri / sulci bands
    n_bands = 9
    band_h  = total_h / n_bands
    
    for y in range(y_top, y_bot + 1):
        # Which half?
        if side == 'left':
            row_mask = bm[y, :cx]
            x_offset = 0
        else:
            row_mask = bm[y, cx:]
            x_offset = cx
        
        xs = np.where(row_mask > 0)[0]
        if len(xs) == 0:
            continue
        
        x_inner = cx  # brain center x
        x_outer = xs[0] if side == 'left' else xs[-1] + cx
        
        # How far along vertically (0=top, 1=bottom)
        t_y = (y - y_top) / total_h
        
        # Which band (gyrus number) based on y position
        band_idx = int(t_y * n_bands)
        band_frac = (t_y * n_bands) - band_idx
        
        # Within each band: crown (bright) → flank → sulcus (dark) → flank → crown
        # Represent as sine wave
        band_phase = band_frac * 2 * math.pi
        intensity = (math.sin(band_phase) + 1) / 2  # 0=sulcus, 1=crown
        
        # Color selection
        col_idx_f = intensity * (len(gyrus_colors) - 1)
        col_idx = min(int(col_idx_f), len(gyrus_colors) - 2)
        frac     = col_idx_f - col_idx
        
        # Interpolate between two colors (nearest for pixel art)
        if intensity > 0.7:
            col = gyrus_colors[0]   # crown = brightest
        elif intensity > 0.5:
            col = gyrus_colors[1]
        elif intensity > 0.35:
            col = gyrus_colors[2]
        elif intensity > 0.2:
            col = gyrus_colors[3]
        elif intensity > 0.1:
            col = sulcus_color
        else:
            col = gyrus_colors[-1]  # deep sulcus
        
        # Dithering at transitions (checkerboard)
        # Apply horizontal extent
        for px_x in xs:
            x = px_x + x_offset
            if x < 0 or x >= WORK:
                continue
            
            # Vary color slightly by x position (horizontal fold curvature)
            # Simulate curvature: folds curve, so left/right edges of each fold are different
            x_norm = (px_x) / len(xs) if len(xs) > 1 else 0.5
            x_curve = math.sin(x_norm * math.pi)  # 0 at edges, 1 in middle
            
            # Integrate x_curve into final shade
            final_intensity = intensity * 0.7 + x_curve * 0.3
            
            if final_intensity > 0.75:
                final_col = gyrus_colors[0]
            elif final_intensity > 0.55:
                final_col = gyrus_colors[1]
            elif final_intensity > 0.38:
                final_col = gyrus_colors[2]
            elif final_intensity > 0.22:
                final_col = gyrus_colors[3]
            elif final_intensity > 0.12:
                final_col = sulcus_color
            else:
                final_col = gyrus_colors[-1]
            
            # Dither: at specific transition bands, alternate pixels
            dither = (x + y) % 2
            if 0.4 < final_intensity < 0.5 and dither:
                final_col = gyrus_colors[2]
            elif 0.2 < final_intensity < 0.3 and dither:
                final_col = sulcus_color
            
            arr[y, x, 0] = final_col[0]
            arr[y, x, 1] = final_col[1]
            arr[y, x, 2] = final_col[2]
            arr[y, x, 3] = 255
    
    return Image.fromarray(arr)

# ── BITCOIN ₿ GLYPH ──────────────────────────────────────────────────────────

def draw_bitcoin(img, cx, cy, h):
    """
    Draw proper Bitcoin ₿ symbol.
    cx, cy = center, h = total height
    
    ₿ = B with two vertical strokes that extend past top and bottom.
    The 'B' has two bumps (upper smaller, lower larger).
    """
    d = ImageDraw.Draw(img)
    
    # Dimensions
    sw  = max(1, h // 14)    # stroke width
    bw  = int(h * 0.40)      # B-body width (from vertical bar to rightmost point)
    ext = max(1, h // 9)     # extension above/below
    
    # Vertical bar position
    vx  = cx - h // 8
    ty  = cy - h // 2
    by_ = cy + h // 2
    
    # Upper bulge: ty → cy-4
    ub_top = ty
    ub_bot = cy - h // 16
    ub_r   = max(2, (ub_bot - ub_top) // 2)
    ub_x2  = vx + int(bw * 0.88)
    
    # Lower bulge: cy+4 → by_  (slightly bigger)
    lb_top = cy + h // 16
    lb_bot = by_
    lb_r   = max(2, (lb_bot - lb_top) // 2)
    lb_x2  = vx + bw
    
    # ── Draw B body ──────────────────────────────────────────
    # Fill both bulges with gold
    d.rounded_rectangle([vx, ub_top, ub_x2, ub_bot], 
                         radius=ub_r, fill=B1+(255,), outline=B0+(255,), width=sw)
    d.rounded_rectangle([vx, lb_top, lb_x2, lb_bot],
                         radius=lb_r, fill=B1+(255,), outline=B0+(255,), width=sw)
    
    # Hollow interior of upper bulge
    ip = sw + max(1, h//18)
    d.rounded_rectangle([vx + sw*2, ub_top + ip, ub_x2 - ip, ub_bot - ip],
                         radius=max(1, ub_r - ip), fill=(0,0,0,255))
    
    # Hollow interior of lower bulge
    d.rounded_rectangle([vx + sw*2, lb_top + ip, lb_x2 - ip, lb_bot - ip],
                         radius=max(1, lb_r - ip), fill=(0,0,0,255))
    
    # ── Vertical strokes ─────────────────────────────────────
    # Left stroke (primary): extends ext above/below
    rect(d, vx - sw, ty - ext, vx + sw, by_ + ext, B0)
    
    # Right stroke: slightly right of left
    vx2 = vx + sw * 3
    rect(d, vx2 - sw, ty - ext, vx2 + sw, by_ + ext, B0)
    
    # ── Serifs on stroke ends ─────────────────────────────────
    serif_w = sw * 3
    rect(d, vx - serif_w, ty - ext,              vx + serif_w, ty - ext + sw, B0)  # top
    rect(d, vx - serif_w, by_ + ext - sw,        vx + serif_w, by_ + ext,     B0)  # bottom
    rect(d, vx2 - serif_w, ty - ext,             vx2 + serif_w, ty - ext + sw, B0) # top 2
    rect(d, vx2 - serif_w, by_ + ext - sw,       vx2 + serif_w, by_ + ext,     B0) # bot 2
    
    # ── Highlight pixels ─────────────────────────────────────
    # Top-left of each bulge → brightest pixel
    for hx, hy in [(vx + sw*2, ub_top + sw),
                   (vx + sw*2, lb_top + sw),
                   (vx - sw,   ty - ext)]:
        d.rectangle([hx, hy, hx+1, hy+1], fill=B0+(255,))
    
    return img

# ── CIRCUIT BACKGROUND ────────────────────────────────────────────────────

def draw_bg(img, rng):
    d = ImageDraw.Draw(img)
    # H/V traces
    for _ in range(24):
        x1 = int(rng.integers(4, WORK-4))
        y1 = int(rng.integers(4, WORK-4))
        x2 = int(rng.integers(4, WORK-4))
        y2 = int(rng.integers(4, WORK-4))
        d.line([(x1,y1),(x2,y1)], fill=CKTRACE+(255,), width=1)
        d.line([(x2,y1),(x2,y2)], fill=CKTRACE+(255,), width=1)
        # Corner dot
        d.rectangle([x2-1,y1-1,x2+1,y1+1], fill=(0,36,28,255))
    return img

# ── MEDIAL FISSURE (brain center line) ────────────────────────────────────

def draw_fissure(img, brain_pts_list, cx):
    """Draw the interhemispheric fissure at x=cx, bounded by the brain."""
    bm = Image.new("L", (WORK,WORK), 0)
    ImageDraw.Draw(bm).polygon([(int(x),int(y)) for x,y in brain_pts_list], fill=255)
    bma = np.array(bm)
    col = bma[:, cx]
    rows = np.where(col > 0)[0]
    if len(rows) == 0:
        return img
    y_top = rows[0]
    y_bot = rows[-1]
    
    fiss = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    d = ImageDraw.Draw(fiss)
    # Two-tone fissure: dark center, slight lighter edge
    d.line([(cx, y_top), (cx, y_bot)], fill=(80,0,80,200), width=1)
    d.line([(cx+1, y_top), (cx+1, y_bot)], fill=(0,80,0,200), width=1)
    return fiss

# ── EDGE HIGHLIGHT ────────────────────────────────────────────────────────

def edge_highlight(brain_pts_list):
    """Return RGBA layer with bright outline around brain edge."""
    layer = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    d = ImageDraw.Draw(layer)
    pts_int = [(int(x),int(y)) for x,y in brain_pts_list]
    d.line(pts_int + [pts_int[0]], fill=(255,255,255,80), width=1)
    return layer

# ── MAIN BUILD ────────────────────────────────────────────────────────────

def build():
    rng = np.random.default_rng(77)
    
    # Base canvas
    canvas = Image.new("RGBA", (WORK,WORK), (0,0,0,255))
    
    # Circuit background
    draw_bg(canvas, rng)
    
    # ── Brain placement ───────────────────────────────────────
    # Center horizontally, upper ~55% of canvas vertically
    bcx = WORK // 2       # 128
    bcy = int(WORK * 0.38) # 97  (center of brain)
    brw = int(WORK * 0.40) # 102 (horizontal radius)
    brh = int(WORK * 0.34) # 87  (vertical radius)
    
    bpts = brain_mask_pts(bcx, bcy, brw, brh)
    bpts_int = [(int(x), int(y)) for x,y in bpts]
    
    # ── Brain base: fill with deepest colors first ─────────────
    # Left side (magenta)
    left_base = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    lb_d = ImageDraw.Draw(left_base)
    lb_d.polygon(bpts_int, fill=M4+(255,))
    lb_arr = np.array(left_base)
    lb_arr[:, bcx:] = 0   # mask right half
    left_base = Image.fromarray(lb_arr)
    
    # Right side (green)
    right_base = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    rb_d = ImageDraw.Draw(right_base)
    rb_d.polygon(bpts_int, fill=G4+(255,))
    rb_arr = np.array(right_base)
    rb_arr[:, :bcx] = 0
    right_base = Image.fromarray(rb_arr)
    
    canvas = composite(canvas, left_base)
    canvas = composite(canvas, right_base)
    
    # ── Gyri texture ───────────────────────────────────────────
    canvas = draw_gyri(canvas, bpts, bcx, bcy, brw, brh, 'left')
    canvas = draw_gyri(canvas, bpts, bcx, bcy, brw, brh, 'right')
    
    # ── Glow on brain halves ────────────────────────────────────
    # Extract each half for glow
    brain_full = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    ImageDraw.Draw(brain_full).polygon(bpts_int, fill=(255,255,255,30))
    
    mag_glow_layer = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    ImageDraw.Draw(mag_glow_layer).polygon(
        [(min(x, bcx), y) for x,y in bpts_int], fill=M1+(150,))
    mag_arr = np.array(mag_glow_layer); mag_arr[:, bcx:] = 0
    mag_glow_layer = Image.fromarray(mag_arr)
    
    grn_glow_layer = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    ImageDraw.Draw(grn_glow_layer).polygon(
        [(max(x, bcx), y) for x,y in bpts_int], fill=G1+(150,))
    grn_arr = np.array(grn_glow_layer); grn_arr[:, :bcx] = 0
    grn_glow_layer = Image.fromarray(grn_arr)
    
    canvas = add_glow(canvas, mag_glow_layer, [(4, 0.5), (12, 0.3), (25, 0.15)])
    canvas = add_glow(canvas, grn_glow_layer, [(4, 0.5), (12, 0.3), (25, 0.15)])
    
    # ── Medial fissure ──────────────────────────────────────────
    fissure = draw_fissure(canvas, bpts, bcx)
    canvas = add_glow(canvas, fissure, [(2, 0.8), (6, 0.4)])
    
    # ── Edge highlight (rim light) ──────────────────────────────
    edge_l = edge_highlight(bpts)
    canvas = add_glow(canvas, edge_l, [(2, 0.8), (5, 0.4)])
    
    # ── Bitcoin ₿ symbol ────────────────────────────────────────
    # Find brain bounds at center
    bm_img = Image.new("L", (WORK,WORK), 0)
    ImageDraw.Draw(bm_img).polygon(bpts_int, fill=255)
    bma = np.array(bm_img)
    rows_at_cx = np.where(bma[:, bcx] > 0)[0]
    brain_top = int(rows_at_cx[0])  if len(rows_at_cx) else int(bcy - brh)
    brain_bot = int(rows_at_cx[-1]) if len(rows_at_cx) else int(bcy + brh)
    brain_height = brain_bot - brain_top
    
    btc_layer = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    btc_h = int(brain_height * 0.48)   # Bitcoin glyph height
    draw_bitcoin(btc_layer, bcx, bcy, btc_h)
    
    # Mask BTC to brain interior
    btc_arr = np.array(btc_layer)
    btc_arr[...,3] = np.minimum(btc_arr[...,3], bma)
    btc_layer = Image.fromarray(btc_arr)
    
    canvas = add_glow(canvas, btc_layer, [(2, 1.0), (6, 0.7), (14, 0.45), (28, 0.2)])
    
    # ── BIOHACKER text ──────────────────────────────────────────
    text_layer = Image.new("RGBA", (WORK,WORK), (0,0,0,0))
    td = ImageDraw.Draw(text_layer)
    
    text = "BIOHACKER"
    
    try:
        font = ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf", size=14)
    except:
        try:
            font = ImageFont.truetype(f"{FONT_DIR}/PixelifySans-Medium.ttf", size=14)
        except:
            font = ImageFont.load_default()
    
    bbox  = td.textbbox((0,0), text, font=font)
    tw    = bbox[2] - bbox[0]
    th    = bbox[3] - bbox[1]
    
    # Vertically: center in space below brain
    gap       = 5
    text_y    = brain_bot + gap
    text_x    = WORK//2 - tw//2
    
    # Clamp to canvas
    if text_y + th > WORK - 4:
        text_y = WORK - 4 - th
    
    # Shadow
    td.text((text_x+1, text_y+1), text, font=font, fill=C2+(180,))
    # Main
    td.text((text_x, text_y), text, font=font, fill=C0+(255,))
    # Pixel highlight line: brightest pixels at top of glyphs
    td.line([(text_x, text_y), (text_x+tw, text_y)], fill=(255,255,255,80), width=1)
    
    canvas = add_glow(canvas, text_layer, [(1, 1.0), (4, 0.8), (10, 0.5), (18, 0.25)])
    
    # ── 4× NEAREST upscale ──────────────────────────────────────
    big = canvas.resize((SIZE,SIZE), Image.NEAREST)
    
    # ── Post-process at 1024×1024 ────────────────────────────────
    big_arr = np.array(big, dtype=np.float32)
    
    # 1) Vignette
    ys = np.linspace(-1, 1, SIZE)
    xs = np.linspace(-1, 1, SIZE)
    xx, yy = np.meshgrid(xs, ys)
    dist = np.sqrt(xx**2 + yy**2)
    vig = np.clip(1.0 - dist * 0.50, 0.45, 1.0)
    big_arr[..., :3] *= vig[..., np.newaxis]
    
    # 2) Wide atmospheric bloom (very subtle)
    big_rgb = Image.fromarray(big_arr.clip(0,255).astype(np.uint8)).convert("RGB")
    bloom = big_rgb.filter(ImageFilter.GaussianBlur(5))
    ba  = np.array(big_rgb,  dtype=np.float32)
    blo = np.array(bloom, dtype=np.float32)
    big_rgb = Image.fromarray((ba * 0.85 + blo * 0.15).clip(0,255).astype(np.uint8))
    
    # 3) Subtle scanlines (every 4px at 1024 = every pixel at 256 → corresponds to pixel rows)
    sla = np.array(big_rgb, dtype=np.float32)
    for y in range(0, SIZE, SCALE):
        sla[y] = sla[y] * 0.88
    big_rgb = Image.fromarray(sla.clip(0,255).astype(np.uint8))
    
    return big_rgb

# ── RUN ───────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Building BIOHACKER icon v4c (256→1024px pixel art)...")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    
    icon = build()
    icon.save(OUT_PATH, "PNG")
    
    v = Image.open(OUT_PATH)
    print(f"Saved  : {OUT_PATH}")
    print(f"Size   : {v.size[0]}x{v.size[1]}")
    print(f"Mode   : {v.mode}")
    print(f"Bytes  : {os.path.getsize(OUT_PATH):,}")
