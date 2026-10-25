#!/usr/bin/env python3
"""Exporta arte ORIGINAL Azul-Rubi em SVGs e PNGs transparentes (640x360).
Os membros usam a mesma prancheta e pontos de articulacao. Sem assets externos.
Requisitos apenas para exportacao: cairosvg, Pillow. O jogo usa so os PNGs.
"""
from pathlib import Path
import math, random, json
from io import BytesIO
import cairosvg
from PIL import Image,ImageDraw

W,H,S=320,180,2
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets'/'fish'/'azul_rubi'
OUT.mkdir(parents=True,exist_ok=True)

DEFS='''<defs>
<linearGradient id="body" x1=".21" y1=".02" x2=".56" y2=".94">
<stop stop-color="#153e69"/><stop offset=".19" stop-color="#168aaf"/>
<stop offset=".4" stop-color="#30d6db"/><stop offset=".58" stop-color="#69ecdd"/>
<stop offset=".77" stop-color="#adeff1"/><stop offset=".94" stop-color="#4389b1"/>
<stop offset="1" stop-color="#1c577b"/></linearGradient>
<linearGradient id="tail" x1=".92" y1=".5" x2=".05" y2=".45">
<stop stop-color="#085b85"/><stop offset=".24" stop-color="#0aa8c1"/>
<stop offset=".56" stop-color="#652b8c"/><stop offset=".8" stop-color="#ed3958"/>
<stop offset="1" stop-color="#ff8c5c"/></linearGradient>
<linearGradient id="dorsal" x1=".3" y1="1" x2=".1" y2=".1">
<stop stop-color="#00668e"/><stop offset=".4" stop-color="#2396c5"/>
<stop offset=".68" stop-color="#e84667"/><stop offset="1" stop-color="#ffa66e"/></linearGradient>
<linearGradient id="pelvic" x1=".1" y1=".02" x2=".6" y2="1">
<stop stop-color="#1cb4b8"/><stop offset=".48" stop-color="#4165ad"/>
<stop offset="1" stop-color="#f74c70"/></linearGradient>
<linearGradient id="pectoral" x1=".8" y1=".1" x2=".1" y2=".95">
<stop stop-color="#a2fff0" stop-opacity=".8"/><stop offset=".45" stop-color="#35a3d4" stop-opacity=".91"/>
<stop offset="1" stop-color="#8a4ad5" stop-opacity=".74"/></linearGradient>
<radialGradient id="iris" cx=".35" cy=".25" r=".8">
<stop stop-color="#f7ffe3"/><stop offset=".2" stop-color="#ffd97c"/>
<stop offset=".5" stop-color="#f5a74d"/><stop offset=".77" stop-color="#92574c"/>
<stop offset="1" stop-color="#12384b"/></radialGradient>
<linearGradient id="neck" x1="0" y1="0" x2="0" y2="1">
<stop stop-color="#14517b"/><stop offset=".4" stop-color="#33babb"/>
<stop offset=".9" stop-color="#9ef8e8"/><stop offset="1" stop-color="#255879"/></linearGradient>
<clipPath id="clipBody"><path d="M99,91 C111,76 134,60 166,58 C193,56 220,61 248,70 C267,76 280,85 294,89 Q299,93 294,98 C280,112 259,119 235,125 C203,132 169,130 143,122 C119,114 106,102 99,91 Z"/></clipPath>
</defs>'''

parts={}
parts['tail']='''<path d="M110,93 C83,84 69,54 54,30 Q31,13 15,29 C22,42 29,63 40,78 C28,86 15,90 8,92 C29,101 30,107 40,115 C31,132 23,147 18,159 C43,157 58,141 69,128 C88,112 100,104 110,96 Z" fill="url(#tail)" stroke="#123e69" stroke-width="2.2"/>
<g fill="none" stroke="#a9eefa" stroke-width="1.7" opacity=".63">
<path d="M104,93 Q79,47 18,30"/><path d="M104,93 Q64,56 34,38"/>
<path d="M104,93 Q65,73 36,66"/><path d="M104,93 Q64,84 11,92"/>
<path d="M104,93 Q65,105 42,115"/><path d="M104,93 Q60,123 18,157"/>
<path d="M104,93 Q82,123 58,137"/></g>
<path d="M84,87 C69,59 50,39 22,33 M80,100 C67,129 45,145 23,151"
 fill="none" stroke="#ffaab0" stroke-width="2.5" opacity=".78"/>'''
parts['dorsal']='''<path d="M151,67 Q147,49 152,37 Q159,17 175,11 Q173,37 184,36 Q197,12 210,23 Q207,48 226,65 L193,73 L151,69 Z" fill="url(#dorsal)" stroke="#15527e" stroke-width="2"/>
<path d="M158,66 L172,19 M169,65 L178,39 M181,66 L197,31 M195,68 L209,29 M209,67 L218,62" fill="none" stroke="#ffe2b3" opacity=".71" stroke-width="1.6"/>
<path d="M155,61 Q176,44 218,62" fill="none" stroke="#a9fcf1" stroke-width="2.3" opacity=".7"/>'''
parts['pelvic']='''<path d="M161,118 Q155,143 140,167 Q159,165 174,149 Q177,166 192,173 Q202,153 202,125 Z" fill="url(#pelvic)" stroke="#2f6286" stroke-width="1.7"/>
<path d="M165,127 L145,161 M172,129 L171,153 M180,128 L187,167 M189,126 L196,161" stroke="#b9e9fd" stroke-width="1.3" opacity=".62"/>'''

body='''<path d="M95,89 Q108,80 129,76 L131,108 Q106,104 95,96 Z" fill="url(#neck)" stroke="#134e6f" stroke-width="1.5"/>
<path d="M99,91 C111,76 134,60 166,58 C193,56 220,61 248,70 C267,76 280,85 294,89 Q299,93 294,98 C280,112 259,119 235,125 C203,132 169,130 143,122 C119,114 106,102 99,91 Z" fill="url(#body)" stroke="#153c63" stroke-width="2.7"/>
<g clip-path="url(#clipBody)">
<path d="M98,75 C151,49 230,52 284,84" stroke="#0d426d" stroke-width="22" opacity=".65" fill="none"/>
<path d="M104,98 C171,87 214,94 295,90" stroke="#02c5ce" stroke-width="8" opacity=".19" fill="none"/>
<path d="M114,106 C185,136 237,127 283,106" stroke="#f4fff3" stroke-width="12" opacity=".2" fill="none"/>
<path d="M125,72 Q187,48 260,79" stroke="#d8fff6" stroke-width="5" opacity=".36" fill="none"/>
</g><g clip-path="url(#clipBody)" fill="none" stroke="#ccffff" stroke-width=".85" opacity=".38">'''
for row in range(7):
 y=66+row*9.2
 for col in range(17):
  x=108+col*10.2+(row%2)*5.1
  body+=f'<path d="M{x:.1f},{y:.1f} q5,-1 6,4 q-3,5 -6,6"/>'
body+='''</g>
<path d="M246,75 C238,91 243,109 251,115" fill="none" stroke="#174e77" stroke-width="2.4" opacity=".7"/>
<path d="M252,79 C248,93 250,102 259,110" fill="none" stroke="#c0fdfe" stroke-width="1.2" opacity=".63"/>
<path d="M288,95 q5,-2 9,1" fill="none" stroke="#164562" stroke-width="1.8"/>
<circle cx="283" cy="80" r="1.3" fill="#203851"/>'''
parts['body']=body

randomizer=random.Random(81642)
for p in range(1,7):
 marks='<g clip-path="url(#clipBody)">'
 if p==1:
  for i in range(19):
   x=125+randomizer.random()*105;y=73+randomizer.random()*39;rx=1+randomizer.random()*2
   marks+=f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx:.1f}" ry="{rx*.6:.1f}" fill="#ffd5bd" opacity=".65"/>'
 elif p==2:
  for x in range(137,246,21):
   marks+=f'<path d="M{x},55 Q{x-12},88 {x+2},129" stroke="#1a527c" stroke-width="11" opacity=".73" fill="none"/>'
   marks+=f'<path d="M{x-3},59 Q{x-9},92 {x},125" stroke="#defcff" stroke-width="1.8" opacity=".38" fill="none"/>'
 elif p==3:
  for i in range(13):
   x=128+randomizer.random()*113;y=78+randomizer.random()*30;rx=2.9+randomizer.random()*4.6
   marks+=f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="{rx:.1f}" ry="{rx*.81:.1f}" fill="#dd4668" opacity=".68"/>'
 elif p==4:
  for i in range(36):
   x=122+randomizer.random()*124;y=71+randomizer.random()*51
   marks+=f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{1+randomizer.random()*1.7:.1f}" fill="#fff9e2" opacity=".72"/>'
 elif p==5:
  marks+='<path d="M112,92 Q170,80 274,91" stroke="#ff9d69" stroke-width="8" opacity=".74" fill="none"/>'
  marks+='<path d="M118,97 Q180,90 277,97" stroke="#213e80" stroke-width="4" opacity=".77" fill="none"/>'
 else:
  for x in range(125,255,13):
   for y in range(72,130,14):
    marks+=f'<path d="M{x-5},{y} l5,-5 l5,5 l-5,5Z" fill="none" stroke="#f4e1ff" stroke-width="1.2" opacity=".52"/>'
 parts[f'pattern_{p}']=marks+'</g>'

parts['pectoral']='''<path d="M243,100 Q231,122 193,146 C223,146 250,133 255,111 Z" fill="url(#pectoral)" stroke="#21698a" stroke-width="1.6" opacity=".95"/>
<path d="M246,106 L202,143 M245,106 L215,142 M245,107 L231,135 M248,108 L244,120" stroke="#e4fcff" opacity=".66" stroke-width="1.35"/>
<path d="M245,103 Q236,115 225,119" fill="none" stroke="#003f6b" stroke-width="2" opacity=".52"/>'''
parts['eye']='''<ellipse cx="274" cy="86" rx="11.5" ry="12" fill="#124563" opacity=".55"/>
<circle cx="273" cy="85" r="10.1" fill="#f2f6e8" stroke="#144965" stroke-width="1.9"/>
<circle cx="273.5" cy="85.5" r="7.8" fill="url(#iris)"/>
<circle cx="275" cy="85" r="4.1" fill="#08152b"/>
<circle cx="272" cy="82" r="2.3" fill="white" opacity=".94"/>
<circle cx="277" cy="88" r=".85" fill="#a8f7ff" opacity=".72"/>'''

pivots={'tail':[110,94],'dorsal':[187,64],'pelvic':[176,121],
        'pectoral':[245,104],'eye':[273,85]}
bbox={'tail':[6,12,114,164],'dorsal':[145,8,230,75],
      'pelvic':[135,115,204,177],'body':[94,54,299,137],
      'pectoral':[187,98,262,150],'eye':[261,73,287,99]}
for i in range(1,7):
 bbox[f'pattern_{i}']=[97,55,297,132]
order=['tail','dorsal','pelvic','body','pattern_1','pectoral','eye']

images={}
for name,element in parts.items():
 source=f'<svg xmlns="http://www.w3.org/2000/svg" width="{W*S}" height="{H*S}" viewBox="0 0 {W} {H}">{DEFS}{element}</svg>'
 (OUT/(name+'.svg')).write_text(source,encoding='utf-8')
 data=cairosvg.svg2png(bytestring=source.encode('utf-8'))
 (OUT/(name+'.png')).write_bytes(data)
 image=Image.open(BytesIO(data)).convert('RGBA')
 assert image.size==(W*S,H*S) and image.getbbox(),name
 images[name]=image

def composed(t,pattern=1):
 frame=Image.new('RGBA',(W*S,H*S),(0,0,0,0))
 for name in ['tail','dorsal','pelvic','body',f'pattern_{pattern}','pectoral','eye']:
  layer=images[name]
  if name in pivots:
   base={'tail':12,'dorsal':5,'pelvic':7,'pectoral':16,'eye':0}[name]
   angle=base*math.sin(t*4+('pectoral'==name)*.7)
   if angle:
    px,py=pivots[name]
    layer=layer.rotate(angle,resample=Image.Resampling.BICUBIC,center=(px*S,py*S))
  frame.alpha_composite(layer)
 return frame

composed(.3).save(OUT/'preview.png')
frames=[composed(i*(2*math.pi/12)/4) for i in range(12)]
frames[0].save(OUT/'swim.gif',save_all=True,append_images=frames[1:],
               duration=90,loop=0,disposal=2,optimize=False)
metadata={'name':'Azul-Rubi','source':'Desenho original em SVG, sem sprites de terceiros',
 'canvas':[W,H],'png':[W*S,H*S],'scale':S,'facing':'right',
 'draw_order':order,'pivots':pivots,'bounds':bbox,
 'dna':{'body':[1],'fin':[1],'palette':[1,12],'pattern':[1,6]}}
(OUT/'rig.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Azul-Rubi: 12 partes SVG+PNG, preview, GIF e rig.json gerados')
