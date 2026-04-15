#!/usr/bin/env python3
"""
BIOHACKER App Icon v6
Key fix: draw EXPLICIT sulcus (groove) lines on the brain surface.
Each sulcus = a dark curved line. Gyri = bright areas between sulci.
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math
import os

SIZE     = 1024
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"
OUT_PATH = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"

# ── PALETTE ────────────────────────────────────────────────────────────────
M_BRIGHT = (255,  20, 242)
M_HOT    = (230,   0, 195)
M_MID    = (170,   0, 135)
M_DARK   = ( 85,   0,  65)
M_DEEP   = ( 32,   0,  24)

G_BRIGHT = ( 45, 255,  90)
G_HOT    = (  0, 215,  65)
G_MID    = (  0, 155,  45)
G_DARK   = (  0,  68,  20)
G_DEEP   = (  0,  22,   7)

GOLD_H   = (255, 248,  90)
GOLD_M   = (240, 190,   0)
GOLD_D   = (155, 105,   0)

CYAN_H   = (  0, 255, 255)
CYAN_D   = (  0,  80, 110)

BLACK    = (  0,   0,   0)
CIRCUIT  = (  0,  28,  20)

def composite(base, over):
    return Image.alpha_composite(base, over)

def blur_layer(layer, r, a=1.0):
    g = layer.filter(ImageFilter.GaussianBlur(r))
    arr = np.array(g, dtype=np.float32)
    arr[...,3] = (arr[...,3]*a).clip(0,255)
    return Image.fromarray(arr.astype(np.uint8))

def add_glow(base, layer, specs):
    for r, a in specs:
        base = composite(base, blur_layer(layer, r, a))
    return composite(base, layer)

# ── BRAIN OUTLINE ──────────────────────────────────────────────────────────

def brain_pts(cx, cy, rw, rh, n=1000):
    pts = []
    for i in range(n):
        t = 2*math.pi*i/n
        bx = rw * math.cos(t)
        by = rh * math.sin(t)
        
        # Top surface gyral bumps (y < 0 in PIL = upper screen)
        top_f = max(0, -math.sin(t))
        gyri = (
            top_f * 0.11 * math.sin(4.5*t + 0.35) +
            top_f * 0.055 * math.sin(9.0*t + 0.85) +
            top_f * 0.028 * math.sin(14.0*t + 0.25)
        )
        
        # Temporal bulges at mid-lower sides
        temp = (
            0.07 * math.exp(-((t - math.pi*0.30)**2)/0.10) +
            0.07 * math.exp(-((t - math.pi*0.70)**2)/0.10)
        )
        
        # Flatten bottom
        if by > rh * 0.60:
            by = rh*0.60 + (by - rh*0.60)*0.35
        
        # Slightly wider at top
        if by < 0:
            bx *= 1.0 + 0.05*(-by/rh)
        
        r = 1.0 + gyri + temp
        pts.append((cx + r*bx, cy + r*by))
    return pts

# ── SULCUS LINE DRAWING ────────────────────────────────────────────────────

def draw_sulci(canvas, brain_mask_arr, bpts_i, cx, cy, rw, rh, side):
    """
    Draw explicit dark sulcus lines across one hemisphere.
    Sulci = arc-shaped dark lines running roughly parallel to the brain edge,
    from inner (medial) to outer (lateral) edge.
    """
    pal_dark  = M_DARK  if side == 'left' else G_DARK
    pal_deep  = M_DEEP  if side == 'left' else G_DEEP
    pal_mid   = M_MID   if side == 'left' else G_MID
    pal_bright= M_BRIGHT if side == 'left' else G_BRIGHT
    
    bm = brain_mask_arr
    
    rows = np.where(bm.max(axis=1) > 0)[0]
    y_top = rows[0]
    y_bot = rows[-1]
    H = y_bot - y_top
    
    # We'll draw N_SULCI horizontal-ish curved sulcus bands
    N_SULCI = 7
    
    # For each sulcus, find the y-positions along a parametric curve
    # Each sulcus is at a fraction of the brain height, slightly arched
    
    sulcus_layers = []
    gyrus_layers  = []
    
    for si in range(N_SULCI + 1):
        # Fraction of brain height
        frac = si / N_SULCI
        
        # The sulcus runs at a certain y-level, with curvature
        # It curves slightly (arches upward in the middle of the hemisphere)
        # representing the natural curvature of gyri
        
        # Build a filled strip for each gyrus band
        # Between sulcus si and si+1
        if si < N_SULCI:
            frac_next = (si+1) / N_SULCI
            frac_mid  = (frac + frac_next) / 2
            
            # Build the band polygon
            # Top edge: frac row across hemisphere
            # Bottom edge: frac_next row across hemisphere
            
            band_pts_top = []
            band_pts_bot = []
            
            for xi_pct in range(0, 101, 2):
                xi_f = xi_pct / 100.0
                
                # x position within hemisphere
                if side == 'left':
                    # x goes from cx (inner) to left edge
                    # find outer extent at each y
                    pass
                
                # Parametric: use angular scan of brain
                # Angle range: left side = [pi/2, 3pi/2] (left hemisphere top→bottom arc)
                # Right side = [-pi/2, pi/2] (right hemisphere)
                
                # For simplicity: use y = y_top + frac*H + curvature
                y_top_band = y_top + frac      * H
                y_bot_band = y_top + frac_next * H
                
                # Arch curvature: middle of each band is slightly higher
                arch = 0.03 * H * math.sin(xi_f * math.pi)
                
                y_t = y_top_band - arch
                y_b = y_bot_band - arch
                
                # Find x at each y level in the hemisphere
                if side == 'left':
                    col_t = bm[max(0,min(SIZE-1,int(y_t))), :]
                    xs_t  = np.where((col_t > 0) & (np.arange(SIZE) < cx))[0]
                    col_b = bm[max(0,min(SIZE-1,int(y_b))), :]
                    xs_b  = np.where((col_b > 0) & (np.arange(SIZE) < cx))[0]
                    
                    if len(xs_t) == 0 or len(xs_b) == 0:
                        continue
                    
                    # Interpolate x from center to outer edge
                    x_t = cx + (xs_t[0] - cx) * xi_f  # cx=0, outer=1
                    x_b = cx + (xs_b[0] - cx) * xi_f
                else:
                    col_t = bm[max(0,min(SIZE-1,int(y_t))), :]
                    xs_t  = np.where((col_t > 0) & (np.arange(SIZE) >= cx))[0]
                    col_b = bm[max(0,min(SIZE-1,int(y_b))), :]
                    xs_b  = np.where((col_b > 0) & (np.arange(SIZE) >= cx))[0]
                    
                    if len(xs_t) == 0 or len(xs_b) == 0:
                        continue
                    
                    # Right side: cx=0, outer=1
                    x_t = cx + (xs_t[-1] - cx) * xi_f
                    x_b = cx + (xs_b[-1] - cx) * xi_f
                
                band_pts_top.append((int(x_t), int(y_t)))
                band_pts_bot.append((int(x_b), int(y_b)))
            
            gyrus_layers.append(band_pts_top + band_pts_bot[::-1])
    
    # Now draw the gyrus bands with color gradient (simulate 3D ridge)
    d = ImageDraw.Draw(canvas)
    
    for gi, gpts in enumerate(gyrus_layers):
        if len(gpts) < 4:
            continue
        
        # Gyrus color: each band alternates bright crown / dark at edges
        # We draw the whole band in mid color, then will overlay edge darkening
        pal = [M_BRIGHT, M_HOT, M_MID] if side == 'left' else [G_BRIGHT, G_HOT, G_MID]
        
        # Use mid color for gyrus body
        d.polygon(gpts, fill=pal[1]+(255,))
    
    # Draw sulcus LINES over the gyrus bands
    for si in range(N_SULCI + 1):
        frac = si / N_SULCI
        sulcus_pts = []
        
        for xi_pct in range(0, 101, 2):
            xi_f = xi_pct / 100.0
            arch = 0.03 * H * math.sin(xi_f * math.pi)
            y_s = y_top + frac * H - arch
            
            if side == 'left':
                col_s = bm[max(0,min(SIZE-1,int(y_s))), :]
                xs_s  = np.where((col_s > 0) & (np.arange(SIZE) < cx))[0]
                if len(xs_s) == 0:
                    continue
                x_s = cx + (xs_s[0] - cx) * xi_f
            else:
                col_s = bm[max(0,min(SIZE-1,int(y_s))), :]
                xs_s  = np.where((col_s > 0) & (np.arange(SIZE) >= cx))[0]
                if len(xs_s) == 0:
                    continue
                x_s = cx + (xs_s[-1] - cx) * xi_f
            
            sulcus_pts.append((int(x_s), int(y_s)))
        
        if len(sulcus_pts) > 1:
            # Draw the sulcus as a thick dark line
            d.line(sulcus_pts, fill=pal_deep+(255,), width=4)
            d.line(sulcus_pts, fill=pal_dark+(255,), width=2)
    
    # Draw gyrus CROWNS (bright highlight on the ridge tops)
    for gi, gpts in enumerate(gyrus_layers):
        if len(gpts) < 4:
            continue
        mid_pts = gpts[:len(gpts)//2]
        if len(mid_pts) > 1:
            bright_col = M_BRIGHT if side == 'left' else G_BRIGHT
            d.line(mid_pts, fill=bright_col+(200,), width=2)
    
    return canvas

# ── BRAIN BASE FILL ────────────────────────────────────────────────────────

def fill_brain_half(bpts_i, cx, side):
    layer = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    ImageDraw.Draw(layer).polygon(bpts_i, fill=(
        (M_MID+(255,)) if side=='left' else (G_MID+(255,))
    ))
    arr = np.array(layer)
    if side == 'left':
        arr[:,cx:] = 0
    else:
        arr[:,:cx] = 0
    return Image.fromarray(arr)

# ── CIRCUIT BG ─────────────────────────────────────────────────────────────

def draw_bg(canvas):
    rng = np.random.default_rng(42)
    d = ImageDraw.Draw(canvas)
    for _ in range(30):
        x1,y1 = int(rng.integers(8,SIZE-8)), int(rng.integers(8,SIZE-8))
        x2,y2 = int(rng.integers(8,SIZE-8)), int(rng.integers(8,SIZE-8))
        d.line([(x1,y1),(x2,y1)], fill=CIRCUIT+(255,), width=2)
        d.line([(x2,y1),(x2,y2)], fill=CIRCUIT+(255,), width=2)
        d.ellipse([x2-3,y1-3,x2+3,y1+3], fill=(0,45,32,255))

# ── MAIN ───────────────────────────────────────────────────────────────────

def build():
    canvas = Image.new("RGBA", (SIZE,SIZE), BLACK+(255,))
    draw_bg(canvas)
    
    # Brain params
    bcx = SIZE//2
    bcy = int(SIZE * 0.380)
    brw = int(SIZE * 0.415)
    brh = int(SIZE * 0.345)
    
    bpts = brain_pts(bcx, bcy, brw, brh)
    bpts_i = [(int(x),int(y)) for x,y in bpts]
    
    bm_img = Image.new("L", (SIZE,SIZE), 0)
    ImageDraw.Draw(bm_img).polygon(bpts_i, fill=255)
    bma = np.array(bm_img)
    
    cx_rows = np.where(bma[:,bcx] > 0)[0]
    brain_top = int(cx_rows[0])  if len(cx_rows) else bcy-brh
    brain_bot = int(cx_rows[-1]) if len(cx_rows) else bcy+brh
    
    # Base fills
    left_fill  = fill_brain_half(bpts_i, bcx, 'left')
    right_fill = fill_brain_half(bpts_i, bcx, 'right')
    canvas = composite(canvas, left_fill)
    canvas = composite(canvas, right_fill)
    
    # Draw sulci and gyri
    canvas = draw_sulci(canvas, bma, bpts_i, bcx, bcy, brw, brh, 'left')
    canvas = draw_sulci(canvas, bma, bpts_i, bcx, bcy, brw, brh, 'right')
    
    # Clip brain to mask (ensure nothing outside)
    arr = np.array(canvas)
    outside = bma == 0
    # Black out outside of brain (except background circuit traces keep their own pixels)
    # Actually the brain is drawn on the full canvas, so the base fills already stay inside
    canvas = Image.fromarray(arr)
    
    # ── Neon halo ───────────────────────────────────────────────
    mag_halo = fill_brain_half(bpts_i, bcx, 'left')
    grn_halo = fill_brain_half(bpts_i, bcx, 'right')
    
    canvas = add_glow(canvas, mag_halo, [(25, 0.28), (60, 0.16), (110, 0.08)])
    canvas = add_glow(canvas, grn_halo, [(25, 0.28), (60, 0.16), (110, 0.08)])
    
    # ── Rim light ───────────────────────────────────────────────
    rim = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(rim).line(bpts_i+[bpts_i[0]], fill=M_BRIGHT+(220,), width=5)
    ra = np.array(rim)
    rl = ra.copy(); rl[:,bcx:] = 0
    rr = ra.copy(); rr[:,:bcx] = 0
    # Color right rim green
    rr_f = rr.astype(np.float32)
    rr_f[...,0] = rr_f[...,0] * 0.2
    rr_f[...,1] = np.minimum(rr_f[...,1].astype(np.float32)*0.4 + 120, 255)
    rr_f[...,2] = rr_f[...,2] * 0.3
    
    canvas = add_glow(canvas, Image.fromarray(rl), [(5,0.9),(18,0.55),(40,0.25)])
    canvas = add_glow(canvas, Image.fromarray(rr_f.clip(0,255).astype(np.uint8)), [(5,0.9),(18,0.55),(40,0.25)])
    
    # ── Medial fissure ───────────────────────────────────────────
    fiss = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    fd = ImageDraw.Draw(fiss)
    fd.line([(bcx,brain_top),(bcx,brain_bot)], fill=(0,0,0,255), width=5)
    fd.line([(bcx-3,brain_top),(bcx-3,brain_bot)], fill=M_DARK+(180,), width=2)
    fd.line([(bcx+3,brain_top),(bcx+3,brain_bot)], fill=G_DARK+(180,), width=2)
    canvas = composite(canvas, fiss)
    
    # ── Bitcoin ₿ ────────────────────────────────────────────────
    btc_sz = int((brain_bot - brain_top) * 0.50)
    try:
        btc_font = ImageFont.truetype(f"{FONT_DIR}/IBMPlexMono-Bold.ttf", btc_sz)
    except:
        btc_font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf", btc_sz)
    
    btc_l = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    bd = ImageDraw.Draw(btc_l)
    bb = bd.textbbox((0,0),"₿",font=btc_font)
    bw,bh = bb[2]-bb[0], bb[3]-bb[1]
    bx = bcx - bw//2 - bb[0]
    by_ = bcy - bh//2 - bb[1]
    
    # Shadow
    bd.text((bx+4,by_+4),"₿",font=btc_font,fill=GOLD_D+(200,))
    # Base gold
    bd.text((bx,by_),"₿",font=btc_font,fill=GOLD_M+(255,))
    # Brighten hot pixels
    ba = np.array(btc_l)
    hot = ba[...,0] > 140
    ba[hot,0] = np.minimum(ba[hot,0].astype(int)+45,255).astype(np.uint8)
    ba[hot,1] = np.minimum(ba[hot,1].astype(int)+55,255).astype(np.uint8)
    btc_l = Image.fromarray(ba)
    
    # Mask to brain
    ba2 = np.array(btc_l)
    ba2[...,3] = np.minimum(ba2[...,3], bma)
    btc_l = Image.fromarray(ba2)
    
    canvas = add_glow(canvas, btc_l, [(7,1.0),(18,0.75),(38,0.45),(70,0.2)])
    
    # ── BIOHACKER text ───────────────────────────────────────────
    target_w = int(SIZE * 0.80)
    text_font = None
    
    for sz in range(260, 20, -2):
        try:
            f = ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf", sz)
            bb2 = ImageDraw.Draw(Image.new("L",(10,10))).textbbox((0,0),"BIOHACKER",font=f)
            if (bb2[2]-bb2[0]) <= target_w:
                text_font = f; text_bb = bb2; break
        except:
            break
    
    if text_font is None:
        text_font = ImageFont.load_default(); text_bb = (0,0,200,20)
    
    tw = text_bb[2]-text_bb[0]
    th = text_bb[3]-text_bb[1]
    gap = int(SIZE * 0.032)
    tx = SIZE//2 - tw//2 - text_bb[0]
    ty = brain_bot + gap - text_bb[1]
    if ty+th > SIZE-20: ty = SIZE-20-th
    
    tl = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    td = ImageDraw.Draw(tl)
    td.text((tx+5,ty+5),"BIOHACKER",font=text_font,fill=CYAN_D+(180,))
    td.text((tx,ty),"BIOHACKER",font=text_font,fill=CYAN_H+(255,))
    td.line([(tx,ty),(tx+tw,ty)],fill=(255,255,255,90),width=2)
    
    canvas = add_glow(canvas, tl, [(5,1.0),(14,0.8),(30,0.5),(60,0.22)])
    
    # ── RGB post-process ─────────────────────────────────────────
    out = Image.new("RGB",(SIZE,SIZE),BLACK)
    out.paste(canvas.convert("RGB"),(0,0))
    
    arr = np.array(out, dtype=np.float32)
    ys = np.linspace(-1,1,SIZE); xs = np.linspace(-1,1,SIZE)
    xx,yy = np.meshgrid(xs,ys)
    vig = np.clip(1.0 - np.sqrt(xx**2+yy**2)*0.40, 0.50, 1.0)
    arr *= vig[...,np.newaxis]
    out = Image.fromarray(arr.clip(0,255).astype(np.uint8))
    
    # Bloom
    bloom = out.filter(ImageFilter.GaussianBlur(5))
    a1 = np.array(out,dtype=np.float32)
    a2 = np.array(bloom,dtype=np.float32)
    out = Image.fromarray((a1*0.84+a2*0.16).clip(0,255).astype(np.uint8))
    
    return out

if __name__ == "__main__":
    print("Building BIOHACKER icon v6 (explicit sulci)...")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    icon = build()
    icon.save(OUT_PATH,"PNG")
    from PIL import Image as _I
    v = _I.open(OUT_PATH)
    print(f"Saved: {OUT_PATH}")
    print(f"Size:  {v.size[0]}x{v.size[1]}")
    print(f"Bytes: {os.path.getsize(OUT_PATH):,}")
