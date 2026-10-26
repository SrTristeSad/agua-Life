#!/usr/bin/env python3
"""Relatório visual HONESTO da matriz original.

Não altera pixels, não afirma que imagens pequenas foram restauradas.
Marca possíveis barbatanas truncadas no atlas e monta uma folha comparativa
das colunas F12, F15 e F21 para revisão humana.
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

COLUMNS=(12,15,21)
CELL_W,CELL_H=192,96
def inspect(tile):
    alpha=tile.getchannel('A')
    bb=alpha.getbbox()
    if not bb:
        return {'empty':True,'score':1,'possible_clip':True}
    pixels=alpha.load()
    x0,y0,x1,y1=bb
    # Amostrar interior da margem: contornos horizontais longos sugerem
    # barbatana atravessada pelo limite da imagem original.
    def count(y):
        return sum(pixels[x,y]>=145 for x in range(x0,x1))
    high=count(y0)
    low=count(y1-1)
    width=max(1,x1-x0)
    ratio=max(high,low)/width
    return {
        'empty':False,
        'alpha_bbox':[x0,y0,x1,y1],
        'top_edge_width':high,
        'bottom_edge_width':low,
        'flat_edge_ratio':round(ratio,3),
        'possible_clip':(max(high,low)>=18 and ratio>=.18)
    }
def main(source,output):
    source=Path(source);out=Path(output)
    out.mkdir(parents=True,exist_ok=True)
    im=Image.open(source).convert('RGBA')
    if im.size!=(4032,2220):raise ValueError('Atlas 4032x2220 necessário.')
    results=[];suggested=[]
    for body in range(1,22):
        for fin in range(1,22):
            x=(fin-1)*CELL_W;y=(body-1)*CELL_H
            record={'body':body,'fin':fin,
                    **inspect(im.crop((x,y,x+CELL_W,y+CELL_H)))}
            results.append(record)
            if record['possible_clip']:suggested.append(record)
    page=Image.new('RGB',(3*360,21*166+45),(12,36,55))
    d=ImageDraw.Draw(page)
    for n,fin in enumerate(COLUMNS):
        d.text((n*360+12,12),f'F{fin} - coluna sensível a sobreposição',fill='#e3f4fa')
    for row in range(21):
        for col,fin in enumerate(COLUMNS):
            x0=col*360;y0=45+row*166
            d.rectangle((x0+5,y0,x0+355,y0+157),outline=(48,85,108),width=1)
            spec=results[row*21+fin-1]
            tag='REVISAR' if spec['possible_clip'] else 'verificar'
            d.text((x0+13,y0+9),f'C{row+1:02d} F{fin:02d}  {tag}',fill=(255,192,123) if spec['possible_clip'] else (171,226,218))
            cut=im.crop(((fin-1)*CELL_W,row*CELL_H,fin*CELL_W,(row+1)*CELL_H))
            copy=Image.new('RGBA',(336,116),'#15394c')
            enlarged=cut.resize((264,132),Image.Resampling.LANCZOS)
            # Recortar ao tamanho de exibição do cartão.
            enlarged=enlarged.resize((232,116),Image.Resampling.LANCZOS)
            copy.alpha_composite(enlarged,((336-enlarged.width)//2,0))
            page.paste(copy.convert('RGB'),(x0+12,y0+32))
    page.save(out/'colunas_em_revisao.png',optimize=True)
    info={'source':str(source),
          'note':'Indicador heurístico: possíveis cortes não provam defeito.',
          'total':441,
          'suspects':len(suggested),
          'highlight_columns':list(COLUMNS),
          'fish':results}
    (out/'relatorio_qualidade.json').write_text(json.dumps(info,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print(f'{len(suggested)} de 441 espécimes sinalizados para revisão, SEM alterações em PNG.')
if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('--source',default='assets/fish/matrix/atlas_original_clean_4k.png')
    ap.add_argument('--output',default='quality-review')
    args=ap.parse_args()
    main(args.source,args.output)
