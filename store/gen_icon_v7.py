#!/usr/bin/env python3
"""
BIOHACKER App Icon v7 - FINAL
Approach: Draw brain, then EXPLICITLY paint dark curved sulcus lines on top.
Bitcoin via font. Text via Silkscreen. Strong glow.
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
M_HOT    = (220,   0, 185)
M_MID    = (165,   0, 130)
M_DARK   = ( 80,   0,  60)
M_DEEP   = ( 30,   0,  22)

G_BRIGHT = ( 40, 255,  88)
G_HOT    = (  0, 210,  62)
G_MID    = (  0, 148,  44)
G_DARK   = (  0,  62,  18)
G_DEEP   = (  0,  20,   6)

GOLD_H   = (255, 248,  90)
GOLD_M   = (240, 190,   0)
GOLD_D   = (155, 105,   0)

CYAN_H   = (  0, 255, 255)
CYAN_D   = (  0,  80, 110)

BLACK    = (  0,   0,   0)
CIRCUIT  = (  0,  28,  20)

def composite(base, over):
    return Image.alpha_composite(base, over)

def blur_layer(lyr, r, a=1.0):
    g = lyr.filter(ImageFilter.GaussianBlur(r))
    arr = np.array(g, dtype=np.float32)
    arr[...,3] = (arr[...,3]*a).clip(0,255)
    return Image.fromarray(arr.astype(np.uint8))

def add_glow(base, layer, specs):
    for r, a in specs:
        base = composite(base, blur_layer(layer, r, a))
    return composite(base, layer)

def brain_outline_pts(cx, cy, rw, rh, n=1000):
    """Clean bumpy brain silhouette."""
    pts = []
    for i in range(n):
        t = 2*math.pi*i/n
        bx = rw*math.cos(t)
        by = rh*math.sin(t)
        
        top_f = max(0, -math.sin(t))
        gyri  = (top_f * 0.10 * math.sin(4.5*t+0.35) +
                 top_f * 0.05 * math.sin(9.0*t+0.85) +
                 top_f * 0.025* math.sin(14.0*t+0.25))
        
        temp  = (0.065 * math.exp(-((t - math.pi*0.30)**2)/0.10) +
                 0.065 * math.exp(-((t - math.pi*0.70)**2)/0.10))
        
        if by > rh*0.60:
            by = rh*0.60 + (by-rh*0.60)*0.35
        if by < 0:
            bx *= 1.0 + 0.05*(-by/rh)
        
        pts.append((cx + (1.0+gyri+temp)*bx, cy + (1.0+gyri+temp)*by))
    return pts

def draw_circuits(canvas):
    rng = np.random.default_rng(42)
    d = ImageDraw.Draw(canvas)
    for _ in range(30):
        x1,y1 = int(rng.integers(8,SIZE-8)), int(rng.integers(8,SIZE-8))
        x2,y2 = int(rng.integers(8,SIZE-8)), int(rng.integers(8,SIZE-8))
        d.line([(x1,y1),(x2,y1)], fill=CIRCUIT+(255,), width=2)
        d.line([(x2,y1),(x2,y2)], fill=CIRCUIT+(255,), width=2)
        d.ellipse([x2-3,y1-3,x2+3,y1+3], fill=(0,45,32,255))

def sulcus_arc_pts(bma, cx, cy, brain_top, brain_bot, frac, side, n_pts=80):
    """
    Return a list of (x,y) points forming one sulcus arc at vertical fraction `frac`.
    The arc goes from the medial edge (near cx) to the outer brain edge,
    with a slight concave-upward arch.
    """
    H = brain_bot - brain_top
    
    pts = []
    for i in range(n_pts):
        xi = i / (n_pts - 1)  # 0 = medial (center), 1 = outer edge
        
        # Slight arch: rises toward center-of-arc
        arch_amount = int(H * 0.025 * math.sin(xi * math.pi))
        y_base = int(brain_top + frac * H)
        y = y_base - arch_amount
        
        # Clamp y
        y = max(0, min(SIZE-1, y))
        
        # Find the outer edge of the brain at this y
        row = bma[y]
        if side == 'left':
            xs = np.where((row > 0) & (np.arange(SIZE) < cx))[0]
            if len(xs) == 0:
                continue
            x_inner = cx - 6   # slightly off center to avoid fissure
            x_outer = xs[0]
            x = int(x_inner + xi * (x_outer - x_inner))
        else:
            xs = np.where((row > 0) & (np.arange(SIZE) >= cx))[0]
            if len(xs) == 0:
                continue
            x_inner = cx + 6
            x_outer = xs[-1]
            x = int(x_inner + xi * (x_outer - x_inner))
        
        # Only include if inside brain mask
        if 0 <= x < SIZE and 0 <= y < SIZE and bma[y, x] > 0:
            pts.append((x, y))
    
    return pts


def build():
    canvas = Image.new("RGBA", (SIZE,SIZE), BLACK+(255,))
    draw_circuits(canvas)
    
    # Brain parameters
    bcx = SIZE // 2
    bcy = int(SIZE * 0.378)
    brw = int(SIZE * 0.415)
    brh = int(SIZE * 0.345)
    
    bpts = brain_outline_pts(bcx, bcy, brw, brh)
    bpts_i = [(int(x),int(y)) for x,y in bpts]
    
    # Brain mask
    bm_img = Image.new("L", (SIZE,SIZE), 0)
    ImageDraw.Draw(bm_img).polygon(bpts_i, fill=255)
    bma = np.array(bm_img)
    
    cx_rows = np.where(bma[:,bcx] > 0)[0]
    brain_top = int(cx_rows[0])  if len(cx_rows) else bcy-brh
    brain_bot = int(cx_rows[-1]) if len(cx_rows) else bcy+brh
    
    # ── 1. Fill brain base (gradient-ish using radial distance) ──────────
    brain_arr = np.zeros((SIZE,SIZE,4), dtype=np.uint8)
    
    # Create gradient for each pixel inside the brain
    ys_idx = np.arange(SIZE)
    xs_idx = np.arange(SIZE)
    yy, xx = np.meshgrid(ys_idx, xs_idx, indexing='ij')
    
    # Normalized distance from center
    dist_from_cx = np.abs(xx - bcx).astype(np.float32)
    dist_from_cy = np.abs(yy - bcy).astype(np.float32)
    norm_dist = np.sqrt((dist_from_cx/brw)**2 + (dist_from_cy/brh)**2)
    
    inside = bma > 0
    
    # Left half
    left_mask = inside & (xx < bcx)
    for row in range(SIZE):
        for col in range(SIZE):
            if not left_mask[row, col]:
                continue
            d = norm_dist[row, col]
            # Radial gradient: bright at edge/mid, dark at center
            if d > 0.85:
                col_px = M_BRIGHT
            elif d > 0.65:
                col_px = M_HOT
            elif d > 0.45:
                col_px = M_MID
            elif d > 0.28:
                col_px = M_DARK
            else:
                col_px = M_DEEP
            brain_arr[row,col] = col_px + (255,)
    
    # Right half
    right_mask = inside & (xx >= bcx)
    for row in range(SIZE):
        for col in range(SIZE):
            if not right_mask[row, col]:
                continue
            d = norm_dist[row, col]
            if d > 0.85:
                col_px = G_BRIGHT
            elif d > 0.65:
                col_px = G_HOT
            elif d > 0.45:
                col_px = G_MID
            elif d > 0.28:
                col_px = G_DARK
            else:
                col_px = G_DEEP
            brain_arr[row,col] = col_px + (255,)
    
    brain_layer = Image.fromarray(brain_arr)
    canvas = composite(canvas, brain_layer)
    
    # ── 2. Draw VISIBLE sulcus lines directly ─────────────────────────────
    # Draw them with thick dark lines, then bright highlight edges
    sulcus_fracs = [0.12, 0.22, 0.34, 0.46, 0.58, 0.70, 0.82]
    
    # Layer for sulci
    sulci_layer = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    sd = ImageDraw.Draw(sulci_layer)
    
    for frac in sulcus_fracs:
        for side in ('left', 'right'):
            pts = sulcus_arc_pts(bma, bcx, bcy, brain_top, brain_bot, frac, side)
            if len(pts) < 3:
                continue
            
            dark_col  = M_DEEP  if side=='left' else G_DEEP
            shadow_col = M_DARK if side=='left' else G_DARK
            
            # Draw thick dark sulcus
            sd.line(pts, fill=dark_col+(255,), width=7)
            # Narrower shadow overlay
            sd.line(pts, fill=shadow_col+(220,), width=4)
            # Black core
            sd.line(pts, fill=(0,0,0,200), width=2)
    
    canvas = composite(canvas, sulci_layer)
    
    # ── 3. Gyrus crown highlights (bright lines between sulci) ──────────
    # Between each pair of sulci, draw a bright line at the midpoint
    crown_fracs = [(a+b)/2 for a,b in zip([0]+sulcus_fracs, sulcus_fracs+[1.0])]
    
    crown_layer = Image.new("RGBA", (SIZE,SIZE), (0,0,0,0))
    cd = ImageDraw.Draw(crown_layer)
    
    for frac in crown_fracs:
        for side in ('left', 'right'):
            pts = sulcus_arc_pts(bma, bcx, bcy, brain_top, brain_bot, frac, side)
            if len(pts) < 3:
                continue
            bright_col = M_BRIGHT if side=='left' else G_BRIGHT
            hot_col    = M_HOT    if side=='left' else G_HOT
            
            cd.line(pts, fill=hot_col+(180,), width=3)
            cd.line(pts, fill=bright_col+(120,), width=1)
    
    canvas = composite(canvas, crown_layer)
    
    # ── 4. Neon glow on brain halves ─────────────────────────────────────
    mag_glow = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(mag_glow).polygon(bpts_i, fill=M_HOT+(180,))
    mga = np.array(mag_glow); mga[:,bcx:]=0; mag_glow=Image.fromarray(mga)
    
    grn_glow = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(grn_glow).polygon(bpts_i, fill=G_HOT+(180,))
    gga = np.array(grn_glow); gga[:,:bcx]=0; grn_glow=Image.fromarray(gga)
    
    for r,a in [(22,0.28),(55,0.16),(100,0.08)]:
        canvas = composite(canvas, blur_layer(mag_glow,r,a))
        canvas = composite(canvas, blur_layer(grn_glow,r,a))
    
    # ── 5. Neon edge rim ──────────────────────────────────────────────────
    rim_l = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    rim_r = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    rl_d = ImageDraw.Draw(rim_l); rr_d = ImageDraw.Draw(rim_r)
    rl_d.line(bpts_i+[bpts_i[0]], fill=M_BRIGHT+(200,), width=6)
    rr_d.line(bpts_i+[bpts_i[0]], fill=G_BRIGHT+(200,), width=6)
    rla = np.array(rim_l); rla[:,bcx:]=0; rim_l=Image.fromarray(rla)
    rra = np.array(rim_r); rra[:,:bcx]=0; rim_r=Image.fromarray(rra)
    
    canvas = add_glow(canvas, rim_l, [(4,0.9),(15,0.55),(38,0.25)])
    canvas = add_glow(canvas, rim_r, [(4,0.9),(15,0.55),(38,0.25)])
    
    # ── 6. Medial fissure ─────────────────────────────────────────────────
    fiss = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    fid = ImageDraw.Draw(fiss)
    fid.line([(bcx,brain_top),(bcx,brain_bot)], fill=(0,0,0,255), width=6)
    fid.line([(bcx-4,brain_top),(bcx-4,brain_bot)], fill=M_DARK+(160,), width=2)
    fid.line([(bcx+4,brain_top),(bcx+4,brain_bot)], fill=G_DARK+(160,), width=2)
    canvas = composite(canvas, fiss)
    
    # ── 7. Bitcoin ₿ ──────────────────────────────────────────────────────
    btc_sz = int((brain_bot - brain_top) * 0.48)
    try:
        btc_font = ImageFont.truetype(f"{FONT_DIR}/IBMPlexMono-Bold.ttf", btc_sz)
    except:
        btc_font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf", btc_sz)
    
    btc_l = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    bd = ImageDraw.Draw(btc_l)
    bb = bd.textbbox((0,0),"₿",font=btc_font)
    bw,bh = bb[2]-bb[0], bb[3]-bb[1]
    bx2 = bcx - bw//2 - bb[0]
    by2 = bcy - bh//2 - bb[1]
    
    bd.text((bx2+4,by2+4),"₿",font=btc_font,fill=GOLD_D+(200,))
    bd.text((bx2,by2),"₿",font=btc_font,fill=GOLD_M+(255,))
    
    # Brighten
    bta = np.array(btc_l)
    hot = bta[...,0] > 130
    bta[hot,0] = np.minimum(bta[hot,0].astype(int)+45,255).astype(np.uint8)
    bta[hot,1] = np.minimum(bta[hot,1].astype(int)+58,255).astype(np.uint8)
    btc_l = Image.fromarray(bta)
    
    # Mask to brain interior
    bta2 = np.array(btc_l)
    bta2[...,3] = np.minimum(bta2[...,3], bma)
    btc_l = Image.fromarray(bta2)
    
    canvas = add_glow(canvas, btc_l, [(7,1.0),(18,0.75),(38,0.45),(72,0.20)])
    
    # ── 8. BIOHACKER text ─────────────────────────────────────────────────
    target_w = int(SIZE * 0.80)
    text_font = None
    text_bb = (0,0,200,20)
    
    for sz in range(260, 20, -2):
        try:
            f = ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf", sz)
            bb_t = ImageDraw.Draw(Image.new("L",(10,10))).textbbox((0,0),"BIOHACKER",font=f)
            if (bb_t[2]-bb_t[0]) <= target_w:
                text_font = f; text_bb = bb_t; break
        except:
            break
    
    if text_font is None:
        text_font = ImageFont.load_default()
    
    tw = text_bb[2]-text_bb[0]; th = text_bb[3]-text_bb[1]
    gap = int(SIZE*0.032)
    tx = SIZE//2 - tw//2 - text_bb[0]
    ty = brain_bot + gap - text_bb[1]
    if ty+th > SIZE-20: ty = SIZE-20-th
    
    tl = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    td = ImageDraw.Draw(tl)
    td.text((tx+5,ty+5),"BIOHACKER",font=text_font,fill=CYAN_D+(180,))
    td.text((tx,ty),"BIOHACKER",font=text_font,fill=CYAN_H+(255,))
    td.line([(tx,ty),(tx+tw,ty)],fill=(255,255,255,85),width=2)
    
    canvas = add_glow(canvas, tl, [(5,1.0),(14,0.8),(30,0.5),(60,0.22)])
    
    # ── Final RGB ──────────────────────────────────────────────────────────
    out = Image.new("RGB",(SIZE,SIZE),BLACK)
    out.paste(canvas.convert("RGB"),(0,0))
    
    arr = np.array(out, dtype=np.float32)
    ys = np.linspace(-1,1,SIZE); xs = np.linspace(-1,1,SIZE)
    xx2,yy2 = np.meshgrid(xs,ys)
    vig = np.clip(1.0-np.sqrt(xx2**2+yy2**2)*0.40, 0.50, 1.0)
    arr *= vig[...,np.newaxis]
    out = Image.fromarray(arr.clip(0,255).astype(np.uint8))
    
    bloom = out.filter(ImageFilter.GaussianBlur(5))
    a1 = np.array(out,dtype=np.float32)
    a2 = np.array(bloom,dtype=np.float32)
    out = Image.fromarray((a1*0.83+a2*0.17).clip(0,255).astype(np.uint8))
    
    return out

if __name__ == "__main__":
    print("Building BIOHACKER icon v7 (direct sulci)...")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    icon = build()
    icon.save(OUT_PATH,"PNG")
    v = Image.open(OUT_PATH)
    print(f"Saved: {OUT_PATH}\nSize:  {v.size}\nBytes: {os.path.getsize(OUT_PATH):,}")
