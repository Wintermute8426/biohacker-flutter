#!/usr/bin/env python3
"""
BIOHACKER App Icon v2 — Waneella/Kirokaze cyberpunk pixel art — 1024×1024
v3 rewrite: proper two-lobe brain, numpy wave folds, bigger BTC, premium glow
"""
from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import math
import random

random.seed(99)
np.random.seed(99)

SIZE = 1024
PS   = 4     # art pixel size (4x4 actual pixels per "art pixel")

# ─── PALETTE ───────────────────────────────────────────────────────────────
BG       = (2,   3,  14)

# 52-step palette — wider gyri with narrow sulci at phase 0-5
# Phase 0-5 = dark sulcus, phases 44-48 = bright crest, rest = gyrus body
def _build_palette(dark, shadow, lo, mid, hi, bright):
    """Build 52-entry palette: 6 dark, 8 shadow-rise, 26 mid, 8 rise, 4 bright"""
    p = []
    p += [dark]   * 4   # 0-3  sulcus floor
    p += [shadow] * 4   # 4-7  shadow transition
    # 8-18 rise from shadow->lo->mid (11 steps)
    for i in range(11):
        t = i / 10.0
        p.append(tuple(int(shadow[c] + (mid[c]-shadow[c])*t) for c in range(3)))
    # 19-33 flat mid plateau (15 steps)
    p += [mid] * 15
    # 34-43 rise to bright (10 steps)
    for i in range(10):
        t = i / 9.0
        p.append(tuple(int(mid[c] + (bright[c]-mid[c])*t) for c in range(3)))
    # 44-47 bright crest (4 steps)
    p += [bright] * 4
    # 48-51 fast fall (4 steps)
    for i in range(4):
        t = (i+1) / 4.0
        p.append(tuple(int(bright[c] + (shadow[c]-bright[c])*t) for c in range(3)))
    return p

CYAN_STEPS  = _build_palette(
    (0, 38,38), (0,65,63), (0,100,98), (0,162,160), (0,210,208), (0,255,255))
GREEN_STEPS = _build_palette(
    (8,36,2),  (18,65,5), (28,100,8), (40,158,12), (50,210,16), (57,255,20))

GOLD_B  = (255, 215,  40)
GOLD_M  = (200, 155,   8)
GOLD_D  = ( 90,  48,   0)
GOLD_HL = (255, 240, 160)  # highlight

TR_DIM  = (0,  14,  11)
TR_MED  = (0,  33,  27)
TR_BRT  = (0,  58,  48)
TR_DOT  = (0,  85,  70)

CENTER_LINE = (150, 255, 210)

# ─── BRAIN GEOMETRY ────────────────────────────────────────────────────────
# Centered at BCX, BCY — characteristic two-lobe top-view silhouette
BCX, BCY = 512, 462

# Detailed two-lobe silhouette — more polygon points for smooth visible bumps
BRAIN_VERTS_REL = [
    # ── Top frontal lobe region: characteristic two-bump shape ──
    (  0, -232),   # deep midline cleft between lobes
    (-12, -240),
    (-30, -248),
    (-58, -258),   # left lobe crest
    (-82, -255),
    (-108,-242),   # left lobe outer slope
    (-138,-225),
    # ── Left hemisphere ──
    (-178,-195),
    (-218,-148),
    (-252, -88),   # left outer (widest)
    (-258,  -8),
    (-248,  70),
    (-228, 130),
    (-188, 172),
    (-140, 196),
    (-80,  202),
    # ── Bottom ──
    (  0,  205),
    # ── Right hemisphere (mirror) ──
    ( +80, 202),
    (+140, 196),
    (+188, 172),
    (+228, 130),
    (+248,  70),
    (+258,  -8),
    (+252, -88),
    (+218,-148),
    (+178,-195),
    # ── Right frontal lobe ──
    (+138,-225),
    (+108,-242),
    ( +82,-255),
    ( +58,-258),   # right lobe crest
    ( +30,-248),
    ( +12,-240),
]

def snap(v):
    return (int(round(float(v))) // PS) * PS

def brain_polygon():
    return [(snap(BCX + dx), snap(BCY + dy)) for dx, dy in BRAIN_VERTS_REL]

def build_brain_mask():
    m = Image.new('L', (SIZE, SIZE), 0)
    ImageDraw.Draw(m).polygon(brain_polygon(), fill=255)
    return np.array(m)

# ─── PIXEL-ART GYRI (numpy wave approach) ──────────────────────────────────
def draw_brain(brain_mask):
    """
    Fill brain with wave-based gyri using numpy for speed.
    Phase 0-3 = dark sulcus, phase 22 = bright neon crest.
    Left half = cyan, right half = neon green.
    """
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)

    Y, X = np.mgrid[0:SIZE, 0:SIZE]
    inside = brain_mask > 0

    # Wave offsets — left side waves right, right side waves left (mirror)
    AMP   = 14.0
    FREQ  = 0.020

    wave_L = AMP * np.sin(FREQ * X + 0.0)
    wave_R = AMP * np.sin(FREQ * (SIZE - X) + 0.4)

    # Smooth blend at center divide
    blend = np.clip((X.astype(float) - BCX) / 120.0, 0.0, 1.0)
    wave  = wave_L * (1.0 - blend) + wave_R * blend

    FOLD_PERIOD = 64
    phase = ((Y.astype(float) - BCY - wave) % FOLD_PERIOD).astype(int)
    phase = ((phase % FOLD_PERIOD) + FOLD_PERIOD) % FOLD_PERIOD
    phase = np.clip(phase, 0, 51)  # palette has 52 entries

    is_left  = (X < BCX) & inside
    is_right = (X >= BCX) & inside

    # Build per-pixel color lookup (vectorised)
    c_arr = np.array(CYAN_STEPS,  dtype=np.uint8)  # (28, 3)
    g_arr = np.array(GREEN_STEPS, dtype=np.uint8)

    arr[:, :, :3][is_left]  = c_arr[phase[is_left]]
    arr[:, :, 3][is_left]   = 255
    arr[:, :, :3][is_right] = g_arr[phase[is_right]]
    arr[:, :, 3][is_right]  = 255

    # ── Bright neon rim (1 art-pixel border) ──
    from scipy.ndimage import binary_erosion
    eroded   = binary_erosion(inside, iterations=PS)
    rim_mask = inside & ~eroded
    arr[:, :, :3][rim_mask & (X < BCX)]  = CYAN_STEPS[47]
    arr[:, :, :3][rim_mask & (X >= BCX)] = GREEN_STEPS[47]

    # ── Center divide line ──
    cx = snap(BCX)
    for x in range(cx - 1, cx + 3):
        if 0 <= x < SIZE:
            col_line = inside[:, x]
            arr[:, x, :3][col_line] = CENTER_LINE
            arr[:, x, 3][col_line]  = 255

    return arr


# ─── BITCOIN ₿ PIXEL ART ───────────────────────────────────────────────────
BTC_BITMAP = [
    "0 0 1 1 0 0 0 0 0 0",
    "0 0 1 1 0 0 0 0 0 0",
    "1 1 1 1 1 1 1 1 0 0",
    "1 1 0 1 1 0 0 1 1 0",
    "1 1 0 1 1 0 0 0 1 1",
    "1 1 0 1 1 0 0 0 1 1",
    "0 1 1 1 1 1 1 1 0 0",
    "0 1 1 1 1 1 1 1 1 0",
    "1 1 0 1 1 0 0 0 1 1",
    "1 1 0 1 1 0 0 0 1 1",
    "1 1 0 1 1 0 0 1 1 0",
    "1 1 1 1 1 1 1 1 0 0",
    "0 0 1 1 0 0 0 0 0 0",
    "0 0 1 1 0 0 0 0 0 0",
]

def draw_btc():
    """Render ₿ with 3-tone pixel art shading (highlight / mid / shadow)"""
    arr  = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    glow = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)

    rows = len(BTC_BITMAP)
    cols = len(BTC_BITMAP[0].split())
    BPS  = 11   # each BTC art-pixel = 11×11 actual pixels

    tw = cols * BPS
    th = rows * BPS
    ox = snap(BCX - tw // 2 + 4)  # slight right nudge for visual centering
    oy = snap(BCY - th // 2 - 5)

    bitmap = [[int(b) for b in row.split()] for row in BTC_BITMAP]

    for r, row in enumerate(bitmap):
        for c, val in enumerate(row):
            if val == 0:
                continue
            px = ox + c * BPS
            py = oy + r * BPS
            for dy in range(BPS):
                for dx in range(BPS):
                    ny, nx = py + dy, px + dx
                    if not (0 <= ny < SIZE and 0 <= nx < SIZE):
                        continue
                    # Shading: top-left = highlight, bottom-right = shadow, rest = mid
                    if dx <= 1 and dy <= 1:
                        col = GOLD_HL
                    elif dx >= BPS - 2 or dy >= BPS - 2:
                        col = GOLD_D
                    else:
                        col = GOLD_B if (dx + dy) < BPS else GOLD_M
                    arr[ny, nx]  = [*col,   255]
                    glow[ny, nx] = [*GOLD_B, 255]

    return arr, glow


# ─── CIRCUIT TRACES ────────────────────────────────────────────────────────
def draw_circuits():
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)

    def seg_h(y, x0, x1, col, alpha):
        y = snap(y)
        if 0 <= y < SIZE:
            arr[y:y+2, max(0,x0):min(SIZE,x1), :3] = col
            arr[y:y+2, max(0,x0):min(SIZE,x1),  3] = alpha

    def seg_v(x, y0, y1, col, alpha):
        x = snap(x)
        if 0 <= x < SIZE:
            arr[max(0,y0):min(SIZE,y1), x:x+2, :3] = col
            arr[max(0,y0):min(SIZE,y1), x:x+2,  3] = alpha

    def dot(x, y, col, r=3):
        for dy in range(-r, r+1):
            for dx in range(-r, r+1):
                ny, nx = y+dy, x+dx
                if 0 <= ny < SIZE and 0 <= nx < SIZE:
                    arr[ny, nx, :3] = col
                    arr[ny, nx,  3] = 210

    # Main grid — every 64px
    for gy in range(0, SIZE, 64):
        x = 0
        while x < SIZE:
            length = random.choice([64, 96, 128, 192])
            end    = min(x + length, SIZE)
            col    = random.choice([TR_DIM, TR_DIM, TR_MED])
            alpha  = random.randint(130, 190)
            seg_h(gy, x, end, col, alpha)
            x += length + random.choice([0, 0, 32, 64])

    for gx in range(0, SIZE, 64):
        y = 0
        while y < SIZE:
            length = random.choice([64, 96, 128])
            end    = min(y + length, SIZE)
            col    = random.choice([TR_DIM, TR_DIM, TR_MED])
            alpha  = random.randint(120, 175)
            seg_v(gx, y, end, col, alpha)
            y += length + random.choice([0, 0, 32, 64])

    # Junctions
    for gy in range(0, SIZE, 64):
        for gx in range(0, SIZE, 64):
            if random.random() < 0.28:
                dot(gx, gy, TR_DOT)

    # PCB L-jogs
    jogs = [
        (96, 320, 96, 416, 192, 416),
        (832,192, 752,192, 752, 320),
        (896,640, 896, 736, 800, 736),
        (128,768, 128, 864, 224, 864),
        (936,448, 848, 448, 848, 576),
        ( 64,512,  64, 608, 160, 608),
        (704, 64, 704, 128, 800, 128),
        (288,960, 384, 960, 384, 880),
        (960,256, 896, 256, 896, 352),
        ( 64,160, 160, 160, 160, 256),
    ]
    for x1,y1,x2,y2,x3,y3 in jogs:
        seg_h(y1, min(x1,x2), max(x1,x2)+2, TR_MED, 165)
        seg_v(x2, min(y2,y3), max(y2,y3)+2, TR_MED, 165)
        seg_h(y3, min(x2,x3), max(x2,x3)+2, TR_MED, 165)
        dot(x2, y2, TR_BRT, r=4)
        dot(x3, y3, TR_BRT, r=3)

    # Small IC component boxes
    for bx, by in [(72,104),(200,72),(840,912),(912,352),(136,912),(720,48),(864,720)]:
        bx, by = snap(bx), snap(by)
        for dy in range(0, 20, 2):
            for dx in range(0, 28, 2):
                ny, nx = by+dy, bx+dx
                if 0 <= ny < SIZE and 0 <= nx < SIZE:
                    arr[ny, nx, :3] = TR_MED
                    arr[ny, nx,  3] = 140
        # Bright outline
        for dx in range(0, 28, 2):
            for row in [by, by+18]:
                if 0 <= row < SIZE and 0 <= bx+dx < SIZE:
                    arr[row, bx+dx, :3] = TR_BRT; arr[row, bx+dx, 3] = 180
        for dy in range(0, 20, 2):
            for col in [bx, bx+26]:
                if 0 <= by+dy < SIZE and 0 <= col < SIZE:
                    arr[by+dy, col, :3] = TR_BRT; arr[by+dy, col, 3] = 180

    return arr


# ─── BIOHACKER TEXT  5×7 pixel font ────────────────────────────────────────
FONT = {
    'B': ["11110","11001","11001","11110","11001","11001","11110"],
    'I': ["01110","00100","00100","00100","00100","00100","01110"],
    'O': ["01110","11011","11011","11011","11011","11011","01110"],
    'H': ["11011","11011","11011","11111","11011","11011","11011"],
    'A': ["01110","11011","11011","11111","11011","11011","11011"],
    'C': ["01111","11000","11000","11000","11000","11000","01111"],
    'K': ["11011","11010","11100","11000","11100","11010","11011"],
    'E': ["11111","11000","11000","11110","11000","11000","11111"],
    'R': ["11110","11001","11001","11110","11100","11010","11001"],
}

def draw_text():
    arr = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    word = "BIOHACKER"
    SC   = 3   # scale: each font pixel = 3×3 actual pixels
    GAP  = 4   # gap between letters
    LW   = 5 * SC
    LH   = 7 * SC
    total_w = len(word) * (LW + GAP) - GAP
    tx = (SIZE - total_w) // 2
    ty = SIZE - 72
    for ch in word:
        bmap = FONT.get(ch, FONT['I'])
        for ri, row in enumerate(bmap):
            for ci, b in enumerate(row):
                if b != '1':
                    continue
                for dy in range(SC):
                    for dx in range(SC):
                        ny = ty + ri*SC + dy
                        nx = tx + ci*SC + dx
                        if 0 <= ny < SIZE and 0 <= nx < SIZE:
                            # bright top row, dim rest
                            col = (0, 255, 252) if dy == 0 else (0, 185, 182)
                            arr[ny, nx] = [*col, 255]
        tx += LW + GAP
    return arr


# ─── HELPERS ───────────────────────────────────────────────────────────────
def alpha_comp(base, over):
    a_o = over[:, :, 3:4].astype(float) / 255.0
    a_b = base[:, :, 3:4].astype(float) / 255.0
    a_out = a_o + a_b * (1 - a_o)
    rgb = (over[:, :, :3].astype(float) * a_o +
           base[:, :, :3].astype(float) * a_b * (1 - a_o))
    with np.errstate(divide='ignore', invalid='ignore'):
        rgb = np.where(a_out > 1e-6, rgb / np.maximum(a_out, 1e-6), 0)
    out = np.zeros_like(base, dtype=np.uint8)
    out[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    out[:, :, 3]  = np.clip(a_out[:, :, 0] * 255, 0, 255).astype(np.uint8)
    return out


def glow_layer(src_arr, radius, alpha_mult=1.0):
    img  = Image.fromarray(src_arr)
    blur = np.array(img.filter(ImageFilter.GaussianBlur(radius)))
    blur[:, :, 3] = np.clip(blur[:, :, 3].astype(float) * alpha_mult, 0, 255).astype(np.uint8)
    return blur


def pixelate(arr, grid=PS):
    """Enforce pixel-art grid: downscale NEAREST then upscale NEAREST"""
    img   = Image.fromarray(arr)
    small = img.resize((SIZE // grid, SIZE // grid), Image.NEAREST)
    return np.array(small.resize((SIZE, SIZE), Image.NEAREST))


def add_scanlines(arr):
    """Very subtle horizontal CRT scanlines — 1px every 6px, 12% darkening"""
    for y in range(0, SIZE, 6):
        if y < SIZE:
            arr[y, :, :3] = (arr[y, :, :3].astype(float) * 0.88).astype(np.uint8)
    return arr


def add_vignette(arr):
    cx, cy = SIZE / 2, SIZE / 2
    Y, X = np.mgrid[0:SIZE, 0:SIZE]
    dist = np.sqrt((X - cx)**2 + (Y - cy)**2) / math.sqrt(cx**2 + cy**2)
    factor = np.clip(1.0 - 0.50 * dist**1.75, 0.28, 1.0)
    arr[:, :, :3] = np.clip(
        arr[:, :, :3].astype(float) * factor[:, :, np.newaxis], 0, 255
    ).astype(np.uint8)
    return arr


# ─── MAIN ──────────────────────────────────────────────────────────────────
def main():
    print("BIOHACKER icon v2 — rendering…")

    # Background with micro noise
    bg = np.zeros((SIZE, SIZE, 4), dtype=np.uint8)
    bg[:, :, :3] = BG
    bg[:, :, 3]  = 255
    noise = np.random.randint(-4, 5, (SIZE, SIZE, 3))
    bg[:, :, :3] = np.clip(bg[:, :, :3].astype(int) + noise, 0, 255).astype(np.uint8)

    print("  [1/6] Circuit traces")
    circuits = draw_circuits()

    print("  [2/6] Brain mask")
    mask = build_brain_mask()

    print("  [3/6] Brain pixel art (wave gyri)")
    brain = draw_brain(mask)

    print("  [4/6] BTC ₿ symbol")
    btc, btc_glow_src = draw_btc()

    print("  [5/6] Text")
    text = draw_text()

    print("  [6/6] Glow + composite")

    # Brain glow layers
    bg_w  = glow_layer(brain, 58, 0.42)
    bg_m  = glow_layer(brain, 24, 0.62)
    bg_t  = glow_layer(brain,  9, 0.80)

    # BTC glow
    btc_gw = glow_layer(btc_glow_src, 32, 0.85)
    btc_gm = glow_layer(btc_glow_src, 12, 1.00)

    # Text glow
    tg    = glow_layer(text, 7, 0.65)

    result = bg.copy()
    result = alpha_comp(result, circuits)
    result = alpha_comp(result, bg_w)
    result = alpha_comp(result, bg_m)
    result = alpha_comp(result, bg_t)
    result = alpha_comp(result, brain)
    result = alpha_comp(result, btc_gw)
    result = alpha_comp(result, btc_gm)
    result = alpha_comp(result, btc)
    result = alpha_comp(result, tg)
    result = alpha_comp(result, text)

    result = add_scanlines(result)
    result = add_vignette(result)

    out = '/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v2.png'
    Image.fromarray(result).convert('RGBA').save(out)

    img = Image.open(out)
    print(f"\n✅  {out}")
    print(f"    Size: {img.size}  Mode: {img.mode}")


if __name__ == '__main__':
    main()
