"""Frames rendered app screens as Play Store screenshots: a coloured background,
a large caption, and the screen shown smaller with rounded corners and a soft
shadow. Raw screens come from tool/store_screens/render_test.dart.

Run: flutter test tool/store_screens/render_test.dart
     python tool/frame_screenshots.py
Writes store/screenshots/<lang>/NN.png (1080x1920, 9:16), which
tool/sync_play_listing.py copies into Gradle Play Publisher's tree.
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

FONT = r'C:\dev\flutter\bin\cache\artifacts\material_fonts\roboto-bold.ttf'
SRC = 'tool/store_screens/out'
DST = 'store/screenshots'
W, H = 1080, 1920

# (raw file, background colour, English caption, Norwegian caption)
SHOTS = [
    ('02_pictures', '#8D6E63', 'Every board hides a picture',
     'Hvert brett skjuler et bilde'),
    ('03_revealed', '#A1887F', 'Clear it and see what it was',
     'Løs det og se hva det var'),
    ('01_home', '#3F7DAA', '15 brain games in one place',
     '15 hjernetrim-spill samlet'),
    ('04_maze', '#2E8B8B', 'Puzzles that keep getting harder',
     'Oppgaver som stadig blir vanskeligere'),
    ('05_nonogram', '#00796B', 'Logic for careful thinkers',
     'Logikk for den som tenker seg om'),
    ('06_word_search', '#B5527D', 'Word games in English and Norwegian',
     'Ordspill på norsk og engelsk'),
]


def wrap(draw, text, font, width):
    """Greedy word wrap to [width] pixels."""
    lines, line = [], ''
    for word in text.split():
        trial = f'{line} {word}'.strip()
        if draw.textlength(trial, font=font) <= width:
            line = trial
        else:
            lines.append(line)
            line = word
    lines.append(line)
    return lines


def frame(raw_path, colour, caption, out_path):
    canvas = Image.new('RGB', (W, H), colour)
    draw = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(FONT, 84)
    lines = wrap(draw, caption, font, W - 140)
    y = 110
    for line in lines:
        w = draw.textlength(line, font=font)
        draw.text(((W - w) / 2, y), line, font=font, fill='white')
        y += 104

    screen = Image.open(raw_path).convert('RGB')
    top = y + 60
    target_h = H - top
    scale = min((W - 160) / screen.width, target_h / screen.height)
    sw, sh = int(screen.width * scale), int(screen.height * scale)
    screen = screen.resize((sw, sh), Image.LANCZOS)
    x = (W - sw) // 2

    radius = 44
    mask = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, sw, sh), radius, fill=255)

    shadow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x, top + 16, x + sw, top + sh + 16), radius, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(24))
    canvas.paste(shadow, (0, 0), shadow)
    canvas.paste(screen, (x, top), mask)
    # The screen runs off the bottom edge, like a phone held up to the camera.
    canvas.save(out_path, optimize=True)


def main():
    for lang in ('en', 'nb'):
        os.makedirs(f'{DST}/{lang}', exist_ok=True)
        for old in os.listdir(f'{DST}/{lang}'):
            os.remove(f'{DST}/{lang}/{old}')
        for i, (name, colour, en, nb) in enumerate(SHOTS, 1):
            frame(f'{SRC}/{lang}/{name}.png', colour, en if lang == 'en' else nb,
                  f'{DST}/{lang}/{i:02}.png')
        print(f'{lang}: {len(SHOTS)} screenshots')


if __name__ == '__main__':
    main()
