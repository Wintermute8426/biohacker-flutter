#!/usr/bin/env python3
"""
BIOHACKER App Icon - Final Version
1024×1024 PNG, neon cyberpunk pixel art aesthetic
- Proper anatomical brain silhouette with neon glow halves
- ₿ rendered via IBMPlexMono-Bold font (clean, readable)
- BIOHACKER in Silkscreen pixel font
- Volumetric neon glow throughout
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

SIZE     = 1024
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"
OUT_PATH = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"

# ── COLOR PALETTE ──────────────────────────────────────────────────────────
# Neon magenta (left brain)
MAG = [
    (255, 20,  240),   # 0 hottest
    (230, 0,   190),   # 1 bright
    (180, 0,   140),   # 2 mid
    (100, 0,    75),   # 3 shadow
    ( 40, 0,    28),   # 4 deep
]
# Neon green (right brain)
GRN = [
    ( 60, 255, 100),   # 0 hottest
    (  0, 220,  70),   # 1 bright
    (  0, 160,  50),   # 2 mid
    (  0,  75,  25),   # 3 shadow
    (  0,  25,   8),   # 4 deep
]
# Gold (Bitcoin)
GOLD_H   = (255, 240,  70)
GOLD_MID = (235, 185,   0)
GOLD_D   = (150, 100,   0)

# Cyan (text)
CYAN_H   = (  0, 255, 255)
CYAN_M   = (  0, 200, 230)

# BG
BLACK    = (  0,   0,   0)
CIRCUIT  = (  0,  25,  18)

# ── BRAIN SILHOUETTE (anatomical, clean) ───────────────────────────────────

def brain_polygon(cx, cy, rw, rh, n=800):
    """
    Generate a cleaner, more anatomically recognizable brain outline.
    Key features:
    - Bumpy top with ~5 visible lobes
    - Temporal lobe bulge on lower sides
    - Flat bottom (brainstem cut)
    - Deep central fissure
    """
    pts = []
    for i in range(n):
        t = 2*math.pi * i / n
        bx = rw * math.cos(t)
        by = rh * math.sin(t)
        
        # Normalize angle to [0, 2pi]
        t_norm = t % (2*math.pi)
        
        # In PIL: t=0 → right, t=pi/2 → DOWN, t=pi → left, t=3pi/2 → UP
        # So "top" of brain in screen coords is t=3pi/2 (or ~4.71)
        
        # TOP half (roughly t in [pi, 2pi], i.e. going from left, up, to right)
        # Gyral bumps on top
        if math.sin(t) < 0:  # upper half (negative y = up in screen)
            top_strength = -math.sin(t)  # 0 at sides, 1 at very top
            gyri = (
                top_strength * 0.13 * math.sin(5 * t + 0.4) +    # 5 main lobes
                top_strength * 0.06 * math.sin(10 * t + 0.9) +   # sub-gyri
                top_strength * 0.03 * math.sin(15 * t + 0.2)     # micro detail
            )
        else:
            gyri = 0.0
        
        # Temporal lobe bulge (lower sides, ~t=pi/4 and t=3pi/4)
        temporal = 0.06 * (math.exp(-((t - math.pi/3)**2) / 0.15) +
                           math.exp(-((t - 2*math.pi/3)**2) / 0.15))
        
        # Flatten the very bottom (brainstem)
        if by > rh * 0.65:
            by = rh * 0.65 + (by - rh * 0.65) * 0.4
        
        # Slight oval-ification: wider at top
        top_width = 1.0 + 0.05 * max(0, -by / rh)
        bx *= top_width
        
        r = 1.0 + gyri + temporal
        pts.append((cx + r*bx, cy + r*by))
    
    return pts

def gyri_mask_bands(canvas, brain_pts_list, cx, bcy, brw, brh, side):
    """
    Paint neon gyri on one hemisphere using horizontal scan lines.
    Uses a proper 2D gyral pattern based on cortical fold math.
    """
    arr = np.array(canvas)
    
    # Build brain mask
    bm = Image.new("L", (SIZE, SIZE), 0)
    ImageDraw.Draw(bm).polygon([(int(x), int(y)) for x,y in brain_pts_list], fill=255)
    bma = np.array(bm)
    
    pal  = MAG if side == 'left' else GRN
    
    # For each row in the brain, shade based on 2D gyral pattern
    rows = np.where(bma.max(axis=1) > 0)[0]
    if len(rows) == 0:
        return canvas
    
    y_top = rows[0]
    y_bot = rows[-1]
    h_brain = y_bot - y_top
    
    for y in range(y_top, y_bot + 1):
        # Row scan
        row = bma[y]
        if side == 'left':
            xs = np.where((row > 0) & (np.arange(SIZE) < cx))[0]
        else:
            xs = np.where((row > 0) & (np.arange(SIZE) >= cx))[0]
        
        if len(xs) == 0:
            continue
        
        # Vertical position (0=top, 1=bottom)
        vy = (y - y_top) / h_brain
        
        for x in xs:
            if x < 0 or x >= SIZE or y < 0 or y >= SIZE:
                continue
            
            # Horizontal position within this half (0=center, 1=outer edge)
            hx = abs(x - cx) / max(1, abs(xs[0] - cx) if side == 'right' else abs(xs[-1] - cx))
            hx = min(hx, 1.0)
            
            # 2D gyral wave function
            # Gyri run mostly horizontally (anterior-posterior on a top-view brain)
            # Number of gyri: ~6-8 on the superior surface
            n_gyri = 7
            
            # The gyri wave: frequency increases from top to bottom (more folds lower)
            freq = n_gyri * (0.8 + 0.4 * vy)
            phase = vy * freq * 2 * math.pi
            
            # Gyrus crown (positive) vs sulcus (negative)
            gyrus_val = math.sin(phase)
            
            # Also modulate by horizontal curvature of the lobe
            curve = math.sin(hx * math.pi)  # 0 at edge, 1 at center
            
            # The crown of each gyrus gets the brightest pixels
            # The sulcus (fold valley) gets the darkest
            combined = gyrus_val * 0.65 + curve * 0.35
            
            # Dithering for transition bands
            dither = (x + y) % 2
            
            # Normalize combined to [0, 1]
            norm = (combined + 1) / 2
            
            # Map to palette
            if norm > 0.82:
                col = pal[0]
            elif norm > 0.65:
                col = pal[1] if not dither else pal[0]
            elif norm > 0.48:
                col = pal[2] if not dither else pal[1]
            elif norm > 0.32:
                col = pal[3] if not dither else pal[2]
            elif norm > 0.18:
                col = pal[3]
            else:
                col = pal[4]
            
            arr[y, x, 0] = col[0]
            arr[y, x, 1] = col[1]
            arr[y, x, 2] = col[2]
            arr[y, x, 3] = 255
    
    return Image.fromarray(arr)

def composite(base, over):
    return Image.alpha_composite(base, over)

def make_glow(layer, blur, alpha):
    g = layer.filter(ImageFilter.GaussianBlur(blur))
    a = np.array(g, dtype=np.float32)
    a[..., 3] = (a[..., 3] * alpha).clip(0, 255)
    return Image.fromarray(a.astype(np.uint8))

def add_glow(base, layer, specs):
    """specs = [(blur, alpha), ...]"""
    for blur, alpha in specs:
        base = composite(base, make_glow(layer, blur, alpha))
    return composite(base, layer)

def draw_circuits(canvas):
    rng = np.random.default_rng(42)
    d = ImageDraw.Draw(canvas)
    for _ in range(30):
        x1 = int(rng.integers(10, SIZE-10))
        y1 = int(rng.integers(10, SIZE-10))
        x2 = int(rng.integers(10, SIZE-10))
        y2 = int(rng.integers(10, SIZE-10))
        d.line([(x1,y1),(x2,y1)], fill=CIRCUIT+(255,), width=2)
        d.line([(x2,y1),(x2,y2)], fill=CIRCUIT+(255,), width=2)
        d.ellipse([x2-3,y1-3,x2+3,y1+3], fill=(0,38,28,255))

def build():
    # ── Base canvas ──────────────────────────────────────────────────────
    canvas = Image.new("RGBA", (SIZE, SIZE), BLACK+(255,))
    draw_circuits(canvas)
    
    # ── Brain parameters ─────────────────────────────────────────────────
    bcx = SIZE // 2         # 512  horizontal center
    bcy = int(SIZE * 0.385) # 394  vertical center of brain
    brw = int(SIZE * 0.415) # 425  horizontal radius
    brh = int(SIZE * 0.345) # 353  vertical radius
    
    bpts = brain_polygon(bcx, bcy, brw, brh)
    bpts_int = [(int(x), int(y)) for x,y in bpts]
    
    # ── Brain mask ───────────────────────────────────────────────────────
    bm_img = Image.new("L", (SIZE,SIZE), 0)
    ImageDraw.Draw(bm_img).polygon(bpts_int, fill=255)
    bma = np.array(bm_img)
    
    # Find brain vertical extent at center x
    cx_col = bma[:, bcx]
    rows   = np.where(cx_col > 0)[0]
    brain_top = int(rows[0])  if len(rows) else int(bcy - brh)
    brain_bot = int(rows[-1]) if len(rows) else int(bcy + brh)
    
    # ── Fill base (deepest shadows) ───────────────────────────────────────
    base_layer = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    bd = ImageDraw.Draw(base_layer)
    bd.polygon(bpts_int, fill=MAG[4]+(255,))
    # Apply left mask
    bl = np.array(base_layer); bl[:, bcx:] = 0
    left_base = Image.fromarray(bl)
    
    base_layer2 = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(base_layer2).polygon(bpts_int, fill=GRN[4]+(255,))
    br = np.array(base_layer2); br[:, :bcx] = 0
    right_base = Image.fromarray(br)
    
    canvas = composite(canvas, left_base)
    canvas = composite(canvas, right_base)
    
    # ── Gyri texture ─────────────────────────────────────────────────────
    canvas = gyri_mask_bands(canvas, bpts, bcx, bcy, brw, brh, 'left')
    canvas = gyri_mask_bands(canvas, bpts, bcx, bcy, brw, brh, 'right')
    
    # ── Outer rim highlight (neon edge glow) ─────────────────────────────
    rim_layer = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    rd = ImageDraw.Draw(rim_layer)
    rd.line(bpts_int + [bpts_int[0]], fill=MAG[0]+(220,), width=4)
    # Mask rim to brain area (expanded 2px)
    bm_exp = bm_img.filter(ImageFilter.MaxFilter(5))
    ra = np.array(rim_layer)
    ra[...,3] = np.minimum(ra[...,3], np.array(bm_exp))
    # Split rim colors
    ra_l = ra.copy(); ra_l[:, bcx:] = 0
    ra_r = ra.copy(); ra_r[:, :bcx] = 0
    # Recolor
    ra_r[:,:,0] = (ra_r[:,:,0].astype(int) * GRN[0][0] // 255).clip(0,255)
    ra_r[:,:,1] = (ra_r[:,:,1].astype(int) * GRN[0][1] // 255).clip(0,255)
    ra_r[:,:,2] = (ra_r[:,:,2].astype(int) * GRN[0][2] // 255).clip(0,255)
    
    rim_left  = Image.fromarray(ra_l)
    rim_right = Image.fromarray(ra_r)
    
    canvas = add_glow(canvas, rim_left,  [(6, 0.8), (18, 0.5), (40, 0.25)])
    canvas = add_glow(canvas, rim_right, [(6, 0.8), (18, 0.5), (40, 0.25)])
    
    # ── Medial fissure ────────────────────────────────────────────────────
    fiss = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    fd = ImageDraw.Draw(fiss)
    fd.line([(bcx-2, brain_top), (bcx-2, brain_bot)], fill=MAG[3]+(200,), width=3)
    fd.line([(bcx+2, brain_top), (bcx+2, brain_bot)], fill=GRN[3]+(200,), width=3)
    fd.line([(bcx,   brain_top), (bcx,   brain_bot)], fill=(0,0,0,255),   width=2)
    canvas = add_glow(canvas, fiss, [(3, 0.7), (10, 0.4)])
    
    # ── Brain ambient glow (outer halo) ───────────────────────────────────
    glow_mag = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(glow_mag).polygon(bpts_int, fill=MAG[1]+(120,))
    gm_a = np.array(glow_mag); gm_a[:, bcx:] = 0
    glow_mag = Image.fromarray(gm_a)
    
    glow_grn = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(glow_grn).polygon(bpts_int, fill=GRN[1]+(120,))
    gg_a = np.array(glow_grn); gg_a[:, :bcx] = 0
    glow_grn = Image.fromarray(gg_a)
    
    canvas = add_glow(canvas, glow_mag, [(15, 0.4), (35, 0.2), (70, 0.1)])
    canvas = add_glow(canvas, glow_grn, [(15, 0.4), (35, 0.2), (70, 0.1)])
    
    # ── Bitcoin ₿ symbol (font-rendered, gold, centered in brain) ─────────
    # Size: ~45% of brain height for readability
    btc_h = int((brain_bot - brain_top) * 0.52)
    
    try:
        btc_font = ImageFont.truetype(f"{FONT_DIR}/IBMPlexMono-Bold.ttf", btc_h)
    except:
        btc_font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf", btc_h)
    
    btc_layer = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    btc_d = ImageDraw.Draw(btc_layer)
    
    bb = btc_d.textbbox((0,0), "₿", font=btc_font)
    bw = bb[2] - bb[0]
    bh = bb[3] - bb[1]
    
    # Center vertically in brain, center horizontally
    btc_x = bcx - bw // 2 - bb[0]
    btc_y = bcy - bh // 2 - bb[1]
    
    # Shadow first
    btc_d.text((btc_x+3, btc_y+3), "₿", font=btc_font, fill=GOLD_D+(180,))
    # Main gold
    btc_d.text((btc_x, btc_y), "₿", font=btc_font, fill=GOLD_MID+(255,))
    # Highlight pass: sample and brighten
    btc_arr = np.array(btc_layer)
    bright_mask = btc_arr[...,0] > 180
    btc_arr[bright_mask, 0] = np.minimum(btc_arr[bright_mask, 0].astype(int) + 30, 255).astype(np.uint8)
    btc_arr[bright_mask, 1] = np.minimum(btc_arr[bright_mask, 1].astype(int) + 40, 255).astype(np.uint8)
    btc_layer = Image.fromarray(btc_arr)
    
    # Mask BTC to brain interior
    btc_arr2 = np.array(btc_layer)
    btc_arr2[...,3] = np.minimum(btc_arr2[...,3], bma)
    btc_layer = Image.fromarray(btc_arr2)
    
    canvas = add_glow(canvas, btc_layer, [(5, 0.9), (15, 0.65), (30, 0.35), (55, 0.15)])
    
    # ── "BIOHACKER" text ──────────────────────────────────────────────────
    # Dynamic font size: fill ~80% of icon width
    target_w = int(SIZE * 0.82)
    
    def fit_font(target_width, font_path, text):
        for sz in range(200, 10, -2):
            f = ImageFont.truetype(font_path, sz)
            bb = ImageDraw.Draw(Image.new("L",(10,10))).textbbox((0,0), text, font=f)
            if (bb[2]-bb[0]) <= target_width:
                return f, bb
        return f, bb
    
    try:
        text_font, text_bb = fit_font(target_w, f"{FONT_DIR}/Silkscreen-Regular.ttf", "BIOHACKER")
    except:
        try:
            text_font, text_bb = fit_font(target_w, f"{FONT_DIR}/JetBrainsMono-Bold.ttf", "BIOHACKER")
        except:
            text_font = ImageFont.load_default()
            text_bb = (0, 0, 200, 20)
    
    tw = text_bb[2] - text_bb[0]
    th = text_bb[3] - text_bb[1]
    
    # Center horizontally, position below brain with gap
    gap     = int(SIZE * 0.025)
    text_x  = SIZE//2 - tw//2 - text_bb[0]
    text_y  = brain_bot + gap - text_bb[1]
    
    # If text overflows bottom, scale down
    if text_y + th > SIZE - 20:
        text_y = SIZE - 20 - th
    
    text_layer = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    td = ImageDraw.Draw(text_layer)
    
    # Dark shadow
    td.text((text_x+4, text_y+4), "BIOHACKER", font=text_font, fill=(0,60,70,200))
    # Main cyan
    td.text((text_x,   text_y),   "BIOHACKER", font=text_font, fill=CYAN_H+(255,))
    # Bright highlight on top pixel row
    td.line([(text_x, text_y), (text_x+tw, text_y)], fill=(255,255,255,120), width=2)
    
    canvas = add_glow(canvas, text_layer, [(4, 1.0), (12, 0.75), (25, 0.4), (45, 0.2)])
    
    # ── Convert to RGB and post-process ────────────────────────────────────
    out = Image.new("RGB", (SIZE,SIZE), BLACK)
    out.paste(canvas.convert("RGB"), (0,0))
    
    # Vignette
    arr = np.array(out, dtype=np.float32)
    ys = np.linspace(-1, 1, SIZE)
    xs = np.linspace(-1, 1, SIZE)
    xx, yy = np.meshgrid(xs, ys)
    dist = np.sqrt(xx**2 + yy**2)
    vig = np.clip(1.0 - dist * 0.42, 0.5, 1.0)
    arr *= vig[..., np.newaxis]
    out = Image.fromarray(arr.clip(0,255).astype(np.uint8))
    
    # Subtle atmospheric bloom
    bloom = out.filter(ImageFilter.GaussianBlur(4))
    ba = np.array(out, dtype=np.float32)
    bl = np.array(bloom, dtype=np.float32)
    out = Image.fromarray((ba*0.87 + bl*0.13).clip(0,255).astype(np.uint8))
    
    return out

# ── RUN ───────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Building BIOHACKER icon (final)...")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    icon = build()
    icon.save(OUT_PATH, "PNG")
    v = Image.open(OUT_PATH)
    print(f"Saved  : {OUT_PATH}")
    print(f"Size   : {v.size[0]}x{v.size[1]}")
    print(f"Bytes  : {os.path.getsize(OUT_PATH):,}")
