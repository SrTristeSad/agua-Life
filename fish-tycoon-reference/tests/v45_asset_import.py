"""V45: importação de PNGs originais, opcionais e validação de dimensões."""
import importlib.util
import tempfile
import struct
import zlib
import zipfile
from pathlib import Path

module_path = Path(__file__).resolve().parents[1] / 'scripts' / 'import_j2me_assets.py'
spec = importlib.util.spec_from_file_location('j2me_assets', module_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

def chunk(kind, content):
    return struct.pack('>I', len(content)) + kind + content + struct.pack('>I', zlib.crc32(kind + content) & 0xffffffff)

def fake_png(w=240, h=320):
    header = struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0)
    pixels = (b'\x00' + b'\x00\x00\x00' * w) * h
    return module.PNG_SIGNATURE + chunk(b'IHDR', header) + chunk(b'IDAT', zlib.compress(pixels)) + chunk(b'IEND', b'')

with tempfile.TemporaryDirectory() as temp:
    root = Path(temp)
    jar = root / 'test.jar'
    with zipfile.ZipFile(jar, 'w') as z:
        z.writestr('assets.png', fake_png())
        z.writestr('store.png', fake_png(113, 123))
        z.writestr('menutank.png', fake_png(240, 256))
        z.writestr('fish.png', fake_png(100, 320))
        z.writestr('fins.png', fake_png(64, 320))
        z.writestr('tank1.png', fake_png(240, 154))
        z.writestr('tank2.png', fake_png(240, 154))
        z.writestr('tank3.png', fake_png(240, 154))
        z.writestr('tanktop.png', fake_png(240, 110))
        z.writestr('isolation_tank.png', fake_png(98, 46))
        z.writestr('icon.png', fake_png(48, 48))
        z.writestr('isola.png', fake_png(240, 80))
        z.writestr('oberon.png', fake_png(240, 320))
        z.writestr('people.png', fake_png(136, 25))
        z.writestr('supllies_big.png', fake_png(245, 168))
        z.writestr('supply_animations.png', fake_png(109, 98))
    imported, missing = module.import_assets(jar, root / 'out')
    assert set(imported) == {'assets.png', 'store.png', 'menutank.png', 'fish.png',
                             'fins.png', 'tank1.png', 'tank2.png', 'tank3.png',
                             'tanktop.png', 'isolation_tank.png', 'icon.png',
                             'isola.png', 'oberon.png', 'people.png',
                             'supllies_big.png', 'supply_animations.png'}
    assert 'trhopy_ball.png' in missing and 'splash.png' in missing
    assert (root / 'out' / 'store.png').read_bytes() == fake_png(113, 123)
    assert (root / 'out' / 'menutank.png').read_bytes() == fake_png(240, 256)
    for name in ('fish', 'fins', 'tank1', 'tank2', 'tank3', 'tanktop', 'isolation_tank',
                 'icon', 'isola', 'oberon', 'people', 'supllies_big', 'supply_animations'):
        assert (root / 'out' / (name + '.png')).is_file(), name

    for malformed in (b'not a png', module.PNG_SIGNATURE + b'\x00' * 16,
                      fake_png(2, 2)[:-6], fake_png(2, 2)[:-1] + b'X'):
        invalid = root / 'invalid.jar'
        with zipfile.ZipFile(invalid, 'w') as z:
            z.writestr('assets.png', malformed)
        try:
            module.import_assets(invalid, root / 'bad-out')
            raise AssertionError('Invalid PNG was accepted')
        except ValueError:
            assert not (root / 'bad-out').exists()

print('OK v45: sprites store/menutank, missing resources and invalid PNG')
