"""Turns raw emulator screenshots into Play-valid ones.

Play rejects a screenshot whose long side is more than twice its short side
(aspect must sit between 16:9 and 9:16). The pixel_api35 emulator is 1080x2400,
a ratio of 2.22 — so raw captures are rejected.

The fix here is to **pad**, not crop: cropping 1080x2400 down to 9:16 would throw
away 480px of board. Padding the width to 1350 gives exactly 9:16, which is also
Play's recommended shape, and keeps every pixel of the game visible. The padding
colour is sampled from the screenshot's own top-left pixel, so it blends into the
app's background instead of showing black bars.

Also flattens any alpha, since Play wants 24-bit PNG with no transparency.

Usage:
  python tool/prepare_screenshots.py store/raw store/screenshots

Put the raw captures in the input folder in the order you want them shown; output
files are numbered so Play keeps that order.
"""
import collections
import os
import sys
from PIL import Image

# 9:16 — Play's recommended portrait shape and comfortably inside the 2x rule.
TARGET_RATIO = 9 / 16
MIN_SIDE, MAX_SIDE = 320, 3840


def sample_background(img):
    """The app's background colour, for padding that blends in.

    Sampled from the side edges at mid height, *not* from a corner: emulator
    captures have rounded corners with black outside them, so (0, 0) is black and
    padding with it produces ugly bars.
    """
    rgb = img.convert('RGB')
    w, h = rgb.size
    votes = collections.Counter()
    for fraction in (0.3, 0.4, 0.5, 0.6, 0.7):
        y = int(h * fraction)
        votes[rgb.getpixel((0, y))] += 1
        votes[rgb.getpixel((w - 1, y))] += 1
    return votes.most_common(1)[0][0]


def pad_to_ratio(img):
    """Pad (never crop) until the aspect ratio is valid."""
    w, h = img.size
    if h >= w:
        want_w = max(w, round(h * TARGET_RATIO))
        want_h = h
    else:
        want_h = max(h, round(w * TARGET_RATIO))
        want_w = w

    if (want_w, want_h) == (w, h):
        return img.convert('RGB'), False

    bg = sample_background(img)
    canvas = Image.new('RGB', (want_w, want_h), bg)
    canvas.paste(img.convert('RGB'),
                 ((want_w - w) // 2, (want_h - h) // 2))
    return canvas, True


def main():
    src_dir = sys.argv[1] if len(sys.argv) > 1 else 'store/raw'
    out_dir = sys.argv[2] if len(sys.argv) > 2 else 'store/screenshots'

    if not os.path.isdir(src_dir):
        print(f'No input folder "{src_dir}".')
        print('Put your raw emulator PNGs there, then run this again.')
        return 1

    names = sorted(n for n in os.listdir(src_dir)
                   if n.lower().endswith(('.png', '.jpg', '.jpeg')))
    if not names:
        print(f'No images in "{src_dir}".')
        return 1

    os.makedirs(out_dir, exist_ok=True)
    problems = 0
    for i, name in enumerate(names, start=1):
        img = Image.open(os.path.join(src_dir, name))
        before = img.size
        out, padded = pad_to_ratio(img)
        w, h = out.size

        ratio_ok = max(w, h) <= 2 * min(w, h)
        size_ok = MIN_SIDE <= min(w, h) and max(w, h) <= MAX_SIDE
        out_path = os.path.join(out_dir, f'{i:02d}.png')
        out.save(out_path, 'PNG')
        mb = os.path.getsize(out_path) / (1024 * 1024)

        flags = []
        if not ratio_ok:
            flags.append('RATIO STILL INVALID')
        if not size_ok:
            flags.append('SIDE OUT OF RANGE')
        if mb > 8:
            flags.append('OVER 8MB')
        if flags:
            problems += 1

        print(f'{name} {before[0]}x{before[1]} -> {w}x{h} '
              f'{"(padded)" if padded else "(unchanged)"} {mb:.2f} MB '
              f'{" ".join(flags) if flags else "ok"}')

    print('')
    print(f'{len(names)} screenshot(s) written to {out_dir}/')
    if len(names) < 4:
        print('Play asks for at least 4 phone screenshots — add a few more.')
    if len(names) > 8:
        print('Play accepts at most 8; the extras will need removing.')
    print('All valid.' if problems == 0 else f'{problems} still need attention.')
    return 1 if problems else 0


if __name__ == '__main__':
    sys.exit(main())
