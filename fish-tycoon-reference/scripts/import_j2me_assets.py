#!/usr/bin/env python3
"""Importa PNGs do JAR local do usuário para comparação visual no LÖVE.

Não baixa arquivos e não altera o JAR. Recursos ausentes são relatados,
sem impedir a importação dos que estiverem presentes.
Uso: python3 scripts/import_j2me_assets.py /caminho/Fish_Tycoon.jar
"""
import sys
import struct
import zlib
from pathlib import Path
from zipfile import ZipFile, BadZipFile

PNG_SIGNATURE = b'\x89PNG\r\n\x1a\n'
REQUIRED = ('assets.png', 'splash.png', 'gameMenuTank.png')
OPTIONAL = ('fish.png', 'fins.png', 'tank1.png', 'tank2.png', 'tank3.png',
            'tanktop.png', 'isolation_tank.png', 'trhopy_ball.png',
            'store.png', 'menutank.png', 'icon.png', 'isola.png',
            'oberon.png', 'people.png', 'supllies_big.png',
            'supply_animations.png')

def png_dimensions(data, filename):
    """Check chunk boundaries and CRCs before accepting a PNG from the JAR."""
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError('PNG inválido: ' + filename)
    pos = len(PNG_SIGNATURE)
    dimensions = None
    finished = False
    while pos + 12 <= len(data):
        length = struct.unpack_from('>I', data, pos)[0]
        end = pos + 12 + length
        if end > len(data):
            raise ValueError('PNG truncado: ' + filename)
        kind = data[pos + 4:pos + 8]
        payload = data[pos + 8:pos + 8 + length]
        expected = struct.unpack_from('>I', data, pos + 8 + length)[0]
        if zlib.crc32(kind + payload) & 0xffffffff != expected:
            raise ValueError('CRC PNG inválido: ' + filename)
        if dimensions is None:
            if kind != b'IHDR' or length != 13:
                raise ValueError('IHDR PNG inválido: ' + filename)
            width, height = struct.unpack_from('>II', payload)
            if not width or not height:
                raise ValueError('Dimensões PNG inválidas: ' + filename)
            dimensions = width, height
        elif kind == b'IHDR':
            raise ValueError('IHDR duplicado: ' + filename)
        pos = end
        if kind == b'IEND':
            if length or pos != len(data):
                raise ValueError('Final PNG inválido: ' + filename)
            finished = True
            break
    if not finished:
        raise ValueError('PNG incompleto: ' + filename)
    return dimensions


def import_assets(jar: Path, root: Path):
    imported, missing = [], []
    with ZipFile(jar) as archive:
        names = set(archive.namelist())
        # Validate all present files before writing any output.
        pending = {}
        for filename in REQUIRED + OPTIONAL:
            if filename not in names:
                missing.append(filename)
                continue
            data = archive.read(filename)
            width, height = png_dimensions(data, filename)
            pending[filename] = (data, width, height)
        if not pending:
            raise ValueError('Nenhum dos recursos gráficos esperados foi encontrado no JAR')
        root.mkdir(parents=True, exist_ok=True)
        for filename, (data, width, height) in pending.items():
            destination = root / filename
            destination.write_bytes(data)
            imported.append(filename)
            print(f'Extraído: {destination} ({width}x{height})')
    if missing:
        print('Ausentes no JAR:', ', '.join(missing))
    return imported, missing

if __name__ == '__main__':
    if len(sys.argv) != 2:
        sys.exit('Uso: python3 scripts/import_j2me_assets.py /caminho/para/fish.jar')
    try:
        import_assets(Path(sys.argv[1]), Path(__file__).resolve().parents[1] / 'assets' / 'original')
    except (OSError, BadZipFile, ValueError) as exc:
        sys.exit(str(exc))
