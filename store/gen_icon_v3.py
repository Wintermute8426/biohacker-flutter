#!/usr/bin/env python3
"""
BIOHACKER App Icon v3 — Cinematic high-fidelity pixel art — 1024×1024
Philosophy: NEURAL SOVEREIGNTY
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import numpy as np
import math
import random
import os

random.seed(99)
np.random.seed(99)

SIZE = 1024
PS = 3  # pixel grid size

FONT_DIR = os.path.expanduser("~/.openclaw/workspace/skills/canvas-design/canvas-fonts")
SILKSCREEN   = os.path.join(FONT_DIR, "Silkscreen-Regular.ttf")
IBM_MONO_B   = os.path.join(FONT_DIR, "IBMPlexMono-Bold.ttf")
GEIST_MONO_B = os.path.join(FONT_DIR, "GeistMono-Bold.ttf")

# ── PALETTE ────────────────────────────────────────────────────────────────
BG      = (1, 2, 10)

# Cyan (left hemisphere)
C0 = (215, 255, 255)
C1 = (0,   255, 255)
C2 = (0,   195, 195)
C3 = (0,   120, 122)
C4 = (0,    48,  52)
C5 = (0,    12,  16)

# Green (right hemisphere)
G0 = (215, 255, 205)
G1 = (57,  255,  20)
G2 = (30,  195,  10)
G3 = (15,  115,   5)
G4 = (5,    42,   2)
G5 = (1,    10,   0)

# Gold / BTC
GOLD0 = (255, 255, 215)
GOLD1 = (255, 215,  35)
GOLD2 = (195, 148,   0)
GOLD3 = ( 90,  58,   0)

# Purple aura
PURP  = (160,  30, 255)

# Circuit
TR0 = ( 0,  9,  7)
TR1 = ( 0, 20, 16)
TR2 = ( 0, 40, 34)
TR3 = ( 0, 68, 57)

# Matrix
MTX0 = ( 0, 210, 55)
MTX1 = ( 0, 115, 28)
MTX2 = ( 0,  55, 13)

BCX, BCY = 510, 455

def sp(v):
    return (int(round(float(v))) // PS) * PS

# ── BRAIN SILHOUETTE  ──────────────────────────────────────────────────────
def brain_radius(deg):
    """
    360° polar silhouette. deg=0=right, 90=down, 180=left, 270=up
    Produces a proper top-view brain oval.
    """
    t = math.radians(deg)
    # Oval base — slightly wider than tall
    a, b = 212, 195
    base = (a * b) / math.sqrt((b * math.cos(t))**2 + (a * math.sin(t))**2)

    # Temporal bulges (east / west sides)
    temp_r = 30 * math.exp(-((deg        )**2) / 700)
    temp_l = 30 * math.exp(-((deg - 180  )**2) / 700)
    temp_l2= 30 * math.exp(-((deg - 180+360)**2) / 700)  # wrap-around
    temp_r2= 30 * math.exp(-((deg - 360  )**2) / 700)

    # Frontal lobe (top of canvas = 270°)
    front  = 20 * math.exp(-((deg - 270)**2) / 1500)

    # Occipital (bottom = 90°)
    occ    = 15 * math.exp(-((deg - 90)**2) / 900)

    # Slight central sulcus indent at crown (270°)
    sulcus = -6 * math.exp(-((deg - 270)**2) / 150)

    return base + temp_r + temp_r2 + temp_l + temp_l2 + front + occ + sulcus

def full_brain_poly():
    pts = []
    for deg in range(0, 360, 2):
        r = brain_radius(deg)
        t = math.radians(deg)
        x = sp(BCX + r * math.cos(t))
        y = sp(BCY + r * math.sin(t))
        pts.append((x, y))
    return pts

def build_brain_mask():
    mask = Image.new('L', (SIZE, SIZE), 0)
    ImageDraw.Draw(mask).polygon(full_brain_poly(), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(1.8))
    arr  = np.array(mask)
    return (arr > 55).astype(np.uint8) * 255

# ── VOLUMETRIC SHADING ─────────────────────────────────────────────────────
def get_voxel_color(x, y):
    side    = 'left' if x < BCX else 'right'
    palette = [C5, C4, C3, C2, C1, C0] if side == 'left' else [G5, G4, G3, G2, G1, G0]

    # Light source: upper-center of each hemisphere
    lx = BCX - 72 if side == 'left' else BCX + 72
    ly = BCY - 55
    dist = math.sqrt((x - lx)**2 + (y - ly)**2)

    t = min(dist / 230.0, 1.0)

    # Top-light bonus for crown
    top_bonus = max(0.0, (BCY - 90 - y) / 90.0) * 0.20
    brightness = (1.0 - t**1.4) + top_bonus
    brightness = max(0.0, min(1.0, brightness))

    idx = int(brightness * (len(palette) - 1))
    return palette[min(idx, len(palette) - 1)]

def draw_brain_volumetric(mask):
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    for y in range(0, SIZE, PS):
        for x in range(0, SIZE, PS):
            if mask[y, x] == 0:
                continue
            col = get_voxel_color(x, y)
            arr[y:y+PS, x:x+PS, :3] = col
            arr[y:y+PS, x:x+PS, 3]  = 255
    return arr

# ── GYRI — very gentle ────────────────────────────────────────────────────
def draw_gyri(arr, mask):
    """
    Very sparse gyri overlaid. 40px spacing, low contrast, just a hint.
    """
    fold_offsets = list(range(-190, 200, 42))

    for fo in fold_offsets:
        for x in range(0, SIZE, PS):
            phase = (x / SIZE) * 2.8 * math.pi + fo * 0.035
            fy = sp(BCY + fo + 8 * math.sin(phase))

            side   = 'left' if x < BCX else 'right'
            crest  = C3 if side == 'left' else G3
            sulcus = C5 if side == 'left' else G5

            for ry, tgt, strength in [(fy - PS, crest, 0.35), (fy, sulcus, 0.30)]:
                if 0 <= ry < SIZE:
                    for dx in range(PS):
                        nx = x + dx
                        if 0 <= nx < SIZE and mask[ry, nx]:
                            e = arr[ry, nx, :3].astype(float)
                            c = np.array(tgt, dtype=float)
                            arr[ry, nx, :3] = np.clip(e * (1 - strength) + c * strength, 0, 255).astype(np.uint8)

    # Neon rim
    for y in range(PS, SIZE - PS):
        for x in range(PS, SIZE - PS):
            if mask[y, x] == 0:
                continue
            ne = (mask[y-PS, x] == 0 or mask[y+PS, x] == 0 or
                  mask[y, x-PS] == 0 or mask[y, x+PS] == 0)
            if ne:
                arr[y, x, :3] = C1 if x < BCX else G1
                arr[y, x, 3]  = 255

    # Central fissure
    cx = sp(BCX)
    for y in range(SIZE):
        if 0 <= y < SIZE and mask[y, cx]:
            arr[y, cx, :3] = (130, 255, 215)
            arr[y, cx, 3]  = 255

    return arr

# ── BTC ₿ RENDERED FROM FONT ──────────────────────────────────────────────
def draw_btc():
    """Render the ₿ character from IBMPlexMono-Bold for accuracy, then gold-colorize"""
    arr      = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    glow_src = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)

    # Render ₿ to a temp image
    fsize = 155
    ch = "₿"
    try:
        fnt = ImageFont.truetype(IBM_MONO_B, fsize)
    except:
        try:
            fnt = ImageFont.truetype(GEIST_MONO_B, fsize)
        except:
            fnt = ImageFont.load_default()

    tmp = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(tmp)
    bbox = draw.textbbox((0, 0), ch, font=fnt)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = BCX - tw // 2 - bbox[0]
    ty = BCY - th // 2 - bbox[1] - 4
    draw.text((tx, ty), ch, font=fnt, fill=(255, 255, 255, 255))

    tmp_arr = np.array(tmp)

    # Snap to pixel grid and gold-colorize
    for y in range(0, SIZE, PS):
        for x in range(0, SIZE, PS):
            block = tmp_arr[y:y+PS, x:x+PS, 3]
            if block.max() < 60:
                continue
            alpha = block.max()

            # Determine shade based on position within glyph
            # Top pixels brighter, bottom darker
            rel_y = (y - (BCY - th//2)) / max(th, 1)
            if rel_y < 0.15:
                fc = GOLD0
            elif rel_y < 0.35:
                fc = GOLD1
            elif rel_y > 0.85:
                fc = GOLD3
            else:
                fc = GOLD2

            # Snap to pixel grid
            arr[y:y+PS, x:x+PS, :3] = fc
            arr[y:y+PS, x:x+PS, 3]  = alpha
            glow_src[y:y+PS, x:x+PS, :3] = GOLD1
            glow_src[y:y+PS, x:x+PS, 3]  = min(255, int(alpha * 1.1))

    return arr, glow_src

# ── CIRCUIT TRACES ─────────────────────────────────────────────────────────
def draw_circuits():
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    grid = 80

    for hy in range(0, SIZE, grid):
        x = 0
        while x < SIZE:
            seg = random.choice([80, 120, 160])
            end = min(x + seg, SIZE)
            col = random.choice([TR0, TR0, TR1])
            a   = random.randint(85, 140)
            for dy in range(2):
                r = hy + dy
                if 0 <= r < SIZE:
                    arr[r, x:end, :3] = col
                    arr[r, x:end, 3]  = a
            x += end - x + random.choice([0, 40, 80])

    for vx in range(0, SIZE, grid):
        y = 0
        while y < SIZE:
            seg = random.choice([80, 120, 160])
            end = min(y + seg, SIZE)
            col = random.choice([TR0, TR0, TR1])
            a   = random.randint(75, 125)
            for dx in range(2):
                c = vx + dx
                if 0 <= c < SIZE:
                    arr[y:end, c, :3] = col
                    arr[y:end, c, 3]  = a
            y += end - y + random.choice([0, 40, 80])

    for hy in range(0, SIZE, grid):
        for vx in range(0, SIZE, grid):
            if random.random() < 0.20:
                r = 4
                for dy in range(-r, r+1):
                    for dx in range(-r, r+1):
                        if dy**2 + dx**2 <= r**2:
                            ny, nx = hy+dy, vx+dx
                            if 0 <= ny < SIZE and 0 <= nx < SIZE:
                                arr[ny, nx, :3] = TR3
                                arr[ny, nx, 3]  = 165

    jogs = [
        ( 96, 290,  96, 410, 196, 410),
        (800, 175, 720, 175, 720, 305),
        (900, 595, 900, 705, 810, 705),
        (120, 735, 120, 855, 225, 855),
        ( 50, 505,  50, 615, 150, 615),
        (695,  50, 695, 130, 795, 130),
    ]
    for (x1,y1, x2,y2, x3,y3) in jogs:
        a = 145
        for dy in range(2):
            r = y1+dy
            if 0 <= r < SIZE:
                arr[r, min(x1,x2):max(x1,x2), :3] = TR2
                arr[r, min(x1,x2):max(x1,x2), 3]  = a
        for dx in range(2):
            c = x2+dx
            if 0 <= c < SIZE:
                arr[min(y2,y3):max(y2,y3)+1, c, :3] = TR2
                arr[min(y2,y3):max(y2,y3)+1, c, 3]  = a
        for dy in range(-5, 6):
            for dx in range(-5, 6):
                if dy**2+dx**2 <= 25:
                    ny, nx = y2+dy, x2+dx
                    if 0 <= ny < SIZE and 0 <= nx < SIZE:
                        arr[ny, nx, :3] = TR3
                        arr[ny, nx, 3]  = 182

    return arr

# ── MATRIX RAIN ────────────────────────────────────────────────────────────
def draw_matrix_rain():
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    chars = "01₿∂∑Ω∆Ψ"
    try:
        fnt = ImageFont.truetype(SILKSCREEN, 10)
    except:
        fnt = ImageFont.load_default()

    img  = Image.fromarray(arr)
    draw = ImageDraw.Draw(img)

    for vx in range(15, SIZE, 28):
        start_y = random.randint(-SIZE//3, SIZE//2)
        chain   = random.randint(4, 13)
        for i in range(chain):
            cy = start_y + i * 17
            if not (0 <= cy < SIZE - 18) or not (0 <= vx < SIZE - 14):
                continue
            ch = random.choice(chars)
            t  = i / chain
            if t < 0.12:
                col, a = MTX0, 180
            elif t < 0.45:
                col, a = MTX1, 118
            else:
                col, a = MTX2, 62
            draw.text((vx, cy), ch, font=fnt, fill=(*col, a))

    return np.array(img)

# ── PURPLE AURA ────────────────────────────────────────────────────────────
def draw_purple_aura():
    """Strong elliptical purple bloom behind brain"""
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    cx, cy = BCX, BCY
    rx, ry = 315, 292

    ys, xs = np.mgrid[0:SIZE, 0:SIZE]
    dist   = np.sqrt(((xs - cx)/rx)**2 + ((ys - cy)/ry)**2)
    t      = np.clip(1.2 - dist, 0, 1) ** 1.8

    arr[:,:,0] = np.clip(PURP[0] * t,   0, 255).astype(np.uint8)
    arr[:,:,1] = np.clip(PURP[1] * t,   0, 255).astype(np.uint8)
    arr[:,:,2] = np.clip(PURP[2] * t,   0, 255).astype(np.uint8)
    arr[:,:,3] = np.clip(255 * t,        0, 255).astype(np.uint8)
    return arr

# ── BIOHACKER TEXT ─────────────────────────────────────────────────────────
def draw_text_label():
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    img  = Image.fromarray(arr)
    draw = ImageDraw.Draw(img)

    text  = "BIOHACKER"
    fsize = 40
    try:
        fnt = ImageFont.truetype(SILKSCREEN, fsize)
    except:
        fnt = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw   = bbox[2] - bbox[0]
    tx   = (SIZE - tw) // 2
    ty   = SIZE - 76

    for off, a in [(6, 28), (5, 38), (4, 50), (3, 65), (2, 78)]:
        for doff in [(-off, 0), (off, 0), (0, -off), (0, off)]:
            draw.text((tx + doff[0], ty + doff[1]), text, font=fnt, fill=(0, 180, 180, a))

    draw.text((tx, ty), text, font=fnt, fill=(0, 255, 255, 255))

    return np.array(img)

# ── COMPOSITING ────────────────────────────────────────────────────────────
def alpha_comp(base, over):
    a_o   = over[:,:,3:4].astype(float) / 255.0
    a_b   = base[:,:,3:4].astype(float) / 255.0
    a_out = a_o + a_b * (1 - a_o)
    rgb   = (over[:,:,:3].astype(float) * a_o +
             base[:,:,:3].astype(float) * a_b * (1 - a_o))
    with np.errstate(divide='ignore', invalid='ignore'):
        rgb = np.where(a_out > 1e-6, rgb / np.maximum(a_out, 1e-6), 0)
    out = np.zeros_like(base, dtype=np.uint8)
    out[:,:,:3] = np.clip(rgb, 0, 255).astype(np.uint8)
    out[:,:,3]  = np.clip(a_out[:,:,0] * 255, 0, 255).astype(np.uint8)
    return out

def screen_blend(base, over, strength=1.0):
    b  = base[:,:,:3].astype(float) / 255.0
    o  = over[:,:,:3].astype(float) / 255.0
    a  = over[:,:,3:4].astype(float) / 255.0 * strength
    s  = 1 - (1 - b) * (1 - o)
    out = base.copy()
    out[:,:,:3] = np.clip((b + (s - b) * a) * 255, 0, 255).astype(np.uint8)
    return out

def make_glow(arr, radius, alpha_mult=1.0):
    img     = Image.fromarray(arr)
    blurred = np.array(img.filter(ImageFilter.GaussianBlur(radius)))
    blurred[:,:,3] = np.clip(blurred[:,:,3].astype(float) * alpha_mult, 0, 255).astype(np.uint8)
    return blurred

def add_vignette(arr):
    cx, cy = SIZE/2, SIZE/2
    ys, xs = np.mgrid[0:SIZE, 0:SIZE]
    dist   = np.sqrt((xs-cx)**2 + (ys-cy)**2) / math.sqrt(cx**2+cy**2)
    factor = np.clip(1.0 - 0.62 * dist**1.7, 0.18, 1.0)
    arr[:,:,:3] = np.clip(arr[:,:,:3].astype(float) * factor[:,:,np.newaxis], 0, 255).astype(np.uint8)
    return arr

def add_fine_noise(arr):
    noise = np.random.randint(-3, 4, (SIZE, SIZE, 3))
    arr[:,:,:3] = np.clip(arr[:,:,:3].astype(int) + noise, 0, 255).astype(np.uint8)
    return arr

def add_scanlines(arr, spacing=6):
    for y in range(0, SIZE, spacing):
        arr[y, :, :3] = np.clip(arr[y, :, :3].astype(float) * 0.85, 0, 255).astype(np.uint8)
    return arr

# ── MAIN ───────────────────────────────────────────────────────────────────
def main():
    print("🧠 BIOHACKER icon v3 — Neural Sovereignty (final)")

    print("  [1/9] Background...")
    bg = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    bg[:,:,:3] = BG
    bg[:,:, 3] = 255

    print("  [2/9] Matrix rain...")
    rain = draw_matrix_rain()

    print("  [3/9] Circuit traces...")
    circuits = draw_circuits()

    print("  [4/9] Purple aura...")
    purple = draw_purple_aura()

    print("  [5/9] Brain...")
    mask   = build_brain_mask()
    brain  = draw_brain_volumetric(mask)
    brain  = draw_gyri(brain, mask)

    print("  [6/9] Bitcoin ₿...")
    btc, btc_glow_src = draw_btc()

    print("  [7/9] BIOHACKER text...")
    text = draw_text_label()

    print("  [8/9] Glow layers...")
    brain_glow_xl = make_glow(brain, 75,  0.40)
    brain_glow_lg = make_glow(brain, 38,  0.60)
    brain_glow_md = make_glow(brain, 17,  0.80)
    brain_glow_sm = make_glow(brain,  7,  0.94)

    btc_glow_lg   = make_glow(btc_glow_src, 48, 0.92)
    btc_glow_md   = make_glow(btc_glow_src, 20, 1.10)
    btc_glow_sm   = make_glow(btc_glow_src,  8, 1.35)

    text_glow     = make_glow(text, 10, 0.85)

    print("  [9/9] Compositing...")
    out = bg.copy()
    out = alpha_comp(out, rain)
    out = alpha_comp(out, circuits)

    # Purple aura — prominent
    out = alpha_comp(out, purple)
    out = screen_blend(out, purple, strength=0.78)

    # Brain glow (contributes to colored bloom around edges)
    out = screen_blend(out, brain_glow_xl, strength=0.52)
    out = screen_blend(out, brain_glow_lg, strength=0.68)
    out = screen_blend(out, brain_glow_md, strength=0.84)
    out = screen_blend(out, brain_glow_sm, strength=0.94)

    # Solid brain
    out = alpha_comp(out, brain)

    # BTC glow
    out = screen_blend(out, btc_glow_lg, strength=0.75)
    out = screen_blend(out, btc_glow_md, strength=0.90)
    out = screen_blend(out, btc_glow_sm, strength=1.10)

    # Solid BTC
    out = alpha_comp(out, btc)

    # Text
    out = screen_blend(out, text_glow, strength=0.85)
    out = alpha_comp(out, text)

    # Post
    out = add_fine_noise(out)
    out = add_scanlines(out, spacing=6)
    out = add_vignette(out)

    out_path = '/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v3.png'
    Image.fromarray(out).convert('RGBA').save(out_path, optimize=True)

    img = Image.open(out_path)
    print(f"\n✅  Saved: {out_path}")
    print(f"    Size:  {img.size}  Mode: {img.mode}")
    print(f"    File:  {os.path.getsize(out_path):,} bytes")

if __name__ == '__main__':
    main()
