#!/usr/bin/env python3
"""
BIOHACKER Store Assets - Final Generation
Uses pixel-art-animator's CityScene engine for authentic Waneella-style renders.

Asset 1: Feature Graphic - 1024×500px landscape banner
Asset 2: App Icon       - 1024×1024px square
"""

import sys
import os
import math
import random
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Add the pixel-art-animator to path
sys.path.insert(0, '/home/wintermute/.openclaw/workspace/pixel-art-animator')

# Monkey-patch the canvas dimensions for our renders
import sprites
from sprites import (
    PAL, LAYER_CFG, NEON_COLORS,
    fill, blend, hline, vline, spx, bpx, blit,
    gen_layer, render_body, render_bridges,
    render_static_windows, render_animated_windows, render_neon_sign,
    iter_windows,
    make_speeder, make_heavy, make_drone,
)

FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"
OUT_DIR  = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store"
os.makedirs(OUT_DIR, exist_ok=True)


# =============================================================================
# SHARED SCENE RENDERER (canvas-size-agnostic)
# =============================================================================

class StoreScene:
    """Cyberpunk city scene renderer that works at arbitrary canvas dimensions."""

    def __init__(self, canvas_w, canvas_h, seed=99):
        self.W = canvas_w
        self.H = canvas_h
        self.rng = random.Random(seed)
        print(f"  Building {canvas_w}×{canvas_h} scene...")
        self._build_layers()
        self._init_rain()
        self._precompute_neon()
        print("  Caching background...")
        self.bg = self._cache_background()
        print("  Scene ready.")

    def _build_layers(self):
        self.layers = []
        for name in ["far", "mid_far", "mid", "near"]:
            bldgs, bridges = gen_layer(self.rng, name, self.W, self.H)
            self.layers.append((name, bldgs, bridges))

    def _init_rain(self):
        n_drops = int(350 * (self.W * self.H) / (360 * 640))
        self.rain_drops = []
        for _ in range(n_drops):
            self.rain_drops.append({
                "x": self.rng.uniform(-50, self.W + 50),
                "y": self.rng.uniform(-self.H, self.H),
                "speed": self.rng.uniform(5.0, 9.0),
                "length": self.rng.randint(3, 9),
                "bright": self.rng.random() < 0.15,
                "wind": self.rng.uniform(-0.8, -0.3),
            })

    def _precompute_neon(self):
        self.all_neon = []
        for name, bldgs, _ in self.layers:
            for b in bldgs:
                for sign in b["neon"]:
                    self.all_neon.append((b["x"], b["y"], sign))

    def _render_sky(self, canvas):
        stops = [
            (0.00, PAL["sky0"]),
            (0.15, PAL["sky1"]),
            (0.40, PAL["sky2"]),
            (0.70, PAL["sky3"]),
            (1.00, PAL["sky4"]),
        ]
        for y in range(self.H):
            t = y / self.H
            for i in range(len(stops) - 1):
                if t <= stops[i + 1][0] or i == len(stops) - 2:
                    span = max(0.001, stops[i + 1][0] - stops[i][0])
                    lt = max(0.0, min(1.0, (t - stops[i][0]) / span))
                    c1 = np.array(stops[i][1], dtype=np.float32)
                    c2 = np.array(stops[i + 1][1], dtype=np.float32)
                    canvas[y, :] = (c1 * (1 - lt) + c2 * lt).astype(np.uint8)
                    break
        # Stars
        srng = random.Random(777)
        star_h = int(self.H * 0.25)
        for _ in range(int(60 * self.W / 360)):
            sx = srng.randint(0, self.W - 1)
            sy = srng.randint(0, star_h)
            br = srng.uniform(0.15, 0.5)
            c = tuple(int(v * br) for v in PAL["white"])
            spx(canvas, sx, sy, c)

    def _render_atmo_band(self, canvas, y_center, half_h, peak_alpha, color):
        for y in range(max(0, y_center - half_h), min(self.H, y_center + half_h)):
            dist = abs(y - y_center) / max(1, half_h)
            a = peak_alpha * max(0, 1 - dist ** 1.5)
            if a > 0.01:
                blend(canvas, 0, y, self.W, 1, color, a)

    def _cache_background(self):
        canvas = np.zeros((self.H, self.W, 3), dtype=np.uint8)
        self._render_sky(canvas)

        # Scale y-positions for cloud/fog based on canvas height ratio
        r = self.H / 640

        # Far buildings
        name, bldgs, bridges = self.layers[0]
        pfx = LAYER_CFG[name]["pfx"]
        for b in bldgs:
            render_body(canvas, b, pfx)
        for b in bldgs:
            render_static_windows(canvas, b)
        render_bridges(canvas, bridges, pfx)

        self._render_atmo_band(canvas, int(300 * r), int(250 * r), 0.18, PAL["fog"])

        # Mid-far
        name, bldgs, bridges = self.layers[1]
        pfx = LAYER_CFG[name]["pfx"]
        for b in bldgs:
            render_body(canvas, b, pfx)
        for b in bldgs:
            render_static_windows(canvas, b)
        render_bridges(canvas, bridges, pfx)

        # Mid
        name, bldgs, bridges = self.layers[2]
        pfx = LAYER_CFG[name]["pfx"]
        for b in bldgs:
            render_body(canvas, b, pfx)
        for b in bldgs:
            render_static_windows(canvas, b)
        render_bridges(canvas, bridges, pfx)

        # Near
        name, bldgs, bridges = self.layers[3]
        pfx = LAYER_CFG[name]["pfx"]
        for b in bldgs:
            render_body(canvas, b, pfx)
        for b in bldgs:
            render_static_windows(canvas, b)
        render_bridges(canvas, bridges, pfx)

        # Atmospheric overlays
        self._render_atmo_band(canvas, int(150 * r), int(50 * r), 0.15, PAL["fog_l"])
        self._render_atmo_band(canvas, int(280 * r), int(55 * r), 0.55, PAL["cl_m"])
        self._render_atmo_band(canvas, int(460 * r), int(35 * r), 0.12, PAL["fog"])

        # Neon signs (static frame t=1.5)
        t = 1.5
        for bx, by, sign in self.all_neon:
            render_neon_sign(canvas, bx, by, sign, t)

        # Rain (one static pass)
        rain_c = np.array(PAL["rain"], dtype=np.float32)
        rain_b = np.array(PAL["rain_b"], dtype=np.float32)
        for drop in self.rain_drops:
            dx, dy = drop["x"], drop["y"]
            length = drop["length"]
            color = rain_b if drop["bright"] else rain_c
            alpha = 0.45 if drop["bright"] else 0.25
            for i in range(length):
                rx = int(dx + i * drop["wind"] * 0.3)
                ry = int(dy - i)
                if 0 <= rx < self.W and 0 <= ry < self.H:
                    base = canvas[ry, rx].astype(np.float32)
                    canvas[ry, rx] = (base * (1 - alpha) + color * alpha).astype(np.uint8)

        # Scanlines
        canvas[::3] = (canvas[::3].astype(np.float32) * 0.93).astype(np.uint8)

        # Vignette
        y_c = np.linspace(-1, 1, self.H, dtype=np.float32).reshape(-1, 1, 1)
        x_c = np.linspace(-1, 1, self.W, dtype=np.float32).reshape(1, -1, 1)
        vignette = np.clip(1.0 - 0.25 * (x_c ** 2 + y_c ** 2), 0.65, 1.0)
        canvas = (canvas.astype(np.float32) * vignette).astype(np.uint8)

        return canvas

    def render(self):
        """Return PIL Image of the scene."""
        return Image.fromarray(self.bg.copy())


# =============================================================================
# TEXT OVERLAY HELPERS
# =============================================================================

def get_font(name, size):
    path = os.path.join(FONT_DIR, name)
    try:
        return ImageFont.truetype(path, size)
    except Exception:
        return ImageFont.load_default()


def draw_glow_text(draw, x, y, text, font, color, glow_color, glow_r=8, anchor="lt"):
    """Draw text with multi-layer glow."""
    # Create glow on temp image
    tmp = Image.new("RGBA", draw.im.size, (0, 0, 0, 0))
    td = ImageDraw.Draw(tmp)
    gc = glow_color + (180,) if len(glow_color) == 3 else glow_color
    # Multiple offset glow passes
    for dx in range(-glow_r, glow_r + 1, 2):
        for dy in range(-glow_r, glow_r + 1, 2):
            if dx*dx + dy*dy <= glow_r*glow_r:
                td.text((x + dx, y + dy), text, font=font, fill=gc, anchor=anchor)
    blurred = tmp.filter(ImageFilter.GaussianBlur(glow_r // 2))
    draw._image.paste(blurred, (0, 0), blurred)
    # Core text
    draw.text((x, y), text, font=font, fill=color + (255,) if len(color) == 3 else color, anchor=anchor)


# =============================================================================
# FEATURE GRAPHIC  1024×500
# =============================================================================

def make_feature_graphic():
    print("\n=== Feature Graphic (1024×500) ===")

    # Render at 512×250, then 2x upscale to 1024×500
    NATIVE_W, NATIVE_H = 512, 250
    SCALE = 2

    scene = StoreScene(NATIVE_W, NATIVE_H, seed=77)
    img_native = scene.render()

    # Scale up with NEAREST for authentic pixel art
    img = img_native.resize((1024, 500), Image.NEAREST)

    # Convert to RGBA for compositing
    img = img.convert("RGBA")

    # --- Dark overlay on top third for text legibility ---
    overlay = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for y in range(160):
        a = int(120 * (1 - y / 160))
        od.line([(0, y), (1023, y)], fill=(5, 0, 18, a))
    img = Image.alpha_composite(img, overlay)

    # --- Text overlays ---
    draw = ImageDraw.Draw(img)

    # "BIOHACKER" - large, cyan, top area
    font_title = get_font("PixelifySans-Medium.ttf", 96)
    font_sub   = get_font("JetBrainsMono-Bold.ttf", 28)
    font_tiny  = get_font("GeistMono-Bold.ttf", 18)

    # Title: centered horizontally, y=24
    title_x = 512  # center
    title_y = 28

    # Draw glow
    glow_tmp = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_tmp)
    for r in [20, 14, 8]:
        alpha = int(80 * (1 - r / 20))
        for dx in range(-r, r+1, 3):
            for dy in range(-r, r+1, 3):
                if dx*dx + dy*dy <= r*r:
                    gd.text((title_x + dx, title_y + dy), "BIOHACKER",
                             font=font_title, fill=(0, 255, 255, alpha), anchor="mt")
    glow_blurred = glow_tmp.filter(ImageFilter.GaussianBlur(10))
    img = Image.alpha_composite(img, glow_blurred)
    draw = ImageDraw.Draw(img)
    draw.text((title_x, title_y), "BIOHACKER", font=font_title,
               fill=(0, 255, 255, 255), anchor="mt")

    # Subtitle: "OWN YOUR BIOLOGY" in amber
    sub_y = title_y + 104
    glow_tmp2 = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
    gd2 = ImageDraw.Draw(glow_tmp2)
    for dx in range(-6, 7, 2):
        for dy in range(-6, 7, 2):
            if dx*dx + dy*dy <= 36:
                gd2.text((title_x + dx, sub_y + dy), "OWN YOUR BIOLOGY",
                          font=font_sub, fill=(255, 179, 0, 120), anchor="mt")
    glow_blurred2 = glow_tmp2.filter(ImageFilter.GaussianBlur(5))
    img = Image.alpha_composite(img, glow_blurred2)
    draw = ImageDraw.Draw(img)
    draw.text((title_x, sub_y), "OWN YOUR BIOLOGY",
               font=font_sub, fill=(255, 200, 60, 255), anchor="mt")

    # URL bottom-right
    draw.text((1008, 480), "biohacker.systems",
               font=font_tiny, fill=(0, 200, 220, 160), anchor="rb")

    # Thin cyan line under title
    draw.line([(title_x - 220, title_y + 100), (title_x + 220, title_y + 100)],
               fill=(0, 200, 255, 80), width=1)

    # Final: convert to RGB and save
    final = img.convert("RGB")
    out_path = os.path.join(OUT_DIR, "feature_graphic_final.png")
    final.save(out_path)
    print(f"  Saved: {out_path}  ({final.size[0]}×{final.size[1]})")
    return final


# =============================================================================
# APP ICON  1024×1024
# =============================================================================

def make_app_icon():
    print("\n=== App Icon (1024×1024) ===")

    # Render at 256×256, then 4x upscale to 1024×1024
    NATIVE_W, NATIVE_H = 256, 256
    SCALE = 4

    scene = StoreScene(NATIVE_W, NATIVE_H, seed=42)
    img_native = scene.render()

    # Scale up with NEAREST for pixel art look
    img = img_native.resize((1024, 1024), Image.NEAREST)
    img = img.convert("RGBA")

    # --- Strong vignette for icon (darkens corners/edges) ---
    vign = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vign)
    center_x, center_y = 512, 512
    for r in range(0, 600, 4):
        dist = r / 600
        alpha = int(min(255, dist * dist * 200))
        vd.ellipse([center_x - r, center_y - r, center_x + r, center_y + r],
                   outline=(0, 0, 0, alpha), width=4)
    img = Image.alpha_composite(img, vign)

    # --- Dramatic bottom bar with "BIOHACKER" ---
    # Semi-transparent dark strip at bottom
    bar = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bar)
    for y in range(880, 1024):
        a = int(200 * ((y - 880) / 144))
        bd.line([(0, y), (1023, y)], fill=(3, 0, 12, a))
    img = Image.alpha_composite(img, bar)

    # Tiny "BIOHACKER" text at the very bottom
    draw = ImageDraw.Draw(img)
    font_icon = get_font("PixelifySans-Medium.ttf", 48)

    glow_tmp = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow_tmp)
    for dx in range(-10, 11, 3):
        for dy in range(-10, 11, 3):
            if dx*dx + dy*dy <= 100:
                gd.text((512 + dx, 980 + dy), "BIOHACKER",
                         font=font_icon, fill=(0, 255, 255, 100), anchor="mb")
    glow_blurred = glow_tmp.filter(ImageFilter.GaussianBlur(8))
    img = Image.alpha_composite(img, glow_blurred)
    draw = ImageDraw.Draw(img)
    draw.text((512, 980), "BIOHACKER",
               font=font_icon, fill=(0, 235, 255, 230), anchor="mb")

    # Cyan accent line above text
    draw.line([(312, 935), (712, 935)], fill=(0, 200, 255, 120), width=2)

    # Final save
    final = img.convert("RGB")
    out_path = os.path.join(OUT_DIR, "icon_final.png")
    final.save(out_path)
    print(f"  Saved: {out_path}  ({final.size[0]}×{final.size[1]})")
    return final


# =============================================================================
# MAIN
# =============================================================================

if __name__ == "__main__":
    print("BIOHACKER Store Assets Generator")
    print("=" * 50)
    feature = make_feature_graphic()
    icon = make_app_icon()
    print("\n✓ Done!")
    print(f"  Feature graphic: {feature.size}")
    print(f"  App icon:        {icon.size}")
