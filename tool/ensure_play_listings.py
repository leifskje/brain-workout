"""Creates any store-listing languages that don't exist in Play yet.

Why this is needed: `gradlew publishListing` uploads listing text and graphics
concurrently, and its media uploader asks Play for
`listings/<lang>/featureGraphic` before the listing exists. For a language that
has never been added to the app that returns:

    404  Listing for language 'en-GB' not found.

So a brand-new language cannot be created by GPP in one pass. This writes the
text for each locale found in android/app/src/main/play/listings/, which creates
the language, after which `publishListing` succeeds and attaches the graphics.

Idempotent: re-running it just rewrites the same text.

Run: python tool/ensure_play_listings.py
"""
import io
import json
import os
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

KEY = 'android/app/play-service-account.json'
PACKAGE = 'net.skjelten.brain_workout'
API = 'https://androidpublisher.googleapis.com/androidpublisher/v3'
LISTINGS_DIR = 'android/app/src/main/play/listings'


def access_token(key_path):
    with io.open(key_path, encoding='utf-8') as fh:
        key = json.load(fh)
    now = int(time.time())
    assertion = jwt.encode(
        {
            'iss': key['client_email'],
            'scope': 'https://www.googleapis.com/auth/androidpublisher',
            'aud': key['token_uri'],
            'iat': now,
            'exp': now + 3600,
        },
        key['private_key'],
        algorithm='RS256',
    )
    body = urllib.parse.urlencode({
        'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion': assertion,
    }).encode()
    with urllib.request.urlopen(
            urllib.request.Request(key['token_uri'], data=body),
            timeout=60) as resp:
        return json.load(resp)['access_token']


def call(token, method, path, body=None):
    req = urllib.request.Request(
        f'{API}/{path}',
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={'Authorization': f'Bearer {token}',
                 'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        raise SystemExit(f'{e.code} on {method} {path}\n'
                         f'{e.read().decode(errors="replace")}')


def read(locale, name):
    path = os.path.join(LISTINGS_DIR, locale, f'{name}.txt')
    if not os.path.exists(path):
        return ''
    return io.open(path, encoding='utf-8').read().strip()


def main():
    locales = sorted(d for d in os.listdir(LISTINGS_DIR)
                     if os.path.isdir(os.path.join(LISTINGS_DIR, d)))
    if not locales:
        raise SystemExit(f'no locales under {LISTINGS_DIR}')

    token = access_token(KEY)
    edit_id = call(token, 'POST', f'applications/{PACKAGE}/edits', {})['id']
    print(f'edit {edit_id}')

    for locale in locales:
        payload = {
            'language': locale,
            'title': read(locale, 'title'),
            'shortDescription': read(locale, 'short-description'),
            'fullDescription': read(locale, 'full-description'),
        }
        call(token, 'PUT',
             f'applications/{PACKAGE}/edits/{edit_id}/listings/{locale}',
             payload)
        print(f'  {locale}: text written '
              f'({len(payload["fullDescription"])} chars of description)')

    call(token, 'POST', f'applications/{PACKAGE}/edits/{edit_id}:commit')
    print('committed — languages now exist, so publishListing can add graphics')


if __name__ == '__main__':
    main()
