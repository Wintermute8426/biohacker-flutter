#!/usr/bin/env python3
"""
Generate BH monogram app icon in Blade Runner cyberpunk style
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os

def create_bh_icon(size=1024):
    """Create BH monogram icon with enhanced cyberpunk styling"""

    # Create image with pure black background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 255))
    draw = ImageDraw.Draw(img)

    # Draw hexagonal grid background pattern
    hex_color = (15, 15, 15, 255)
    hex_size = size // 25
    for row in range(0, size // hex_size + 2):
        for col in range(0, size // hex_size + 2):
            x = col * hex_size * 1.5
            y = row * hex_size * 1.732  # Height of equilateral triangle
            if col % 2 == 1:
                y += hex_size * 0.866
            # Draw hexagon
            points = []
            for angle in range(0, 360, 60):
                rad = angle * 3.14159 / 180
                px = x + hex_size * 0.5 * (1 + 0.866 * (1 if angle % 120 else -1))
                py = y + hex_size * 0.5 * 0.866
                points.append((int(px), int(py)))
            if len(points) > 2:
                draw.polygon(points, outline=hex_color)

    # Draw corner brackets (Blade Runner style)
    corner_size = size // 10
    corner_color = (0, 255, 255, 100)  # Cyan with transparency
    corner_width = 3
    # Top-left
    draw.line([(0, corner_size), (0, 0), (corner_size, 0)], fill=corner_color, width=corner_width)
    # Top-right
    draw.line([(size-corner_size, 0), (size, 0), (size, corner_size)], fill=corner_color, width=corner_width)
    # Bottom-left
    draw.line([(0, size-corner_size), (0, size), (corner_size, size)], fill=corner_color, width=corner_width)
    # Bottom-right
    draw.line([(size-corner_size, size), (size, size), (size, size-corner_size)], fill=corner_color, width=corner_width)

    # Try to use a bold font, fallback to default
    try:
        # Try common monospace fonts
        font_paths = [
            '/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf',
            '/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf',
            '/System/Library/Fonts/Monaco.ttf',
            'C:\\Windows\\Fonts\\consola.ttf',
        ]
        font = None
        for path in font_paths:
            if os.path.exists(path):
                font = ImageFont.truetype(path, size // 2)
                break
        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()

    # Create text layer for "BH"
    text = "BH"

    # Create a separate image for text to apply glow effects
    text_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    text_draw = ImageDraw.Draw(text_layer)

    # Get text bounding box for centering
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]

    # Center position
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - bbox[1]  # Adjust for baseline

    # Draw green outer glow (shadow)
    for offset in range(15, 0, -3):
        opacity = int(255 * 0.3 * (offset / 15))
        green_glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(green_glow)
        glow_draw.text((x, y), text, font=font, fill=(57, 255, 20, opacity))
        green_glow = green_glow.filter(ImageFilter.GaussianBlur(radius=offset))
        img = Image.alpha_composite(img, green_glow)

    # Draw cyan glow
    for offset in range(10, 0, -2):
        opacity = int(255 * 0.5 * (offset / 10))
        cyan_glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        glow_draw = ImageDraw.Draw(cyan_glow)
        glow_draw.text((x, y), text, font=font, fill=(0, 255, 255, opacity))
        cyan_glow = cyan_glow.filter(ImageFilter.GaussianBlur(radius=offset))
        img = Image.alpha_composite(img, cyan_glow)

    # Draw main cyan text
    text_draw.text((x, y), text, font=font, fill=(0, 255, 255, 255))
    img = Image.alpha_composite(img, text_layer)

    # Add circuit trace patterns inside letters
    circuit_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    circuit_draw = ImageDraw.Draw(circuit_layer)
    circuit_color = (57, 255, 20, 120)  # Green with transparency

    # Circuit patterns near the text (simplified for readability)
    text_center_x = x + text_width // 2
    text_center_y = y + text_height // 2

    # Horizontal traces
    for i in range(-3, 4):
        offset_y = text_center_y + i * (text_height // 8)
        if 0 < offset_y < size:
            circuit_draw.line([
                (text_center_x - text_width // 3, offset_y),
                (text_center_x + text_width // 3, offset_y)
            ], fill=circuit_color, width=1)

    # Vertical traces
    for i in range(-2, 3):
        offset_x = text_center_x + i * (text_width // 6)
        if 0 < offset_x < size:
            circuit_draw.line([
                (offset_x, text_center_y - text_height // 3),
                (offset_x, text_center_y + text_height // 3)
            ], fill=circuit_color, width=1)

    img = Image.alpha_composite(img, circuit_layer)

    # Add scanline overlay effect
    scanline_layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    scanline_draw = ImageDraw.Draw(scanline_layer)
    scanline_color = (0, 255, 255, 15)  # Very subtle cyan

    for y_pos in range(0, size, 4):
        scanline_draw.line([(0, y_pos), (size, y_pos)], fill=scanline_color, width=1)

    img = Image.alpha_composite(img, scanline_layer)

    return img

def main():
    base_dir = '/home/wintermute/.openclaw/workspace/biohacker-flutter'

    # Generate master icon (1024x1024)
    print("Generating master icon (1024x1024)...")
    master_icon = create_bh_icon(1024)
    master_path = os.path.join(base_dir, 'assets/icon/app_icon.png')
    os.makedirs(os.path.dirname(master_path), exist_ok=True)
    master_icon.save(master_path, 'PNG')
    print(f"✓ Saved: {master_path}")

    # Generate Android icons in various sizes
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }

    for folder, size in android_sizes.items():
        print(f"Generating {folder} icon ({size}x{size})...")
        icon = create_bh_icon(size)
        icon_path = os.path.join(base_dir, f'android/app/src/main/res/{folder}/ic_launcher.png')
        os.makedirs(os.path.dirname(icon_path), exist_ok=True)
        icon.save(icon_path, 'PNG')
        print(f"✓ Saved: {icon_path}")

    print("\n✅ Icon generation complete!")

if __name__ == '__main__':
    main()
