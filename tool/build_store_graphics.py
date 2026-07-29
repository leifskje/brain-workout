"""Generates the two graphics Play refuses to publish without.

  store/icon_512.png        512x512, no alpha  (Play's store icon)
  store/feature_1024x500.png  1024x500, no alpha (Play's feature graphic)

Both are derived from assets/icon/app_icon.png, so they stay in step with the
launcher icon. Play rejects transparency in either, so the alpha channel is
flattened onto the app's brand blue rather than left to chance.

Run: python tool/build_store_graphics.py
"""
import os
from PIL import Image

SRC = 'assets/icon/app_icon.png'
OUT = 'store'
# Same blue as the adaptive icon background in pubspec.yaml.
BRAND = (63, 125, 170)


def flatten(img, size, background):
    """Composite onto an opaque background — Play rejects an alpha channel."""
    img = img.convert('RGBA')
    canvas = Image.new('RGB', size, background)
    # Centre, preserving aspect ratio.
    scaled = img.copy()
    scaled.thumbnail(size, Image.LANCZOS)
    x = (size[0] - scaled.width) // 2
    y = (size[1] - scaled.height) // 2
    canvas.paste(scaled, (x, y), scaled)
    return canvas


def main():
    os.makedirs(OUT, exist_ok=True)
    src = Image.open(SRC)
    print(f'source {SRC}: {src.width}x{src.height} mode={src.mode}')

    icon = flatten(src, (512, 512), BRAND)
    icon_path = os.path.join(OUT, 'icon_512.png')
    icon.save(icon_path, 'PNG')

    # Feature graphic. Uses the *foreground* (transparent brain) on a gradient
    # rather than the full icon: pasting the square icon onto a flat colour left
    # a visible box, which read as a mistake rather than a banner. Play crops the
    # edges on some surfaces, so the artwork stays well inside them.
    feature = Image.new('RGB', (1024, 500))
    top, bottom = (74, 144, 196), (44, 92, 132)
    for y in range(500):
        t = y / 499
        row = tuple(round(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        feature.paste(row, (0, y, 1024, y + 1))

    fg_path = 'assets/icon/app_icon_foreground.png'
    badge = Image.open(fg_path).convert('RGBA')
    # The adaptive foreground has wide safe-zone padding; trim it so the brain
    # is not lost in the middle of the banner.
    bbox = badge.getbbox()
    if bbox:
        badge = badge.crop(bbox)
    badge.thumbnail((330, 330), Image.LANCZOS)
    feature.paste(badge, ((1024 - badge.width) // 2,
                          (500 - badge.height) // 2), badge)
    feature_path = os.path.join(OUT, 'feature_1024x500.png')
    feature.save(feature_path, 'PNG')

    for path, want in ((icon_path, (512, 512)), (feature_path, (1024, 500))):
        check = Image.open(path)
        ok = check.size == want and check.mode == 'RGB'
        kb = os.path.getsize(path) / 1024
        print(f'{path}: {check.size[0]}x{check.size[1]} mode={check.mode} '
              f'{kb:.0f} KB  {"OK" if ok else "WRONG - check this"}')


if __name__ == '__main__':
    main()
