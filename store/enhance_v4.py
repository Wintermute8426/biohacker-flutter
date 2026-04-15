#!/usr/bin/env python3
"""
Feature Graphic v3 → v4 Enhancement
Fixes: hooded figure visibility, wet street reflections, building brightness
"""

import numpy as np
from PIL import Image, ImageFilter, ImageDraw, ImageEnhance
import os

INPUT = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v3.png"
OUTPUT = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v4.png"

img = Image.open(INPUT).convert("RGB")
arr = np.array(img, dtype=np.float32)
H, W = arr.shape[:2]  # 500, 1024

print(f"Loaded: {W}x{H}")

r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]

# ─── STEP 1: IDENTIFY REGIONS ──────────────────────────────────────────────
# Bottom half = ground/street region (y > 300)
# Figure is roughly in center horizontal band (x: 350-680, y: 120-440)
# Buildings are left (x < 300) and right (x > 700)

ground_y = 300  # below this is the street
fig_x1, fig_x2 = 350, 680
fig_y1, fig_y2 = 100, 440

# ─── STEP 2: BRIGHTEN MIDTONES (buildings + figure region) ─────────────────
# We want to brighten pixels that are NOT already bright neon signs
# Neon signs = very saturated bright pixels (high saturation, high value in HSV)
# Midtones = relatively dark, not neon

# Compute per-pixel max channel (proxy for brightness/value in HSV)
max_ch = np.max(arr, axis=2)
min_ch = np.min(arr, axis=2)
saturation = np.where(max_ch > 0, (max_ch - min_ch) / (max_ch + 1e-6), 0)
brightness = max_ch / 255.0

# Neon pixels: high brightness + high saturation
is_neon = (brightness > 0.5) & (saturation > 0.5)

# Building zones: left and right sides, upper portion
building_mask = np.zeros((H, W), dtype=bool)
building_mask[:, :320] = True
building_mask[:, 700:] = True
# Also brighten the figure zone
building_mask[fig_y1:fig_y2, fig_x1:fig_x2] = True

# Brighten non-neon pixels in building+figure zone by 50%
boost = np.ones((H, W), dtype=np.float32)
boost_zone = building_mask & ~is_neon
boost[boost_zone] = 1.55  # 55% brighter

arr_out = arr.copy()
for c in range(3):
    arr_out[:,:,c] = np.clip(arr[:,:,c] * boost, 0, 255)

# ─── STEP 3: HOODED FIGURE RIM LIGHTING ────────────────────────────────────
# The figure occupies roughly x: 390-660, y: 140-440
# We'll detect the figure silhouette by looking for non-black pixels in that zone
# Then apply rim lighting along the edges

fig_region = arr_out[fig_y1:fig_y2, fig_x1:fig_x2].copy()

# Create a mask of figure pixels (not just pure black background)
fig_brightness = np.max(fig_region, axis=2)
# Figure pixels are slightly brighter than the deep black background
# The background in that zone is very dark (< 20 on all channels)
# The figure cloak is dark grey/purple
figure_pix_mask = fig_brightness > 15  # anything slightly lit

# Apply bilateral-like edge detection to find figure boundaries
# We'll use a simple approach: scan columns for leftmost and rightmost figure pixels per row
from PIL import Image as PILImage
# Actually, let's just apply a gradient: 
# Left edge of figure gets cyan glow, right edge gets magenta glow
# Strategy: for each row in figure zone, find leftmost/rightmost figure pixel
# and paint a glowing edge

fig_arr = arr_out.copy()

# Create glow layers
cyan_layer = np.zeros((H, W, 3), dtype=np.float32)
magenta_layer = np.zeros((H, W, 3), dtype=np.float32)

CYAN = np.array([0, 255, 255], dtype=np.float32)
MAGENTA = np.array([255, 0, 255], dtype=np.float32)

# For the figure zone, scan each row
for row in range(fig_y1, fig_y2):
    row_brightness = np.max(arr_out[row, fig_x1:fig_x2], axis=1)
    fig_cols = np.where(row_brightness > 12)[0]
    if len(fig_cols) == 0:
        continue
    
    left_col = fig_cols[0] + fig_x1
    right_col = fig_cols[-1] + fig_x1
    
    # Paint cyan rim on left edge (outward glow)
    for spread in range(8):
        col = left_col - spread
        if 0 <= col < W:
            intensity = (1.0 - spread / 8.0) ** 2 * 180
            cyan_layer[row, col] = np.maximum(cyan_layer[row, col], CYAN * intensity / 255.0)
    
    # Bright inner left rim (2-3px inside figure)
    for spread in range(4):
        col = left_col + spread
        if 0 <= col < W:
            intensity = (1.0 - spread / 4.0) ** 1.5 * 220
            cyan_layer[row, col] = np.maximum(cyan_layer[row, col], CYAN * intensity / 255.0)
    
    # Paint magenta rim on right edge
    for spread in range(8):
        col = right_col + spread
        if 0 <= col < W:
            intensity = (1.0 - spread / 8.0) ** 2 * 180
            magenta_layer[row, col] = np.maximum(magenta_layer[row, col], MAGENTA * intensity / 255.0)
    
    # Bright inner right rim
    for spread in range(4):
        col = right_col - spread
        if 0 <= col < W:
            intensity = (1.0 - spread / 4.0) ** 1.5 * 220
            magenta_layer[row, col] = np.maximum(magenta_layer[row, col], MAGENTA * intensity / 255.0)

# Also brighten the figure itself — it's too dark. Lift all figure pixels.
fig_mask = np.zeros((H, W), dtype=bool)
for row in range(fig_y1, fig_y2):
    row_brightness = np.max(arr_out[row, fig_x1:fig_x2], axis=1)
    fig_cols = np.where(row_brightness > 12)[0]
    if len(fig_cols) > 0:
        left = fig_cols[0] + fig_x1
        right = fig_cols[-1] + fig_x1
        fig_mask[row, left:right+1] = True

# Lift figure pixels significantly
for c in range(3):
    arr_out[:,:,c] = np.where(fig_mask, np.clip(arr_out[:,:,c] * 2.2 + 25, 0, 255), arr_out[:,:,c])

# Add a subtle teal/blue tint to figure (hooded cloak look)
arr_out[:,:,0] = np.where(fig_mask, arr_out[:,:,0] * 0.8, arr_out[:,:,0])  # reduce red
arr_out[:,:,2] = np.where(fig_mask, np.clip(arr_out[:,:,2] * 1.3, 0, 255), arr_out[:,:,2])  # boost blue

# Composite the glow layers using screen blend
for c in range(3):
    arr_out[:,:,c] = np.clip(arr_out[:,:,c] + cyan_layer[:,:,c] * 255, 0, 255)
    arr_out[:,:,c] = np.clip(arr_out[:,:,c] + magenta_layer[:,:,c] * 255, 0, 255)

# ─── STEP 4: WET STREET REFLECTIONS ─────────────────────────────────────────
# Bottom region: y > 300
# We'll create a distorted, brightened reflection of the upper portion

street_start = 290
street_region_height = H - street_start  # ~210 pixels

# The reflection should be a vertically flipped, distorted, colored version of 
# the neon-heavy upper portion. We take the strip just above the ground and flip it.
# Mirror zone: reflect from y=street_start upward
reflect_source_start = street_start - street_region_height
if reflect_source_start < 0:
    reflect_source_start = 0

source_strip = arr_out[reflect_source_start:street_start, :].copy()
source_strip_flipped = source_strip[::-1, :, :]  # flip vertically

# Scale to fill street region height
from PIL import Image as PILImg
src_h = source_strip_flipped.shape[0]
src_img = PILImg.fromarray(source_strip_flipped.astype(np.uint8))
src_img_scaled = src_img.resize((W, street_region_height), PILImg.LANCZOS)
reflection = np.array(src_img_scaled, dtype=np.float32)

# Extract only the bright/neon parts of the reflection (isolate neon colors)
refl_max = np.max(reflection, axis=2)
refl_min = np.min(reflection, axis=2)
refl_sat = np.where(refl_max > 0, (refl_max - refl_min) / (refl_max + 1e-6), 0)
refl_bright = refl_max / 255.0

# Only keep bright, saturated (neon) reflection
neon_refl_mask = (refl_bright > 0.3) & (refl_sat > 0.35)

# Fade reflection with distance (stronger near top of street, fade to bottom)
fade = np.linspace(1.0, 0.05, street_region_height)[:, np.newaxis]

# Add ripple/puddle distortion — horizontal sine waves
ripple_strength = np.linspace(0, 4, street_region_height)
reflection_distorted = np.zeros_like(reflection)
for row in range(street_region_height):
    shift = int(ripple_strength[row] * np.sin(row * 0.4))
    reflection_distorted[row] = np.roll(reflection[row], shift, axis=0)

# Boost neon colors in reflection (make them glow more)
refl_final = reflection_distorted.copy()
# Boost saturation of neon reflection colors
for c in range(3):
    # Keep neon, darken non-neon
    refl_final[:,:,c] = np.where(
        neon_refl_mask,
        np.clip(reflection_distorted[:,:,c] * 1.8, 0, 255),
        reflection_distorted[:,:,c] * 0.15
    )

# Apply fade
for c in range(3):
    refl_final[:,:,c] *= fade

# Add some specific neon puddle streaks - vertical light streaks from above neons
# Find bright neon columns in upper half
neon_cols_top = np.max(arr_out[:street_start], axis=0)  # shape (W, 3)
neon_cols_max = np.max(neon_cols_top, axis=1)  # W
bright_neon_cols = neon_cols_max > 180

# Add vertical streaks in street for those columns
for col in range(W):
    if bright_neon_cols[col]:
        neon_color = neon_cols_top[col]  # (3,)
        sat = (np.max(neon_color) - np.min(neon_color)) / (np.max(neon_color) + 1e-6)
        if sat > 0.4 and np.max(neon_color) > 150:
            # Paint a fading vertical streak
            for dy in range(street_region_height):
                streak_intensity = max(0, 1.0 - dy / (street_region_height * 0.6)) ** 2
                streak_width = max(1, int(3 - dy / 60))
                for dx in range(-streak_width, streak_width+1):
                    c2 = col + dx
                    if 0 <= c2 < W:
                        refl_final[dy, c2] = np.maximum(
                            refl_final[dy, c2],
                            neon_color * streak_intensity * 0.9
                        )

# Composite street reflection onto image
street_zone_y = slice(street_start, H)
current_street = arr_out[street_zone_y, :, :].astype(np.float32)

# Blend: screen mode for reflections (keeps reflections bright on dark surface)
for c in range(3):
    # Screen blend: 1 - (1-a)(1-b)
    a = current_street[:,:,c] / 255.0
    b_refl = np.clip(refl_final[:,:,c], 0, 255) / 255.0
    screened = 1.0 - (1.0 - a) * (1.0 - b_refl)
    arr_out[street_start:, :, c] = np.clip(screened * 255, 0, 255)

# Also add scattered cyan/magenta/amber puddle pools at the very bottom
# These are bright circular/elliptical glowing areas
puddle_y_base = H - 60  # near the bottom
puddle_data = [
    # (cx, cy, rx, ry, color)
    (512, H-30, 120, 18, [0, 220, 220]),   # cyan center (figure reflection)
    (380, H-45, 60, 12, [255, 0, 220]),    # magenta left-center
    (650, H-40, 70, 14, [255, 0, 220]),    # magenta right-center
    (200, H-55, 80, 10, [255, 160, 0]),    # amber far left
    (820, H-50, 80, 10, [0, 255, 180]),    # teal far right
    (130, H-35, 50, 8, [220, 0, 255]),     # purple left
    (900, H-35, 50, 8, [220, 0, 255]),     # purple right
]

yy, xx = np.mgrid[0:H, 0:W]
for (cx, cy, rx, ry, color) in puddle_data:
    dist = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    glow = np.clip(1.0 - dist, 0, 1) ** 0.5  # soft ellipse
    glow = glow * (yy >= street_start - 10)  # only in street zone
    for c in range(3):
        arr_out[:,:,c] = np.clip(arr_out[:,:,c] + glow * color[c] * 0.85, 0, 255)

# ─── STEP 5: ADD RAIN ENHANCEMENT IN STREET ──────────────────────────────────
# The rain streaks in the bottom should catch some neon light
rng = np.random.default_rng(42)
num_drops = 80
for _ in range(num_drops):
    x = rng.integers(0, W)
    y_start = rng.integers(street_start, H - 20)
    length = rng.integers(15, 45)
    y_end = min(H, y_start + length)
    # Pick a neon color from nearby
    col_color = arr_out[max(0, street_start - 50), x].copy()
    neon_intensity = np.max(col_color)
    if neon_intensity > 80:
        drop_color = col_color * 0.6
        for dy in range(y_end - y_start):
            fade_f = 1.0 - dy / (y_end - y_start)
            arr_out[y_start + dy, x] = np.clip(arr_out[y_start + dy, x] + drop_color * fade_f, 0, 255)
            if x + 1 < W:
                arr_out[y_start + dy, x+1] = np.clip(arr_out[y_start + dy, x+1] + drop_color * fade_f * 0.4, 0, 255)

# ─── STEP 6: FINAL OUTPUT ────────────────────────────────────────────────────
result_arr = np.clip(arr_out, 0, 255).astype(np.uint8)
result_img = Image.fromarray(result_arr)

# Apply a very slight sharpening to crisp up pixel art
result_img = result_img.filter(ImageFilter.UnsharpMask(radius=0.8, percent=110, threshold=3))

result_img.save(OUTPUT, "PNG", optimize=False)

# Verify
final = Image.open(OUTPUT)
print(f"Saved: {OUTPUT}")
print(f"Dimensions: {final.width}x{final.height}")
assert final.width == 1024 and final.height == 500, f"Wrong size! Got {final.width}x{final.height}"
print("✅ Done — feature_graphic_v4.png is 1024×500px")
