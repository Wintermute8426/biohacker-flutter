#!/usr/bin/env python3
"""
Feature Graphic v4 → pass 3
AGGRESSIVE rim lighting: explicit thick glowing strokes on figure silhouette
"""

import numpy as np
from PIL import Image, ImageFilter, ImageDraw

# Start from v3 (original clean image) for figure detection, but apply to v4
INPUT_ORIG = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v3.png"
INPUT_V4 = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v4.png"
OUTPUT = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v4.png"

orig = Image.open(INPUT_ORIG).convert("RGB")
v4 = Image.open(INPUT_V4).convert("RGB")
orig_arr = np.array(orig, dtype=np.float32)
arr = np.array(v4, dtype=np.float32)
H, W = arr.shape[:2]

# ─── DEFINE FIGURE SILHOUETTE MANUALLY ────────────────────────────────────────
# Based on visual inspection: hooded figure is roughly a triangle/cloak shape
# Hood top: around x=460-560, y=90-130
# Body/cloak: widens to x=390-640 at y=430
# The figure is centered around x=512

# Define the hooded figure as a polygon (left edge points, right edge points)
# These are approximate coordinates based on the image
# Hood is narrower at top, cloak spreads at bottom

left_edge = [
    (490, 90),   # hood top-left
    (450, 130),  # hood shoulder-left  
    (420, 170),  # upper chest left
    (400, 220),  # mid-chest left
    (385, 280),  # waist left
    (375, 340),  # lower left
    (368, 390),  # ankle left
    (370, 430),  # hem left
]

right_edge = [
    (540, 90),   # hood top-right
    (570, 130),  # hood shoulder-right
    (595, 170),  # upper chest right
    (615, 220),  # mid-chest right
    (630, 280),  # waist right
    (640, 340),  # lower right
    (648, 390),  # ankle right
    (645, 430),  # hem right
]

# Create a figure mask via polygon fill
from PIL import ImageDraw
mask_img = Image.new("L", (W, H), 0)
mask_draw = ImageDraw.Draw(mask_img)

# Build the full polygon: left edge (top to bottom) + right edge (bottom to top)
polygon = left_edge + list(reversed(right_edge))
mask_draw.polygon(polygon, fill=255)

# Smooth the mask slightly
mask_img = mask_img.filter(ImageFilter.GaussianBlur(radius=3))
fig_mask = np.array(mask_img) > 50

# ─── PAINT FIGURE ITSELF AS VISIBLE DARK SHAPE ────────────────────────────────
# Fill figure with dark teal/blue-grey so it's visibly distinct from pure black bg
arr_out = arr.copy()

# Sample existing figure pixels - are they visible at all?
fig_pixels = orig_arr[fig_mask]
avg_fig = np.mean(fig_pixels, axis=0) if len(fig_pixels) > 0 else np.array([0,0,0])
print(f"Avg figure pixel brightness in orig: {avg_fig}")

# Lift figure interior: target a dark teal cloak look (~30-60 range)
# Use distance from edge for interior depth effect
mask_arr = np.array(mask_img, dtype=np.float32) / 255.0

# Edge erosion to get interior
inner_mask_img = mask_img.filter(ImageFilter.MinFilter(25))  # erode 12px
inner_mask = np.array(inner_mask_img, dtype=np.float32) / 255.0

# Rim = mask - eroded mask  (the edges)
rim_mask = np.clip(mask_arr - inner_mask, 0, 1)

# Interior boost: make the cloak a visible dark shape
# Target: dark navy/teal = [10, 30, 60]
cloak_target = np.array([12, 35, 75], dtype=np.float32)
for c in range(3):
    # Blend toward cloak_target for interior pixels
    blend = inner_mask * 0.85  # strong blend in center
    arr_out[:,:,c] = np.clip(
        arr_out[:,:,c] * (1 - blend) + cloak_target[c] * blend,
        0, 255
    )

# Add subtle hood fold highlights (lighter stripe down center of hood)
hood_highlight = np.zeros((H, W), dtype=np.float32)
# Center vertical strip in upper figure
cx = 512
for row in range(90, 240):
    progress = (row - 90) / 150.0
    spread = int(8 + progress * 15)
    for col in range(cx - spread, cx + spread + 1):
        if 0 <= col < W and fig_mask[row, col]:
            dist_from_center = abs(col - cx) / spread
            hood_highlight[row, col] = (1.0 - dist_from_center) ** 2 * 0.6

for c in range(3):
    highlight_color = [20, 60, 100][c]
    arr_out[:,:,c] = np.clip(
        arr_out[:,:,c] + hood_highlight * highlight_color,
        0, 255
    )

# ─── STRONG CYAN RIM LIGHT (LEFT SIDE) ────────────────────────────────────────
# Create a bright cyan glow layer
cyan_glow = np.zeros((H, W, 3), dtype=np.float32)
CYAN = np.array([0, 255, 255], dtype=np.float32)

# For each column in figure zone, scan top to bottom for left edge
for col in range(350, 660):
    col_mask = fig_mask[:, col]
    rows = np.where(col_mask)[0]
    if len(rows) == 0:
        continue
    
    # Also scan right to left for left edge per row
    # The left edge is the leftmost pixel in each row

for row in range(85, 440):
    row_mask = fig_mask[row, :]
    cols_fig = np.where(row_mask)[0]
    if len(cols_fig) < 3:
        continue
    
    left_col = cols_fig[0]
    right_col = cols_fig[-1]
    width = right_col - left_col
    if width < 10:
        continue
    
    # Row weight: taper at very top and bottom
    t = (row - 85) / (440 - 85)
    if t < 0.1:
        weight = t / 0.1
    elif t > 0.9:
        weight = (1.0 - t) / 0.1
    else:
        weight = 1.0
    
    weight = max(0.3, weight)
    
    # CYAN LEFT RIM - very bright, 25px wide glow
    for spread in range(28):
        # Outside glow
        col = left_col - spread
        if 0 <= col < W:
            intensity = ((1.0 - spread / 28.0) ** 1.3) * weight
            cyan_glow[row, col] = np.maximum(
                cyan_glow[row, col],
                CYAN * intensity
            )
        # Inside bright rim
        if spread < 8:
            col_in = left_col + spread
            if col_in < W:
                intensity_in = ((1.0 - spread / 8.0) ** 1.0) * weight * 1.2
                cyan_glow[row, col_in] = np.maximum(
                    cyan_glow[row, col_in],
                    CYAN * min(intensity_in, 1.0)
                )

# MAGENTA RIGHT RIM
magenta_glow = np.zeros((H, W, 3), dtype=np.float32)
MAGENTA = np.array([255, 0, 255], dtype=np.float32)

for row in range(85, 440):
    row_mask = fig_mask[row, :]
    cols_fig = np.where(row_mask)[0]
    if len(cols_fig) < 3:
        continue
    
    left_col = cols_fig[0]
    right_col = cols_fig[-1]
    width = right_col - left_col
    if width < 10:
        continue
    
    t = (row - 85) / (440 - 85)
    if t < 0.1:
        weight = t / 0.1
    elif t > 0.9:
        weight = (1.0 - t) / 0.1
    else:
        weight = 1.0
    weight = max(0.3, weight)
    
    for spread in range(28):
        # Outside glow
        col = right_col + spread
        if 0 <= col < W:
            intensity = ((1.0 - spread / 28.0) ** 1.3) * weight
            magenta_glow[row, col] = np.maximum(
                magenta_glow[row, col],
                MAGENTA * intensity
            )
        # Inside bright rim
        if spread < 8:
            col_in = right_col - spread
            if col_in >= 0:
                intensity_in = ((1.0 - spread / 8.0) ** 1.0) * weight * 1.2
                magenta_glow[row, col_in] = np.maximum(
                    magenta_glow[row, col_in],
                    MAGENTA * min(intensity_in, 1.0)
                )

# CYAN TOP RIM (hood outline glow from above)
for col in range(400, 620):
    col_mask = fig_mask[:200, col]
    rows_fig = np.where(col_mask)[0]
    if len(rows_fig) == 0:
        continue
    top_row = rows_fig[0]
    
    # Column center weight
    cx = 512
    col_t = abs(col - cx) / 100.0
    weight = max(0.2, 1.0 - col_t * 0.7)
    
    for spread in range(20):
        r2 = top_row - spread
        if 0 <= r2 < H:
            intensity = ((1.0 - spread / 20.0) ** 1.5) * weight * 0.9
            cyan_glow[r2, col] = np.maximum(
                cyan_glow[r2, col],
                CYAN * intensity
            )

# Blur glow layers for soft luminous effect (important for realism)
def blur_channel(ch_arr, radius=4):
    img_ch = Image.fromarray(np.clip(ch_arr * 255, 0, 255).astype(np.uint8))
    blurred = img_ch.filter(ImageFilter.GaussianBlur(radius=radius))
    return np.array(blurred, dtype=np.float32) / 255.0

print("Blurring glow layers...")
cyan_blurred = np.stack([
    blur_channel(cyan_glow[:,:,0], radius=5),
    blur_channel(cyan_glow[:,:,1], radius=5),
    blur_channel(cyan_glow[:,:,2], radius=5),
], axis=2)

magenta_blurred = np.stack([
    blur_channel(magenta_glow[:,:,0], radius=5),
    blur_channel(magenta_glow[:,:,1], radius=5),
    blur_channel(magenta_glow[:,:,2], radius=5),
], axis=2)

# Combine: original + blurred glow + sharp glow overlay
# Sharp glow = raw unblurred (for bright edges)
# Blurred glow = soft luminous halo

for c in range(3):
    a = arr_out[:,:,c] / 255.0
    
    # Screen blend with combined glow
    b_total = np.clip(cyan_glow[:,:,c] * 0.7 + cyan_blurred[:,:,c] * 0.9 +
                      magenta_glow[:,:,c] * 0.7 + magenta_blurred[:,:,c] * 0.9, 0, 1.0)
    
    screened = 1.0 - (1.0 - a) * (1.0 - b_total)
    arr_out[:,:,c] = np.clip(screened * 255, 0, 255)

# ─── SAVE ─────────────────────────────────────────────────────────────────────
result = np.clip(arr_out, 0, 255).astype(np.uint8)
result_img = Image.fromarray(result)
result_img.save(OUTPUT, "PNG")

final = Image.open(OUTPUT)
assert final.width == 1024 and final.height == 500
print(f"✅ Pass 3 done — {final.width}x{final.height}px")
