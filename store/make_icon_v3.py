#!/usr/bin/env python3
"""
BIOHACKER icon_pixel_v3.py
Color-accuracy pass: no palette quantization, preserve original neon colors.
"""
from PIL import Image, ImageFilter
import numpy as np

INPUT = "/home/wintermute/.openclaw/workspace/biohacker-flutter/assets/logo/biohacker-neon-logo.png"
OUTPUT = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/icon_pixel_v3.png"

# 1. Load original
img = Image.open(INPUT).convert("RGBA")
print(f"Original size: {img.size}")

# 2. Downscale to 256×256 (LANCZOS for quality) — no palette quantization
small = img.resize((256, 256), Image.LANCZOS)

# 3. Upscale to 1024×1024 with NEAREST (creates 4×4 pixel blocks)
pixelated = small.resize((1024, 1024), Image.NEAREST)

# 4. Neon glow bloom
# Work in RGBA throughout
arr = np.array(pixelated, dtype=np.float32)
rgb = arr[:, :, :3]
alpha = arr[:, :, 3:4]

# Mask: pixels where any channel > 160
bright_mask = np.any(rgb > 160, axis=2)  # (1024,1024) bool

# Create glow image: copy bright pixels, black out dim ones
glow_arr = rgb.copy()
glow_arr[~bright_mask] = 0

glow_img = Image.fromarray(glow_arr.astype(np.uint8), mode="RGB")
glow_blurred = glow_img.filter(ImageFilter.GaussianBlur(radius=14))
glow_blurred_arr = np.array(glow_blurred, dtype=np.float32)

# Blend: original + 55% of blurred glow, clamp
result_rgb = np.clip(rgb + glow_blurred_arr * 0.55, 0, 255)

# 5. Circuit trace grid — only on near-black background pixels
# "background" = all channels < 30 in original
bg_mask = np.all(rgb < 30, axis=2)  # (1024,1024)

# Draw grid lines at every 32px
grid_brightness = 12
for i in range(0, 1024, 32):
    # horizontal
    row_bg = bg_mask[i, :]
    result_rgb[i, row_bg] = np.clip(result_rgb[i, row_bg] + grid_brightness, 0, 255)
    # vertical
    col_bg = bg_mask[:, i]
    result_rgb[col_bg, i] = np.clip(result_rgb[col_bg, i] + grid_brightness, 0, 255)

# 6. Force bottom-right 80×80 to pure black
result_rgb[944:1024, 944:1024] = 0

# 7. Reassemble RGBA
result_arr = np.concatenate([result_rgb, alpha], axis=2).astype(np.uint8)
result = Image.fromarray(result_arr, mode="RGBA")

# Save
result.save(OUTPUT, "PNG")
print(f"Saved: {OUTPUT}")
print(f"Final size: {result.size}")
assert result.size == (1024, 1024), "Size mismatch!"
print("✅ Done — 1024×1024 confirmed")
