"""Integration regression for J2ME screenshot manifest and PNG validation."""
import importlib.util
import struct
import tempfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location(
    'retro_validator', ROOT / 'scripts' / 'validate_retro_screenshots.py')
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)


def chunk(kind, data):
    crc = zlib.crc32(kind + data) & 0xffffffff
    return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', crc)


def screenshot():
    # Construct a genuine 480x640 RGBA PNG, with variable pixels on every row.
    raw = b''.join(
        b'\x00' + b''.join(bytes((x & 255, y & 255, (x + y) & 255, 255))
                         for x in range(480))
        for y in range(640)
    )
    ihdr = struct.pack('>IIBBBBB', 480, 640, 8, 6, 0, 0, 0)
    return (validator.PNG_SIGNATURE + chunk(b'IHDR', ihdr)
            + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


names = validator.expected_screens()
assert len(names) >= 31, 'V54 menu/title screenshot steps missing'
assert names[-4:] == [
    '28-titulo-com-save', '29-confirmar-novo-jogo',
    '30-opcoes-do-titulo', '31-voltar-ao-titulo'
]
with tempfile.TemporaryDirectory() as temp:
    folder = Path(temp)
    data = screenshot()
    for name in names:
        (folder / (name + '.png')).write_bytes(data)
    marker = folder / 'ok.txt'
    marker.write_text(f'{len(names)} J2ME-style screens rendered\n', encoding='utf-8')
    assert validator.validate_run(folder) == len(names)

    missing = folder / (names[-1] + '.png')
    missing.unlink()
    try:
        validator.validate_run(folder)
        raise AssertionError('A missing screenshot was accepted')
    except AssertionError as error:
        assert 'Missing LÖVE screenshot' in str(error)
    missing.write_bytes(data)

    marker.write_text('27 J2ME-style screens rendered\n', encoding='utf-8')
    try:
        validator.validate_run(folder)
        raise AssertionError('An obsolete 27-screen marker was accepted')
    except AssertionError as error:
        assert 'Expected' in str(error)
    marker.write_text(f'{len(names)} J2ME-style screens rendered\n', encoding='utf-8')

    bad = bytearray(data)
    bad[29] ^= 1  # Corrupt IHDR CRC without changing the PNG signature.
    missing.write_bytes(bad)
    try:
        validator.validate_png(missing)
        raise AssertionError('Corrupt screenshot CRC was accepted')
    except AssertionError as error:
        assert 'CRC' in str(error)

print('OK V55: every retro screenshot is checked; missing, stale and corrupt PNG rejected')
