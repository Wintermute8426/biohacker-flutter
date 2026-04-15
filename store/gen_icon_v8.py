#!/usr/bin/env python3
"""
BIOHACKER App Icon v8 - Distance-transform based gyri
Sulci follow the brain outline (organic, not parallel horizontal bands).
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy.ndimage import distance_transform_edt
import math
import os

SIZE     = 1024
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"
OUT_PATH = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"

# ── PALETTE ────────────────────────────────────────────────────────────────
M_BRIGHT = (255,  20, 242)
M_HOT    = (220,   0, 185)
M_MID    = (162,   0, 128)
M_DARK   = ( 78,   0,  58)
M_DEEP   = ( 28,   0,  20)

G_BRIGHT = ( 40, 255,  88)
G_HOT    = (  0, 208,  60)
G_MID    = (  0, 145,  42)
G_DARK   = (  0,  60,  17)
G_DEEP   = (  0,  18,   5)

GOLD_H   = (255, 248,  90)
GOLD_M   = (240, 190,   0)
GOLD_D   = (152, 102,   0)

CYAN_H   = (  0, 255, 255)
CYAN_D   = (  0,  75, 108)

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

def brain_pts(cx, cy, rw, rh, n=1000):
    pts = []
    for i in range(n):
        t = 2*math.pi*i/n
        bx = rw*math.cos(t)
        by = rh*math.sin(t)
        top_f = max(0, -math.sin(t))
        gyri  = (top_f*0.10*math.sin(4.5*t+0.35) +
                 top_f*0.05*math.sin(9.0*t+0.85) +
                 top_f*0.025*math.sin(14.0*t+0.25))
        temp  = (0.065*math.exp(-((t-math.pi*0.30)**2)/0.10) +
                 0.065*math.exp(-((t-math.pi*0.70)**2)/0.10))
        if by > rh*0.60: by = rh*0.60+(by-rh*0.60)*0.35
        if by < 0: bx *= 1.0+0.05*(-by/rh)
        pts.append((cx+(1+gyri+temp)*bx, cy+(1+gyri+temp)*by))
    return pts

def draw_circuits(canvas):
    rng = np.random.default_rng(42)
    d = ImageDraw.Draw(canvas)
    for _ in range(30):
        x1,y1=int(rng.integers(8,SIZE-8)),int(rng.integers(8,SIZE-8))
        x2,y2=int(rng.integers(8,SIZE-8)),int(rng.integers(8,SIZE-8))
        d.line([(x1,y1),(x2,y1)],fill=CIRCUIT+(255,),width=2)
        d.line([(x2,y1),(x2,y2)],fill=CIRCUIT+(255,),width=2)
        d.ellipse([x2-3,y1-3,x2+3,y1+3],fill=(0,45,32,255))

def build():
    canvas = Image.new("RGBA",(SIZE,SIZE),BLACK+(255,))
    draw_circuits(canvas)
    
    # Brain
    bcx = SIZE//2
    bcy = int(SIZE*0.378)
    brw = int(SIZE*0.415)
    brh = int(SIZE*0.345)
    
    bpts_list = brain_pts(bcx, bcy, brw, brh)
    bpts_i = [(int(x),int(y)) for x,y in bpts_list]
    
    bm_img = Image.new("L",(SIZE,SIZE),0)
    ImageDraw.Draw(bm_img).polygon(bpts_i, fill=255)
    bma = np.array(bm_img)
    
    cx_rows = np.where(bma[:,bcx]>0)[0]
    brain_top = int(cx_rows[0])  if len(cx_rows) else bcy-brh
    brain_bot = int(cx_rows[-1]) if len(cx_rows) else bcy+brh
    
    # ── Distance transform for organic sulci ─────────────────────────────
    # Compute distance from each inside pixel to the EDGE of the brain
    dist_inside = distance_transform_edt(bma)  # 0 at edge, max at center
    
    # Normalize to [0,1]
    max_d = dist_inside.max()
    dist_norm = dist_inside / max_d  # 0=edge, 1=center
    
    # Left half distance: normalize by half-brain width for each side
    left_dist = dist_norm.copy()
    right_dist = dist_norm.copy()
    
    # We want sulci to follow the outline (concentric rings)
    # Number of gyri rings per hemisphere: 8
    N = 8
    
    # Gyrus/sulcus pattern: sin wave in distance space
    # Each full cycle of sin = one gyrus + one sulcus
    # Map [0, 1] in dist_norm → [0, N*pi] angle
    
    # Angular argument for gyral wave
    angle_field = dist_norm * N * 2 * math.pi  # N full cycles
    
    # The wave: 1=crown (brightest), -1=sulcus (darkest)
    wave = np.sin(angle_field)
    
    # Add small asymmetry/noise for organic look
    # Small random per-pixel variation
    rng = np.random.default_rng(77)
    noise = rng.normal(0, 0.06, (SIZE,SIZE))
    wave = (wave + noise).clip(-1, 1)
    
    # ── Build brain color array ────────────────────────────────────────────
    brain_arr = np.zeros((SIZE,SIZE,4), dtype=np.uint8)
    
    # Build color lookup arrays
    M_pal = np.array([M_BRIGHT, M_HOT, M_MID, M_DARK, M_DEEP], dtype=np.uint8)
    G_pal = np.array([G_BRIGHT, G_HOT, G_MID, G_DARK, G_DEEP], dtype=np.uint8)
    
    left_mask  = (bma > 0) & (np.arange(SIZE)[np.newaxis,:] < bcx)
    right_mask = (bma > 0) & (np.arange(SIZE)[np.newaxis,:] >= bcx)
    
    # Map wave [-1, 1] → palette index [0, 4]
    # Crown (wave=1) → bright (index 0)
    # Sulcus (wave=-1) → deep (index 4)
    
    def apply_palette(mask, pal):
        w = wave.copy()
        # At the brain boundary (dist_norm < 0.05), force to bright (rim light)
        w[dist_norm < 0.05] = 1.0
        
        norm = (1.0 - w) / 2.0  # 0=bright, 1=dark
        idx = (norm * 4.0).clip(0, 3.99).astype(int)
        
        result = np.zeros((SIZE,SIZE,4), dtype=np.uint8)
        for yi in range(SIZE):
            for xi in range(SIZE):
                if mask[yi,xi]:
                    result[yi,xi] = pal[idx[yi,xi]] + (255,)
        return result
    
    # This loop is slow — vectorize
    w_field = wave.copy()
    w_field[dist_norm < 0.05] = 1.0
    norm_field = (1.0 - w_field) / 2.0  # 0=bright, 1=dark
    idx_field  = (norm_field * 4.0).clip(0, 3.99).astype(int)
    
    # Left hemisphere
    for pi, p_col in enumerate(M_pal):
        mask = left_mask & (idx_field == pi)
        brain_arr[mask] = list(p_col) + [255]
    
    # Right hemisphere
    for pi, p_col in enumerate(G_pal):
        mask = right_mask & (idx_field == pi)
        brain_arr[mask] = list(p_col) + [255]
    
    brain_layer = Image.fromarray(brain_arr)
    canvas = composite(canvas, brain_layer)
    
    # ── Sulcus darkening (additional pass to deepen grooves) ──────────────
    # Where wave < -0.5 (deep sulcus), darken further
    sulcus_mask = (bma > 0) & (wave < -0.5)
    darken = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    darken_arr = np.array(darken)
    darken_arr[sulcus_mask & left_mask, :3] = M_DEEP
    darken_arr[sulcus_mask & right_mask, :3] = G_DEEP
    darken_arr[sulcus_mask, 3] = 180
    darken = Image.fromarray(darken_arr)
    canvas = composite(canvas, darken)
    
    # ── Rim light (outermost ring = bright) ───────────────────────────────
    rim = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    rd = ImageDraw.Draw(rim)
    rd.line(bpts_i+[bpts_i[0]], fill=M_BRIGHT+(200,), width=6)
    ra = np.array(rim)
    rl = ra.copy(); rl[:,bcx:]=0
    rr = ra.copy(); rr[:,:bcx]=0
    # Recolor right rim green
    rr_f = rr.astype(np.float32)
    rr_f[...,0]=rr_f[...,0]*0.15; rr_f[...,1]=np.minimum(rr_f[...,1]*0.4+128,255); rr_f[...,2]=rr_f[...,2]*0.25
    
    canvas = add_glow(canvas, Image.fromarray(rl), [(4,0.9),(16,0.55),(40,0.25)])
    canvas = add_glow(canvas, Image.fromarray(rr_f.clip(0,255).astype(np.uint8)), [(4,0.9),(16,0.55),(40,0.25)])
    
    # ── Outer halo ────────────────────────────────────────────────────────
    mag_h = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(mag_h).polygon(bpts_i,fill=M_HOT+(160,))
    mha = np.array(mag_h); mha[:,bcx:]=0; mag_h=Image.fromarray(mha)
    
    grn_h = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(grn_h).polygon(bpts_i,fill=G_HOT+(160,))
    gha = np.array(grn_h); gha[:,:bcx]=0; grn_h=Image.fromarray(gha)
    
    for r,a in [(25,0.28),(60,0.16),(110,0.08)]:
        canvas = composite(canvas, blur_layer(mag_h,r,a))
        canvas = composite(canvas, blur_layer(grn_h,r,a))
    
    # ── Medial fissure ────────────────────────────────────────────────────
    fiss = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    fid = ImageDraw.Draw(fiss)
    fid.line([(bcx,brain_top),(bcx,brain_bot)],fill=(0,0,0,255),width=6)
    fid.line([(bcx-4,brain_top),(bcx-4,brain_bot)],fill=M_DARK+(160,),width=2)
    fid.line([(bcx+4,brain_top),(bcx+4,brain_bot)],fill=G_DARK+(160,),width=2)
    canvas = composite(canvas, fiss)
    
    # ── Bitcoin ₿ ─────────────────────────────────────────────────────────
    btc_sz = int((brain_bot-brain_top)*0.48)
    try:
        btc_font = ImageFont.truetype(f"{FONT_DIR}/IBMPlexMono-Bold.ttf",btc_sz)
    except:
        btc_font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",btc_sz)
    
    btc_l = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    bd = ImageDraw.Draw(btc_l)
    bb = bd.textbbox((0,0),"₿",font=btc_font)
    bw,bh = bb[2]-bb[0],bb[3]-bb[1]
    bx2 = bcx - bw//2 - bb[0]
    by2 = bcy - bh//2 - bb[1]
    
    bd.text((bx2+4,by2+4),"₿",font=btc_font,fill=GOLD_D+(200,))
    bd.text((bx2,by2),"₿",font=btc_font,fill=GOLD_M+(255,))
    
    bta = np.array(btc_l)
    hot = bta[...,0]>130
    bta[hot,0]=np.minimum(bta[hot,0].astype(int)+45,255).astype(np.uint8)
    bta[hot,1]=np.minimum(bta[hot,1].astype(int)+58,255).astype(np.uint8)
    btc_l = Image.fromarray(bta)
    bta2 = np.array(btc_l)
    bta2[...,3]=np.minimum(bta2[...,3],bma)
    btc_l = Image.fromarray(bta2)
    
    canvas = add_glow(canvas, btc_l, [(7,1.0),(18,0.75),(38,0.45),(72,0.20)])
    
    # ── BIOHACKER text ────────────────────────────────────────────────────
    target_w = int(SIZE*0.80)
    text_font = None; text_bb = (0,0,200,20)
    
    for sz in range(260,20,-2):
        try:
            f = ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf",sz)
            bb_t = ImageDraw.Draw(Image.new("L",(10,10))).textbbox((0,0),"BIOHACKER",font=f)
            if (bb_t[2]-bb_t[0]) <= target_w:
                text_font=f; text_bb=bb_t; break
        except:
            break
    
    if text_font is None: text_font=ImageFont.load_default()
    
    tw=text_bb[2]-text_bb[0]; th=text_bb[3]-text_bb[1]
    gap=int(SIZE*0.032)
    tx=SIZE//2-tw//2-text_bb[0]
    ty=brain_bot+gap-text_bb[1]
    if ty+th>SIZE-20: ty=SIZE-20-th
    
    tl=Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    td=ImageDraw.Draw(tl)
    td.text((tx+5,ty+5),"BIOHACKER",font=text_font,fill=CYAN_D+(180,))
    td.text((tx,ty),"BIOHACKER",font=text_font,fill=CYAN_H+(255,))
    td.line([(tx,ty),(tx+tw,ty)],fill=(255,255,255,85),width=2)
    
    canvas = add_glow(canvas, tl, [(5,1.0),(14,0.8),(30,0.5),(60,0.22)])
    
    # ── RGB post ─────────────────────────────────────────────────────────
    out = Image.new("RGB",(SIZE,SIZE),BLACK)
    out.paste(canvas.convert("RGB"),(0,0))
    
    arr = np.array(out,dtype=np.float32)
    ys = np.linspace(-1,1,SIZE); xs = np.linspace(-1,1,SIZE)
    xx2,yy2 = np.meshgrid(xs,ys)
    vig = np.clip(1.0-np.sqrt(xx2**2+yy2**2)*0.40,0.50,1.0)
    arr *= vig[...,np.newaxis]
    out = Image.fromarray(arr.clip(0,255).astype(np.uint8))
    
    bloom = out.filter(ImageFilter.GaussianBlur(5))
    a1=np.array(out,dtype=np.float32); a2=np.array(bloom,dtype=np.float32)
    out = Image.fromarray((a1*0.83+a2*0.17).clip(0,255).astype(np.uint8))
    
    return out

if __name__ == "__main__":
    print("Building BIOHACKER icon v8 (distance-transform gyri)...")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    icon = build()
    icon.save(OUT_PATH,"PNG")
    v = Image.open(OUT_PATH)
    print(f"Saved: {OUT_PATH}\nSize:  {v.size}\nBytes: {os.path.getsize(OUT_PATH):,}")
