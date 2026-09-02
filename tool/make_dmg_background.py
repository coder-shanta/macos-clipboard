#!/usr/bin/env python3
"""Generates the background image used by the Clipboard DMG installer window."""

import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SCALE = 2  # render at 2x then downsample for anti-aliasing
W, H = 660, 400
CW, CH = W * SCALE, H * SCALE

APP_X, APP_Y = 180 * SCALE, 195 * SCALE
APPS_X, APPS_Y = 480 * SCALE, 195 * SCALE

BG_TOP = (246, 247, 249, 255)
BG_BOTTOM = (230, 232, 236, 255)
TEXT_COLOR = (55, 58, 66, 255)
SUB_COLOR = (120, 124, 132, 255)
ARROW_COLOR = (214, 40, 40, 255)

img = Image.new("RGBA", (CW, CH), BG_TOP)
draw = ImageDraw.Draw(img)

# vertical gradient background
for y in range(CH):
    t = y / CH
    r = int(BG_TOP[0] + (BG_BOTTOM[0] - BG_TOP[0]) * t)
    g = int(BG_TOP[1] + (BG_BOTTOM[1] - BG_TOP[1]) * t)
    b = int(BG_TOP[2] + (BG_BOTTOM[2] - BG_TOP[2]) * t)
    draw.line([(0, y), (CW, y)], fill=(r, g, b, 255))

# subtle top border accent
draw.rectangle([0, 0, CW, 6 * SCALE], fill=ARROW_COLOR)

def font(path, size):
    return ImageFont.truetype(path, size * SCALE)

title_font = font("/System/Library/Fonts/SFNS.ttf", 26)
sub_font = font("/System/Library/Fonts/SFNS.ttf", 14)
label_font = font("/System/Library/Fonts/SFNS.ttf", 13)

def center_text(d, cx, y, text, f, fill):
    bbox = d.textbbox((0, 0), text, font=f)
    w = bbox[2] - bbox[0]
    d.text((cx - w / 2, y), text, font=f, fill=fill)

center_text(draw, CW / 2, 34 * SCALE, "Install Clipboard", title_font, TEXT_COLOR)
center_text(draw, CW / 2, 70 * SCALE, "Drag the app into Applications to install it",
            sub_font, SUB_COLOR)

# curved arrow between the two icon slots
start = (APP_X + 78 * SCALE, APP_Y - 6 * SCALE)
end = (APPS_X - 78 * SCALE, APPS_Y - 6 * SCALE)
mid = ((start[0] + end[0]) / 2, start[1] - 46 * SCALE)

def quad_bezier(p0, p1, p2, steps=60):
    pts = []
    for i in range(steps + 1):
        t = i / steps
        x = (1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t ** 2 * p2[0]
        y = (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t ** 2 * p2[1]
        pts.append((x, y))
    return pts

pts = quad_bezier(start, mid, end)
draw.line(pts, fill=ARROW_COLOR, width=int(3.4 * SCALE), joint="curve")

# arrowhead pointing at the Applications icon
tail = pts[-8]
tip = pts[-1]
ang = math.atan2(tip[1] - tail[1], tip[0] - tail[0])
head_len = 16 * SCALE
head_w = 10 * SCALE
p1 = (tip[0] - head_len * math.cos(ang - math.radians(28)),
      tip[1] - head_len * math.sin(ang - math.radians(28)))
p2 = (tip[0] - head_len * math.cos(ang + math.radians(28)),
      tip[1] - head_len * math.sin(ang + math.radians(28)))
draw.polygon([tip, p1, p2], fill=ARROW_COLOR)

# faint rounded "drop zone" hint under the Applications slot
zone_r = 74 * SCALE
draw.ellipse(
    [APPS_X - zone_r, APPS_Y - zone_r, APPS_X + zone_r, APPS_Y + zone_r],
    outline=(214, 40, 40, 60), width=int(2 * SCALE)
)

center_text(draw, APP_X, (APP_Y + 92 * SCALE), "Clipboard", label_font, TEXT_COLOR)
center_text(draw, APPS_X, (APPS_Y + 92 * SCALE), "Applications", label_font, TEXT_COLOR)

out = img.resize((W, H), Image.LANCZOS)
out.save("assets/dmg_background.png")
print("saved assets/dmg_background.png", out.size)
