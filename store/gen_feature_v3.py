#!/usr/bin/env python3
"""
Feature Graphic v3 - Sovereign Noir (refined)
Cinematic pixel art: rain-soaked cyberpunk street, hooded figure, biohacker HUD
1024x500px PNG
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageEnhance
import math
import random
import os

FONT_DIR = os.path.expanduser("~/.openclaw/workspace/skills/canvas-design/canvas-fonts")
OUT_PATH = "/home/wintermute/.openclaw/workspace/biohacker-flutter/store/feature_graphic_v3.png"

W, H = 1024, 500

# Color palette
BG_DEEP = (8, 0, 22)
BG_PURPLE = (22, 0, 42)
CYAN = (0, 255, 255)
MAGENTA = (255, 0, 255)
AMBER = (255, 179, 0)
DARK_CYAN = (0, 140, 160)
DIM_CYAN = (0, 90, 110)
NEON_PINK = (255, 40, 160)
NEON_GREEN = (40, 220, 120)
NEON_BLUE = (40, 80, 255)
WARM_WHITE = (255, 240, 200)

random.seed(42)
FONT_CACHE = {}

def get_font(name, size):
    key = (name, size)
    if key not in FONT_CACHE:
        try:
            FONT_CACHE[key] = ImageFont.truetype(os.path.join(FONT_DIR, name), size)
        except:
            FONT_CACHE[key] = ImageFont.load_default()
    return FONT_CACHE[key]

def lerp(a, b, t):
    return a + (b - a) * t

def lerp_color(c1, c2, t):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(len(c1)))

def draw_text_glow(draw, x, y, text, font, color, glow_color, glow_radius=6):
    """Draw text with glow effect."""
    # Glow passes
    for r in range(glow_radius, 0, -1):
        alpha = int(120 * (1 - r / glow_radius))
        gc = tuple(min(255, int(c * alpha / 255)) for c in glow_color[:3])
        for dx in range(-r, r+1, max(1, r//2)):
            for dy in range(-r, r+1, max(1, r//2)):
                draw.text((x+dx, y+dy), text, font=font, fill=gc)
    draw.text((x, y), text, font=font, fill=color)

# ─── Background sky gradient ──────────────────────────────────────────────────
def draw_sky(draw):
    for y in range(H):
        t = y / H
        if t < 0.5:
            sky_t = t / 0.5
            # Deep space blue-black to deep purple
            col = lerp_color((5, 0, 18), (20, 0, 40), sky_t)
        else:
            col = lerp_color((20, 0, 40), (12, 0, 28), (t - 0.5) / 0.5)
        draw.line([(0, y), (W, y)], fill=col)

# ─── Stars ────────────────────────────────────────────────────────────────────
def draw_stars(draw):
    rng = random.Random(7)
    for _ in range(180):
        x = rng.randint(0, W)
        y = rng.randint(0, int(H * 0.38))
        b = rng.randint(50, 180)
        tint = rng.choice([(b, b, b), (b, int(b*0.7), b), (int(b*0.6), b, b)])
        size = rng.choice([1, 1, 1, 2])
        if size == 1:
            draw.point((x, y), fill=tint)
        else:
            draw.ellipse([x-1, y-1, x+1, y+1], fill=tint)

# ─── Buildings ────────────────────────────────────────────────────────────────
def draw_buildings(img, draw):
    """Architectural building silhouettes with grid windows."""
    
    vp_x, vp_y = W // 2, int(H * 0.40)
    
    # Define buildings as rectangles (x, top_y, width, but use perspective)
    # Left buildings: anchored to left edge, varying heights
    left_bldgs = [
        # (x_left, x_right, top_y, color, window_color)
        (0,   95,  int(H*0.06),  (12,3,25),  (200,140,80)),    # foreground far left
        (65,  160, int(H*0.03),  (8,2,18),   (140,200,255)),
        (130, 230, int(H*0.10),  (15,4,30),  (255,160,80)),
        (190, 280, int(H*0.01),  (10,3,22),  (180,140,255)),
        (250, 330, int(H*0.07),  (6,2,15),   (100,220,200)),
        (0,   60,  int(H*0.15),  (18,5,35),  (220,100,160)),    # tall left
    ]
    
    right_bldgs = [
        (W-95,  W,     int(H*0.06),  (12,3,25),  (200,140,80)),
        (W-160, W-65,  int(H*0.03),  (8,2,18),   (140,200,255)),
        (W-230, W-130, int(H*0.10),  (15,4,30),  (255,160,80)),
        (W-280, W-190, int(H*0.01),  (10,3,22),  (180,140,255)),
        (W-330, W-250, int(H*0.07),  (6,2,15),   (100,220,200)),
        (W-60,  W,     int(H*0.15),  (18,5,35),  (220,100,160)),
    ]
    
    ground_y = int(H * 0.60)
    
    for bldg_list in [left_bldgs, right_bldgs]:
        for (x0, x1, top_y, bldg_col, win_col) in bldg_list:
            # Draw building body
            draw.rectangle([x0, top_y, x1, ground_y], fill=bldg_col)
            
            # Roof detail line
            draw.line([(x0, top_y), (x1, top_y)], fill=tuple(c+8 for c in bldg_col), width=1)
            
            # Window grid
            w_size = 5
            w_gap_x = 10
            w_gap_y = 8
            
            rng = random.Random(x0 * 31 + top_y)
            
            for wy in range(top_y + 12, ground_y - 5, w_gap_y):
                for wx in range(x0 + 8, x1 - 8, w_gap_x):
                    if rng.random() > 0.35:
                        # Lit window
                        brightness = rng.uniform(0.5, 1.0)
                        wc = tuple(int(c * brightness) for c in win_col)
                        draw.rectangle([wx, wy, wx+w_size, wy+w_size-1], fill=wc)
                    else:
                        # Dark window
                        draw.rectangle([wx, wy, wx+w_size, wy+w_size-1],
                                      fill=tuple(max(0, c-2) for c in bldg_col))
    
    # Building edge shadows (vertical gradient on inner edges)
    for x in range(250, 350):
        t = (x - 250) / 100
        alpha = int(180 * (1 - t))
        shadow_col = (0, 0, 0)
        for y in range(0, ground_y):
            # Existing pixel
            px = img.getpixel((x, y))
            blended = tuple(int(px[i] * (1 - alpha/255 * 0.3)) for i in range(3))
            img.putpixel((x, y), blended)

# ─── Neon Signs ───────────────────────────────────────────────────────────────
KANJI_SIGNS = [
    "バイオハッカー", "生体最適化", "解放強化", "身体データ",
    "制御革命", "神経電脳", "量子転写", "進化統制", "血液解析",
    "最適化", "生体強化", "転写進化",
]

def draw_neon_signs(img, draw):
    """Draw vertical kanji neon signs on building faces."""
    
    # Try Japanese fonts
    jp_font = None
    for fp in [
        "/usr/share/fonts/truetype/takao-gothic/TakaoGothic.ttf",
        "/usr/share/fonts/opentype/ipafont-gothic/ipag.ttf",
        "/usr/share/fonts/truetype/fonts-japanese-gothic.ttf",
        "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
    ]:
        if os.path.exists(fp):
            try:
                jp_font = ImageFont.truetype(fp, 16)
                print(f"  Using JP font: {fp}")
                break
            except:
                pass
    
    if jp_font is None:
        print("  No JP font found, using Latin fallback for signs")
        # Use pixel font for sign labels
        jp_font = get_font("PixelifySans-Medium.ttf", 12)
    
    sign_configs = [
        # LEFT SIDE
        {'x': 8,   'y': 60,  'text': "バイオハッカー", 'color': MAGENTA,   'bg': (40,0,60)},
        {'x': 40,  'y': 40,  'text': "生体最適化",    'color': CYAN,      'bg': (0,20,40)},
        {'x': 68,  'y': 75,  'text': "解放強化",      'color': NEON_PINK,  'bg': (40,0,30)},
        {'x': 96,  'y': 50,  'text': "身体データ",    'color': AMBER,     'bg': (40,25,0)},
        {'x': 124, 'y': 80,  'text': "制御革命",      'color': MAGENTA,   'bg': (40,0,60)},
        {'x': 152, 'y': 45,  'text': "神経電脳",      'color': CYAN,      'bg': (0,20,40)},
        # Horizontal box signs
        {'x': 5,   'y': 240, 'text': "量子転写",      'color': NEON_PINK,  'bg': (40,0,30), 'horiz': True},
        {'x': 5,   'y': 272, 'text': "進化統制",      'color': AMBER,     'bg': (40,25,0), 'horiz': True},
        
        # RIGHT SIDE
        {'x': W-30,  'y': 55, 'text': "バイオ革命",   'color': CYAN,      'bg': (0,20,40)},
        {'x': W-58,  'y': 70, 'text': "生体強化",     'color': MAGENTA,   'bg': (40,0,60)},
        {'x': W-86,  'y': 40, 'text': "電脳解放",     'color': AMBER,     'bg': (40,25,0)},
        {'x': W-114, 'y': 80, 'text': "量子統制",     'color': NEON_PINK,  'bg': (40,0,30)},
        {'x': W-142, 'y': 55, 'text': "神経転写",     'color': CYAN,      'bg': (0,20,40)},
        {'x': W-170, 'y': 100,'text': "最適化強",     'color': MAGENTA,   'bg': (40,0,60)},
        # Horizontal box signs
        {'x': W-220, 'y': 235,'text': "最適化強",     'color': NEON_GREEN, 'bg': (0,30,15), 'horiz': True},
        {'x': W-215, 'y': 268,'text': "身体制御",     'color': AMBER,     'bg': (40,25,0), 'horiz': True},
    ]
    
    glow_layer = Image.new('RGBA', (W, H), (0,0,0,0))
    glow_draw = ImageDraw.Draw(glow_layer)
    
    for cfg in sign_configs:
        col = cfg['color']
        glow_c = tuple(c // 3 for c in col)
        horiz = cfg.get('horiz', False)
        
        if horiz:
            # Horizontal sign box
            bbox = draw.textbbox((0,0), cfg['text'], font=jp_font)
            tw = bbox[2] - bbox[0]
            th = bbox[3] - bbox[1]
            padding = 5
            bx0, by0 = cfg['x'], cfg['y']
            bx1, by1 = bx0 + tw + padding*2, by0 + th + padding*2
            
            # Box background
            draw.rectangle([bx0, by0, bx1, by1], fill=cfg['bg'])
            draw.rectangle([bx0, by0, bx1, by1], outline=col, width=1)
            draw.rectangle([bx0-1, by0-1, bx1+1, by1+1], outline=tuple(c//3 for c in col), width=1)
            
            # Glow
            for r in [6, 3, 1]:
                glow_draw.rectangle([bx0-r, by0-r, bx1+r, by1+r],
                                   outline=(*col, 40//r), width=r)
            
            draw.text((bx0+padding, by0+padding), cfg['text'], font=jp_font, fill=col)
        else:
            # Vertical sign
            y = cfg['y']
            char_h = 20
            
            for char in cfg['text']:
                # Glow behind char
                for dx, dy in [(-2,0),(2,0),(0,-2),(0,2)]:
                    glow_draw.text((cfg['x']+dx, y+dy), char, font=jp_font,
                                  fill=(*glow_c, 100))
                draw.text((cfg['x'], y), char, font=jp_font, fill=col)
                y += char_h
    
    # Blur glow and composite
    glow_blurred = glow_layer.filter(ImageFilter.GaussianBlur(radius=4))
    img.paste(glow_blurred, mask=glow_blurred)

# ─── Street ───────────────────────────────────────────────────────────────────
def draw_street(img, draw):
    """Wet reflective street with perspective and neon pools."""
    
    street_top = int(H * 0.60)
    vp_x = W // 2
    
    # Street base gradient
    for y in range(street_top, H):
        t = (y - street_top) / (H - street_top)
        col = lerp_color((10, 3, 22), (6, 1, 14), t)
        draw.line([(0, y), (W, y)], fill=col)
    
    # Perspective road lines
    road_x0_near = 0
    road_x1_near = W
    road_x0_far = int(vp_x * 0.35)
    road_x1_far = int(vp_x + (W - vp_x) * 0.65)
    
    # Curb lines  
    draw.line([(int(W*0.06), H), (int(vp_x*0.45), street_top + 5)],
             fill=(30, 10, 55), width=2)
    draw.line([(int(W*0.94), H), (int(vp_x + (W-vp_x)*0.55), street_top + 5)],
             fill=(30, 10, 55), width=2)
    
    # Center dashed line (very faint, far away)
    for seg_y in range(street_top + 30, H, 25):
        t = (seg_y - street_top) / (H - street_top)
        x_center = vp_x
        width_at_y = int(t * 3)
        draw.line([(x_center - width_at_y, seg_y), (x_center + width_at_y, seg_y + 10)],
                 fill=(25, 8, 45), width=max(1, width_at_y))
    
    # Neon reflections - pools of color on wet street
    ref_layer = Image.new('RGBA', (W, H), (0,0,0,0))
    ref_draw = ImageDraw.Draw(ref_layer)
    
    reflections = [
        # (cx, cy, rx, ry, color, alpha)
        (int(W*0.18), int(H*0.72), 70, 18, MAGENTA, 50),
        (int(W*0.82), int(H*0.74), 65, 16, CYAN, 45),
        (int(W*0.35), int(H*0.82), 55, 14, NEON_PINK, 40),
        (int(W*0.65), int(H*0.80), 80, 18, AMBER, 38),
        (int(W*0.50), int(H*0.70), 100, 20, (80, 0, 130), 55),
        (int(W*0.10), int(H*0.85), 40, 10, CYAN, 30),
        (int(W*0.90), int(H*0.87), 45, 11, MAGENTA, 35),
        (int(W*0.50), int(H*0.90), 150, 25, (40, 0, 80), 40),
        (int(W*0.25), int(H*0.76), 45, 12, AMBER, 30),
        (int(W*0.75), int(H*0.77), 50, 13, NEON_GREEN, 25),
    ]
    
    for cx, cy, rx, ry, col, alpha in reflections:
        for scale in [2.0, 1.4, 1.0, 0.6]:
            a = int(alpha * (0.3 / scale + 0.1))
            ref_draw.ellipse([cx-int(rx*scale), cy-int(ry*scale),
                             cx+int(rx*scale), cy+int(ry*scale)],
                            fill=(*col[:3], a))
    
    ref_soft = ref_layer.filter(ImageFilter.GaussianBlur(radius=10))
    img.paste(ref_soft, mask=ref_soft)
    
    # Horizontal streak highlights (wet asphalt)
    rng = random.Random(55)
    for _ in range(100):
        x = rng.randint(0, W)
        y = rng.randint(street_top + 20, H - 5)
        length = rng.randint(15, 120)
        cols = [CYAN, MAGENTA, AMBER, NEON_PINK, NEON_GREEN]
        c = rng.choice(cols)
        bright = rng.randint(18, 65)
        streak_col = tuple(ch * bright // 255 for ch in c[:3])
        draw.line([(x, y), (x + length, y)], fill=streak_col, width=1)
    
    # Center mirror reflection of figure (blurry)
    fig_ref = Image.new('RGBA', (W, H), (0,0,0,0))
    fig_ref_draw = ImageDraw.Draw(fig_ref)
    # Silhouette reflection centered
    ref_cx = W // 2
    ref_y_start = int(H * 0.62)
    fig_ref_draw.polygon([
        (ref_cx-50, ref_y_start+5), (ref_cx+50, ref_y_start+5),
        (ref_cx+30, ref_y_start+70), (ref_cx-30, ref_y_start+70)
    ], fill=(30, 0, 60, 55))
    fig_ref_draw.polygon([
        (ref_cx-20, ref_y_start), (ref_cx+20, ref_y_start),
        (ref_cx+12, ref_y_start+30), (ref_cx-12, ref_y_start+30)
    ], fill=(40, 0, 80, 70))
    fig_ref_blurred = fig_ref.filter(ImageFilter.GaussianBlur(radius=8))
    img.paste(fig_ref_blurred, mask=fig_ref_blurred)

# ─── Fog / Atmosphere ─────────────────────────────────────────────────────────
def draw_fog(img):
    fog = Image.new('RGBA', (W, H), (0,0,0,0))
    fog_draw = ImageDraw.Draw(fog)
    
    # Background haze near vanishing point
    fog_draw.ellipse([int(W*0.25), int(H*0.30), int(W*0.75), int(H*0.55)],
                    fill=(50, 0, 90, 70))
    fog_draw.ellipse([int(W*0.32), int(H*0.34), int(W*0.68), int(H*0.52)],
                    fill=(40, 0, 75, 80))
    fog_draw.ellipse([int(W*0.40), int(H*0.37), int(W*0.60), int(H*0.50)],
                    fill=(30, 0, 60, 90))
    
    # Ground mist
    fog_draw.ellipse([-50, int(H*0.57), W+50, int(H*0.72)], fill=(15, 0, 35, 100))
    fog_draw.ellipse([50, int(H*0.60), W-50, int(H*0.70)], fill=(20, 0, 45, 80))
    
    # Steam wisps from street grates
    rng = random.Random(33)
    for i in range(12):
        x = rng.randint(80, W-80)
        y0 = int(H * 0.60)
        for j in range(6):
            r = 12 + j * 4
            a = max(0, 70 - j * 12)
            drift = rng.randint(-8, 8)
            fog_draw.ellipse([x - r + drift, y0 - j*18 - r//2,
                             x + r + drift, y0 - j*18 + r//2],
                            fill=(50, 0, 80, a))
    
    fog_blurred = fog.filter(ImageFilter.GaussianBlur(radius=22))
    img.paste(fog_blurred, mask=fog_blurred)

# ─── Hooded Figure ────────────────────────────────────────────────────────────
def draw_hooded_figure(img, draw):
    """Cinematic pixel art hooded figure - sovereign, detailed."""
    
    cx = W // 2
    feet_y = int(H * 0.595)
    total_h = 165
    head_top_y = feet_y - total_h
    
    # Colors
    COAT_DARK = (10, 3, 22)
    COAT_MID = (20, 7, 38)
    COAT_EDGE = (45, 15, 80)
    COAT_BRIGHT = (65, 25, 110)
    BOOT = (12, 4, 24)
    
    # ── FEET / BOOTS ──
    # Left boot
    draw.polygon([(cx-22, feet_y-15), (cx-6, feet_y-15),
                  (cx-4, feet_y), (cx-24, feet_y)], fill=BOOT)
    draw.line([(cx-22, feet_y-15), (cx-6, feet_y-15)], fill=COAT_EDGE, width=1)
    
    # Right boot
    draw.polygon([(cx+6, feet_y-15), (cx+22, feet_y-15),
                  (cx+24, feet_y), (cx+4, feet_y)], fill=(12, 4, 22))
    draw.line([(cx+6, feet_y-15), (cx+22, feet_y-15)], fill=COAT_EDGE, width=1)
    
    # ── LEGS ──
    leg_top = feet_y - int(total_h * 0.42)
    
    # Left leg - pants
    draw.polygon([
        (cx-20, leg_top), (cx-9, leg_top),
        (cx-6, feet_y-13), (cx-22, feet_y-13)
    ], fill=COAT_DARK)
    
    # Right leg
    draw.polygon([
        (cx+9, leg_top), (cx+20, leg_top),
        (cx+22, feet_y-13), (cx+6, feet_y-13)
    ], fill=COAT_MID)
    
    # Leg crease highlight
    draw.line([(cx-14, leg_top+5), (cx-14, feet_y-14)], fill=COAT_EDGE, width=1)
    
    # ── CLOAK / BODY ──
    torso_top = feet_y - int(total_h * 0.72)
    
    # Main cloak silhouette - wide flowing coat
    cloak = [
        (cx - 62, feet_y + 2),       # bottom left sweep
        (cx - 52, feet_y - 8),
        (cx - 42, leg_top + 5),
        (cx - 30, torso_top + 15),
        (cx - 16, torso_top + 5),     # shoulder left
        (cx - 8, torso_top),
        (cx + 8, torso_top),
        (cx + 16, torso_top + 5),     # shoulder right
        (cx + 30, torso_top + 15),
        (cx + 42, leg_top + 5),
        (cx + 52, feet_y - 8),
        (cx + 62, feet_y + 2),
    ]
    draw.polygon(cloak, fill=COAT_DARK)
    
    # Inner coat body (slightly lighter center)
    draw.polygon([
        (cx-22, torso_top+8), (cx+22, torso_top+8),
        (cx+28, leg_top+8), (cx-28, leg_top+8)
    ], fill=COAT_MID)
    
    # Coat center seam
    draw.line([(cx, torso_top+6), (cx, feet_y-14)], fill=COAT_EDGE, width=1)
    
    # Coat edge highlights (wet fabric shimmer)
    draw.line([(cx-62, feet_y+2), (cx-30, torso_top+15)], fill=COAT_EDGE, width=1)
    draw.line([(cx+62, feet_y+2), (cx+30, torso_top+15)], fill=COAT_EDGE, width=1)
    
    # Coat fold lines
    draw.line([(cx-40, leg_top), (cx-25, torso_top+20)], fill=COAT_EDGE, width=1)
    draw.line([(cx+40, leg_top), (cx+25, torso_top+20)], fill=COAT_EDGE, width=1)
    
    # ── HOOD ──
    hood_base_y = torso_top + 5
    hood_top_y = head_top_y + 5
    hood_w = 38
    
    # Hood main shape
    hood = [
        (cx - hood_w, hood_base_y),
        (cx - hood_w + 6, hood_top_y + 18),
        (cx - 10, hood_top_y + 5),
        (cx + 4, hood_top_y),       # slight 3/4 lean
        (cx + hood_w - 4, hood_top_y + 20),
        (cx + hood_w, hood_base_y),
    ]
    draw.polygon(hood, fill=COAT_DARK)
    
    # Hood inner shadow (face area dark)
    draw.polygon([
        (cx - 14, hood_base_y + 3),
        (cx - 8, hood_top_y + 22),
        (cx + 6, hood_top_y + 18),
        (cx + 18, hood_base_y + 3),
    ], fill=(4, 1, 9))
    
    # Hood highlight seams
    draw.line([(cx - hood_w, hood_base_y), (cx + 4, hood_top_y)], fill=COAT_EDGE, width=1)
    draw.line([(cx + hood_w, hood_base_y), (cx + hood_w - 4, hood_top_y + 20)], fill=(20,7,38), width=1)
    
    # Hood top crease
    draw.line([(cx - 5, hood_top_y + 5), (cx + 4, hood_top_y)], fill=COAT_BRIGHT, width=1)
    
    # ── RIM LIGHTING from neon signs ──
    rim_layer = Image.new('RGBA', (W, H), (0,0,0,0))
    rim_draw = ImageDraw.Draw(rim_layer)
    
    # Left side cyan rim - strong
    rim_draw.polygon([
        (cx-65, feet_y+2), (cx-58, feet_y-8),
        (cx-32, torso_top+12), (cx-42, torso_top+14)
    ], fill=(0, 220, 255, 90))
    # Second pass - softer spread
    rim_draw.polygon([
        (cx-70, feet_y+2), (cx-62, feet_y-10),
        (cx-35, torso_top+10), (cx-50, torso_top+14)
    ], fill=(0, 180, 220, 45))
    
    # Right side magenta rim - strong
    rim_draw.polygon([
        (cx+65, feet_y+2), (cx+58, feet_y-8),
        (cx+32, torso_top+12), (cx+42, torso_top+14)
    ], fill=(255, 0, 220, 80))
    rim_draw.polygon([
        (cx+70, feet_y+2), (cx+62, feet_y-10),
        (cx+35, torso_top+10), (cx+50, torso_top+14)
    ], fill=(220, 0, 180, 40))
    
    # Hood left rim
    rim_draw.polygon([
        (cx-hood_w, hood_base_y), (cx-hood_w+8, hood_top_y+18),
        (cx-5, hood_top_y+5), (cx-10, hood_top_y+8)
    ], fill=(0, 200, 230, 65))
    # Hood top highlight
    rim_draw.line([(cx-5, hood_top_y+5), (cx+4, hood_top_y)], 
                 fill=(0, 180, 220, 120), width=2)
    
    # Ground-level purple light spill below figure
    rim_draw.ellipse([cx-50, feet_y-5, cx+50, feet_y+20],
                    fill=(60, 0, 120, 80))
    
    rim_soft = rim_layer.filter(ImageFilter.GaussianBlur(radius=4))
    img.paste(rim_soft, mask=rim_soft)
    
    # ── SUBTLE FACE (back/3-quarter view - just a hint) ──
    # No full face visible - just the dark recess under hood
    # Maybe a tiny point of reflected light on chin area
    chin_x = cx + 6
    chin_y = hood_top_y + 35
    draw.ellipse([chin_x-2, chin_y-2, chin_x+2, chin_y+2], fill=(20, 8, 35))
    
    # Reflected light on nose ridge (barely visible)
    draw.line([(cx+3, hood_top_y+25), (cx+5, hood_top_y+30)], fill=(30, 12, 45), width=1)

# ─── HUD Panel ────────────────────────────────────────────────────────────────
def draw_hud(img):
    hud_layer = Image.new('RGBA', (W, H), (0,0,0,0))
    hud_draw = ImageDraw.Draw(hud_layer)
    
    # HUD position - upper right, floating
    hx, hy = int(W * 0.56), int(H * 0.20)
    hw, hh = 330, 90
    
    # Panel fill
    hud_draw.rectangle([hx, hy, hx+hw, hy+hh], fill=(0, 15, 30, 110))
    
    # Outer glow
    for r, a in [(8, 15), (5, 25), (2, 45), (1, 80)]:
        hud_draw.rectangle([hx-r, hy-r, hx+hw+r, hy+hh+r],
                          outline=(*CYAN, a), width=1)
    
    # Corner brackets
    bl = 14
    bc = (*CYAN, 220)
    # TL
    hud_draw.line([(hx, hy), (hx+bl, hy)], fill=bc, width=2)
    hud_draw.line([(hx, hy), (hx, hy+bl)], fill=bc, width=2)
    # TR
    hud_draw.line([(hx+hw, hy), (hx+hw-bl, hy)], fill=bc, width=2)
    hud_draw.line([(hx+hw, hy), (hx+hw, hy+bl)], fill=bc, width=2)
    # BL
    hud_draw.line([(hx, hy+hh), (hx+bl, hy+hh)], fill=bc, width=2)
    hud_draw.line([(hx, hy+hh), (hx, hy+hh-bl)], fill=bc, width=2)
    # BR
    hud_draw.line([(hx+hw, hy+hh), (hx+hw-bl, hy+hh)], fill=bc, width=2)
    hud_draw.line([(hx+hw, hy+hh), (hx+hw, hy+hh-bl)], fill=bc, width=2)
    
    # Diagonal accent at corners (extra tech detail)
    hud_draw.line([(hx+bl+2, hy), (hx+bl+10, hy-4)], fill=(*CYAN, 100), width=1)
    hud_draw.line([(hx+hw-bl-2, hy), (hx+hw-bl-10, hy-4)], fill=(*CYAN, 100), width=1)
    
    # Header bar
    hud_draw.rectangle([hx, hy, hx+hw, hy+16], fill=(0, 30, 60, 150))
    
    # Load fonts
    f_label = get_font("GeistMono-Regular.ttf", 9)
    f_mono = get_font("IBMPlexMono-Bold.ttf", 12)
    f_mono_sm = get_font("IBMPlexMono-Regular.ttf", 9)
    f_bold = get_font("RedHatMono-Bold.ttf", 11)
    
    # Header text
    hud_draw.text((hx + 10, hy + 3), "◈ BIOMETRIC DASHBOARD  ●  LIVE", font=f_label,
                 fill=(*DIM_CYAN, 200))
    hud_draw.text((hx + hw - 65, hy + 3), "23:47:12 EST", font=f_label,
                 fill=(*DIM_CYAN, 160))
    
    # Separator
    hud_draw.line([(hx, hy+17), (hx+hw, hy+17)], fill=(*CYAN, 60), width=1)
    
    # Row 1: Main metrics
    row1 = hy + 23
    pad = 12
    
    # CORTISOL
    hud_draw.text((hx+pad, row1), "CORTISOL", font=f_label, fill=(*DIM_CYAN, 180))
    hud_draw.text((hx+pad+2, row1+11), "OPTIMAL", font=f_bold,
                 fill=(*NEON_GREEN, 240))
    
    # Divider
    hud_draw.line([(hx+pad+85, row1+2), (hx+pad+85, row1+24)],
                 fill=(*CYAN, 60), width=1)
    
    # HRV
    hud_draw.text((hx+pad+92, row1), "HRV", font=f_label, fill=(*DIM_CYAN, 180))
    hud_draw.text((hx+pad+96, row1+11), "94", font=f_bold, fill=(*CYAN, 240))
    
    # Divider
    hud_draw.line([(hx+pad+135, row1+2), (hx+pad+135, row1+24)],
                 fill=(*CYAN, 60), width=1)
    
    # TESTOSTERONE
    hud_draw.text((hx+pad+142, row1), "TEST", font=f_label, fill=(*DIM_CYAN, 180))
    hud_draw.text((hx+pad+146, row1+11), "↑ HIGH", font=f_bold, fill=(*AMBER, 240))
    
    # Divider
    hud_draw.line([(hx+pad+210, row1+2), (hx+pad+210, row1+24)],
                 fill=(*CYAN, 60), width=1)
    
    # SLEEP
    hud_draw.text((hx+pad+217, row1), "SLEEP", font=f_label, fill=(*DIM_CYAN, 180))
    hud_draw.text((hx+pad+221, row1+11), "8.2h", font=f_bold, fill=(*NEON_GREEN, 240))
    
    # Divider
    hud_draw.line([(hx+pad+267, row1+2), (hx+pad+267, row1+24)],
                 fill=(*CYAN, 60), width=1)
    
    # INFLAM
    hud_draw.text((hx+pad+272, row1), "INFLAM", font=f_label, fill=(*DIM_CYAN, 180))
    hud_draw.text((hx+pad+276, row1+11), "LOW", font=f_bold, fill=(*NEON_GREEN, 240))
    
    # Separator
    hud_draw.line([(hx, hy+50), (hx+hw, hy+50)], fill=(*CYAN, 40), width=1)
    
    # Row 2: Mini bar chart row
    row2 = hy + 55
    
    bars = [
        ("GUT", 91, NEON_GREEN),
        ("NAD+", 84, CYAN),
        ("INFLAM", 12, AMBER),   # low=good
        ("HRV TREND", 88, CYAN),
        ("RECOVERY", 95, NEON_GREEN),
        ("OMEGA-3", 76, MAGENTA),
    ]
    
    bar_x = hx + pad
    bar_w = 38
    bar_gap = 52
    bar_h = 6
    
    for label, val, col in bars:
        hud_draw.text((bar_x, row2), label, font=f_label, fill=(*DIM_CYAN, 160))
        # Bar track
        hud_draw.rectangle([bar_x, row2+11, bar_x+bar_w, row2+11+bar_h],
                           fill=(10, 20, 40, 180))
        # Bar fill
        fill_w = int(bar_w * val / 100)
        hud_draw.rectangle([bar_x, row2+11, bar_x+fill_w, row2+11+bar_h],
                           fill=(*col, 200))
        # Val
        hud_draw.text((bar_x+bar_w+2, row2+9), f"{val}", font=f_label,
                     fill=(*col, 180))
        bar_x += bar_gap
    
    # Holographic connection line (dashed) to figure
    fig_cx = W // 2
    fig_y = int(H * 0.37)
    # Draw dashed line
    line_pts = [(hx, hy + hh//2), (fig_cx + 45, fig_y)]
    for i in range(0, 20, 2):
        t0 = i / 20
        t1 = (i+1) / 20
        x0 = int(line_pts[0][0] + (line_pts[1][0] - line_pts[0][0]) * t0)
        y0 = int(line_pts[0][1] + (line_pts[1][1] - line_pts[0][1]) * t0)
        x1 = int(line_pts[0][0] + (line_pts[1][0] - line_pts[0][0]) * t1)
        y1 = int(line_pts[0][1] + (line_pts[1][1] - line_pts[0][1]) * t1)
        hud_draw.line([(x0, y0), (x1, y1)], fill=(*CYAN, 30), width=1)
    
    # Composite
    hud_soft = hud_layer.filter(ImageFilter.GaussianBlur(radius=0.5))
    img.paste(hud_soft, mask=hud_soft)
    img.paste(hud_layer, mask=hud_layer)

# ─── Rain ─────────────────────────────────────────────────────────────────────
def draw_rain(img):
    rain = Image.new('RGBA', (W, H), (0,0,0,0))
    rain_draw = ImageDraw.Draw(rain)
    
    rng = random.Random(77)
    
    # Fine background rain
    for _ in range(1200):
        x = rng.randint(0, W)
        y = rng.randint(0, H)
        l = rng.randint(6, 18)
        a = rng.randint(15, 65)
        dx = rng.randint(-1, 0)
        rain_draw.line([(x, y), (x+dx, y+l)], fill=(140, 190, 220, a), width=1)
    
    # Heavier near-foreground drops
    for _ in range(200):
        x = rng.randint(0, W)
        y = rng.randint(int(H*0.5), H)
        l = rng.randint(20, 40)
        a = rng.randint(40, 90)
        rain_draw.line([(x, y), (x-1, y+l)], fill=(160, 200, 230, a), width=1)
    
    rain_soft = rain.filter(ImageFilter.GaussianBlur(radius=0.3))
    img.paste(rain_soft, mask=rain_soft)

# ─── Mid-distance vanishing point glow ────────────────────────────────────────
def draw_vanishing_glow(img):
    vp_x, vp_y = W // 2, int(H * 0.40)
    
    glow = Image.new('RGBA', (W, H), (0,0,0,0))
    glow_draw = ImageDraw.Draw(glow)
    
    # Atmospheric glow at vanishing point
    for r, a in [(80, 20), (55, 35), (35, 50), (20, 60), (10, 70)]:
        glow_draw.ellipse([vp_x-r, vp_y-int(r*0.6), vp_x+r, vp_y+int(r*0.6)],
                         fill=(60, 0, 100, a))
    
    # Small bright distant lights
    for offset, col in [(-18, MAGENTA), (0, CYAN), (18, AMBER)]:
        cx = vp_x + offset
        cy = vp_y + 8
        for r, a in [(12, 25), (8, 40), (5, 60), (3, 100), (1, 200)]:
            glow_draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=(*col, a))
    
    glow_blurred = glow.filter(ImageFilter.GaussianBlur(radius=6))
    img.paste(glow_blurred, mask=glow_blurred)

# ─── Main Text ────────────────────────────────────────────────────────────────
def draw_main_text(img, draw):
    
    f_title = get_font("PixelifySans-Medium.ttf", 74)
    f_subtitle = get_font("Tektur-Medium.ttf", 20)
    f_url = get_font("GeistMono-Regular.ttf", 12)
    
    # ── BIOHACKER ──
    title = "BIOHACKER"
    bbox = draw.textbbox((0,0), title, font=f_title)
    tw = bbox[2] - bbox[0]
    tx = (W - tw) // 2
    ty = 16
    
    # Deep glow layer
    glow = Image.new('RGBA', (W, H), (0,0,0,0))
    glow_d = ImageDraw.Draw(glow)
    
    for r, a in [(22, 8), (16, 15), (10, 25), (6, 40), (3, 60)]:
        for dx in range(-r, r+1, max(1, r//3)):
            for dy in range(-r//2, r//2+1, max(1, r//3)):
                glow_d.text((tx+dx, ty+dy), title, font=f_title, fill=(*CYAN, a))
    
    glow_blurred = glow.filter(ImageFilter.GaussianBlur(radius=5))
    img.paste(glow_blurred, mask=glow_blurred)
    
    # Shadow
    draw.text((tx+3, ty+3), title, font=f_title, fill=(0, 60, 80))
    # Main text
    draw.text((tx, ty), title, font=f_title, fill=CYAN)
    # Inner highlight pass (slightly brighter)
    draw.text((tx, ty), title, font=f_title, fill=(180, 255, 255))
    
    # ── OWN YOUR BIOLOGY ──
    sub = "OWN YOUR BIOLOGY"
    bbox2 = draw.textbbox((0,0), sub, font=f_subtitle)
    sw = bbox2[2] - bbox2[0]
    sx = (W - sw) // 2
    sy = ty + 82
    
    # Amber glow
    for dx, dy in [(-2,0),(2,0),(0,-2),(0,2),(-1,-1),(1,1),(1,-1),(-1,1)]:
        draw.text((sx+dx, sy+dy), sub, font=f_subtitle, fill=(80, 55, 0))
    draw.text((sx, sy), sub, font=f_subtitle, fill=AMBER)
    
    # Decorative lines flanking subtitle
    line_y = sy + 11
    draw.line([(sx - 40, line_y), (sx - 8, line_y)], fill=(100, 70, 0), width=1)
    draw.line([(sx + sw + 8, line_y), (sx + sw + 40, line_y)], fill=(100, 70, 0), width=1)
    # Small diamonds at ends
    for lx in [sx-8, sx+sw+8]:
        draw.polygon([(lx, line_y), (lx-4, line_y+3), (lx, line_y+6), (lx+4, line_y+3)],
                    fill=(140, 100, 0))
    
    # ── biohacker.systems ──
    url = "biohacker.systems"
    bbox3 = draw.textbbox((0,0), url, font=f_url)
    uw = bbox3[2] - bbox3[0]
    ux = W - uw - 16
    uy = H - 20
    
    # Tiny dim glow
    for dx, dy in [(-1,0),(1,0)]:
        draw.text((ux+dx, uy+dy), url, font=f_url, fill=(0, 40, 55))
    draw.text((ux, uy), url, font=f_url, fill=DIM_CYAN)

# ─── Vignette ─────────────────────────────────────────────────────────────────
def add_vignette(img):
    vig = Image.new('RGBA', (W, H), (0,0,0,0))
    vig_d = ImageDraw.Draw(vig)
    
    for i in range(100):
        t = i / 100
        a = int(t**2 * 200)
        vig_d.rectangle([i, i, W-i, H-i], outline=(0,0,0, a), width=1)
    
    vig_soft = vig.filter(ImageFilter.GaussianBlur(radius=2))
    img.paste(vig_soft, mask=vig_soft)

# ─── Pixel texture / grain ────────────────────────────────────────────────────
def add_grain(img):
    """Subtle CRT / film grain to enhance pixel art feel."""
    px = img.load()
    rng = random.Random(99)
    
    for _ in range(4000):
        x = rng.randint(0, W-1)
        y = rng.randint(0, H-1)
        r, g, b = px[x, y][:3]
        v = rng.randint(-12, 12)
        px[x, y] = (max(0,min(255,r+v)), max(0,min(255,g+v)), max(0,min(255,b+v)))

# ─── MAIN ─────────────────────────────────────────────────────────────────────
def main():
    print("Building Sovereign Noir feature graphic...")
    
    img = Image.new('RGB', (W, H), BG_DEEP)
    draw = ImageDraw.Draw(img)
    
    print("  [1/13] Sky gradient...")
    draw_sky(draw)
    
    print("  [2/13] Stars...")
    draw_stars(draw)
    
    print("  [3/13] Buildings...")
    draw_buildings(img, draw)
    
    print("  [4/13] Neon signs...")
    draw_neon_signs(img, draw)
    
    print("  [5/13] Vanishing point glow...")
    draw_vanishing_glow(img)
    
    print("  [6/13] Fog & atmosphere...")
    draw_fog(img)
    
    print("  [7/13] Street & reflections...")
    draw_street(img, draw)
    
    print("  [8/13] Hooded figure...")
    draw_hooded_figure(img, draw)
    
    print("  [9/13] HUD panel...")
    draw_hud(img)
    
    print("  [10/13] Rain...")
    draw_rain(img)
    
    print("  [11/13] Main text...")
    draw_main_text(img, draw)
    
    print("  [12/13] Pixel grain...")
    add_grain(img)
    
    print("  [13/13] Vignette + color grade...")
    add_vignette(img)
    
    # Color grade: slight contrast + saturation boost
    img = ImageEnhance.Contrast(img).enhance(1.18)
    img = ImageEnhance.Color(img).enhance(1.25)
    img = ImageEnhance.Brightness(img).enhance(0.95)
    
    # Save
    os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
    img.save(OUT_PATH, 'PNG', optimize=True)
    
    verify = Image.open(OUT_PATH)
    print(f"\n✅ Saved: {OUT_PATH}")
    print(f"   Size: {verify.size[0]}x{verify.size[1]}px")
    print(f"   Mode: {verify.mode}")
    print(f"   File: {os.path.getsize(OUT_PATH):,} bytes")

if __name__ == '__main__':
    main()
