"""Reports which build is actually live on each Play track, without changing it.

Answers "what are my testers running, and does it match the repo?" -- which is
not something the repo alone can tell you: `pubspec.yaml` says what the *next*
build would be, and a `versionCode` sitting in git is not evidence that it was
ever uploaded.

Same safe pattern as play_listing_status.py: the Play API only exposes tracks
inside an *edit* transaction, so this creates a draft edit, reads, then
**deletes the edit without committing**. Nothing is published.

Uses only stdlib plus PyJWT, so there is nothing to install.

Run: python tool/play_track_status.py
"""
import io
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt

KEY = 'android/app/play-service-account.json'
PACKAGE = 'net.skjelten.brain_workout'
API = 'https://androidpublisher.googleapis.com/androidpublisher/v3'
TRACKS = ('internal', 'alpha', 'beta', 'production')


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


def call(token, method, path, allow_404=False):
    req = urllib.request.Request(
        f'{API}/{path}',
        method=method,
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
        if allow_404 and e.code == 404:
            return None
        detail = e.read().decode(errors='replace')
        raise SystemExit(f'{e.code} on {method} {path}\n{detail}')


def local_version():
    text = io.open('pubspec.yaml', encoding='utf-8').read()
    m = re.search(r'^version:\s*(\S+)', text, re.M)
    return m.group(1) if m else '(unreadable)'


def main():
    token, who = access_token(KEY)
    print(f'authenticated as {who}\n')

    edit_id = call(token, 'POST', f'applications/{PACKAGE}/edits')['id']
    try:
        for name in TRACKS:
            track = call(
                token, 'GET',
                f'applications/{PACKAGE}/edits/{edit_id}/tracks/{name}',
                allow_404=True)
            if track is None:
                print(f'--- {name} ---\n  (no track)')
                continue
            releases = track.get('releases') or []
            if not releases:
                print(f'--- {name} ---\n  (no releases)')
                continue
            print(f'--- {name} ---')
            for rel in releases:
                codes = ', '.join(str(c) for c in rel.get('versionCodes') or [])
                bits = [f"versionCode {codes or '-'}"]
                bits.append(f"status {rel.get('status', '?')}")
                if rel.get('name'):
                    bits.append(f"name {rel['name']!r}")
                if rel.get('userFraction') is not None:
                    bits.append(f"fraction {rel['userFraction']}")
                print('  ' + '  |  '.join(bits))
    finally:
        # Never commit: this is a read-only look.
        call(token, 'DELETE', f'applications/{PACKAGE}/edits/{edit_id}')
        print('\ndraft edit discarded; Play unchanged')

    print(f'\nlocal pubspec version: {local_version()}')


if __name__ == '__main__':
    main()
