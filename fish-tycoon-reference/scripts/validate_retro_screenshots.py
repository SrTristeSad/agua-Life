#!/usr/bin/env python3
"""Validate every screenshot produced by core/retro_smoke.lua under real LÖVE."""
from pathlib import Path
import os
import re
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
SMOKE_DRIVER = ROOT / 'core' / 'retro_smoke.lua'
DEFAULT_FOLDER = Path.home() / '.local/share/love/mar_de_isola_lua/retro-smoke'
STEP_RE = re.compile(r"^\s*\{'(\d{2}-[^']+)',function\(v\)", re.MULTILINE)
PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'


def expected_screens(driver=SMOKE_DRIVER):
    """Use the actual smoke steps as the authoritative screenshot manifest."""
    names = STEP_RE.findall(Path(driver).read_text(encoding='utf-8'))
    assert names, f'No screenshot steps found in {driver}'
    assert len(names) == len(set(names)), 'Duplicate screenshot names in smoke driver'
    for index, name in enumerate(names, 1):
        assert name.startswith(f'{index:02d}-'), f'Out-of-order screenshot: {name}'
    return names


def validate_png(path):
    data = Path(path).read_bytes()
    assert data.startswith(PNG_SIGNATURE), f'{path}: missing PNG signature'
    offset, width, height, chunks, finished = 8, None, None, [], False
    while offset + 12 <= len(data):
        length = struct.unpack_from('>I', data, offset)[0]
        end = offset + length + 12
        assert end <= len(data), f'{path}: truncated PNG chunk'
        kind = data[offset + 4:offset + 8]
        chunk = data[offset + 8:offset + 8 + length]
        crc = struct.unpack_from('>I', data, offset + 8 + length)[0]
        assert zlib.crc32(kind + chunk) & 0xffffffff == crc, f'{path}: PNG CRC mismatch'
        if width is None:
            assert kind == b'IHDR' and len(chunk) == 13, f'{path}: invalid IHDR'
            width, height = struct.unpack_from('>II', chunk)
        if kind == b'IDAT':
            chunks.append(chunk)
        offset = end
        if kind == b'IEND':
            finished = True
            break
    assert finished and offset == len(data), f'{path}: incomplete PNG'
    assert (width, height) == (480, 640), f'{path}: {width}x{height}, expected 480x640'
    assert chunks, f'{path}: no image data'
    pixels = zlib.decompress(b''.join(chunks))
    assert len(data) > 4000 and len(set(pixels[:200000])) > 12, f'{path}: image appears blank'
    return width, height, len(data)


def validate_run(folder=DEFAULT_FOLDER, driver=SMOKE_DRIVER):
    folder = Path(folder)
    names = expected_screens(driver)
    marker = folder / 'ok.txt'
    assert marker.is_file(), f'LÖVE retro smoke did not finish: {folder}'
    text = marker.read_text(encoding='utf-8')
    assert text.startswith(f'{len(names)} J2ME-style screens rendered'), (
        f'Expected {len(names)} screens but LÖVE reported {text.strip()!r}'
    )
    for name in names:
        path = folder / f'{name}.png'
        assert path.is_file(), f'Missing LÖVE screenshot: {path}'
        print('OK', name, *validate_png(path))
    print(f'{len(names)} retro LÖVE screenshots validated')
    return len(names)


if __name__ == '__main__':
    location = os.environ.get('FISH_RETRO_SCREENSHOT_DIR')
    validate_run(location or DEFAULT_FOLDER)
