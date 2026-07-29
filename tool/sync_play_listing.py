"""Generates Gradle Play Publisher's listing resources from the repo's sources.

GPP reads android/app/src/main/play/. Rather than maintain that tree by hand and
let it drift, this builds it from what already exists:

  docs/plans/store-listing.md   -> title / short / full description per language
  store/icon_512.png            -> listings/<lang>/graphics/icon/1.png
  store/feature_1024x500.png    -> listings/<lang>/graphics/feature-graphic/1.png
  store/screenshots/<lang>/*    -> listings/<lang>/graphics/phone-screenshots/

Play's locale codes are not the app's: Norwegian is `no-NO`, English `en-GB`.

Run: python tool/sync_play_listing.py
"""
import io
import os
import re
import shutil

PLAY_DIR = 'android/app/src/main/play'
# Maps the app's language code -> (Play locale, heading in store-listing.md)
LANGS = {
    'nb': ('no-NO', 'Norwegian (nb)'),
    'en': ('en-GB', 'English (en-GB)'),
}
LIMITS = {'title': 30, 'short-description': 80, 'full-description': 4000}


def parse_listing():
    """Pulls the fenced blocks out of store-listing.md, per language."""
    text = io.open('docs/plans/store-listing.md', encoding='utf-8').read()
    # Split on the "## <language>" headings.
    sections = re.split(r'^## ', text, flags=re.M)[1:]
    found = {}
    for section in sections:
        heading = section.splitlines()[0].strip()
        fields = {}
        for name, key in (('App name', 'title'),
                          ('Short description', 'short-description'),
                          ('Full description', 'full-description')):
            m = re.search(rf'### {name}\s*\n```\n(.*?)\n```', section, re.S)
            if m:
                fields[key] = m.group(1).strip()
        if fields:
            found[heading] = fields
    return found


def main():
    listings = parse_listing()
    problems = 0

    for lang, (locale, heading) in LANGS.items():
        match = next((v for k, v in listings.items() if k.startswith(heading)),
                     None)
        if match is None:
            print(f'{lang}: no section starting "{heading}" in store-listing.md')
            problems += 1
            continue

        base = os.path.join(PLAY_DIR, 'listings', locale)
        os.makedirs(base, exist_ok=True)
        for key, value in match.items():
            if len(value) > LIMITS[key]:
                print(f'{locale}/{key}: {len(value)} chars exceeds '
                      f'{LIMITS[key]}')
                problems += 1
            path = os.path.join(base, f'{key}.txt')
            io.open(path, 'w', encoding='utf-8', newline='\n').write(value + '\n')
            print(f'{path}  ({len(value)} chars)')

        # Graphics. Play wants the same icon and feature graphic per locale.
        for src, sub in (('store/icon_512.png', 'icon'),
                         ('store/feature_1024x500.png', 'feature-graphic')):
            dest_dir = os.path.join(base, 'graphics', sub)
            os.makedirs(dest_dir, exist_ok=True)
            if os.path.exists(src):
                shutil.copyfile(src, os.path.join(dest_dir, '1.png'))
                print(f'{dest_dir}/1.png')
            else:
                print(f'missing {src}')
                problems += 1

        shots_src = os.path.join('store/screenshots', lang)
        shots_dest = os.path.join(base, 'graphics', 'phone-screenshots')
        if os.path.isdir(shots_src):
            shutil.rmtree(shots_dest, ignore_errors=True)
            os.makedirs(shots_dest, exist_ok=True)
            names = sorted(n for n in os.listdir(shots_src)
                           if n.lower().endswith('.png'))
            for i, name in enumerate(names, start=1):
                shutil.copyfile(os.path.join(shots_src, name),
                                os.path.join(shots_dest, f'{i}.png'))
            print(f'{shots_dest}/  ({len(names)} screenshots)')
            if len(names) < 4:
                print(f'  only {len(names)} — Play asks for at least 4')
        else:
            print(f'missing {shots_src}')
            problems += 1

    # default-language.txt tells GPP which listing is canonical.
    os.makedirs(PLAY_DIR, exist_ok=True)
    io.open(os.path.join(PLAY_DIR, 'default-language.txt'), 'w',
            encoding='utf-8', newline='\n').write('no-NO\n')
    io.open(os.path.join(PLAY_DIR, 'contact-email.txt'), 'w',
            encoding='utf-8', newline='\n').write('leifskje@gmail.com\n')
    io.open(os.path.join(PLAY_DIR, 'contact-website.txt'), 'w',
            encoding='utf-8', newline='\n').write(
        'https://leifskje.github.io/brain-workout/\n')

    print('')
    print('Listing resources written.' if problems == 0
          else f'{problems} problem(s) — fix before publishing.')
    return 1 if problems else 0


if __name__ == '__main__':
    raise SystemExit(main())
