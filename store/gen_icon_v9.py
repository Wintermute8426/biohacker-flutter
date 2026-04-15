#!/usr/bin/env python3
"""
BIOHACKER App Icon v9
Strategy: hand-crafted anatomical brain with Bézier sulci,
perturbed distance-transform for organic texture,
strong neon glow.
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from scipy.ndimage import distance_transform_edt, gaussian_filter
import math
import os

SIZE     = 1024
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"
OUT_PATH = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"

M_BRIGHT = (255,  20, 242)
M_HOT    = (210,   0, 175)
M_MID    = (152,   0, 118)
M_DARK   = ( 70,   0,  52)
M_DEEP   = ( 25,   0,  18)

G_BRIGHT = ( 38, 255,  85)
G_HOT    = (  0, 200,  58)
G_MID    = (  0, 140,  40)
G_DARK   = (  0,  55,  16)
G_DEEP   = (  0,  16,   5)

GOLD_H   = (255, 248,  90)
GOLD_M   = (238, 188,   0)
GOLD_D   = (148, 100,   0)

CYAN_H   = (  0, 255, 255)
CYAN_D   = (  0,  72, 105)

BLACK    = (  0,   0,   0)
CIRCUIT  = (  0,  28,  20)

def composite(base, over): return Image.alpha_composite(base, over)
def blur_layer(lyr, r, a=1.0):
    g = lyr.filter(ImageFilter.GaussianBlur(r))
    arr = np.array(g, dtype=np.float32); arr[...,3]=(arr[...,3]*a).clip(0,255)
    return Image.fromarray(arr.astype(np.uint8))
def add_glow(base, layer, specs):
    for r,a in specs: base=composite(base, blur_layer(layer,r,a))
    return composite(base, layer)

def bezier3(p0, p1, p2, t):
    """Quadratic Bézier point."""
    return ((1-t)**2*p0[0]+2*(1-t)*t*p1[0]+t**2*p2[0],
            (1-t)**2*p0[1]+2*(1-t)*t*p1[1]+t**2*p2[1])

def bezier_pts(p0, p1, p2, n=80):
    return [bezier3(p0,p1,p2,i/(n-1)) for i in range(n)]

def cubic_bezier(p0, p1, p2, p3, t):
    return ((1-t)**3*p0[0]+3*(1-t)**2*t*p1[0]+3*(1-t)*t**2*p2[0]+t**3*p3[0],
            (1-t)**3*p0[1]+3*(1-t)**2*t*p1[1]+3*(1-t)*t**2*p2[1]+t**3*p3[1])

def cubic_pts(p0, p1, p2, p3, n=100):
    return [cubic_bezier(p0,p1,p2,p3,i/(n-1)) for i in range(n)]

def draw_circuits(canvas):
    rng = np.random.default_rng(42)
    d = ImageDraw.Draw(canvas)
    for _ in range(30):
        x1,y1=int(rng.integers(8,SIZE-8)),int(rng.integers(8,SIZE-8))
        x2,y2=int(rng.integers(8,SIZE-8)),int(rng.integers(8,SIZE-8))
        d.line([(x1,y1),(x2,y1)],fill=CIRCUIT+(255,),width=2)
        d.line([(x2,y1),(x2,y2)],fill=CIRCUIT+(255,),width=2)
        d.ellipse([x2-3,y1-3,x2+3,y1+3],fill=(0,42,30,255))

# ── ANATOMICAL BRAIN OUTLINE ──────────────────────────────────────────────
# Define key anatomical landmarks at 1024×1024
# Brain occupies roughly x: 80-944, y: 90-740
# Center fissure at x=512

def make_brain_outline():
    """
    Hand-crafted brain outline via cubic Bézier segments.
    Returns list of (x,y) int tuples forming the silhouette polygon.
    Designed to look like a coronal/dorsal-view brain.
    """
    # Key control points (manually crafted for anatomical look):
    # Starting from top-center, going clockwise
    
    # Brain boundaries:
    # Top: y≈100-120 (flatter, small gyri bumps)
    # Sides: x≈85 (left edge), x≈940 (right edge) at widest (y≈400-450)
    # Bottom: y≈720-740 (temporal bases, rounder)
    
    # I'll define 8 cubic Bézier segments around the outline
    
    segs = []
    
    # Segment 1: Top-center (right of fissure) → Top-right → Right shoulder
    # Goes from top center rightward along the frontal and parietal lobe surface
    segs.append(cubic_pts(
        (520, 105),   # top-center (just right of fissure)
        (670, 88),    # front-right heading
        (820, 115),   # top-right region
        (935, 240),   # right upper shoulder
        n=120
    ))
    
    # Segment 2: Right shoulder → Right temporal bulge → Right lower
    segs.append(cubic_pts(
        (935, 240),
        (970, 400),   # right widest point
        (940, 560),   # right lower hemisphere
        (870, 680),   # right temporal bottom
        n=120
    ))
    
    # Segment 3: Right temporal → Bottom center-right → Bottom center
    segs.append(cubic_pts(
        (870, 680),
        (780, 740),   # bottom right curve
        (660, 750),   # bottom
        (520, 745),   # bottom center-right
        n=80
    ))
    
    # Segment 4: Bottom center (right) → Bottom center-left → Left temporal
    segs.append(cubic_pts(
        (520, 745),
        (380, 750),
        (250, 740),
        (148, 680),
        n=80
    ))
    
    # Segment 5: Left temporal → Left lower → Left shoulder
    segs.append(cubic_pts(
        (148, 680),
        ( 72, 560),
        ( 50, 400),
        ( 88, 240),
        n=120
    ))
    
    # Segment 6: Left shoulder → Top-left → Top-center
    segs.append(cubic_pts(
        ( 88, 240),
        (195, 115),
        (340,  88),
        (504, 105),   # top-center (just left of fissure)
        n=120
    ))
    
    # Add gyral bumps on top surface (between seg6 end and seg1 start)
    # These are the visible convolutions on the crown
    # We'll add small sinusoidal perturbations to the top portion
    
    # Flatten into single list
    all_pts = []
    for seg in segs:
        all_pts.extend(seg)
    
    # Post-process: add small gyral bumps to top portion (y < 300)
    result = []
    for (x, y) in all_pts:
        if y < 300:
            # Add small sine bumps
            bump = 18 * math.sin((x - 512) * 0.018 + 0.3) * math.sin((x - 512) * 0.040 + 0.7)
            y += bump * max(0, (300 - y) / 300)
        result.append((int(x), int(y)))
    
    return result

# ── SULCUS PATHS (Bézier) ─────────────────────────────────────────────────

def make_sulci(cx, brain_top, brain_bot):
    """
    Define major brain sulci as lists of (x,y) point lists.
    Returns dict: {'left': [(pts_list), ...], 'right': [(pts_list), ...]}
    
    Sulci run roughly parallel to the brain edge, from the central fissure
    outward, with irregular curves.
    
    Coordinate system: brain roughly x:85-940, y:100-740, cx=512
    """
    
    left_sulci  = []
    right_sulci = []
    
    # ── LEFT HEMISPHERE sulci ───────────────────────────────────
    # Each sulcus is a cubic Bézier from near the fissure outward/downward
    
    # Sulcus 1 (Superior Frontal): near the top, shallow arc
    left_sulci.append(cubic_pts(
        (500, 145), (430, 155), (300, 170), (165, 220), n=80))
    
    # Sulcus 2: Superior Parietal
    left_sulci.append(cubic_pts(
        (502, 200), (400, 205), (270, 225), (148, 290), n=80))
    
    # Sulcus 3: Central/Rolandic
    left_sulci.append(cubic_pts(
        (504, 268), (380, 275), (235, 305), (135, 375), n=80))
    
    # Sulcus 4: Postcentral
    left_sulci.append(cubic_pts(
        (504, 345), (362, 360), (218, 400), (125, 465), n=80))
    
    # Sulcus 5: Superior Temporal (curves down toward temporal lobe)
    left_sulci.append(cubic_pts(
        (504, 430), (345, 445), (205, 490), (120, 548), n=80))
    
    # Sulcus 6: Lateral (Sylvian) - prominent, curves down
    left_sulci.append(cubic_pts(
        (504, 520), (340, 540), (195, 570), (122, 620), n=80))
    
    # Sulcus 7: Temporal (lower, curves toward base)
    left_sulci.append(cubic_pts(
        (504, 610), (360, 628), (230, 638), (165, 660), n=60))
    
    # ── RIGHT HEMISPHERE sulci (mirror of left) ──────────────────
    def mirror_pts(pts):
        return [(SIZE - x, y) for x,y in pts]
    
    for s in left_sulci:
        right_sulci.append(mirror_pts(s))
    
    # Add a couple of additional asymmetric sulci for realism
    # Right extra: inferior frontal
    right_sulci.append(cubic_pts(
        (520, 165), (610, 172), (730, 178), (840, 220), n=60))
    
    # Left extra: inferio-temporal
    left_sulci.append(cubic_pts(
        (502, 162), (406, 170), (288, 176), (178, 216), n=60))
    
    return {'left': left_sulci, 'right': right_sulci}

# ── MAIN BUILD ─────────────────────────────────────────────────────────────

def build():
    canvas = Image.new("RGBA",(SIZE,SIZE),BLACK+(255,))
    draw_circuits(canvas)
    
    bcx = SIZE // 2  # 512
    bcy = int(SIZE * 0.415)  # 425 - adjusted for this brain shape
    
    # Brain outline
    bpts = make_brain_outline()
    
    # Brain mask
    bm_img = Image.new("L",(SIZE,SIZE),0)
    ImageDraw.Draw(bm_img).polygon(bpts, fill=255)
    bma = np.array(bm_img)
    
    cx_rows = np.where(bma[:,bcx]>0)[0]
    brain_top = int(cx_rows[0])  if len(cx_rows) else 100
    brain_bot = int(cx_rows[-1]) if len(cx_rows) else 740
    
    # ── Distance-transform + noise for organic texture ──────────
    dist_inside = distance_transform_edt(bma).astype(np.float32)
    max_d = dist_inside.max()
    dist_norm = dist_inside / max_d
    
    # Add perlin-like noise (gaussian-filtered random) to break up concentricity
    rng = np.random.default_rng(42)
    noise_raw = rng.standard_normal((SIZE,SIZE)).astype(np.float32)
    noise_smooth = gaussian_filter(noise_raw, sigma=25) * 0.18
    noise_smooth += gaussian_filter(noise_raw, sigma=8) * 0.08
    
    # Perturbed distance field
    dist_perturbed = (dist_norm + noise_smooth).clip(0, 1)
    
    # Gyral wave (more cycles = more folds)
    N_CYCLES = 9
    wave = np.sin(dist_perturbed * N_CYCLES * 2 * math.pi)
    
    # ── Color mapping ─────────────────────────────────────────────
    inside = bma > 0
    left_m  = inside & (np.arange(SIZE)[np.newaxis,:] < bcx)
    right_m = inside & (np.arange(SIZE)[np.newaxis,:] >= bcx)
    
    M_pal = [M_BRIGHT, M_HOT, M_MID, M_DARK, M_DEEP]
    G_pal = [G_BRIGHT, G_HOT, G_MID, G_DARK, G_DEEP]
    
    # 0=crown(bright), 1=sulcus(dark)
    norm_field = (1.0 - wave) / 2.0
    # Force outer rim to bright
    norm_field[dist_norm < 0.04] = 0.0
    idx_field = (norm_field * 4.0).clip(0, 3.99).astype(int)
    
    brain_arr = np.zeros((SIZE,SIZE,4), dtype=np.uint8)
    for pi in range(5):
        mask_l = left_m  & (idx_field == pi)
        mask_r = right_m & (idx_field == pi)
        brain_arr[mask_l] = list(M_pal[pi]) + [255]
        brain_arr[mask_r] = list(G_pal[pi]) + [255]
    
    canvas = composite(canvas, Image.fromarray(brain_arr))
    
    # ── Explicit anatomical sulci (drawn on top) ──────────────────
    sulci_data = make_sulci(bcx, brain_top, brain_bot)
    
    sulci_layer = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    sd = ImageDraw.Draw(sulci_layer)
    
    for side, sulci_list in sulci_data.items():
        deep_col  = M_DEEP if side=='left' else G_DEEP
        dark_col  = M_DARK if side=='left' else G_DARK
        
        for spts in sulci_list:
            ipts = [(int(x),int(y)) for x,y in spts]
            # Filter to only draw inside brain mask
            valid = [(x,y) for x,y in ipts
                     if 0<=x<SIZE and 0<=y<SIZE and bma[y,x]>0]
            if len(valid) < 3:
                continue
            # Thick dark groove
            sd.line(valid, fill=deep_col+(255,), width=8)
            sd.line(valid, fill=dark_col+(200,), width=5)
            sd.line(valid, fill=(0,0,0,160), width=2)
    
    # Blend sulci layer (more transparent to not overpower)
    sa = np.array(sulci_layer)
    sa[...,3] = (sa[...,3].astype(np.float32)*0.80).clip(0,255).astype(np.uint8)
    sulci_layer = Image.fromarray(sa)
    
    canvas = composite(canvas, sulci_layer)
    
    # ── Gyrus crown highlights between sulci ─────────────────────
    crown_layer = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    cd = ImageDraw.Draw(crown_layer)
    
    for side, sulci_list in sulci_data.items():
        bright_col = M_BRIGHT if side=='left' else G_BRIGHT
        hot_col    = M_HOT    if side=='left' else G_HOT
        
        # The crown is halfway between adjacent sulci
        for i in range(len(sulci_list)-1):
            s1 = sulci_list[i]; s2 = sulci_list[i+1]
            n = min(len(s1), len(s2))
            crown = [((s1[j][0]+s2[j][0])//2, (s1[j][1]+s2[j][1])//2) for j in range(n)]
            valid = [(int(x),int(y)) for x,y in crown
                     if 0<=int(x)<SIZE and 0<=int(y)<SIZE and bma[int(y),int(x)]>0]
            if len(valid)<2: continue
            cd.line(valid, fill=hot_col+(120,), width=3)
            cd.line(valid, fill=bright_col+(60,), width=1)
    
    canvas = composite(canvas, crown_layer)
    
    # ── Neon rim glow ────────────────────────────────────────────
    rim_l = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    rim_r = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(rim_l).line(bpts+[bpts[0]], fill=M_BRIGHT+(200,), width=6)
    ImageDraw.Draw(rim_r).line(bpts+[bpts[0]], fill=G_BRIGHT+(200,), width=6)
    rla=np.array(rim_l); rla[:,bcx:]=0; rim_l=Image.fromarray(rla)
    rra=np.array(rim_r); rra[:,:bcx]=0; rim_r=Image.fromarray(rra)
    
    canvas = add_glow(canvas, rim_l, [(5,0.85),(18,0.5),(42,0.22)])
    canvas = add_glow(canvas, rim_r, [(5,0.85),(18,0.5),(42,0.22)])
    
    # ── Outer halo ───────────────────────────────────────────────
    mag_h = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(mag_h).polygon(bpts,fill=M_HOT+(150,))
    mha=np.array(mag_h); mha[:,bcx:]=0; mag_h=Image.fromarray(mha)
    
    grn_h = Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    ImageDraw.Draw(grn_h).polygon(bpts,fill=G_HOT+(150,))
    gha=np.array(grn_h); gha[:,:bcx]=0; grn_h=Image.fromarray(gha)
    
    for r,a in [(28,0.30),(65,0.17),(120,0.09)]:
        canvas=composite(canvas, blur_layer(mag_h,r,a))
        canvas=composite(canvas, blur_layer(grn_h,r,a))
    
    # ── Medial fissure ───────────────────────────────────────────
    fiss=Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    fd=ImageDraw.Draw(fiss)
    fd.line([(bcx,brain_top),(bcx,brain_bot)],fill=(0,0,0,255),width=7)
    fd.line([(bcx-5,brain_top),(bcx-5,brain_bot)],fill=M_DARK+(150,),width=2)
    fd.line([(bcx+5,brain_top),(bcx+5,brain_bot)],fill=G_DARK+(150,),width=2)
    canvas=composite(canvas, fiss)
    
    # ── Bitcoin ₿ ─────────────────────────────────────────────────
    btc_sz = int((brain_bot-brain_top)*0.44)
    try:
        btc_font = ImageFont.truetype(f"{FONT_DIR}/IBMPlexMono-Bold.ttf",btc_sz)
    except:
        btc_font = ImageFont.truetype("/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",btc_sz)
    
    btc_l=Image.new("RGBA",(SIZE,SIZE),(0,0,0,0))
    bd=ImageDraw.Draw(btc_l)
    bb=bd.textbbox((0,0),"₿",font=btc_font)
    bw,bh=bb[2]-bb[0],bb[3]-bb[1]
    bx2=bcx-bw//2-bb[0]; by2=bcy-bh//2-bb[1]
    
    bd.text((bx2+4,by2+4),"₿",font=btc_font,fill=GOLD_D+(200,))
    bd.text((bx2,by2),"₿",font=btc_font,fill=GOLD_M+(255,))
    bta=np.array(btc_l); hot=bta[...,0]>130
    bta[hot,0]=np.minimum(bta[hot,0].astype(int)+45,255).astype(np.uint8)
    bta[hot,1]=np.minimum(bta[hot,1].astype(int)+60,255).astype(np.uint8)
    btc_l=Image.fromarray(bta)
    bta2=np.array(btc_l); bta2[...,3]=np.minimum(bta2[...,3],bma); btc_l=Image.fromarray(bta2)
    
    canvas=add_glow(canvas, btc_l, [(8,1.0),(20,0.75),(42,0.45),(78,0.20)])
    
    # ── BIOHACKER text ────────────────────────────────────────────
    target_w=int(SIZE*0.80)
    text_font=None; text_bb=(0,0,200,20)
    for sz in range(260,20,-2):
        try:
            f=ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf",sz)
            bb_t=ImageDraw.Draw(Image.new("L",(10,10))).textbbox((0,0),"BIOHACKER",font=f)
            if (bb_t[2]-bb_t[0])<=target_w: text_font=f; text_bb=bb_t; break
        except: break
    if text_font is None: text_font=ImageFont.load_default()
    
    tw=text_bb[2]-text_bb[0]; th=text_bb[3]-text_bb[1]
    gap=int(SIZE*0.028)
    tx=SIZE//2-tw//2-text_bb[0]; ty=brain_bot+gap-text_bb[1]
    if ty+th>SIZE-18: ty=SIZE-18-th
    
    tl=Image.new("RGBA",(SIZE,SIZE),(0,0,0,0)); td=ImageDraw.Draw(tl)
    td.text((tx+5,ty+5),"BIOHACKER",font=text_font,fill=CYAN_D+(180,))
    td.text((tx,ty),"BIOHACKER",font=text_font,fill=CYAN_H+(255,))
    td.line([(tx,ty),(tx+tw,ty)],fill=(255,255,255,85),width=2)
    canvas=add_glow(canvas, tl, [(5,1.0),(14,0.8),(30,0.5),(60,0.22)])
    
    # ── Final ────────────────────────────────────────────────────
    out=Image.new("RGB",(SIZE,SIZE),BLACK)
    out.paste(canvas.convert("RGB"),(0,0))
    
    arr=np.array(out,dtype=np.float32)
    ys=np.linspace(-1,1,SIZE); xs=np.linspace(-1,1,SIZE)
    xx2,yy2=np.meshgrid(xs,ys)
    vig=np.clip(1.0-np.sqrt(xx2**2+yy2**2)*0.40,0.50,1.0)
    arr*=vig[...,np.newaxis]
    out=Image.fromarray(arr.clip(0,255).astype(np.uint8))
    
    bloom=out.filter(ImageFilter.GaussianBlur(5))
    a1=np.array(out,dtype=np.float32); a2=np.array(bloom,dtype=np.float32)
    out=Image.fromarray((a1*0.83+a2*0.17).clip(0,255).astype(np.uint8))
    
    return out

if __name__ == "__main__":
    print("Building BIOHACKER icon v9 (anatomical bezier sulci)...")
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    icon = build()
    icon.save(OUT_PATH,"PNG")
    v = Image.open(OUT_PATH)
    print(f"Saved: {OUT_PATH}\nSize: {v.size}\nBytes: {os.path.getsize(OUT_PATH):,}")
