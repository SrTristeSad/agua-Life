#!/usr/bin/env python3
"""Verify true LÖVE native PNG screenshots without third-party packages."""
import os
import struct
import sys
import zlib
from pathlib import Path

folder = Path(sys.argv[1] if len(sys.argv) > 1 else
              os.path.expanduser('~/.local/share/love/mar_de_isola_lua/native-smoke'))
expected = ['01-aquario', '02-isolamento', '03-vendas', '04-loja',
            '05-pesquisas', '06-colecao', '07-paisagem']
assert (folder / 'ok.txt').is_file(), f'Native smoke did not complete: {folder}'
for name in expected:
    file = folder / (name + '.png')
    blob = file.read_bytes()
    assert blob.startswith(b'\x89PNG\r\n\x1a\n') and len(blob) > 5000, f'Invalid PNG: {file}'
    pos, payload, width, height = 8, bytearray(), None, None
    while pos < len(blob):
        length = struct.unpack_from('>I', blob, pos)[0]
        kind = blob[pos + 4:pos + 8]
        content = blob[pos + 8:pos + 8 + length]
        if kind == b'IHDR':
            width, height = struct.unpack_from('>II', content)
        elif kind == b'IDAT':
            payload.extend(content)
        pos += length + 12
        if kind == b'IEND':
            break
    assert width and height and payload, f'Invalid PNG image data: {file}'
    assert (width, height) == ((960, 600) if name == '07-paisagem' else (480, 640)), \
        f'Unexpected size for {name}: {width}x{height}'
    pixels = zlib.decompress(payload)
    assert len(pixels) > width * height, f'Suspicious short image: {name}'
    assert len(set(pixels[:min(300000, len(pixels))])) >= 14, f'Blank image? {name}'
    print(f'OK {name}: {width}x{height}, {len(blob)} bytes')
print('Seven real LÖVE screenshots checked successfully.')
