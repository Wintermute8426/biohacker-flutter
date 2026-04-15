#!/usr/bin/env python3
"""
Feature Graphic v4 → v4 (pass 2)
Focus: Much stronger rim lighting on figure, brighter buildings
"""

import numpy as np
from PIL import Image, ImageFilter, ImageDraw

INPUT = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v4.png"
OUTPUT = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v4.png"

img = Image.open(INPUT).convert("RGB")
arr = np.array(img, dtype=np.float32)
H, W = arr.shape[:2]
print(f"Loaded: {W}x{H}")

# Figure zone
fig_x1, fig_x2 = 350, 680
fig_y1, fig_y2 = 90, 440

CYAN = np.array([0, 255, 255], dtype=np.float32)
MAGENTA = np.array([255, 20, 255], dtype=np.float32)
WHITE_CYAN = np.array([160, 255, 255], dtype=np.float32)
WHITE_MAGENTA = np.array([255, 160, 255], dtype=np.float32)

# ─── STRONGER FIGURE DETECTION ───────────────────────────────────────────────
# Look at original pixel values to detect figure vs pure background
# The figure is a dark shape - we need to detect its silhouette boundary
# Strategy: compare each pixel to its neighbors - figure boundary = transition from
# dark-uniform-bg to slightly-different-dark

# Use edge detection via gradient magnitude
from PIL import ImageFilter as IF

# Convert to grayscale for edge detection
gray = img.convert("L")
gray_arr = np.array(gray, dtype=np.float32)

# Sobel-like gradient in the figure zone
# We'll do it manually
def sobel_x(a):
    k = np.array([[-1,0,1],[-2,0,2],[-1,0,1]])
    from PIL import ImageFilter
    tmp = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).filter(
        ImageFilter.Kernel(size=3, kernel=k.flatten().tolist(), scale=8, offset=128)
    )
    return np.array(tmp, dtype=np.float32) - 128

def sobel_y(a):
    k = np.array([[-1,-2,-1],[0,0,0],[1,2,1]])
    from PIL import ImageFilter
    tmp = Image.fromarray(np.clip(a, 0, 255).astype(np.uint8)).filter(
        ImageFilter.Kernel(size=3, kernel=k.flatten().tolist(), scale=8, offset=128)
    )
    return np.array(tmp, dtype=np.float32) - 128

# Detect figure by: in the figure zone, look for non-trivially-dark pixels
# relative to the pure background (which is deep purple/black ~= r<20, g<15, b<30)
fig_zone = arr[fig_y1:fig_y2, fig_x1:fig_x2]
fig_brightness = np.max(fig_zone, axis=2)

# The figure (cloak) is dark but distinguishable - even 8-20 brightness difference matters
# Use adaptive threshold: pixels brighter than local background min + 8
# Background in this zone: very dark purplish
bg_level = 18
fig_mask_zone = fig_brightness > bg_level

# Morphological cleanup: fill small holes, remove noise
# Simple approach: median of neighborhood
from PIL import Image as PILImg
mask_img = PILImg.fromarray((fig_mask_zone * 255).astype(np.uint8))
mask_img = mask_img.filter(ImageFilter.MaxFilter(5))  # dilate
mask_img = mask_img.filter(ImageFilter.MinFilter(3))  # slight erode
fig_mask_zone = np.array(mask_img) > 127

# Full-image figure mask
fig_mask = np.zeros((H, W), dtype=bool)
fig_mask[fig_y1:fig_y2, fig_x1:fig_x2] = fig_mask_zone

# ─── DRAMATICALLY BRIGHT RIM LIGHTING ────────────────────────────────────────
rim_cyan = np.zeros((H, W, 3), dtype=np.float32)
rim_magenta = np.zeros((H, W, 3), dtype=np.float32)

# For each row in figure zone, find leftmost/rightmost figure pixel
for row in range(fig_y1, min(fig_y2, H)):
    row_mask = fig_mask[row, fig_x1:fig_x2]
    cols = np.where(row_mask)[0]
    if len(cols) < 3:
        continue
    
    left_rel = cols[0]
    right_rel = cols[-1]
    left_col = left_rel + fig_x1
    right_col = right_rel + fig_x1
    
    # Figure width (for scaling)
    width = right_col - left_col
    if width < 20:
        continue
    
    # Row weighting - strongest in middle of figure, fade at top/bottom
    row_center = (fig_y1 + fig_y2) / 2
    row_dist = abs(row - row_center) / ((fig_y2 - fig_y1) / 2)
    row_weight = max(0.3, 1.0 - row_dist * 0.6)
    
    # ── CYAN LEFT RIM ──
    # Outer glow (outside figure)
    for spread in range(20):
        col = left_col - spread
        if 0 <= col < W:
            intensity = ((1.0 - spread / 20.0) ** 1.5) * 255 * row_weight * 0.85
            rim_cyan[row, col] = np.maximum(rim_cyan[row, col], CYAN * intensity / 255.0)
    
    # Bright inner edge (inside figure, left side)
    for spread in range(6):
        col = left_col + spread
        if 0 <= col < W:
            intensity = ((1.0 - spread / 6.0) ** 1.2) * 255 * row_weight
            rim_cyan[row, col] = np.maximum(rim_cyan[row, col], WHITE_CYAN * intensity / 255.0)
    
    # ── MAGENTA RIGHT RIM ──
    # Outer glow
    for spread in range(20):
        col = right_col + spread
        if 0 <= col < W:
            intensity = ((1.0 - spread / 20.0) ** 1.5) * 255 * row_weight * 0.85
            rim_magenta[row, col] = np.maximum(rim_magenta[row, col], MAGENTA * intensity / 255.0)
    
    # Bright inner edge
    for spread in range(6):
        col = right_col - spread
        if 0 <= col < W:
            intensity = ((1.0 - spread / 6.0) ** 1.2) * 255 * row_weight
            rim_magenta[row, col] = np.maximum(rim_magenta[row, col], WHITE_MAGENTA * intensity / 255.0)

# Also paint bright rim along top of hood
# Hood top: find topmost figure pixels per column
for col in range(fig_x1, fig_x2):
    col_mask = fig_mask[fig_y1:fig_y2, col]
    rows = np.where(col_mask)[0]
    if len(rows) == 0:
        continue
    top_row = rows[0] + fig_y1
    
    # Column centering weight
    col_center = (fig_x1 + fig_x2) / 2
    col_dist = abs(col - col_center) / ((fig_x2 - fig_x1) / 2)
    col_weight = max(0.2, 1.0 - col_dist)
    
    # Cyan glow above hood top
    for spread in range(12):
        r2 = top_row - spread
        if 0 <= r2 < H:
            intensity = ((1.0 - spread / 12.0) ** 2) * 200 * col_weight
            rim_cyan[r2, col] = np.maximum(rim_cyan[r2, col], CYAN * intensity / 255.0)

# ─── APPLY RIM LIGHTING WITH SCREEN BLEND ────────────────────────────────────
arr_out = arr.copy()

for c in range(3):
    # Screen blend rim lights
    a = arr_out[:,:,c] / 255.0
    b_c = rim_cyan[:,:,c]
    b_m = rim_magenta[:,:,c]
    # Combine cyan and magenta rims first
    b_total = np.clip(b_c + b_m, 0, 1.0)
    # Screen: 1 - (1-a)(1-b)
    screened = 1.0 - (1.0 - a) * (1.0 - b_total)
    arr_out[:,:,c] = np.clip(screened * 255, 0, 255)

# ─── EXTRA: LIFT FIGURE INTERIOR ─────────────────────────────────────────────
# Add a subtle self-illumination to figure pixels so it's not pure black void
# Teal/blue tint cloak effect
cloak_color = np.array([15, 45, 80], dtype=np.float32)  # deep teal
for row in range(fig_y1, min(fig_y2, H)):
    row_mask_full = fig_mask[row, :]
    if not np.any(row_mask_full):
        continue
    cols = np.where(row_mask_full)[0]
    left_col = cols[0]
    right_col = cols[-1]
    
    for col in range(left_col, right_col + 1):
        # Distance from edges (normalized)
        width = right_col - left_col
        if width < 1:
            continue
        edge_dist = min(col - left_col, right_col - col) / (width * 0.5)
        edge_dist = min(edge_dist, 1.0)
        
        # Add depth to center, keep edges glowy
        center_boost = edge_dist * 0.4  # subtle center lift
        arr_out[row, col] = np.clip(
            arr_out[row, col] + cloak_color * center_boost + np.array([0, 8, 20]),
            0, 255
        )

# ─── BRIGHTER BUILDINGS ───────────────────────────────────────────────────────
# Additional boost to building windows
left_bld = (slice(0, H), slice(0, 340))
right_bld = (slice(0, H), slice(680, W))
upper = slice(0, 300)

# Detect building windows (small bright colored pixels in building zones)
for zone in [(slice(0, H), slice(0, 340)), (slice(0, H), slice(680, W))]:
    zone_arr = arr_out[zone]
    zone_max = np.max(zone_arr, axis=2)
    zone_min = np.min(zone_arr, axis=2)
    zone_sat = np.where(zone_max > 0, (zone_max - zone_min) / (zone_max + 1e-6), 0)
    
    # Windows: moderately bright, colored pixels
    window_mask = (zone_max > 40) & (zone_max < 240) & (zone_sat > 0.2)
    
    for c in range(3):
        zone_ch = zone_arr[:,:,c].copy()
        zone_ch = np.where(window_mask, np.clip(zone_ch * 1.7 + 20, 0, 255), zone_ch)
        arr_out[zone[0], zone[1], c] = zone_ch

# ─── SAVE ─────────────────────────────────────────────────────────────────────
result_arr = np.clip(arr_out, 0, 255).astype(np.uint8)
result_img = Image.fromarray(result_arr)
result_img = result_img.filter(ImageFilter.UnsharpMask(radius=0.6, percent=100, threshold=2))

result_img.save(OUTPUT, "PNG")

final = Image.open(OUTPUT)
print(f"Saved: {OUTPUT}")
print(f"Dimensions: {final.width}x{final.height}")
assert final.width == 1024 and final.height == 500
print("✅ Pass 2 complete — feature_graphic_v4.png enhanced with stronger rim lighting")
