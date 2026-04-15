#!/usr/bin/env python3
"""
BIOHACKER App Icon v5 - Cinematic Neon
1024×1024 PNG
Focus: visible brain folds + massive neon glow
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

SIZE     = 1024
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"
OUT_PATH = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"

# ── PALETTE ────────────────────────────────────────────────────────────────
M_BRIGHT = (255,  25, 245)
M_HOT    = (230,   0, 200)
M_MID    = (175,   0, 145)
M_DARK   = ( 90,   0,  72)
M_DEEP   = ( 35,   0,  28)

G_BRIGHT = ( 50, 255,  95)
G_HOT    = (  0, 225,  68)
G_MID    = (  0, 160,  48)
G_DARK   = (  0,  75,  22)
G_DEEP   = (  0,  25,   8)

GOLD_H   = (255, 248, 100)
GOLD_M   = (245, 195,   0)
GOLD_D   = (160, 110,   0)

CYAN_H   = (  0, 255, 255)
CYAN_M   = (  0, 210, 240)
CYAN_D   = (  0,  90, 120)

BLACK    = (  0,   0,   0)
CIRCUIT  = (  0,  28,  20)

# ── HELPERS ────────────────────────────────────────────────────────────────

def composite(base, over):
    return Image.alpha_composite(base, over)

def blur_layer(layer, radius, alpha=1.0):
    g = layer.filter(ImageFilter.GaussianBlur(radius))
    a = np.array(g, dtype=np.float32)
    a[..., 3] = (a[..., 3] * alpha).clip(0, 255)
    return Image.fromarray(a.astype(np.uint8))

def add_glow(base, layer, specs):
    for radius, alpha in specs:
        base = composite(base, blur_layer(layer, radius, alpha))
    return composite(base, layer)

# ── BRAIN SILHOUETTE ────────────────────────────────────────────────────────

def make_brain_pts(cx, cy, rw, rh, n=1000):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        bx = rw * math.cos(t)
        by = rh * math.sin(t)
        
        # In PIL: y increases downward. t=3pi/2 → top of brain (by is most negative)
        # sin(t) < 0 means upper half of brain
        top_factor = max(0, -math.sin(t))  # 1 at crown, 0 at base
        
        # Cortical folding pattern (sinusoidal gyri on top)
        gyri = (
            top_factor * 0.12 * math.sin(4.5 * t + 0.35) +   # major lobes
            top_factor * 0.06 * math.sin( 9.0 * t + 0.85) +  # secondary gyri
            top_factor * 0.03 * math.sin(14.0 * t + 0.25)    # fine detail
        )
        
        # Temporal bulge on lower-lateral sides
        temp_angle_l = math.pi * 0.30  # left temporal
        temp_angle_r = math.pi * 0.70  # right temporal  
        temporal = (
            0.07 * math.exp(-((t - temp_angle_l)**2) / 0.10) +
            0.07 * math.exp(-((t - temp_angle_r)**2) / 0.10)
        )
        
        # Flatten bottom (brainstem cut)
        flat = max(0, math.sin(t))  # only lower half
        if by > rh * 0.60:
            by = rh * 0.60 + (by - rh * 0.60) * 0.35
        
        # Slight widening at top
        if by < 0:
            bx *= 1.0 + 0.06 * (-by / rh)
        
        r = 1.0 + gyri + temporal
        pts.append((cx + r * bx, cy + r * by))
    
    return pts

# ── BRAIN FOLD RENDERING ───────────────────────────────────────────────────

def paint_gyri(canvas, bpts, cx, side):
    """
    Paint visible gyral folds using explicit fold curves drawn as filled shapes.
    Each gyrus: bright crown, dark sulci on either side.
    """
    arr = np.array(canvas)
    
    # Brain mask
    bm = Image.new("L", (SIZE,SIZE), 0)
    ImageDraw.Draw(bm).polygon([(int(x),int(y)) for x,y in bpts], fill=255)
    bma = np.array(bm)
    
    # Find vertical extent
    rows = np.where(bma.max(axis=1) > 0)[0]
    if len(rows) == 0:
        return canvas
    y_top = rows[0]
    y_bot = rows[-1]
    H_brain = y_bot - y_top
    
    pal = [M_BRIGHT, M_HOT, M_MID, M_DARK, M_DEEP] if side == 'left' \
          else [G_BRIGHT, G_HOT, G_MID, G_DARK, G_DEEP]
    
    N_FOLDS = 8   # number of gyral bands across the brain height
    
    for y in range(y_top, y_bot + 1):
        row = bma[y]
        if side == 'left':
            xs = np.where((row > 0) & (np.arange(SIZE) < cx))[0]
        else:
            xs = np.where((row > 0) & (np.arange(SIZE) >= cx))[0]
        
        if len(xs) == 0:
            continue
        
        x_min = xs[0]
        x_max = xs[-1]
        x_span = max(1, x_max - x_min)
        
        vy = (y - y_top) / H_brain  # 0=top, 1=bottom
        
        # Gyral phase varies with vertical position
        # More gyri visible in the upper 70% (cortical surface),
        # fewer at base (temporal/occipital)
        fold_freq = N_FOLDS * (1.2 - 0.4 * vy)   # slightly higher freq at top
        fold_phase = vy * fold_freq * 2 * math.pi
        
        for x in xs:
            hx = (x - x_min) / x_span  # 0=brain center side, 1=outer edge
            
            # Each fold has an arch: bright at crown, dark in valleys
            # The fold pattern: primary (large) + secondary (smaller)
            primary   = math.sin(fold_phase)
            secondary = 0.4 * math.sin(fold_phase * 2.2 + 0.5)
            
            # Convexity of the lobe surface (gyri curve away from center at top)
            convex = math.sin(hx * math.pi)  # 0 at edges, peak in middle
            
            # Combine
            val = primary * 0.60 + secondary * 0.20 + convex * 0.20
            norm = (val + 1.0) / 2.0  # map [-1,1] → [0,1]
            
            # Dithering at transition zones
            d = (x + y) % 2
            
            # More granular color mapping with dithering
            if norm > 0.85:
                col = pal[0]   # absolute crown
            elif norm > 0.70:
                col = pal[0] if d else pal[1]
            elif norm > 0.55:
                col = pal[1]
            elif norm > 0.42:
                col = pal[1] if d else pal[2]
            elif norm > 0.30:
                col = pal[2]
            elif norm > 0.20:
                col = pal[2] if d else pal[3]
            elif norm > 0.12:
                col = pal[3]
            elif norm > 0.06:
                col = pal[3] if d else pal[4]
            else:
                col = pal[4]
            
            arr[y, x, 0] = col[0]
            arr[y, x, 1] = col[1]
            arr[y, x, 2] = col[2]
            arr[y, x, 3] = 255
    
    return Image.fromarray(arr)

# ── CIRCUIT BACKGROUND ──────────────────────────────────────────────────────

def draw_bg(canvas):
    rng = np.random.default_rng(55)
    d = ImageDraw.Draw(canvas)
    for _ in range(35):
        x1 = int(rng.integers(8, SIZE-8))
        y1 = int(rng.integers(8, SIZE-8))
        x2 = int(rng.integers(8, SIZE-8))
        y2 = int(rng.integers(8, SIZE-8))
        d.line([(x1,y1),(x2,y1)], fill=CIRCUIT+(255,), width=2)
        d.line([(x2,y1),(x2,y2)], fill=CIRCUIT+(255,), width=2)
        d.ellipse([x2-3, y1-3, x2+3, y1+3], fill=(0,45,32,255))

# ── MAIN BUILD ─────────────────────────────────────────────────────────────

def build():
    canvas = Image.new("RGBA", (SIZE,SIZE), BLACK+(255,))
    draw_bg(canvas)
    
    # Brain placement
    bcx = SIZE // 2
    bcy = int(SIZE * 0.382)
    brw = int(SIZE * 0.415)
    brh = int(SIZE * 0.348)
    
    bpts = make_brain_pts(bcx, bcy, brw, brh)
    bpts_i = [(int(x),int(y)) for x,y in bpts]
    
    # Masks
    bm_img = Image.new("L", (SIZE,SIZE), 0)
    ImageDraw.Draw(bm_img).polygon(bpts_i, fill=255)
    bma = np.array(bm_img)
    
    # Vertical extent
    cx_rows = np.where(bma[:, bcx] > 0)[0]
    brain_top = int(cx_rows[0])  if len(cx_rows) else bcy - brh
    brain_bot = int(cx_rows[-1]) if len(cx_rows) else bcy + brh
    
    # ── Base fill (deep shadow) ──────────────────────────────────
    base = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(base).polygon(bpts_i, fill=M_DEEP+(255,))
    ba = np.array(base); ba[:,bcx:] = 0
    canvas = composite(canvas, Image.fromarray(ba))
    
    base2 = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(base2).polygon(bpts_i, fill=G_DEEP+(255,))
    ba2 = np.array(base2); ba2[:,:bcx] = 0
    canvas = composite(canvas, Image.fromarray(ba2))
    
    # ── Gyri ────────────────────────────────────────────────────
    canvas = paint_gyri(canvas, bpts, bcx, 'left')
    canvas = paint_gyri(canvas, bpts, bcx, 'right')
    
    # ── Neon glow on brain ───────────────────────────────────────
    # Large ambient halo
    glow_shape = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(glow_shape).polygon(bpts_i, fill=(255,255,255,200))
    
    mag_halo = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(mag_halo).polygon(bpts_i, fill=M_HOT+(180,))
    ma = np.array(mag_halo); ma[:,bcx:] = 0
    mag_halo = Image.fromarray(ma)
    
    grn_halo = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(grn_halo).polygon(bpts_i, fill=G_HOT+(180,))
    ga = np.array(grn_halo); ga[:,:bcx] = 0
    grn_halo = Image.fromarray(ga)
    
    # Big outer bloom
    canvas = add_glow(canvas, mag_halo, [(20, 0.30), (50, 0.18), (100, 0.09)])
    canvas = add_glow(canvas, grn_halo, [(20, 0.30), (50, 0.18), (100, 0.09)])
    
    # Bright inner glow
    mag_bright = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(mag_bright).polygon(bpts_i, fill=M_BRIGHT+(220,))
    mba = np.array(mag_bright); mba[:,bcx:] = 0
    mag_bright = Image.fromarray(mba)
    
    grn_bright = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(grn_bright).polygon(bpts_i, fill=G_BRIGHT+(220,))
    gba = np.array(grn_bright); gba[:,:bcx] = 0
    grn_bright = Image.fromarray(gba)
    
    # Only use glow (NOT the filled shape itself)
    for radius, alpha in [(8, 0.4), (20, 0.25), (40, 0.12)]:
        canvas = composite(canvas, blur_layer(mag_bright, radius, alpha))
        canvas = composite(canvas, blur_layer(grn_bright, radius, alpha))
    
    # ── Rim light (neon edge) ────────────────────────────────────
    rim = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    rd = ImageDraw.Draw(rim)
    rd.line(bpts_i + [bpts_i[0]], fill=M_BRIGHT+(200,), width=6)
    
    # Split rim
    ra = np.array(rim)
    ra_l = ra.copy(); ra_l[:,bcx:] = 0
    ra_r = ra.copy(); ra_r[:,:bcx] = 0
    # Green-tint right rim
    ra_r_f = ra_r.astype(np.float32)
    ra_r_f[...,0] *= 0.2; ra_r_f[...,1] = np.minimum(ra_r_f[...,1] * 0.5 + 100, 255)
    ra_r = ra_r_f.clip(0,255).astype(np.uint8)
    
    rim_l = Image.fromarray(ra_l)
    rim_r = Image.fromarray(ra_r)
    
    canvas = add_glow(canvas, rim_l, [(4, 0.8), (14, 0.5), (35, 0.25)])
    canvas = add_glow(canvas, rim_r, [(4, 0.8), (14, 0.5), (35, 0.25)])
    
    # ── Medial fissure ───────────────────────────────────────────
    fiss = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(fiss).line(
        [(bcx, brain_top), (bcx, brain_bot)], fill=(0,0,0,255), width=4)
    # Faint magenta/green glow on fissure edges
    fiss_mag = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(fiss_mag).line(
        [(bcx-3, brain_top), (bcx-3, brain_bot)], fill=M_MID+(160,), width=2)
    fiss_grn = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(fiss_grn).line(
        [(bcx+3, brain_top), (bcx+3, brain_bot)], fill=G_MID+(160,), width=2)
    
    canvas = composite(canvas, fiss)
    canvas = add_glow(canvas, fiss_mag, [(3,0.7),(10,0.4)])
    canvas = add_glow(canvas, fiss_grn, [(3,0.7),(10,0.4)])
    
    # ── Bitcoin ₿ ────────────────────────────────────────────────
    btc_size = int((brain_bot - brain_top) * 0.50)
    try:
        btc_font = ImageFont.truetype(f"{FONT_DIR}/IBMPlexMono-Bold.ttf", btc_size)
    except:
        btc_font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf", btc_size)
    
    btc_lyr = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    bd = ImageDraw.Draw(btc_lyr)
    bb = bd.textbbox((0,0), "₿", font=btc_font)
    bw, bh = bb[2]-bb[0], bb[3]-bb[1]
    bx = bcx - bw//2 - bb[0]
    by_ = bcy - bh//2 - bb[1]
    
    # Dark shadow
    bd.text((bx+4, by_+4), "₿", font=btc_font, fill=GOLD_D+(200,))
    # Base gold
    bd.text((bx,   by_),   "₿", font=btc_font, fill=GOLD_M+(255,))
    # Bright highlight
    ba2 = np.array(btc_lyr)
    hot = ba2[...,0] > 150
    ba2[hot,0] = np.minimum(ba2[hot,0].astype(int) + 40, 255)
    ba2[hot,1] = np.minimum(ba2[hot,1].astype(int) + 50, 255)
    ba2[hot,2] = np.minimum(ba2[hot,2].astype(int) + 0, 255)
    btc_lyr = Image.fromarray(ba2)
    
    # Mask to brain
    ba3 = np.array(btc_lyr)
    ba3[...,3] = np.minimum(ba3[...,3], bma)
    btc_lyr = Image.fromarray(ba3)
    
    canvas = add_glow(canvas, btc_lyr, [(6,1.0),(16,0.7),(35,0.4),(65,0.2)])
    
    # ── BIOHACKER text ───────────────────────────────────────────
    target_w = int(SIZE * 0.80)
    
    try:
        # Find fitting font size
        for sz in range(250, 20, -2):
            f = ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf", sz)
            bb_t = ImageDraw.Draw(Image.new("L",(10,10))).textbbox((0,0),"BIOHACKER",font=f)
            if (bb_t[2]-bb_t[0]) <= target_w:
                text_font = f
                text_bb   = bb_t
                break
    except:
        text_font = ImageFont.load_default()
        text_bb   = (0,0,200,20)
    
    tw = text_bb[2]-text_bb[0]
    th = text_bb[3]-text_bb[1]
    
    gap    = int(SIZE * 0.030)
    text_x = SIZE//2 - tw//2 - text_bb[0]
    text_y = brain_bot + gap - text_bb[1]
    if text_y + th > SIZE - 25:
        text_y = SIZE - 25 - th
    
    txt_lyr = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    td = ImageDraw.Draw(txt_lyr)
    # Dark backing
    td.text((text_x+5, text_y+5), "BIOHACKER", font=text_font, fill=CYAN_D+(180,))
    # Main cyan
    td.text((text_x,   text_y),   "BIOHACKER", font=text_font, fill=CYAN_H+(255,))
    # Top-edge highlight
    td.line([(text_x, text_y),(text_x+tw, text_y)], fill=(255,255,255,100), width=2)
    
    canvas = add_glow(canvas, txt_lyr, [(5,1.0),(14,0.8),(30,0.5),(55,0.25)])
    
    # ── Final RGB & post-process ─────────────────────────────────
    out = Image.new("RGB",(SIZE,SIZE),BLACK)
    out.paste(canvas.convert("RGB"), (0,0))
    
    arr = np.array(out, dtype=np.float32)
    
    # Vignette
    ys = np.linspace(-1,1,SIZE); xs = np.linspace(-1,1,SIZE)
    xx,yy = np.meshgrid(xs,ys)
    vig = np.clip(1.0 - np.sqrt(xx**2+yy**2)*0.42, 0.48, 1.0)
    arr *= vig[...,np.newaxis]
    out = Image.fromarray(arr.clip(0,255).astype(np.uint8))
    
    # Bloom
    bloom = out.filter(ImageFilter.GaussianBlur(5))
    a1 = np.array(out, dtype=np.float32)
    a2 = np.array(bloom, dtype=np.float32)
    out = Image.fromarray((a1*0.84+a2*0.16).clip(0,255).astype(np.uint8))
    
    return out

if __name__ == "__main__":
    print("Building BIOHACKER icon v5...")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    icon = build()
    icon.save(OUT_PATH, "PNG")
    from PIL import Image as _I
    v = _I.open(OUT_PATH)
    print(f"Saved: {OUT_PATH}")
    print(f"Size:  {v.size[0]}x{v.size[1]}")
    print(f"Bytes: {os.path.getsize(OUT_PATH):,}")
