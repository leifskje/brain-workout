"""Reports what the Play Store listing currently contains, without changing it.

Answers "what would publishListing actually overwrite?" by reading Play directly
and diffing against the repo's src/main/play/.

The Play API only exposes listings inside an *edit* transaction, so this creates a
draft edit, reads, then **deletes the edit without committing**. Nothing is
published. Contrast with GPP's `bootstrapListing`, which clears the local
directory before writing and will happily delete your listing if Play is empty.

Uses only stdlib plus PyJWT, so there is nothing to install.

Run: python tool/play_listing_status.py
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
PLAY_DIR = 'android/app/src/main/play'


def access_token(key_path):
    """Service-account JWT -> OAuth access token."""
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
    req = urllib.request.Request(key['token_uri'], data=body)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)['access_token'], key['client_email']


def call(token, method, path, body=None):
    req = urllib.request.Request(
        f'{API}/{path}',
        method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors='replace')
        raise SystemExit(f'{e.code} on {method} {path}\n{detail}')


def local(locale, name):
    path = os.path.join(PLAY_DIR, 'listings', locale, f'{name}.txt')
    if not os.path.exists(path):
        return None
    return io.open(path, encoding='utf-8').read().strip()


def main():
    token, who = access_token(KEY)
    print(f'authenticated as {who}\n')

    edit = call(token, 'POST', f'applications/{PACKAGE}/edits', {})
    edit_id = edit['id']
    try:
        listings = call(token, 'GET',
                        f'applications/{PACKAGE}/edits/{edit_id}/listings')
        entries = listings.get('listings', [])
        print(f'Play currently holds {len(entries)} listing(s).')

        remote = {e['language']: e for e in entries}
        locales = sorted(set(remote) | {'no-NO', 'en-GB'})
        for locale in locales:
            r = remote.get(locale)
            print(f'\n--- {locale} ---')
            for field, key in (('title', 'title'),
                              ('short-description', 'shortDescription'),
                              ('full-description', 'fullDescription')):
                mine = local(locale, field)
                theirs = (r or {}).get(key) or None
                if theirs is None and mine is None:
                    continue
                if theirs == mine:
                    state = 'same'
                elif theirs is None:
                    state = 'EMPTY in Play -> would be filled from the repo'
                elif mine is None:
                    state = 'only in Play -> repo has nothing to push'
                else:
                    state = 'DIFFERENT -> repo version would replace it'
                print(f'  {field:18} {state}')
                if state.startswith('DIFFERENT'):
                    print(f'      Play: {theirs[:70]!r}')
                    print(f'      repo: {mine[:70]!r}')

        images = call(
            token, 'GET',
            f'applications/{PACKAGE}/edits/{edit_id}/listings/no-NO/'
            'phoneScreenshots')
        print(f'\nno-NO phone screenshots in Play: '
              f'{len(images.get("images", []))}')
    finally:
        # Discard the draft edit — nothing is committed, so nothing is published.
        call(token, 'DELETE', f'applications/{PACKAGE}/edits/{edit_id}')
        print('\ndraft edit discarded; Play unchanged')


if __name__ == '__main__':
    main()
