#!/usr/bin/env python3
"""Resolução maior da matriz APROVADA; não redesenha nem altera peixes."""
from pathlib import Path
from PIL import Image, ImageFilter
import json
import argparse

def resize_tile(tile, size):
    # Interpolação pré-multiplicada impede halo escuro nas barbatanas.
    image = tile.convert('RGBA').convert('RGBa').resize(size, Image.Resampling.LANCZOS).convert('RGBA')
    r, g, b, a = image.split()
    rgb = Image.merge('RGB', (r,g,b)).filter(ImageFilter.UnsharpMask(radius=.6, percent=46, threshold=3))
    r,g,b = rgb.split()
    return Image.merge('RGBA', (r,g,b,a))

def build(src_path, output_path, meta_path):
    src = Image.open(src_path).convert('RGBA')
    assert src.size == (2688, 1480), f'Imagem original inesperada: {src.size}'
    output = Image.new('RGBA', (4032,2220), (0,0,0,0))
    for row in range(21):
        for col in range(21):
            crop = src.crop((col*128,row*64,(col+1)*128,(row+1)*64))
            output.paste(resize_tile(crop,(192,96)), (col*192,row*96))
    for i in range(7):
        crop = src.crop((i*384,1344,(i+1)*384,1480))
        output.paste(resize_tile(crop,(576,204)), (i*576,2016))
    target=Path(output_path)
    target.parent.mkdir(parents=True,exist_ok=True)
    output.save(target,optimize=True)
    prev=json.loads(Path(meta_path).read_text(encoding='utf-8'))
    assert prev['grid']==[21,21] and len(prev['bounds'])==21
    updated={
      'version':2,'source':'atlas_441.png — arte original aprovada pelo usuário',
      'grid':[21,21],'cell':[192,96],'magic':[576,204],
      'atlas':[4032,2220],'scale':1.5,'no_redraw':True,
      'bounds':[[[round(v*1.5) for v in b] for b in row] for row in prev['bounds']],
      'magic_bounds':[[round(v*1.5) for v in b] for b in prev['magic_bounds']],
      'magic_pairs':prev['magic_pairs'],
      'notes':'Somente interpolação cuidadosa; detalhes ausentes não podem ser recuperados.'
    }
    target.with_suffix('.json').write_text(json.dumps(updated,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    print('OK: atlas fiel, 4032 x 2220, 441 + 7 peixes, células independentes.')
if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--source',default='assets/fish/matrix/atlas_441.png')
    parser.add_argument('--output',default='assets/fish/matrix/atlas_original_refined_4k.png')
    parser.add_argument('--metadata',default='assets/fish/matrix/atlas_441.json')
    args=parser.parse_args()
    build(args.source,args.output,args.metadata)
