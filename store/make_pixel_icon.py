"""
Create pixel art version of the BIOHACKER app icon.
Pixelates the reference logo using the PAL palette from pixel-art-animator.
"""
from PIL import Image, ImageFilter, ImageDraw, ImageFont
import numpy as np
import os

# PAL palette neon colors (from sprites.py)
PAL = {
    "nc": (0, 255, 255),      # cyan
    "np": (255, 40, 210),     # pink/magenta
    "ng": (40, 255, 130),     # neon green
    "na": (255, 200, 10),     # amber/gold
    "nr": (255, 60, 60),      # red
    "nv": (180, 50, 255),     # violet
    "w_hi": (105, 200, 240),  # window highlight / light blue
    "black": (0, 0, 0),
    "sky0": (5, 8, 18),       # near-black dark bg
    "sky1": (8, 11, 24),
    "sky2": (12, 15, 32),
    "bf":   (28, 35, 56),
    "bm":   (22, 28, 47),
    "bn":   (16, 20, 36),
    "gd":   (20, 24, 38),
}

# Build flat palette list for quantization
PALETTE_COLORS = list(PAL.values())

def nearest_palette_color(pixel, palette):
    """Find nearest color in palette using Euclidean distance."""
    r, g, b = pixel[:3]
    min_dist = float('inf')
    nearest = (0, 0, 0)
    for c in palette:
        dr = int(r) - int(c[0])
        dg = int(g) - int(c[1])
        db = int(b) - int(c[2])
        dist = dr*dr + dg*dg + db*db
        if dist < min_dist:
            min_dist = dist
            nearest = c
    return nearest

def quantize_to_palette(img_array, palette):
    """Quantize image array to palette colors."""
    h, w, c = img_array.shape
    result = np.zeros_like(img_array)
    for y in range(h):
        for x in range(w):
            result[y, x] = nearest_palette_color(img_array[y, x], palette)
    return result

def add_circuit_background(canvas_size=1024):
    """Create a very dim circuit trace background."""
    bg = Image.new('RGB', (canvas_size, canvas_size), (0, 0, 0))
    draw = ImageDraw.Draw(bg)
    
    grid_size = 64  # pixel grid for circuit traces
    circuit_color = (0, 40, 30)  # very dim green-tinted
    
    np.random.seed(42)
    
    # Draw horizontal traces
    for y in range(0, canvas_size, grid_size):
        x = 0
        while x < canvas_size:
            if np.random.random() < 0.3:
                length = np.random.randint(1, 5) * grid_size
                draw.line([(x, y), (x + length, y)], fill=circuit_color, width=1)
                # Add node dot
                if np.random.random() < 0.4:
                    draw.rectangle([x-2, y-2, x+2, y+2], fill=(0, 60, 40))
                x += length + grid_size
            else:
                x += grid_size
    
    # Draw vertical traces
    for x in range(0, canvas_size, grid_size):
        y = 0
        while y < canvas_size:
            if np.random.random() < 0.3:
                length = np.random.randint(1, 4) * grid_size
                draw.line([(x, y), (x, y + length)], fill=circuit_color, width=1)
                y += length + grid_size
            else:
                y += grid_size
    
    return bg

def create_neon_glow(img, glow_color, threshold=50, blur_radius=20, opacity=0.6):
    """Create neon glow bloom effect around bright colored areas."""
    img_array = np.array(img).astype(float)
    r, g, b = glow_color
    
    # Create a mask of pixels matching the glow color (within threshold)
    dr = np.abs(img_array[:,:,0] - r)
    dg = np.abs(img_array[:,:,1] - g)
    db = np.abs(img_array[:,:,2] - b)
    mask = (dr < threshold) & (dg < threshold) & (db < threshold)
    
    # Create glow layer
    glow_layer = np.zeros_like(img_array)
    glow_layer[mask] = [r, g, b]
    
    glow_img = Image.fromarray(glow_layer.astype(np.uint8))
    glow_blurred = glow_img.filter(ImageFilter.GaussianBlur(radius=blur_radius))
    
    # Blend glow back
    glow_array = np.array(glow_blurred).astype(float)
    result = np.clip(img_array + glow_array * opacity, 0, 255).astype(np.uint8)
    return Image.fromarray(result)

def pixelate_image(img, pixel_size=8):
    """Pixelate image: downscale then upscale with NEAREST."""
    orig_size = img.size
    small_size = (orig_size[0] // pixel_size, orig_size[1] // pixel_size)
    small = img.resize(small_size, Image.NEAREST)
    pixelated = small.resize(orig_size, Image.NEAREST)
    return pixelated

# ============================================================
# MAIN: Build the pixel art icon
# ============================================================

OUTPUT_SIZE = 1024
PIXEL_BLOCK = 8  # each "pixel" is 8x8 real pixels → 128x128 grid

print("Loading reference logo...")
ref_path = "/home/wintermute/.openclaw/workspace/biohacker-flutter/assets/logo/biohacker-neon-logo.png"
logo = Image.open(ref_path).convert('RGB')
print(f"Logo size: {logo.size}")

# Resize logo to 1024x1024 first (it might not be square)
logo = logo.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.LANCZOS)

# Step 1: Create circuit background
print("Creating circuit background...")
bg = add_circuit_background(OUTPUT_SIZE)

# Step 2: Downscale logo to 128x128 (pixel grid)
GRID_SIZE = OUTPUT_SIZE // PIXEL_BLOCK  # 128
print(f"Downscaling to {GRID_SIZE}x{GRID_SIZE}...")
logo_small = logo.resize((GRID_SIZE, GRID_SIZE), Image.LANCZOS)

# Step 3: Quantize to PAL palette
print("Quantizing to PAL palette...")
logo_small_array = np.array(logo_small)

# For speed, use PIL's built-in quantize with a custom palette
# Build palette image (PIL needs 256 colors max)
pal_img = Image.new('P', (1, 1))
flat_pal = []
for c in PALETTE_COLORS:
    flat_pal.extend(c)
# Pad to 256 colors
while len(flat_pal) < 256 * 3:
    flat_pal.extend([0, 0, 0])
pal_img.putpalette(flat_pal)

# Quantize logo_small using our palette
logo_small_q = logo_small.quantize(palette=pal_img, dither=Image.Dither.FLOYDSTEINBERG)
logo_small_rgb = logo_small_q.convert('RGB')

# Step 4: Upscale back to 1024x1024 with NEAREST (chunky pixels)
print("Upscaling to 1024x1024 (pixel art)...")
logo_pixel = logo_small_rgb.resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.NEAREST)

# Step 5: Composite onto circuit background
# Where logo is nearly black, show bg; elsewhere show logo
logo_array = np.array(logo_pixel).astype(float)
bg_array = np.array(bg).astype(float)

# Blend: use logo where it has content, blend bg where dark
logo_brightness = logo_array.max(axis=2, keepdims=True) / 255.0
# Smooth blend threshold
alpha = np.clip((logo_brightness - 0.05) / 0.15, 0, 1)
composite = logo_array * alpha + bg_array * (1 - alpha)
composite = np.clip(composite, 0, 255).astype(np.uint8)
result = Image.fromarray(composite)

# Step 6: Add neon glow blooms
print("Adding neon glow effects...")
# Glow for each neon color in the image
glow_colors = [
    ((255, 40, 210), 25, 0.7),   # magenta/pink - brain left
    ((40, 255, 130), 25, 0.7),   # neon green - brain right
    ((0, 255, 255), 20, 0.6),    # cyan - text
    ((255, 200, 10), 15, 0.5),   # amber - bitcoin symbol
    ((105, 200, 240), 15, 0.4),  # window highlight
]

result_array = np.array(result).astype(float)
for glow_color, blur_r, opacity in glow_colors:
    r, g, b = glow_color
    threshold = 60
    
    # Create mask of similar-colored pixels
    dr = np.abs(result_array[:,:,0] - r)
    dg = np.abs(result_array[:,:,1] - g)
    db = np.abs(result_array[:,:,2] - b)
    mask = (dr < threshold) & (dg < threshold) & (db < threshold)
    
    if mask.sum() > 0:
        glow_layer = np.zeros_like(result_array)
        glow_layer[mask] = [r, g, b]
        glow_img = Image.fromarray(glow_layer.astype(np.uint8))
        glow_blurred = glow_img.filter(ImageFilter.GaussianBlur(radius=blur_r))
        glow_array = np.array(glow_blurred).astype(float)
        result_array = np.clip(result_array + glow_array * opacity, 0, 255)

result = Image.fromarray(result_array.astype(np.uint8))

# Step 7: The logo already contains "₿IOHACKER" text (pixelated from the logo)
# Boost the cyan text area with extra glow instead of re-drawing
print("Boosting text glow...")
# The pixelated logo already has the text — add extra cyan glow pass
cyan_glow_layer = np.zeros_like(result_array)
cyan = np.array([0, 255, 255], dtype=float)
result_arr2 = np.array(result).astype(float)

# Find cyan pixels in bottom 40% of image
bottom_start = int(OUTPUT_SIZE * 0.6)
cyan_mask = np.zeros((OUTPUT_SIZE, OUTPUT_SIZE), dtype=bool)
for y in range(bottom_start, OUTPUT_SIZE):
    for x in range(OUTPUT_SIZE):
        px = result_arr2[y, x]
        if px[2] > 150 and px[1] > 150 and px[0] < 100:  # cyan-ish
            cyan_mask[y, x] = True

glow_only = np.zeros_like(result_arr2)
glow_only[cyan_mask] = [0, 255, 255]
glow_img = Image.fromarray(glow_only.astype(np.uint8))
glow_blurred = glow_img.filter(ImageFilter.GaussianBlur(radius=15))
glow_array = np.array(glow_blurred).astype(float)
result_arr2 = np.clip(result_arr2 + glow_array * 0.8, 0, 255)
result = Image.fromarray(result_arr2.astype(np.uint8))

# Step 8: Add pixel grid overlay (subtle scanline effect)
print("Adding pixel grid lines...")
grid_array = np.array(result).astype(float)
for y in range(0, OUTPUT_SIZE, PIXEL_BLOCK):
    grid_array[y, :] = grid_array[y, :] * 0.85
for x in range(0, OUTPUT_SIZE, PIXEL_BLOCK):
    grid_array[:, x] = grid_array[:, x] * 0.85
result = Image.fromarray(np.clip(grid_array, 0, 255).astype(np.uint8))

# Save
output_path = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/icon_pixel_final.png"
os.makedirs(os.path.dirname(output_path), exist_ok=True)
result.save(output_path, 'PNG')

# Verify
saved = Image.open(output_path)
print(f"\n✅ Saved: {output_path}")
print(f"   Size: {saved.size[0]}x{saved.size[1]}px")
print(f"   Mode: {saved.mode}")
