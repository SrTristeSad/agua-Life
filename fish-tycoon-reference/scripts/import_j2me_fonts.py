#!/usr/bin/env python3
"""Extrai fontes PNG e larguras do JAR fornecido pelo proprio usuario.
Uso: python scripts/import_j2me_fonts.py caminho/Fish_Tycoon.jar
A saida assets/local_font/ e privada/ignorada pelo Git. Requer apenas Python 3.
"""
from pathlib import Path
import struct,zipfile,sys

def extract(path,output):
    with zipfile.ZipFile(path) as source:
        data=source.read('1.dat')
    p=0
    nlang=data[p];p+=1+nlang
    nsection=data[p];p+=1
    counts=struct.unpack_from('>'+str(nlang*nsection)+'h',data,p)
    p+=2*nlang*nsection+sum(counts)
    number=data[p]; p+=1
    glyphs=data[p]; p+=1
    if number!=3 or glyphs!=104:raise ValueError('Layout de fonte diferente do JAR J2ME 1.0.1 conhecido')
    output.mkdir(parents=True,exist_ok=True)
    lines=['-- Metricas extraidas de 1.dat para uso LOCAL','return {']
    for i in range(number):
        size=struct.unpack_from('>h',data,p)[0];p+=2
        png=data[p:p+size];p+=size
        if not png.startswith(b'\x89PNG\r\n\x1a\n'):
            raise ValueError('Fonte nao e PNG')
        row_count,baseline,extra,gap=data[p:p+4];p+=4
        pos=struct.unpack_from('>'+str(glyphs+2)+'h',data,p)
        p+=2*(glyphs+2)
        (output/f'font_{i}.png').write_bytes(png)
        lines.append(" {file='font_%d.png',rows=%d,baseline=%d,extra=%d,gap=%d,offsets={%s}},"%
             (i,row_count,baseline,extra,gap,','.join(map(str,pos))))
    if p!=len(data):raise ValueError('1.dat possui dados finais inesperados')
    lines.append('}')
    (output/'font_metrics.lua').write_text('\n'.join(lines)+'\n',encoding='utf8')
    print('Tres fontes PNG e 104 metricas por fonte recuperadas em',output)

if __name__=='__main__':
    if len(sys.argv)!=2:raise SystemExit('Uso: python scripts/import_j2me_fonts.py arquivo.jar')
    extract(Path(sys.argv[1]),Path('assets/local_font'))
