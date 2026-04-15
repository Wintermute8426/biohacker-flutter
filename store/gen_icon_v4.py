#!/usr/bin/env python3
"""
BIOHACKER App Icon v4 - High-Fidelity Pixel Art
Waneella/Kirokaze-style cinematic pixel art — 1024x1024 PNG
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math

# ─────────────────────────────────────────────
# CONSTANTS
# ─────────────────────────────────────────────
SIZE = 1024
HALF = SIZE // 2
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"

# Work at half res for pixel art, then scale up 2x with NEAREST
WORK = 512
WH = WORK // 2

# ─────────────────────────────────────────────
# COLOR PALETTE (neon cyberpunk)
# ─────────────────────────────────────────────
BG           = (0,   0,   0,   255)

# Magenta (left brain)
MAG_H        = (255, 30,  230, 255)   # hot highlight
MAG_MID      = (210, 0,   160, 255)   # main body
MAG_DARK     = (110, 0,   70,  255)   # sulcus shadow
MAG_DEEP     = (45,  0,   30,  255)   # deepest shadow

# Neon green (right brain)
GRN_H        = (80,  255, 120, 255)   # hot highlight
GRN_MID      = (0,   200, 70,  255)   # main body
GRN_DARK     = (0,   90,  30,  255)   # sulcus shadow
GRN_DEEP     = (0,   35,  15,  255)   # deepest shadow

# Bitcoin gold
BTC_H        = (255, 230, 60,  255)
BTC_MID      = (230, 170, 0,   255)
BTC_DARK     = (160, 100, 0,   255)

# Cyan text
CYN_H        = (0,   255, 255, 255)
CYN_MID      = (0,   200, 220, 255)

# Circuit trace (barely visible)
CIRCUIT      = (0,   25,  20,  255)

# ─────────────────────────────────────────────
# PIXEL GRID SNAP (2-px grid in WORK space)
# ─────────────────────────────────────────────
PG = 2  # pixel grid size in WORK space
def sg(v): return int(round(v / PG) * PG)

# ─────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────

def fill_alpha(img: Image.Image, color_rgb):
    """Fill a layer with a solid color where alpha > 0"""
    arr = np.array(img).astype(np.float32)
    out = np.zeros_like(arr)
    out[..., 0] = color_rgb[0]
    out[..., 1] = color_rgb[1]
    out[..., 2] = color_rgb[2]
    out[..., 3] = arr[..., 3]
    return Image.fromarray(out.astype(np.uint8))

def glow_layer(layer_rgba: Image.Image, blur: float, alpha: float = 1.0) -> Image.Image:
    """Return a blurred glow copy of the layer"""
    g = layer_rgba.filter(ImageFilter.GaussianBlur(blur))
    arr = np.array(g).astype(np.float32)
    arr[..., 3] = (arr[..., 3] * alpha).clip(0, 255)
    return Image.fromarray(arr.astype(np.uint8))

def alpha_compose(base: Image.Image, overlay: Image.Image) -> Image.Image:
    return Image.alpha_composite(base, overlay)

def add_glow(base: Image.Image, element: Image.Image,
             blurs=(8, 20, 40), alphas=(1.0, 0.7, 0.4)) -> Image.Image:
    """Add multi-pass glow to base from element layer"""
    for blur, alpha in zip(blurs, alphas):
        g = glow_layer(element, blur, alpha)
        base = alpha_compose(base, g)
    base = alpha_compose(base, element)  # sharp on top
    return base

# ─────────────────────────────────────────────
# BRAIN SHAPE
# ─────────────────────────────────────────────

def brain_outline_points(cx, cy, W, H, n=400):
    """
    Generate outer brain silhouette points.
    cx,cy = center; W,H = semi-axes; n = point count
    Returns list of (x,y) tuples.
    """
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        # Base ellipse
        bx = W * math.cos(t)
        by = H * math.sin(t)
        # Add gyrus bumps (asymmetric sinusoids)
        bump = (
            0.07 * math.sin(3*t + 0.5) +
            0.05 * math.sin(5*t + 1.2) +
            0.04 * math.sin(7*t + 0.8) +
            0.03 * math.sin(9*t + 2.1) +
            0.02 * math.sin(11*t + 3.0) +
            0.015 * math.sin(13*t + 1.7)
        )
        # Flatten the bottom (temporal region)
        if by > 0:
            by_flat = by * (1.0 - 0.18 * (by / H) ** 2)
        else:
            by_flat = by
        r = 1.0 + bump
        x = cx + r * bx
        y = cy + r * by_flat
        pts.append((sg(x), sg(y)))
    return pts

def gyrus_contour_points(cx, cy, W, H, n=400, scale=1.0):
    """
    Inner contour at given scale (0=center, 1=outer boundary).
    """
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        bx = W * math.cos(t)
        by = H * math.sin(t)
        bump = (
            0.07 * math.sin(3*t + 0.5) +
            0.05 * math.sin(5*t + 1.2) +
            0.04 * math.sin(7*t + 0.8) +
            0.03 * math.sin(9*t + 2.1) +
            0.02 * math.sin(11*t + 3.0) +
            0.015 * math.sin(13*t + 1.7)
        )
        if by > 0:
            by_flat = by * (1.0 - 0.18 * (by / H) ** 2)
        else:
            by_flat = by
        r = scale * (1.0 + bump)
        x = cx + r * bx
        y = cy + r * by_flat
        pts.append((sg(x), sg(y)))
    return pts

# ─────────────────────────────────────────────
# BITCOIN SYMBOL (pixel art)
# ─────────────────────────────────────────────

def draw_bitcoin_pixel(draw: ImageDraw.ImageDraw, cx, cy, size, color_h, color_m, color_d):
    """
    Draw ₿ symbol in pixel art style.
    size: radius-equivalent size
    """
    s = size
    lw = max(2, sg(s * 0.14))   # line width for strokes
    
    # Vertical bars (two serifs top and bottom)
    bar_x_l = sg(cx - s * 0.12)
    bar_x_r = sg(cx + s * 0.12)
    top_y    = sg(cy - s * 0.60)
    bot_y    = sg(cy + s * 0.60)
    serif_h  = sg(s * 0.12)
    
    # Main vertical bar (left)
    draw.rectangle([bar_x_l - lw, top_y - serif_h, bar_x_l + lw, bot_y + serif_h], fill=color_h)
    # Main vertical bar (right) — same for ₿
    draw.rectangle([bar_x_r - lw, top_y - serif_h, bar_x_r + lw, bot_y + serif_h], fill=color_h)
    
    # Top bulge (upper B)
    upper_top    = sg(cy - s * 0.58)
    upper_mid    = sg(cy - s * 0.05)
    upper_right  = sg(cx + s * 0.55)
    rounding_u   = sg(s * 0.30)
    
    draw.rounded_rectangle(
        [bar_x_l - lw, upper_top, upper_right, upper_mid],
        radius=rounding_u, fill=color_m, outline=color_h, width=lw
    )
    
    # Bottom bulge (lower B) — slightly wider
    lower_mid    = sg(cy - s * 0.02)
    lower_bot    = sg(cy + s * 0.60)
    lower_right  = sg(cx + s * 0.62)
    rounding_l   = sg(s * 0.32)
    
    draw.rounded_rectangle(
        [bar_x_l - lw, lower_mid, lower_right, lower_bot],
        radius=rounding_l, fill=color_m, outline=color_h, width=lw
    )
    
    # Black hole inside upper bulge
    inner_pad = lw + sg(s * 0.06)
    draw.rounded_rectangle(
        [bar_x_l + lw + sg(s*0.05), upper_top + inner_pad,
         upper_right - inner_pad, upper_mid - inner_pad],
        radius=sg(rounding_u * 0.5), fill=(0, 0, 0, 255)
    )
    
    # Black hole inside lower bulge
    draw.rounded_rectangle(
        [bar_x_l + lw + sg(s*0.05), lower_mid + inner_pad,
         lower_right - inner_pad, lower_bot - inner_pad],
        radius=sg(rounding_l * 0.5), fill=(0, 0, 0, 255)
    )
    
    # Redraw vertical bars on top (so they show through)
    draw.rectangle([bar_x_l - lw, top_y - serif_h, bar_x_l + lw, bot_y + serif_h], fill=color_h)
    draw.rectangle([bar_x_l - lw*2, top_y - serif_h, bar_x_l + lw*2, top_y - serif_h + lw], fill=color_h)
    draw.rectangle([bar_x_l - lw*2, bot_y + serif_h - lw, bar_x_l + lw*2, bot_y + serif_h], fill=color_h)

# ─────────────────────────────────────────────
# CIRCUIT TRACES
# ─────────────────────────────────────────────

def draw_circuits(draw: ImageDraw.ImageDraw, W, H, color=CIRCUIT):
    """Draw subtle horizontal/vertical circuit traces in background"""
    rng = np.random.default_rng(42)
    n_traces = 18
    for _ in range(n_traces):
        x1 = sg(rng.integers(20, W - 20))
        y1 = sg(rng.integers(20, H - 20))
        # Decide direction
        if rng.random() > 0.5:
            # Horizontal then vertical (L-shape)
            x2 = sg(rng.integers(20, W - 20))
            draw.line([(x1, y1), (x2, y1)], fill=color, width=1)
            y2 = sg(rng.integers(20, H - 20))
            draw.line([(x2, y1), (x2, y2)], fill=color, width=1)
            # Corner dot
            draw.rectangle([x2-1, y1-1, x2+1, y1+1], fill=color)
        else:
            # Vertical then horizontal
            y2 = sg(rng.integers(20, H - 20))
            draw.line([(x1, y1), (x1, y2)], fill=color, width=1)
            x2 = sg(rng.integers(20, W - 20))
            draw.line([(x1, y2), (x2, y2)], fill=color, width=1)
            draw.rectangle([x1-1, y2-1, x1+1, y2+1], fill=color)

# ─────────────────────────────────────────────
# MAIN GENERATOR
# ─────────────────────────────────────────────

def build_icon():
    W, H = WORK, WORK
    
    # ── Canvas (RGBA) ──────────────────────────────────────────
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw   = ImageDraw.Draw(canvas)
    
    # ── Circuit traces (barely visible background detail) ──────
    draw_circuits(draw, W, H, color=(0, 28, 22, 255))
    
    # ── Brain placement ────────────────────────────────────────
    # Brain center: horizontally centered, vertically in upper ~60%
    bcx = WH          # 256
    bcy = sg(H * 0.40) # 204  → brain center
    bW  = sg(W * 0.40) # 204  → horizontal semi-axis
    bH  = sg(H * 0.33) # 168  → vertical semi-axis
    
    # ── 1) Outer brain mask ────────────────────────────────────
    brain_pts = brain_outline_points(bcx, bcy, bW, bH)
    
    brain_mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(brain_mask).polygon(brain_pts, fill=255)
    
    # ── 2) Draw gyri layers from outside in ───────────────────
    # We'll draw bands of color to simulate gyri (brain folds)
    # Each band = one gyrus. We alternate bright/dark to simulate ridges and grooves.
    
    n_gyri = 9  # number of gyrus rings
    
    # Layer for left brain (magenta)
    left_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    left_draw  = ImageDraw.Draw(left_layer)
    
    # Layer for right brain (green)
    right_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    right_draw  = ImageDraw.Draw(right_layer)
    
    for gi in range(n_gyri, 0, -1):
        scale = gi / n_gyri
        pts = gyrus_contour_points(bcx, bcy, bW, bH, scale=scale)
        
        # Alternate bright/dark for ridge/groove effect
        is_ridge = (gi % 2 == 0)
        
        if is_ridge:
            mag_col = MAG_MID
            grn_col = GRN_MID
        else:
            mag_col = MAG_DARK
            grn_col = GRN_DARK
        
        # Innermost 2 rings are deeper shadow
        if gi <= 2:
            mag_col = MAG_DEEP
            grn_col = GRN_DEEP
        
        # Outermost ring gets the highlight
        if gi == n_gyri:
            mag_col = MAG_H
            grn_col = GRN_H
        
        left_draw.polygon(pts,  fill=mag_col)
        right_draw.polygon(pts, fill=grn_col)
    
    # Highlight ridge lines (pixel art detail)
    for gi in range(n_gyri, 1, -2):
        scale_outer = gi / n_gyri
        scale_inner = (gi - 0.5) / n_gyri
        pts_out = gyrus_contour_points(bcx, bcy, bW, bH, scale=scale_outer)
        pts_inn = gyrus_contour_points(bcx, bcy, bW, bH, scale=scale_inner)
        # Draw the outline of each ring as a highlight band
        for layer_draw, col in [(left_draw, MAG_H), (right_draw, GRN_H)]:
            layer_draw.line(pts_out + [pts_out[0]], fill=col, width=1)
    
    # ── 3) Apply brain mask to both halves ────────────────────
    # Mask left half: only x < bcx
    left_mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(left_mask).polygon(brain_pts, fill=255)
    # Zero out right side
    lm_arr = np.array(left_mask)
    lm_arr[:, bcx:] = 0
    left_mask = Image.fromarray(lm_arr, mode="L")
    
    # Mask right half: only x >= bcx
    right_mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(right_mask).polygon(brain_pts, fill=255)
    rm_arr = np.array(right_mask)
    rm_arr[:, :bcx] = 0
    right_mask = Image.fromarray(rm_arr, mode="L")
    
    # Apply masks to layers
    ll_arr = np.array(left_layer)
    ll_arr[..., 3] = np.minimum(ll_arr[..., 3], np.array(left_mask))
    left_layer = Image.fromarray(ll_arr)
    
    rl_arr = np.array(right_layer)
    rl_arr[..., 3] = np.minimum(rl_arr[..., 3], np.array(right_mask))
    right_layer = Image.fromarray(rl_arr)
    
    # ── 4) Composite brain halves onto canvas ─────────────────
    canvas = alpha_compose(canvas, left_layer)
    canvas = alpha_compose(canvas, right_layer)
    
    # ── 5) Central dividing line (bright split) ───────────────
    # Find where the brain outline crosses x=bcx to determine the vertical extent
    # Draw a bright line only inside the brain mask
    split_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    split_draw  = ImageDraw.Draw(split_layer)
    
    # Find top and bottom of brain at center x
    bm_arr = np.array(brain_mask)
    center_col = bm_arr[:, bcx]
    brain_rows = np.where(center_col > 0)[0]
    if len(brain_rows) > 0:
        brain_top = int(brain_rows[0])
        brain_bot = int(brain_rows[-1])
        split_draw.line([(bcx, brain_top), (bcx, brain_bot)], 
                        fill=(180, 50, 180, 255), width=2)
        split_draw.line([(bcx+2, brain_top), (bcx+2, brain_bot)],
                        fill=(50, 180, 50, 255), width=2)
    
    canvas = add_glow(canvas, split_layer, blurs=(4, 12), alphas=(0.8, 0.4))
    
    # ── 6) Add neon glow to brain halves ─────────────────────
    # Glow for left half
    canvas = add_glow(canvas, left_layer,  blurs=(6, 18, 35), alphas=(0.6, 0.4, 0.2))
    canvas = add_glow(canvas, right_layer, blurs=(6, 18, 35), alphas=(0.6, 0.4, 0.2))
    
    # ── 7) Bitcoin ₿ symbol ────────────────────────────────────
    btc_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    btc_draw  = ImageDraw.Draw(btc_layer)
    
    btc_cx = bcx
    btc_cy = bcy
    btc_sz = sg(bH * 0.70)  # radius-equivalent size
    
    draw_bitcoin_pixel(btc_draw, btc_cx, btc_cy, btc_sz,
                       BTC_H, BTC_MID, BTC_DARK)
    
    # Mask bitcoin to brain interior
    btc_arr = np.array(btc_layer)
    btc_arr[..., 3] = np.minimum(btc_arr[..., 3], np.array(brain_mask))
    btc_layer = Image.fromarray(btc_arr)
    
    # Glow then composite
    canvas = add_glow(canvas, btc_layer, blurs=(4, 12, 25), alphas=(0.9, 0.6, 0.3))
    
    # ── 8) "BIOHACKER" text ───────────────────────────────────
    text_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    text_draw  = ImageDraw.Draw(text_layer)
    
    text = "BIOHACKER"
    
    # Try Silkscreen (pixel font), fall back to DejaVu Mono
    try:
        font = ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf", size=28)
    except:
        try:
            font = ImageFont.truetype(f"{FONT_DIR}/JetBrainsMono-Bold.ttf", size=26)
        except:
            font = ImageFont.load_default()
    
    bbox = text_draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    
    # Position text below brain
    text_y = sg(brain_bot + sg(H * 0.04)) if len(brain_rows) > 0 else sg(H * 0.78)
    text_x = sg(WH - tw // 2)
    
    # Draw with subtle letter spacing simulation: draw char by char
    text_draw.text((text_x, text_y), text, font=font, fill=CYN_H)
    
    # Glow text
    canvas = add_glow(canvas, text_layer, blurs=(3, 10, 22), alphas=(1.0, 0.7, 0.3))
    
    # ── 9) Scale up 2x with NEAREST (pixel art upscale) ───────
    canvas = canvas.resize((SIZE, SIZE), Image.NEAREST)
    
    # ── 10) Final glow refinement pass (at full 1024 res) ──────
    # Slight overall atmosphere
    atmo = canvas.filter(ImageFilter.GaussianBlur(2))
    atmo_arr = np.array(atmo).astype(np.float32)
    can_arr  = np.array(canvas).astype(np.float32)
    # Blend 10% atmosphere in
    blended  = (can_arr * 0.92 + atmo_arr * 0.08).clip(0, 255).astype(np.uint8)
    canvas   = Image.fromarray(blended)
    
    # Final composite: ensure pure black bg
    final = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    final.paste(canvas.convert("RGB"), (0, 0))
    
    return final

# ─────────────────────────────────────────────
# RUN
# ─────────────────────────────────────────────
if __name__ == "__main__":
    import os, sys
    out_path = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    
    print("Building BIOHACKER icon v4...")
    icon = build_icon()
    icon.save(out_path, "PNG")
    
    # Verify
    verify = Image.open(out_path)
    print(f"✅ Saved: {out_path}")
    print(f"   Size: {verify.size[0]}x{verify.size[1]} px")
    print(f"   Mode: {verify.mode}")
    print(f"   File: {os.path.getsize(out_path):,} bytes")
