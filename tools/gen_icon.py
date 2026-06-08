"""Generate the Brain Workout app icons from the 🧠 emoji on a blue gradient.

Produces:
  assets/icon/app_icon.png            full-bleed icon (web/windows/iOS/legacy)
  assets/icon/app_icon_foreground.png transparent brain for Android adaptive icon

Run from the repo root:  python tools/gen_icon.py
Then regenerate platform icons: dart run flutter_launcher_icons
"""
import os
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
EMOJI = "\U0001F9E0"  # 🧠
FONT_PATH = r"C:\Windows\Fonts\seguiemj.ttf"
TOP = (74, 144, 217)     # #4A90D9
BOTTOM = (46, 107, 150)  # #2E6B96
OUT_DIR = os.path.join("assets", "icon")


def vertical_gradient(top, bottom):
    strip = Image.new("RGBA", (1, SIZE))
    for y in range(SIZE):
        t = y / (SIZE - 1)
        strip.putpixel((0, y), (
            int(top[0] + (bottom[0] - top[0]) * t),
            int(top[1] + (bottom[1] - top[1]) * t),
            int(top[2] + (bottom[2] - top[2]) * t),
            255,
        ))
    return strip.resize((SIZE, SIZE))


def draw_centered_emoji(img, frac):
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_PATH, int(SIZE * frac))
    bbox = draw.textbbox((0, 0), EMOJI, font=font, embedded_color=True)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (SIZE - w) // 2 - bbox[0]
    y = (SIZE - h) // 2 - bbox[1]
    draw.text((x, y), EMOJI, font=font, embedded_color=True)


os.makedirs(OUT_DIR, exist_ok=True)

full = vertical_gradient(TOP, BOTTOM)
draw_centered_emoji(full, 0.62)
full.save(os.path.join(OUT_DIR, "app_icon.png"))

# Android adaptive foreground: transparent, brain kept within the safe zone.
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_centered_emoji(fg, 0.52)
fg.save(os.path.join(OUT_DIR, "app_icon_foreground.png"))

print("Wrote", os.path.join(OUT_DIR, "app_icon.png"),
      "and app_icon_foreground.png")
