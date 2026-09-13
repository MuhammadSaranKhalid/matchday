#!/usr/bin/env python3
"""Validate pinned SVG assets; optionally upload immutable files to Storage.

python3 scripts/upload_notification_icons.py --check
SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... python3 scripts/upload_notification_icons.py --upload
"""
import argparse
import hashlib
import os
from pathlib import Path
import re
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]


def assets():
    catalogue = (ROOT / 'supabase/migrations/20260101000489_notification_icons.sql').read_text()
    entries = re.findall(r"\('[a-z_]+', '(v\d+/[a-z0-9-]+\.svg)', 'tabler-outline', '[0-9a-f]+', 'MIT', '([0-9a-f]{64})'\)", catalogue)
    if not entries:
        raise ValueError('Missing icon catalogue')
    for path, digest in entries:
        data = (ROOT / 'assets/notification_icons' / path).read_bytes()
        if len(data) > 32768 or hashlib.sha256(data).hexdigest() != digest:
            raise ValueError(f'Asset does not match its pinned catalogue: {path}')
        svg = ET.fromstring(data)
        allowed = {'svg', 'path', 'g', 'circle', 'ellipse', 'rect', 'line', 'polyline', 'polygon', 'title', 'desc'}
        for element in svg.iter():
            if element.tag.split('}')[-1] not in allowed:
                raise ValueError(f'Unsupported SVG element in {path}')
            if any(k.lower().startswith('on') or 'href' in k.lower() or k == 'style' for k in element.attrib):
                raise ValueError(f'Unsafe SVG attribute in {path}')
        yield path, data


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--upload', action='store_true')
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    validated = list(assets())
    print(f'Validated {len(validated)} pinned SVG assets')
    if not args.upload:
        return
    url = os.environ['SUPABASE_URL'].rstrip('/')
    key = os.environ['SUPABASE_SERVICE_ROLE_KEY']
    for path, data in validated:
        request = urllib.request.Request(f'{url}/storage/v1/object/notification-icons/{path}',
            data=data, method='POST', headers={'authorization': f'Bearer {key}',
                'apikey': key, 'content-type': 'image/svg+xml',
                'cache-control': 'max-age=31536000', 'x-upsert': 'false'})
        try:
            with urllib.request.urlopen(request, timeout=30):
                pass
        except urllib.error.HTTPError as error:
            if error.code not in (400, 409):
                raise RuntimeError(f'Upload failed with HTTP {error.code}: {path}') from None
            # An existing version must be byte-identical. Never overwrite it.
            with urllib.request.urlopen(f'{url}/storage/v1/object/public/notification-icons/{path}', timeout=30) as response:
                if response.read() != data:
                    raise RuntimeError(f'Immutable asset differs: {path}; publish a new version')
        print(f'Ready: {path}')


if __name__ == '__main__':
    main()
