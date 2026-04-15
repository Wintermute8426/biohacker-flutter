#!/usr/bin/env python3
"""
BIOHACKER App Icon v4b - HIGH FIDELITY Pixel Art
Waneella/Kirokaze-style cinematic neon — 1024x1024 PNG
Refined: larger brain, stronger glow, better composition
"""

import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageFont
import math

SIZE = 1024
FONT_DIR = "/home/wintermute/.openclaw/workspace/skills/canvas-design/canvas-fonts"

# Work at 512×512 for pixel art, then 2× NEAREST upscale
W, H = 512, 512
WH = W // 2

PG = 2
def sg(v): return max(0, int(round(v / PG) * PG))

# ── PALETTE ────────────────────────────────────────────────────────────────
MAG_BRIGHT   = (255, 20,  240, 255)
MAG_HOT      = (245, 0,   200, 255)
MAG_MID      = (200, 0,   155, 255)
MAG_DARK     = (100, 0,   70,  255)
MAG_DEEP     = (40,  0,   28,  255)
MAG_GLOW     = (255, 0,   210, 255)

GRN_BRIGHT   = (50,  255, 100, 255)
GRN_HOT      = (0,   240, 80,  255)
GRN_MID      = (0,   185, 60,  255)
GRN_DARK     = (0,   80,  28,  255)
GRN_DEEP     = (0,   30,  12,  255)
GRN_GLOW     = (0,   255, 80,  255)

BTC_BRIGHT   = (255, 235, 60,  255)
BTC_HOT      = (255, 200, 0,   255)
BTC_MID      = (220, 155, 0,   255)
BTC_DARK     = (140, 90,  0,   255)

CYN_BRIGHT   = (0,   255, 255, 255)
CYN_HOT      = (0,   240, 250, 255)
CYN_MID      = (0,   190, 210, 255)

CIRCUIT_COL  = (0,   35,  28,  255)

# ── HELPERS ────────────────────────────────────────────────────────────────

def glow_layer(layer, blur_r, alpha=1.0):
    g = layer.filter(ImageFilter.GaussianBlur(blur_r))
    a = np.array(g, dtype=np.float32)
    a[..., 3] = (a[..., 3] * alpha).clip(0, 255)
    return Image.fromarray(a.astype(np.uint8))

def composite(base, over):
    return Image.alpha_composite(base, over)

def add_glow(base, layer, blurs, alphas):
    for b, a in zip(blurs, alphas):
        base = composite(base, glow_layer(layer, b, a))
    return composite(base, layer)

# ── BRAIN CONTOUR ──────────────────────────────────────────────────────────

def brain_pts(cx, cy, rw, rh, scale=1.0, n=600):
    pts = []
    for i in range(n):
        t = 2 * math.pi * i / n
        bx = rw * math.cos(t)
        by = rh * math.sin(t)
        bump = (
            0.072 * math.sin(3*t + 0.52) +
            0.055 * math.sin(5*t + 1.25) +
            0.042 * math.sin(7*t + 0.83) +
            0.030 * math.sin(9*t + 2.14) +
            0.022 * math.sin(11*t + 3.00) +
            0.015 * math.sin(13*t + 1.70) +
            0.010 * math.sin(15*t + 0.50)
        )
        if by > 0:
            by = by * (1.0 - 0.20 * (by / rh) ** 2)
        r = scale * (1.0 + bump)
        pts.append((sg(cx + r * bx), sg(cy + r * by)))
    return pts

# ── BITCOIN SYMBOL ─────────────────────────────────────────────────────────

def draw_btc(canvas, cx, cy, sz):
    """Pixel-art ₿ on RGBA canvas. sz ≈ half-height of symbol."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    lw  = max(PG, sg(sz * 0.13))
    # Vertical bar x positions
    vx  = sg(cx - sz * 0.10)
    # Top and bottom of the whole symbol (with serif extensions)
    ty  = sg(cy - sz)
    by_ = sg(cy + sz)
    sfr = sg(sz * 0.12)   # serif extension past bulges

    # Upper bulge
    uy1 = sg(cy - sz)
    uy2 = sg(cy - sz * 0.04)
    ux2 = sg(cx + sz * 0.60)
    ur  = sg(sz * 0.34)

    # Lower bulge (wider)
    ly1 = sg(cy + sz * 0.02)
    ly2 = sg(cy + sz)
    lx2 = sg(cx + sz * 0.68)
    lr  = sg(sz * 0.36)

    # Draw bulges
    d.rounded_rectangle([vx - sg(sz*0.04), uy1, ux2, uy2], radius=ur,
                         fill=BTC_MID, outline=BTC_HOT, width=lw)
    d.rounded_rectangle([vx - sg(sz*0.04), ly1, lx2, ly2], radius=lr,
                         fill=BTC_MID, outline=BTC_HOT, width=lw)

    # Hollow out bulges (black interior)
    ip = lw + sg(sz * 0.06)
    d.rounded_rectangle([vx + lw + sg(sz*0.08), uy1 + ip, ux2 - ip, uy2 - ip],
                         radius=max(2, ur - ip), fill=(0, 0, 0, 255))
    d.rounded_rectangle([vx + lw + sg(sz*0.08), ly1 + ip, lx2 - ip, ly2 - ip],
                         radius=max(2, lr - ip), fill=(0, 0, 0, 255))

    # Vertical bar (redrawn on top)
    d.rectangle([vx - lw, ty - sfr, vx + lw, by_ + sfr], fill=BTC_BRIGHT)

    # Serifs (top and bottom)
    serif_w = sg(sz * 0.18)
    d.rectangle([vx - serif_w, ty - sfr, vx + serif_w, ty - sfr + lw], fill=BTC_BRIGHT)
    d.rectangle([vx - serif_w, by_ + sfr - lw, vx + serif_w, by_ + sfr], fill=BTC_BRIGHT)

    # Highlight dots (brightest pixels on ridges)
    for y_off in [sg(-sz*0.55), sg(-sz*0.25), sg(sz*0.15), sg(sz*0.50)]:
        d.rectangle([sg(cx + sz*0.20), sg(cy + y_off) - 1,
                     sg(cx + sz*0.20) + 2, sg(cy + y_off) + 1], fill=BTC_BRIGHT)

    return layer

# ── CIRCUIT TRACES ─────────────────────────────────────────────────────────

def draw_circuits(canvas_draw, rng):
    for _ in range(22):
        x1 = sg(rng.integers(10, W - 10))
        y1 = sg(rng.integers(10, H - 10))
        x2 = sg(rng.integers(10, W - 10))
        y2 = sg(rng.integers(10, H - 10))
        # L-shaped traces
        canvas_draw.line([(x1, y1), (x2, y1)], fill=CIRCUIT_COL, width=1)
        canvas_draw.line([(x2, y1), (x2, y2)], fill=CIRCUIT_COL, width=1)
        # Tiny dot at corner
        canvas_draw.rectangle([x2-1, y1-1, x2+1, y1+1], fill=(0, 50, 40, 255))
    # Extra horizontal runs
    for _ in range(8):
        y = sg(rng.integers(40, H - 40))
        x1 = sg(rng.integers(0, W // 3))
        x2 = sg(rng.integers(2*W//3, W))
        canvas_draw.line([(x1, y), (x2, y)], fill=CIRCUIT_COL, width=1)

# ── SCANLINES (subtle) ─────────────────────────────────────────────────────

def apply_scanlines(img_rgb: Image.Image) -> Image.Image:
    arr = np.array(img_rgb, dtype=np.float32)
    for y in range(0, arr.shape[0], 4):
        arr[y] = arr[y] * 0.92
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))

# ── ATMOSPHERIC VIGNETTE ───────────────────────────────────────────────────

def apply_vignette(img: Image.Image) -> Image.Image:
    arr = np.array(img, dtype=np.float32)
    ys = np.linspace(-1, 1, arr.shape[0])
    xs = np.linspace(-1, 1, arr.shape[1])
    xx, yy = np.meshgrid(xs, ys)
    dist = np.sqrt(xx**2 + yy**2)
    vignette = np.clip(1.0 - dist * 0.45, 0.55, 1.0)
    arr[..., :3] *= vignette[..., np.newaxis]
    return Image.fromarray(arr.clip(0, 255).astype(np.uint8))

# ── MAIN BUILD ─────────────────────────────────────────────────────────────

def build():
    rng = np.random.default_rng(99)

    # Working canvas at 512×512
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    draw   = ImageDraw.Draw(canvas)

    # ── Circuit background
    draw_circuits(draw, rng)

    # ── Brain parameters
    # Center brain at 40% height → leaves room for text below
    bcx = WH
    bcy = sg(H * 0.390)
    brw = sg(W * 0.425)   # wider
    brh = sg(H * 0.350)   # taller

    outer_pts = brain_pts(bcx, bcy, brw, brh)

    # Outer brain mask
    brain_mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(brain_mask).polygon(outer_pts, fill=255)
    bm = np.array(brain_mask)

    # Find brain extents
    brain_rows = np.where(bm[:, bcx] > 0)[0]
    brain_top  = int(brain_rows[0])  if len(brain_rows) else sg(H*0.07)
    brain_bot  = int(brain_rows[-1]) if len(brain_rows) else sg(H*0.72)

    # ── Gyri layers: draw from outside→in, alternating bright/dark
    n_gyri = 11

    def make_brain_half(is_left):
        layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ld    = ImageDraw.Draw(layer)
        
        if is_left:
            colors = [MAG_HOT, MAG_DARK, MAG_MID, MAG_DARK, MAG_MID,
                      MAG_DARK, MAG_MID, MAG_DARK, MAG_DEEP, MAG_DEEP, MAG_DEEP]
        else:
            colors = [GRN_HOT, GRN_DARK, GRN_MID, GRN_DARK, GRN_MID,
                      GRN_DARK, GRN_MID, GRN_DARK, GRN_DEEP, GRN_DEEP, GRN_DEEP]
        
        # Draw rings from outermost to innermost
        for gi in range(n_gyri, 0, -1):
            sc    = gi / n_gyri
            pts   = brain_pts(bcx, bcy, brw, brh, scale=sc)
            col   = colors[gi - 1]
            ld.polygon(pts, fill=col)
        
        # Highlight outlines on ridges (pixel art fold lines)
        h_col = MAG_BRIGHT if is_left else GRN_BRIGHT
        for gi in range(n_gyri, 1, -2):
            sc  = gi / n_gyri
            pts = brain_pts(bcx, bcy, brw, brh, scale=sc)
            ld.line(pts + [pts[0]], fill=h_col, width=1)
        
        # Apply half-mask
        half_mask = bm.copy()
        if is_left:
            half_mask[:, bcx:] = 0
        else:
            half_mask[:, :bcx] = 0
        la = np.array(layer)
        la[..., 3] = np.minimum(la[..., 3], half_mask)
        return Image.fromarray(la)

    left_layer  = make_brain_half(True)
    right_layer = make_brain_half(False)

    # Composite brain base
    canvas = composite(canvas, left_layer)
    canvas = composite(canvas, right_layer)

    # ── Medial split line
    split = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd    = ImageDraw.Draw(split)
    sd.line([(bcx,   brain_top), (bcx,   brain_bot)], fill=(160, 0, 160, 255), width=2)
    sd.line([(bcx+2, brain_top), (bcx+2, brain_bot)], fill=(0, 160, 0,   255), width=2)
    canvas = add_glow(canvas, split, [3, 10], [0.9, 0.4])

    # ── Brain halves glow (neon bloom)
    canvas = add_glow(canvas, left_layer,  [5, 15, 32], [0.55, 0.35, 0.15])
    canvas = add_glow(canvas, right_layer, [5, 15, 32], [0.55, 0.35, 0.15])

    # ── Bitcoin symbol
    btc_layer = draw_btc(canvas, bcx, bcy, sz=sg(brh * 0.62))
    # Mask to brain
    btc_a = np.array(btc_layer)
    btc_a[..., 3] = np.minimum(btc_a[..., 3], bm)
    btc_layer = Image.fromarray(btc_a)

    canvas = add_glow(canvas, btc_layer, [3, 10, 22, 38], [1.0, 0.7, 0.45, 0.2])

    # ── BIOHACKER text ─────────────────────────────────────────
    text_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    td         = ImageDraw.Draw(text_layer)

    text = "BIOHACKER"
    font_size = 29

    try:
        font = ImageFont.truetype(f"{FONT_DIR}/Silkscreen-Regular.ttf", size=font_size)
    except Exception:
        try:
            font = ImageFont.truetype(f"{FONT_DIR}/JetBrainsMono-Bold.ttf", size=font_size)
        except Exception:
            font = ImageFont.load_default()

    bbox = td.textbbox((0, 0), text, font=font)
    tw   = bbox[2] - bbox[0]
    th   = bbox[3] - bbox[1]

    # Position: vertically centered in the space below brain
    space_top = brain_bot + sg(H * 0.03)
    space_bot = H - sg(H * 0.05)
    ty        = sg(space_top + (space_bot - space_top - th) / 2)
    tx        = sg(WH - tw // 2)

    # Shadow/depth layer first
    td.text((tx+2, ty+2), text, font=font, fill=(0, 60, 70, 200))
    # Main text
    td.text((tx, ty), text, font=font, fill=CYN_BRIGHT)

    # Pixel-bright: add individual bright pixels on top of each char for shimmer
    # (a simple highlight row at the top of each glyph)
    for i, ch in enumerate(text):
        cb = td.textbbox((tx, ty), text[:i+1], font=font)
        px_x = cb[2] - 3
        td.rectangle([px_x, ty, px_x+1, ty+2], fill=(255, 255, 255, 200))

    canvas = add_glow(canvas, text_layer, [2, 8, 18], [1.0, 0.75, 0.35])

    # ── Extra atmosphere: subtle green/magenta edge light on brain outline
    outline_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ol_d = ImageDraw.Draw(outline_layer)
    # Left rim
    ol_d.line(brain_pts(bcx, bcy, brw, brh)[:len(brain_pts(bcx, bcy, brw, brh))//2] +
              [brain_pts(bcx, bcy, brw, brh)[0]],
              fill=MAG_GLOW, width=2)
    # Right rim
    half = len(brain_pts(bcx, bcy, brw, brh))
    full_pts = brain_pts(bcx, bcy, brw, brh)
    ol_d.line(full_pts[half//2:] + [full_pts[0]], fill=GRN_GLOW, width=2)
    # Mask to brain boundary (just outside)
    expanded = brain_mask.filter(ImageFilter.MaxFilter(5))
    ol_a = np.array(outline_layer)
    ol_a[..., 3] = np.minimum(ol_a[..., 3], np.array(expanded))
    outline_layer = Image.fromarray(ol_a)
    canvas = add_glow(canvas, outline_layer, [2, 8], [0.8, 0.4])

    # ── Scale up 2× (NEAREST = pixel art look) ────────────────
    canvas = canvas.resize((SIZE, SIZE), Image.NEAREST)

    # ── Final atmosphere & scanlines (at full 1024) ────────────
    # Vignette
    rgb = canvas.convert("RGB")
    rgb = apply_vignette(rgb)

    # Very slight bloom pass
    bloom = rgb.filter(ImageFilter.GaussianBlur(3))
    r1    = np.array(rgb,   dtype=np.float32)
    r2    = np.array(bloom, dtype=np.float32)
    mixed = (r1 * 0.88 + r2 * 0.12).clip(0, 255).astype(np.uint8)
    rgb   = Image.fromarray(mixed)

    # Subtle scanlines
    rgb = apply_scanlines(rgb)

    return rgb

# ── RUN ────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import os
    out = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/play_store_icon_v4.png"
    print("Building BIOHACKER icon v4b...")
    icon = build()
    icon.save(out, "PNG", optimize=False, compress_level=6)

    from PIL import Image as _I
    v = _I.open(out)
    print(f"Saved  : {out}")
    print(f"Size   : {v.size[0]}x{v.size[1]}")
    print(f"Mode   : {v.mode}")
    print(f"Bytes  : {os.path.getsize(out):,}")
