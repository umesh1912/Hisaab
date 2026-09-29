"""Draws a launcher icon: a glyph centred on a coloured square, plus an adaptive foreground.

usage: python3 tools/make_icon.py apps/<app> "#1E5C4A" "₹" [glyph_color] [accent_color]
The glyph must exist in DejaVu Sans Bold (letters, digits, ₹, many symbols like ✓ ★ ♥ ☀ ✿ ✈ ♫ ☂ ⚑).
"""
import sys
from PIL import Image, ImageDraw, ImageFont

FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf'
app, bg, glyph = sys.argv[1], sys.argv[2], sys.argv[3]
fg = sys.argv[4] if len(sys.argv) > 4 else '#F6EFE2'
accent = sys.argv[5] if len(sys.argv) > 5 else None

def hexc(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4)) + (255,)

def draw(img, size, cx, cy):
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, size)
    b = d.textbbox((0, 0), glyph, font=font)
    w, h = b[2] - b[0], b[3] - b[1]
    d.text((cx - w / 2 - b[0], cy - h / 2 - b[1]), glyph, font=font, fill=hexc(fg))
    if accent:
        r = size * 0.14
        x, y = cx + w * 0.5, cy + h * 0.45
        d.ellipse([x - r, y - r, x + r, y + r], fill=hexc(accent))

S = 1024
full = Image.new('RGBA', (S, S), hexc(bg))
draw(full, 540 if len(glyph) == 1 else 360, S * 0.5, S * 0.5)
full.save(f'{app}/assets/icon.png')
fgimg = Image.new('RGBA', (S, S), (0, 0, 0, 0))
draw(fgimg, 360 if len(glyph) == 1 else 240, S * 0.5, S * 0.5)
fgimg.save(f'{app}/assets/icon_fg.png')
print('icons written for', app)
