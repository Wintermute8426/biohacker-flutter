#!/usr/bin/env python3
"""
BIOHACKER Feature Graphic v2 — Refined
1024×500px — Waneella/Kirokaze-style cyberpunk pixel art
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont
import numpy as np
import random
import math
import os

FONTS = os.path.expanduser("~/.openclaw/workspace/skills/canvas-design/canvas-fonts")

W, H = 1024, 500
GROUND = 330  # y coordinate where street starts

random.seed(77)
np.random.seed(77)

# ─── Color palette ───────────────────────────────────────────────────────────
BG       = (3, 5, 12)
SKY_TOP  = (3, 5, 12)
SKY_MID  = (7, 9, 20)
SKY_BOT  = (12, 8, 28)

CYAN     = (0, 255, 255)
MAGENTA  = (255, 0, 255)
AMBER    = (255, 179, 0)
RED      = (255, 50, 50)
PURPLE   = (120, 0, 220)
GREEN    = (0, 220, 110)

NEON_CYAN_DIM   = (0, 120, 140)
NEON_AMBER_DIM  = (130, 85, 0)
NEON_MAG_DIM    = (130, 0, 130)
NEON_RED_DIM    = (130, 25, 25)

STREET   = (8, 10, 20)
STREET2  = (5, 7, 15)

def lerp_color(c1, c2, t):
    t = max(0, min(1, t))
    return tuple(int(c1[i] + (c2[i]-c1[i])*t) for i in range(3))

def px(n):
    return (n // 2) * 2

# ─── Canvas ──────────────────────────────────────────────────────────────────
img = Image.new("RGBA", (W, H), BG + (255,))
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 1. SKY GRADIENT — dark indigo to near-black, horizon purple bloom
# ═══════════════════════════════════════════════════════════════════════════
for y in range(GROUND + 20):
    if y < 240:
        t = y / 240
        c = lerp_color(SKY_TOP, SKY_MID, t)
    else:
        t = (y - 240) / (GROUND + 20 - 240)
        c = lerp_color(SKY_MID, SKY_BOT, t)
    draw.line([(0, y), (W, y)], fill=c + (255,))

# Horizon magenta/purple bloom
bloom = Image.new("RGBA", (W, H), (0,0,0,0))
bd = ImageDraw.Draw(bloom)
for y in range(270, 360):
    t = 1.0 - abs(y - 315) / 55
    if t > 0:
        a = int(t * t * 45)
        bd.line([(0,y),(W,y)], fill=(70, 0, 90, a))
img = Image.alpha_composite(img, bloom.filter(ImageFilter.GaussianBlur(20)))
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 2. DISTANT FOG BANKS
# ═══════════════════════════════════════════════════════════════════════════
fog = Image.new("RGBA", (W, H), (0,0,0,0))
fd = ImageDraw.Draw(fog)
for _ in range(8):
    fx = random.randint(-80, W)
    fy = random.randint(200, 300)
    fw = random.randint(250, 600)
    fh = random.randint(50, 120)
    fd.ellipse([fx, fy, fx+fw, fy+fh], fill=(12, 14, 30, random.randint(35, 65)))
img = Image.alpha_composite(img, fog.filter(ImageFilter.GaussianBlur(35)))
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 3. BACKGROUND SKYSCRAPERS — very dark, atmospheric
# ═══════════════════════════════════════════════════════════════════════════
def draw_building(draw, bx, by, bw, depth=18, trim_color=None):
    dc = depth
    bcolor = (dc, dc+2, dc+12)
    draw.rectangle([bx, by, bx+bw, GROUND+5], fill=bcolor + (255,))
    if trim_color:
        draw.rectangle([bx, by, bx+bw, by+2], fill=trim_color + (200,))
    # Windows
    for wy in range(by+4, GROUND-4, 8):
        for wx in range(bx+3, bx+bw-3, 7):
            if random.random() < 0.30:
                cr = random.random()
                if cr < 0.45:
                    wc = (0, random.randint(80,150), random.randint(100,180))
                elif cr < 0.70:
                    wc = (random.randint(80,150), random.randint(60,110), 0)
                elif cr < 0.85:
                    wc = (random.randint(60,110), 0, random.randint(80,130))
                else:
                    wc = (random.randint(30,50), random.randint(30,50), random.randint(30,50))
                draw.rectangle([wx, wy, wx+3, wy+4], fill=wc + (255,))

bg_data = [
    (0, 80, 65), (55, 100, 50), (95, 65, 75), (155, 90, 55), (195, 55, 90),
    (270, 70, 65), (320, 100, 50), (355, 60, 80), (420, 85, 60), (465, 45, 95),
    (540, 75, 65), (585, 95, 50), (620, 65, 70), (675, 105, 55), (715, 55, 90),
    (790, 70, 65), (835, 90, 50), (875, 55, 80), (930, 80, 65), (975, 100, 50),
]
trims = [CYAN, None, MAGENTA, None, AMBER, None, RED, None, CYAN, MAGENTA,
         None, AMBER, None, CYAN, None, MAGENTA, None, RED, None, CYAN]

for i, (bx, by, bw) in enumerate(bg_data):
    trim = trims[i % len(trims)]
    draw_building(draw, bx, by, bw, depth=random.randint(14,24), trim_color=trim)
    # Antenna
    if random.random() > 0.4:
        ax = bx + bw // 2
        draw.line([(ax, by), (ax, by-25)], fill=(25, 28, 45, 255), width=1)
        draw.rectangle([ax-1, by-26, ax+1, by-24], fill=RED + (220,))

# Atmospheric fog on bg buildings
fog2 = Image.new("RGBA", (W, H), (0,0,0,0))
f2d = ImageDraw.Draw(fog2)
for y in range(200, 340):
    t = max(0, 1.0 - abs(y-270)/90)
    f2d.line([(0,y),(W,y)], fill=(10, 12, 28, int(t*55)))
img = Image.alpha_composite(img, fog2)
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 4. KANJI-STYLE NEON SIGN BOARDS on bg buildings
# ═══════════════════════════════════════════════════════════════════════════
def draw_kanji_sign(draw, x, y, color, wide=False):
    sw = 38 if wide else 24
    sh = 18
    draw.rectangle([x, y, x+sw, y+sh], fill=(5, 6, 14, 200))
    for edge in [(x,y,x+sw,y+1),(x,y+sh-1,x+sw,y+sh),(x,y,x+1,y+sh),(x+sw-1,y,x+sw,y+sh)]:
        draw.rectangle(edge, fill=color + (220,))
    # Inner pixel rune marks
    cols = 3 if wide else 2
    for ci in range(cols):
        cx = x + 4 + ci * (sw // cols)
        cw = sw // cols - 4
        draw.rectangle([cx, y+3, cx+cw, y+5], fill=color + (180,))
        draw.rectangle([cx+cw//2, y+3, cx+cw//2+1, y+sh-4], fill=color + (180,))
        draw.rectangle([cx, y+sh-6, cx+cw, y+sh-4], fill=color + (180,))

signs = [
    (45, 175, CYAN, False), (115, 155, MAGENTA, True), (200, 168, AMBER, False),
    (295, 148, CYAN, True), (380, 172, RED, False), (460, 152, MAGENTA, False),
    (540, 162, AMBER, True), (620, 145, CYAN, False), (700, 168, MAGENTA, True),
    (800, 155, RED, False), (900, 148, CYAN, True), (975, 162, AMBER, False),
]
for sx, sy, sc, sw2 in signs:
    draw_kanji_sign(draw, sx, sy, sc, sw2)

# ═══════════════════════════════════════════════════════════════════════════
# 5. MIDGROUND BUILDINGS — more defined, neon trim, busy detail
# ═══════════════════════════════════════════════════════════════════════════
mid_data = [
    (0, 195, 85, CYAN), (75, 215, 70, MAGENTA), (135, 182, 105, AMBER),
    (230, 200, 85, PURPLE), (305, 172, 115, CYAN), (410, 205, 90, RED),
    (490, 188, 88, MAGENTA), (568, 198, 95, CYAN), (653, 178, 105, AMBER),
    (748, 208, 82, MAGENTA), (820, 192, 92, CYAN), (902, 180, 122, RED),
]
for bx, by, bw, trim in mid_data:
    depth = random.randint(22, 38)
    bcolor = (depth, depth+4, depth+18)
    draw.rectangle([bx, by, bx+bw, GROUND+8], fill=bcolor + (255,))
    # Roofline neon
    draw.rectangle([bx, by, bx+bw, by+3], fill=trim + (255,))
    # Vertical neon accent
    for vx in [bx+4, bx+bw-6]:
        for vy in range(by+6, GROUND, 5):
            if random.random() < 0.6:
                draw.rectangle([vx, vy, vx+2, vy+2], fill=trim + (150,))
    # Windows — bigger, more vibrant
    for wy in range(by+8, GROUND-6, 10):
        for wx in range(bx+6, bx+bw-6, 10):
            if random.random() < 0.55:
                cr = random.random()
                if cr < 0.5:
                    wc = (0, random.randint(140,220), random.randint(160,240))
                elif cr < 0.75:
                    wc = (random.randint(160,230), random.randint(110,160), 0)
                else:
                    wc = (random.randint(160,200), 0, random.randint(180,230))
                draw.rectangle([wx, wy, wx+5, wy+7], fill=wc + (255,))

# ═══════════════════════════════════════════════════════════════════════════
# 6. ELEVATED WALKWAYS
# ═══════════════════════════════════════════════════════════════════════════
# Main walkway
wy1 = 295
draw.rectangle([0, wy1, W, wy1+10], fill=(18, 20, 38, 255))
draw.rectangle([0, wy1, W, wy1+2], fill=NEON_CYAN_DIM + (255,))
draw.rectangle([0, wy1+9, W, wy1+10], fill=NEON_CYAN_DIM + (200,))
# Support pillars
for ppx in range(80, W, 140):
    draw.rectangle([ppx, wy1+10, ppx+8, GROUND+20], fill=(14, 16, 30, 255))
    draw.rectangle([ppx, wy1+10, ppx+2, wy1+35], fill=NEON_CYAN_DIM + (180,))

# Upper walkway (partial)
wy2 = 260
draw.rectangle([120, wy2, 680, wy2+7], fill=(16, 18, 35, 255))
draw.rectangle([120, wy2, 680, wy2+2], fill=NEON_MAG_DIM + (220,))

# Walkway glow
wg = Image.new("RGBA", (W, H), (0,0,0,0))
wgd = ImageDraw.Draw(wg)
wgd.rectangle([0, wy1-2, W, wy1+12], fill=(0, 180, 200, 50))
wgd.rectangle([120, wy2-2, 680, wy2+9], fill=(160, 0, 160, 30))
img = Image.alpha_composite(img, wg.filter(ImageFilter.GaussianBlur(8)))
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 7. WET STREET
# ═══════════════════════════════════════════════════════════════════════════
for y in range(GROUND, H):
    t = (y - GROUND) / (H - GROUND)
    c = lerp_color(STREET, STREET2, t)
    draw.line([(0, y), (W, y)], fill=c + (255,))

# Lane markings
for lx in range(100, W, 200):
    for ly in range(GROUND + 30, H - 20, 20):
        draw.rectangle([lx, ly, lx+40, ly+8], fill=(20, 22, 35, 255))

# Wet ground puddles/reflections — key element
ref_layer = Image.new("RGBA", (W, H), (0,0,0,0))
rd = ImageDraw.Draw(ref_layer)

def draw_reflection_streak(rd, x, y_start, color, width=3, length=50):
    for i in range(length):
        t = i / length
        a = int((1 - t) ** 1.5 * 110)
        dy = y_start + i * 3
        dx = x + int(math.sin(i * 0.5) * 2)
        if dy < H:
            rd.rectangle([dx, dy, dx+width, dy+2], fill=color + (a,))

neon_ref_points = [
    (70, GROUND+2, CYAN), (160, GROUND+5, MAGENTA), (260, GROUND+3, AMBER),
    (380, GROUND+6, CYAN), (470, GROUND+2, RED), (560, GROUND+4, CYAN),
    (660, GROUND+7, MAGENTA), (750, GROUND+3, AMBER), (840, GROUND+5, CYAN),
    (940, GROUND+4, MAGENTA),
]
for rx, ry, rc in neon_ref_points:
    draw_reflection_streak(rd, rx, ry, rc, width=random.randint(2,5))

ref_blurred = ref_layer.filter(ImageFilter.GaussianBlur(1.5))
img = Image.alpha_composite(img, ref_blurred)
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 8. RAIN STREAKS
# ═══════════════════════════════════════════════════════════════════════════
rain = Image.new("RGBA", (W, H), (0,0,0,0))
raind = ImageDraw.Draw(rain)
for _ in range(600):
    rx = random.randint(0, W)
    ry = random.randint(0, int(H*0.95))
    rl = random.randint(8, 22)
    ra = random.randint(12, 45)
    roff = random.randint(2, 6)
    raind.line([(rx, ry), (rx+roff, ry+rl)], fill=(160, 190, 210, ra), width=1)
img = Image.alpha_composite(img, rain)
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 9. DNA HELIX NEON SIGN (left side, visible above walkway)
# ═══════════════════════════════════════════════════════════════════════════
dna_x = 85
dna_y_top = 218
dna_h = 60

for i in range(dna_h):
    t = i / dna_h * 3.5 * math.pi
    x1 = dna_x + int(10 * math.sin(t))
    x2 = dna_x + int(10 * math.sin(t + math.pi))
    y = dna_y_top + i
    draw.rectangle([x1-1, y, x1+2, y+2], fill=CYAN + (255,))
    draw.rectangle([x2-1, y, x2+2, y+2], fill=MAGENTA + (255,))
    if i % 7 == 0:
        lx1, lx2 = sorted([x1+1, x2+1])
        if lx2 > lx1:
            draw.line([(lx1, y+1), (lx2, y+1)], fill=(100, 120, 200, 200), width=1)

# DNA glow
dna_glow = Image.new("RGBA", (W, H), (0,0,0,0))
dgd = ImageDraw.Draw(dna_glow)
dgd.rectangle([dna_x-18, dna_y_top-4, dna_x+28, dna_y_top+dna_h+4], fill=(0, 50, 70, 50))
img = Image.alpha_composite(img, dna_glow.filter(ImageFilter.GaussianBlur(10)))
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 10. HOLOGRAPHIC BIO-SCAN DISPLAY (right midground)
# ═══════════════════════════════════════════════════════════════════════════
hx, hy = 785, 242
hw, hh = 210, 58

holo = Image.new("RGBA", (W, H), (0,0,0,0))
hd = ImageDraw.Draw(holo)
# Panel background
hd.rectangle([hx, hy, hx+hw, hy+hh], fill=(0, 30, 45, 140))
# Border
for edge in [(hx,hy,hx+hw,hy+2),(hx,hy+hh-2,hx+hw,hy+hh),(hx,hy,hx+2,hy+hh),(hx+hw-2,hy,hx+hw,hy+hh)]:
    hd.rectangle(edge, fill=CYAN + (200,))
# Corner accents
for cx2, cy2 in [(hx,hy),(hx+hw-6,hy),(hx,hy+hh-6),(hx+hw-6,hy+hh-6)]:
    hd.rectangle([cx2, cy2, cx2+6, cy2+2], fill=CYAN + (255,))
    hd.rectangle([cx2, cy2, cx2+2, cy2+6], fill=CYAN + (255,))

# Waveforms
wave_configs = [
    (hx+4, hy+12, CYAN, 0.15, 5, 8),   # HRV — smooth
    (hx+4, hy+28, AMBER, 0.10, 3, 12),  # GLU — slow
    (hx+4, hy+44, GREEN, 0.20, 4, 6),   # O2 — fast
]
try:
    mono_sm = ImageFont.truetype(os.path.join(FONTS, "IBMPlexMono-Regular.ttf"), 7)
    hd.text((hx+4, hy+3), "BIO-SCAN LIVE", font=mono_sm, fill=NEON_CYAN_DIM + (200,))
    labels = ["HRV", "GLU", "O2%"]
    for li, (wx2, wy2, wc, _, _, _) in enumerate(wave_configs):
        hd.text((wx2, wy2-9), labels[li], font=mono_sm, fill=wc + (180,))
except:
    pass

for wx2, wy2, wc, amp, base_amp, freq in wave_configs:
    prev_px, prev_py = wx2+28, wy2+3
    for ppx in range(wx2+28, hx+hw-6, 3):
        rel_x = ppx - wx2
        # ECG spike
        spike = 0
        if rel_x % 40 < 4:
            spike = -12 if wc == CYAN else -6
        val = int(base_amp * math.sin(rel_x * freq * 0.1)) + spike + 3
        ny = wy2 + val
        ny = max(hy+3, min(hy+hh-3, ny))
        hd.line([(prev_px, prev_py), (ppx, ny)], fill=wc + (210,), width=1)
        prev_px, prev_py = ppx, ny

# Scan line
scan_x = hx + 90
hd.line([(scan_x, hy+3), (scan_x, hy+hh-3)], fill=(0, 255, 200, 80), width=1)

img = Image.alpha_composite(img, holo)
# Holo glow
hg = Image.new("RGBA", (W, H), (0,0,0,0))
hgd = ImageDraw.Draw(hg)
hgd.rectangle([hx-8, hy-8, hx+hw+8, hy+hh+8], fill=(0, 60, 90, 35))
img = Image.alpha_composite(img, hg.filter(ImageFilter.GaussianBlur(14)))
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 11. LAB VIALS — foreground, on ledge
# ═══════════════════════════════════════════════════════════════════════════
def draw_vial(draw, x, y, color, fill_ratio=0.6):
    # Body
    draw.rectangle([x+3, y+4, x+11, y+22], fill=(8, 10, 18, 255))
    draw.rectangle([x+3, y+4, x+4, y+22], fill=color + (180,))
    draw.rectangle([x+10, y+4, x+11, y+22], fill=color + (180,))
    draw.rectangle([x+3, y+22, x+11, y+23], fill=color + (220,))
    # Liquid
    fh = int(18 * fill_ratio)
    draw.rectangle([x+4, y+22-fh, x+10, y+21], fill=color + (110,))
    # Neck
    draw.rectangle([x+4, y+1, x+10, y+5], fill=color + (200,))
    # Cap
    draw.rectangle([x+3, y, x+11, y+2], fill=color + (255,))
    # Shine
    draw.rectangle([x+4, y+6, x+5, y+10], fill=(200, 230, 255, 90))

vial_base_y = GROUND + 5
vial_configs = [
    (180, vial_base_y, CYAN, 0.75),
    (200, vial_base_y + 2, MAGENTA, 0.45),
    (220, vial_base_y, AMBER, 0.90),
    (240, vial_base_y + 3, GREEN, 0.60),
    (810, vial_base_y, CYAN, 0.55),
    (830, vial_base_y + 2, MAGENTA, 0.80),
    (850, vial_base_y, RED, 0.35),
]
for vx, vy, vc, vf in vial_configs:
    draw_vial(draw, vx, vy, vc, vf)

# ═══════════════════════════════════════════════════════════════════════════
# 12. LONE HOODED FIGURE (center, foreground, prominent)
# ═══════════════════════════════════════════════════════════════════════════
fx, fy = 472, GROUND - 70
fw = 36
fh = 75
fig_dark = (4, 6, 12)
fig_mid = (10, 12, 22)

# Shadow/puddle on ground
shad = Image.new("RGBA", (W, H), (0,0,0,0))
shd = ImageDraw.Draw(shad)
shd.ellipse([fx-28, fy+fh, fx+fw+28, fy+fh+16], fill=(0, 15, 25, 90))
img = Image.alpha_composite(img, shad.filter(ImageFilter.GaussianBlur(8)))
draw = ImageDraw.Draw(img)

# Legs
draw.rectangle([fx+6, fy+50, fx+16, fy+fh], fill=fig_dark + (255,))
draw.rectangle([fx+20, fy+50, fx+30, fy+fh], fill=fig_dark + (255,))
# Boot highlights
draw.rectangle([fx+6, fy+fh-3, fx+17, fy+fh], fill=(20, 22, 35, 255))
draw.rectangle([fx+20, fy+fh-3, fx+31, fy+fh], fill=(20, 22, 35, 255))

# Torso/coat
coat_pts = [
    fx+3, fy+28,  # left shoulder
    fx+fw-3, fy+28,  # right shoulder
    fx+fw+6, fy+54,  # coat right
    fx-6, fy+54,  # coat left
]
draw.polygon(coat_pts, fill=fig_dark + (255,))
draw.rectangle([fx+3, fy+28, fx+fw-3, fy+52], fill=fig_dark + (255,))

# Hood
draw.ellipse([fx+2, fy+10, fx+fw-2, fy+32], fill=fig_dark + (255,))
draw.rectangle([fx+2, fy+20, fx+fw-2, fy+32], fill=fig_dark + (255,))

# Head
draw.ellipse([fx+7, fy+2, fx+fw-7, fy+18], fill=(8, 10, 18, 255))

# Neon rim lighting — cyan from left (strong), magenta from right (subtle)
rim = Image.new("RGBA", (W, H), (0,0,0,0))
rimd = ImageDraw.Draw(rim)
# Cyan rim — left edge of figure
for y in range(fy, fy+fh+4):
    rimd.rectangle([fx-3, y, fx-1, y+1], fill=(0, 200, 240, 100))
    rimd.rectangle([fx-6, y, fx-4, y+1], fill=(0, 180, 220, 40))
# Magenta rim — right edge
for y in range(fy, fy+fh+4):
    rimd.rectangle([fx+fw+1, y, fx+fw+3, y+1], fill=(200, 0, 210, 70))
# Amber top-light
for x in range(fx+4, fx+fw-4):
    rimd.rectangle([x, fy-1, x+1, fy+1], fill=(200, 150, 0, 50))
img = Image.alpha_composite(img, rim.filter(ImageFilter.GaussianBlur(2)))
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 13. FOREGROUND NEON VERTICAL SIGN PILLARS
# ═══════════════════════════════════════════════════════════════════════════
def draw_vert_sign(draw, x, y, color, h=90, w=20):
    draw.rectangle([x, y, x+w, y+h], fill=(6, 8, 16, 240))
    for edge in [(x,y,x+w,y+2),(x,y+h-2,x+w,y+h),(x,y,x+2,y+h),(x+w-2,y,x+w,y+h)]:
        draw.rectangle(edge, fill=color + (240,))
    # Rune marks
    for mark_y2 in range(y+8, y+h-8, 22):
        draw.rectangle([x+4, mark_y2, x+w-4, mark_y2+2], fill=color + (200,))
        draw.rectangle([x+w//2-1, mark_y2, x+w//2+1, mark_y2+16], fill=color + (200,))
        draw.rectangle([x+4, mark_y2+14, x+w-4, mark_y2+16], fill=color + (180,))

draw_vert_sign(draw, 20, 282, MAGENTA, h=80)
draw_vert_sign(draw, 988, 278, AMBER, h=84)
draw_vert_sign(draw, 8, 358, RED, h=70)
draw_vert_sign(draw, 998, 360, CYAN, h=68)

# ═══════════════════════════════════════════════════════════════════════════
# 14. NEON GLOW COMPOSITE
# ═══════════════════════════════════════════════════════════════════════════
arr = np.array(img).astype(np.uint8)

def build_glow(arr, threshold_brightness=160, blur_r=14, alpha_scale=0.55):
    brightness = arr[:,:,0].astype(int) + arr[:,:,1].astype(int) + arr[:,:,2].astype(int)
    mask = brightness > threshold_brightness * 2
    glow_img = Image.new("RGBA", (W, H), (0,0,0,0))
    gd2 = ImageDraw.Draw(glow_img)
    ys, xs = np.where(mask)
    for xi, yi in zip(xs[::4], ys[::4]):
        r, g, b = int(arr[yi,xi,0]), int(arr[yi,xi,1]), int(arr[yi,xi,2])
        gd2.rectangle([xi-1,yi-1,xi+2,yi+2], fill=(r,g,b,200))
    blurred = glow_img.filter(ImageFilter.GaussianBlur(blur_r))
    ba = np.array(blurred)
    ba[:,:,3] = np.clip(ba[:,:,3].astype(float) * alpha_scale, 0, 255).astype(np.uint8)
    return Image.fromarray(ba, 'RGBA')

glow1 = build_glow(arr, 140, 18, 0.6)
img = Image.alpha_composite(img, glow1)
arr2 = np.array(img).astype(np.uint8)
glow2 = build_glow(arr2, 200, 8, 0.35)
img = Image.alpha_composite(img, glow2)
draw = ImageDraw.Draw(img)

# ═══════════════════════════════════════════════════════════════════════════
# 15. TEXT — BIOHACKER title + tagline + domain
# ═══════════════════════════════════════════════════════════════════════════
try:
    # Silkscreen has a true pixel art feel
    font_title = ImageFont.truetype(os.path.join(FONTS, "Silkscreen-Regular.ttf"), 80)
except:
    font_title = ImageFont.truetype(os.path.join(FONTS, "IBMPlexMono-Bold.ttf"), 72)

try:
    font_sub = ImageFont.truetype(os.path.join(FONTS, "GeistMono-Bold.ttf"), 22)
except:
    font_sub = ImageFont.truetype(os.path.join(FONTS, "IBMPlexMono-Bold.ttf"), 20)

try:
    font_tiny = ImageFont.truetype(os.path.join(FONTS, "IBMPlexMono-Regular.ttf"), 13)
except:
    font_tiny = ImageFont.load_default()

# --- BIOHACKER ---
title = "BIOHACKER"
tmp = Image.new("RGBA", (W, 120), (0,0,0,0))
td = ImageDraw.Draw(tmp)
bbox = td.textbbox((0,0), title, font=font_title)
tw = bbox[2] - bbox[0]
th = bbox[3] - bbox[1]
tx = (W - tw) // 2
ty = 18

# Dark backdrop behind text block for legibility
txt_backing = Image.new("RGBA", (W, H), (0,0,0,0))
tbd = ImageDraw.Draw(txt_backing)
back_pad = 20
back_h = th + 50
tbd.rectangle([tx - back_pad, ty - 8, tx + tw + back_pad, ty + back_h], fill=(2, 3, 8, 130))
txt_backing = txt_backing.filter(ImageFilter.GaussianBlur(16))
img = Image.alpha_composite(img, txt_backing)
draw = ImageDraw.Draw(img)

# Multi-layer bloom glow
for glow_r, ga in [(40, 25), (22, 55), (12, 100), (6, 150)]:
    gl = Image.new("RGBA", (W, H), (0,0,0,0))
    gld = ImageDraw.Draw(gl)
    gld.text((tx, ty), title, font=font_title, fill=(0, 255, 255, 255))
    gl = gl.filter(ImageFilter.GaussianBlur(glow_r))
    gla = np.array(gl)
    gla[:,:,3] = np.clip(gla[:,:,3].astype(float) * ga / 255, 0, 255).astype(np.uint8)
    img = Image.alpha_composite(img, Image.fromarray(gla, 'RGBA'))

draw = ImageDraw.Draw(img)
# Dark shadow
draw.text((tx+3, ty+3), title, font=font_title, fill=(0, 60, 80, 200))
# Main text
draw.text((tx, ty), title, font=font_title, fill=(0, 255, 255, 255))

# --- OWN YOUR BIOLOGY ---
subtitle = "OWN YOUR BIOLOGY"
bbox2 = draw.textbbox((0,0), subtitle, font=font_sub)
sw2 = bbox2[2] - bbox2[0]
sx = (W - sw2) // 2
sy = ty + th + 14

# Amber glow
for glow_r2, ga2 in [(14, 50), (7, 110)]:
    gs = Image.new("RGBA", (W, H), (0,0,0,0))
    gsd = ImageDraw.Draw(gs)
    gsd.text((sx, sy), subtitle, font=font_sub, fill=AMBER + (255,))
    gs = gs.filter(ImageFilter.GaussianBlur(glow_r2))
    gsa = np.array(gs)
    gsa[:,:,3] = np.clip(gsa[:,:,3].astype(float) * ga2 / 255, 0, 255).astype(np.uint8)
    img = Image.alpha_composite(img, Image.fromarray(gsa, 'RGBA'))

draw = ImageDraw.Draw(img)
draw.text((sx+2, sy+2), subtitle, font=font_sub, fill=(90, 60, 0, 160))
draw.text((sx, sy), subtitle, font=font_sub, fill=AMBER + (255,))

# --- biohacker.systems ---
domain = "biohacker.systems"
bbox3 = draw.textbbox((0,0), domain, font=font_tiny)
dw = bbox3[2] - bbox3[0]
dx = W - dw - 18
dy = H - 22
draw.text((dx, dy), domain, font=font_tiny, fill=(0, 120, 145, 170))

# ═══════════════════════════════════════════════════════════════════════════
# 15b. AMBIENT PARTICLE DUST (tiny glowing specks)
# ═══════════════════════════════════════════════════════════════════════════
dust = Image.new("RGBA", (W, H), (0,0,0,0))
dd = ImageDraw.Draw(dust)
for _ in range(80):
    dpx = random.randint(0, W)
    dpy = random.randint(100, GROUND+30)
    dc2 = random.choice([CYAN, MAGENTA, AMBER, (200,200,255)])
    da = random.randint(30, 90)
    draw.rectangle([dpx, dpy, dpx+1, dpy+1], fill=dc2 + (da,))

# ═══════════════════════════════════════════════════════════════════════════
# 16. CRT SCANLINES (subtle, every 2 rows)
# ═══════════════════════════════════════════════════════════════════════════
scl = Image.new("RGBA", (W, H), (0,0,0,0))
scld = ImageDraw.Draw(scl)
for y in range(0, H, 2):
    scld.line([(0,y),(W,y)], fill=(0,0,0,28))
img = Image.alpha_composite(img, scl)

# ═══════════════════════════════════════════════════════════════════════════
# 17. VIGNETTE — moderate, dark edges
# ═══════════════════════════════════════════════════════════════════════════
vig = np.zeros((H, W, 4), dtype=np.uint8)
cx2, cy2 = W/2, H/2
for y in range(H):
    for x in range(W):
        dx2 = (x - cx2) / cx2
        dy2 = (y - cy2) / cy2
        d = math.sqrt(dx2*dx2 + dy2*dy2)
        av = int(max(0, (d - 0.55) * 200))
        if av > 0:
            vig[y,x,3] = min(av, 210)
vig_img = Image.fromarray(vig, 'RGBA')
img = Image.alpha_composite(img, vig_img)

# ═══════════════════════════════════════════════════════════════════════════
# 18. FINAL REFINEMENT — slight contrast boost
# ═══════════════════════════════════════════════════════════════════════════
final = img.convert("RGB")

# Save
out_path = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v2.png"
final.save(out_path, "PNG", optimize=True)
print(f"Saved: {out_path}")
print(f"Size: {final.size}")
