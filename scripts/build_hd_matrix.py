#!/usr/bin/env python3
"""agua-Life HD 2 — original SVG shapes, 21 bodies x 21 fins, fixed 512x256 transparent cells.

No crop from a crowded matrix is ever used. Each full fish is authored and
rasterized separately, then reduced to a 4K catalog. No image interpolation
is used to claim new details; gradients, scales and anatomy are vector source.
"""
from __future__ import annotations
import argparse
import json
import math
import os
from concurrent.futures import ProcessPoolExecutor
from io import BytesIO
from pathlib import Path
import cairosvg
from PIL import Image, ImageDraw, ImageFont

WIDTH, HEIGHT = 512, 256
GRID = 21
PREVIEW = (4096, 2304)
MARGIN = 13
# Base, back, belly, accent, fins: distinct body designs, not recolors of one fish.
SCHEMES = [
 ('#ff933b','#bf342d','#fff2cc','#282b39','#ffca79'),
 ('#31cce7','#114d8a','#e9ffff','#f73b62','#36c8ef'),
 ('#ffc453','#673924','#fce4a8','#272734','#fb8b2d'),
 ('#ffac41','#c65424','#fff6d4','#1d2840','#ffd26c'),
 ('#84d6d3','#347d93','#f9ffe5','#bee7fd','#7ddbc9'),
 ('#39b7df','#285cb0','#ffffff','#ef784f','#4c9cf1'),
 ('#ff783c','#9d3d38','#fce8be','#ec5444','#fc934f'),
 ('#f0df47','#a48a25','#fffbc7','#e3ee51','#fef188'),
 ('#f8a15b','#603f2d','#f7d8ac','#242a35','#b9b19b'),
 ('#ee9acf','#863d96','#fff2fa','#fa64c2','#cf6eee'),
 ('#d6d2ba','#757c84','#fffeed','#7e6f65','#ebdfc1'),
 ('#ff4266','#a11d5d','#ffbad4','#fc62a6','#f42c73'),
 ('#69d7f5','#145baa','#e8ffff','#ec2e71','#42abe7'),
 ('#7c6b4c','#2f2b24','#e6c99b','#111923','#b49858'),
 ('#aa86f3','#4b3292','#ffdeff','#ed69f4','#ba67e8'),
 ('#ffd08b','#e17742','#fffdeb','#99dcef','#fa9448'),
 ('#5dbb77','#2f6761','#eaffb4','#c1a767','#75bd98'),
 ('#c3d8ec','#4d7d9c','#ffffff','#f9a45d','#bdddfc'),
 ('#e9ecdd','#849bb8','#ffffff','#657e97','#d6eff7'),
 ('#5b9fc9','#244b90','#d2faff','#e99559','#3486bf'),
 ('#e8d99c','#78634b','#fffaf0','#202d55','#f5bc52'),
]
# Body silhouettes are truly different: width, height, dorsal/ventral and head profile.
BODY_VARIATION = [
 (1.00,.96,.04),(1.17,.62,-.03),(.83,1.08,.05),(.95,.86,.07),
 (1.07,.85,-.04),(1.02,.92,-.07),(.91,1.03,.04),(.99,.72,-.03),
 (1.20,.68,.08),(1.15,.75,-.02),(.74,1.54,.12),(.77,1.31,.09),
 (1.14,.64,-.08),(1.22,.63,.01),(.83,1.31,.09),(1.15,.77,-.07),
 (1.01,.97,.04),(.89,1.10,.10),(1.20,.63,-.08),(1.15,.73,-.01),
 (.77,1.56,.08)]
FIN_KIND = ['fan','round','fork','veil','spear','diamond','double','fan','round','fork','veil','royal','fan','round','royal','veil','diamond','double','fan','spear','royal']
MAGIC = [(21,17),(15,15),(12,12),(11,10),(6,9),(14,7),(8,8)]
MAGIC_ACCENTS = ['#ef4770','#db76ff','#f62752','#ffe5ab','#ffa84f','#edc36a','#ffca42']
SVG_START='''<svg xmlns="http://www.w3.org/2000/svg" width="512" height="256" viewBox="0 0 512 256">'''

def gradients(base,back,belly,accent,fin):
 return f'''<defs>
 <linearGradient id="skin" x1="0" y1="0" x2=".23" y2="1"><stop stop-color="{back}"/><stop offset=".20" stop-color="{base}"/><stop offset=".50" stop-color="{base}"/><stop offset=".78" stop-color="{belly}"/><stop offset="1" stop-color="{back}"/></linearGradient>
 <linearGradient id="upper" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{accent}"/><stop offset=".42" stop-color="{fin}"/><stop offset="1" stop-color="{back}"/></linearGradient>
 <linearGradient id="fan" x1="0" y1="0" x2=".76" y2="1"><stop stop-color="{accent}"/><stop offset=".36" stop-color="{fin}"/><stop offset=".79" stop-color="{base}"/><stop offset="1" stop-color="{back}"/></linearGradient>
 <radialGradient id="eye"><stop stop-color="#0b2436"/><stop offset=".6" stop-color="#182b34"/><stop offset=".72" stop-color="{accent}"/><stop offset="1" stop-color="#e9f3ef"/></radialGradient>
 </defs>'''

def make_svg(c, f, magic=None):
 base,back,belly,accent,fin=SCHEMES[c-1]
 length,height,head=BODY_VARIATION[c-1]
 kind=FIN_KIND[f-1]
 # Strong fin identity for f12, f15 and f21 just like the combination reference.
 if f in (12,): fin,accent='#ff365e','#fca4bc'
 if f in (15,): fin,accent='#a968f3','#fba2e8'
 if f in (21,): fin,accent='#ffbe43','#7d56eb'
 if magic is not None: fin,accent=MAGIC_ACCENTS[magic],MAGIC_ACCENTS[magic]
 nose=443+int((length-1)*34)
 joint=184
 cy=129+int(head*11)
 h=42*height
 topline=cy-h;bottomline=cy+h
 silhouette=f'M {joint} {cy} C {joint+42} {cy-h*1.20:.2f} {nose-70} {cy-h*1.13:.2f} {nose} {cy-10:.1f} Q {nose+13} {cy} {nose} {cy+9:.1f} C {nose-67} {cy+h*1.02:.2f} {joint+40} {cy+h*1.14:.2f} {joint} {cy} Z'
 defs=gradients(base,back,belly,accent,fin)
 clip=f'<defs><clipPath id="bodyClip"><path d="{silhouette}"/></clipPath></defs>'
 # Tail shape distinct by fin gene. Operates behind body so attachment is concealed.
 spread=36 + (f%4)*6
 reach=100+((f*7)%25)
 left=joint-reach
 wave=6+f%5
 if kind=='fan':
  tail=f'M {joint+4} {cy-10} C {joint-36} {cy-21} {left+20} {cy-spread-19} {left} {cy-spread} Q {left+wave} {cy} {left} {cy+spread} C {left+25} {cy+spread+8} {joint-34} {cy+22} {joint+4} {cy+10} Z'
 elif kind=='round':
  tail=f'M {joint+4} {cy-10} C {left+24} {cy-spread*1.25} {left-17} {cy-spread} {left-19} {cy} C {left-18} {cy+spread} {left+25} {cy+spread*1.25} {joint+4} {cy+10} Z'
 elif kind=='fork':
  tail=f'M {joint+3} {cy-10} Q {left+34} {cy-spread*.64:.1f} {left-14} {cy-spread} Q {left+14} {cy-spread*.17:.1f} {left+51} {cy} Q {left+12} {cy+spread*.16:.1f} {left-17} {cy+spread} Q {left+36} {cy+spread*.65:.1f} {joint+3} {cy+10} Z'
 elif kind=='veil':
  tail=f'M {joint+3} {cy-10} C {left+38} {cy-spread*1.3:.1f} {left-5} {cy-spread*1.4:.1f} {left-11} {cy-spread*1.7:.1f} C {left+2} {cy-spread*.43:.1f} {left+33} {cy-3} {left+6} {cy+spread*.63:.1f} Q {left-32} {cy+spread*1.65:.1f} {left-10} {cy+spread*1.60:.1f} C {left+28} {cy+spread*1.25:.1f} {joint-17} {cy+24} {joint+3} {cy+10} Z'
 elif kind=='royal':
  tail=f'M {joint+3} {cy-8} Q {left+38} {cy-spread:.1f} {left-28} {cy-spread*1.7:.1f} Q {left-1} {cy-spread*.42:.1f} {left+37} {cy-3} Q {left-28} {cy+spread*1.72:.1f} {left-13} {cy+spread*1.86:.1f} Q {joint-24} {cy+33} {joint+3} {cy+8} Z'
 elif kind=='spear':
  tail=f'M {joint+3} {cy-10} Q {left+31} {cy-16} {left-39} {cy} Q {left+42} {cy+17} {joint+3} {cy+10} Z'
 elif kind=='diamond':
  tail=f'M {joint+3} {cy-10} Q {joint-56} {cy-spread*.71:.1f} {left-14} {cy} Q {joint-56} {cy+spread*.71:.1f} {joint+3} {cy+10} Z'
 else: # double
  tail=f'M {joint+3} {cy-9} Q {left+28} {cy-spread*1.11:.1f} {left-18} {cy-spread*1.15:.1f} L {left+21} {cy-3} L {left-18} {cy+spread*1.18:.1f} Q {left+28} {cy+spread*1.11:.1f} {joint+3} {cy+9} Z'
 tailRibs=''.join(f'<path d="M {joint-4} {cy} Q {left+38} {cy+(p-.5)*spread*.9:.1f} {left+11} {cy+(p-.5)*spread*2.05:.1f}" fill="none" stroke="{belly}" stroke-width="1.6" opacity=".53"/>' for p in [i/10 for i in range(11)])
 dorsalY=cy-h*.81
 dorsalTop=max(13,dorsalY-(25+f%4*9)*(1.5 if f in (12,15,21) else 1))
 dorsal=f'M {joint+35} {dorsalY:.1f} Q {joint+52} {dorsalTop:.1f} {joint+110} {dorsalTop+5:.1f} Q {joint+121} {dorsalY-3:.1f} {joint+171} {dorsalY+9:.1f} Z'
 pelvicY=cy+h*.77
 pelvicEnd=min(241,pelvicY+31+(f%4)*9)
 pelvic=f'M {joint+50} {pelvicY:.1f} Q {joint+109} {pelvicEnd+4:.1f} {joint+174} {pelvicY-3:.1f} Q {joint+120} {pelvicEnd-2:.1f} {joint+65} {pelvicY+4:.1f} Z'
 # 21 body patterns, designed to preserve each row identity.
 marks=[]
 typ=(c-1)%7
 if typ==0: # koi-like dark blotches
  for i in range(8):
   x=joint+55+(i*47)%168;y=cy+math.sin(i*1.4)*h*.6
   marks.append(f'<ellipse cx="{x}" cy="{y:.1f}" rx="{9+i%4*4}" ry="{5+i%3*5}" fill="{accent}" opacity=".82" transform="rotate({(i*37)%90-45} {x} {y:.1f})"/>')
 elif typ==1: # blue neon streak
  marks.append(f'<path d="M {joint+17} {cy-7} Q {joint+128} {cy-23} {nose+4} {cy-8}" stroke="{belly}" stroke-width="11" fill="none" opacity=".85"/>')
  marks.append(f'<path d="M {joint+18} {cy+11} Q {joint+128} {cy+2} {nose-6} {cy+12}" stroke="{accent}" stroke-width="12" fill="none" opacity=".86"/>')
 elif typ==2: # bars
  for i in range(6):
   x=joint+33+i*32
   marks.append(f'<path d="M {x} {cy-h*1.4:.1f} Q {x-15} {cy} {x+3} {cy+h*1.4:.1f}" stroke="{accent}" stroke-width="{11+i%3*2}" opacity=".83" fill="none"/>')
 elif typ==3: # clown bands
  for i in range(3):
   x=joint+45+i*71
   marks.append(f'<path d="M {x} {cy-h*1.5:.1f} Q {x-21} {cy} {x+4} {cy+h*1.5:.1f}" stroke="{accent}" stroke-width="18" fill="none" opacity=".88"/>')
   marks.append(f'<path d="M {x+7} {cy-h*1.5:.1f} Q {x-13} {cy} {x+11} {cy+h*1.5:.1f}" stroke="{belly}" stroke-width="4" fill="none" opacity=".8"/>')
 elif typ==4: # pearly scales
  for row in range(5):
   for col in range(12):
    x=joint+31+col*19+(row%2)*9;y=cy-h*.55+row*h*.3
    marks.append(f'<path d="M {x} {y:.1f} q 9 -4 14 0 q -4 8 -14 7" fill="none" stroke="{belly}" opacity=".47" stroke-width="1.4"/>')
 elif typ==5: # stripes and dots
  marks.append(f'<path d="M {joint+15} {cy-16} Q {joint+135} {cy-30} {nose} {cy-6}" stroke="{accent}" stroke-width="10" fill="none" opacity=".82"/>')
  for i in range(20):
   x=joint+27+(i*37)%209;y=cy-15+(i*31)%35
   marks.append(f'<circle cx="{x}" cy="{y}" r="{2+i%3}" fill="{belly}" opacity=".80"/>')
 else:
  for i in range(26):
   x=joint+23+(i*43)%218;y=cy-23+(i*19)%49
   marks.append(f'<ellipse cx="{x}" cy="{y}" rx="{2+i%4}" ry="{1+i%3}" fill="{accent if i%3 else belly}" opacity=".65"/>')
 # Extra individual iridescent scales; physical detail doesn't vanish when zoomed.
 scales=[]
 for row in range(6):
  for col in range(16):
   x=joint+22+col*14+(row%2)*7;y=cy-h*.80+row*h*.32
   scales.append(f'<path d="M {x} {y:.2f} q 7 -3 10 1 q -1 6 -9 8" stroke="{belly}" stroke-width=".95" fill="none" opacity=".28"/>')
 eyeX=nose-32;eyeY=cy-12
 mouthX=nose+3
 extra=''
 if c in (14,21):
  extra=f'<path d="M {mouthX-3} {cy+5} Q {mouthX+14} {cy+35} {mouthX+10} {cy+45} M {mouthX-2} {cy+5} Q {mouthX+23} {cy+21} {mouthX+27} {cy+28}" stroke="{belly}" stroke-width="2" fill="none" opacity=".84"/>'
 return (SVG_START+defs+clip+
   f'<path d="{tail}" fill="url(#fan)" stroke="{back}" stroke-width="3.2"/>'+tailRibs+
   f'<path d="{dorsal}" fill="url(#upper)" stroke="{back}" stroke-width="2.7"/>'+
   f'<path d="{pelvic}" fill="url(#fan)" stroke="{back}" stroke-width="2.3" opacity=".9"/>'+
   f'<path d="{silhouette}" fill="url(#skin)" stroke="{back}" stroke-width="3.3"/>'+
   '<g clip-path="url(#bodyClip)">'+''.join(marks)+''.join(scales)+
   f'<path d="M {joint+27} {cy-h*.30:.1f} Q {joint+170} {cy-h*.83:.1f} {nose-14} {cy-h*.22:.1f}" stroke="{belly}" stroke-width="5" fill="none" opacity=".30"/>'+
   '</g>'+
   f'<path d="M {nose-76} {cy-h*.42:.1f} Q {nose-95} {cy-1} {nose-76} {cy+h*.50:.1f}" stroke="{back}" stroke-width="2.5" fill="none" opacity=".50"/>'+
   f'<path d="M {nose-79} {cy-h*.42:.1f} Q {nose-98} {cy-1} {nose-78} {cy+h*.49:.1f}" stroke="{belly}" stroke-width="1.8" fill="none" opacity=".45"/>'+
   f'<path d="M {nose-109} {cy+3} Q {nose-122} {cy+25} {nose-150} {cy+40} Q {nose-112} {cy+53} {nose-95} {cy+21} Z" fill="url(#upper)" stroke="{back}" stroke-width="1.5" opacity=".87"/>'+
   f'<circle cx="{eyeX}" cy="{eyeY}" r="14.3" fill="{back}"/><circle cx="{eyeX}" cy="{eyeY}" r="11.5" fill="url(#eye)"/><circle cx="{eyeX+1}" cy="{eyeY+.3}" r="5.1" fill="#092232"/><circle cx="{eyeX-2.3}" cy="{eyeY-3.6}" r="2.4" fill="white" opacity=".94"/>'+
   f'<path d="M {nose-8} {cy+8} Q {nose+3} {cy+5} {mouthX} {cy+7}" stroke="{back}" stroke-width="2.3" fill="none"/><circle cx="{nose-4}" cy="{cy-2}" r="1.3" fill="{back}"/>'+extra+'</svg>')

def render_one(task):
 c,f,outdir,magic=task
 png=cairosvg.svg2png(bytestring=make_svg(c,f,magic).encode('utf8'),output_width=WIDTH,output_height=HEIGHT)
 image=Image.open(BytesIO(png)).convert('RGBA')
 if magic is None: path=Path(outdir)/f'C{c:02d}_F{f:02d}.png'
 else: path=Path(outdir)/f'M{magic}.png'
 image.save(path,optimize=True,compress_level=6)
 alpha=image.getchannel('A');bbox=alpha.getbbox()
 assert bbox and bbox[0]>=MARGIN and bbox[1]>=MARGIN and bbox[2]<=WIDTH-MARGIN and bbox[3]<=HEIGHT-MARGIN, (c,f,magic,bbox)
 return [c,f,path.stat().st_size,list(bbox)]

def font(size):
 for path in ['/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf','/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf']:
  if Path(path).exists():return ImageFont.truetype(path,size)
 return ImageFont.load_default()

def build_catalog(outdir, target):
 bg=Image.new('RGB',PREVIEW,(8,35,55))
 transparent=Image.new('RGBA',PREVIEW,(0,0,0,0))
 draw=ImageDraw.Draw(bg)
 tx,ty=32,92;dw,dh=192,96
 draw.rounded_rectangle((18,18,4078,2284),radius=24,outline=(53,119,139),width=3)
 draw.text((47,28),'AGUA-LIFE  /  MATRIZ GENETICA 4K',font=font(33),fill=(223,248,245))
 draw.text((2732,32),'21 CORPOS  x  21 CAUDAS',font=font(24),fill=(128,204,221))
 for i in range(21):
  draw.text((tx+i*dw+78,68),f'F{i+1}',font=font(17),fill=(159,213,228))
  draw.text((10,ty+i*dh+35),f'{i+1:02d}',font=font(15),fill=(173,213,227))
 for c in range(1,22):
  for f in range(1,22):
   x=tx+(f-1)*dw; y=ty+(c-1)*dh
   draw.rectangle((x+1,y+1,x+dw-2,y+dh-2),fill=(9+(c%3)*3,48+(f%4)*2,66+(c%4)*2),outline=(35,82,99),width=1)
   sprite=Image.open(Path(outdir)/f'C{c:02d}_F{f:02d}.png').convert('RGBA')
   sprite.thumbnail((dw-12,dh-10),Image.Resampling.LANCZOS)
   bg.paste(sprite,(x+(dw-sprite.width)//2,y+(dh-sprite.height)//2),sprite)
   transparent.alpha_composite(sprite,(x+(dw-sprite.width)//2,y+(dh-sprite.height)//2))
 magicY=2144
 draw.line((35,2122,4061,2122),fill=(92,174,185),width=2)
 draw.text((45,2136),'7 PEIXES MAGICOS',font=font(21),fill=(255,218,148))
 for i in range(7):
  x=720+i*472
  sprite=Image.open(Path(outdir)/f'M{i}.png').convert('RGBA')
  sprite.thumbnail((345,125),Image.Resampling.LANCZOS)
  bg.paste(sprite,(x+(345-sprite.width)//2,magicY+(125-sprite.height)//2),sprite)
  transparent.alpha_composite(sprite,(x+(345-sprite.width)//2,magicY+(125-sprite.height)//2))
  draw.text((x+145,2272),f'M{i}',font=font(15),fill=(212,237,228))
 Path(target).parent.mkdir(parents=True,exist_ok=True)
 bg.save(target,optimize=True)
 transparent.save(Path(target).with_name('atlas_4k_rgba.png'),optimize=True)

def run(out,workers=4):
 root=Path(out);root.mkdir(parents=True,exist_ok=True)
 folder=root/'sprites';folder.mkdir(parents=True,exist_ok=True)
 tasks=[(c,f,str(folder),None) for c in range(1,22) for f in range(1,22)]
 tasks += [(c,f,str(folder),i) for i,(c,f) in enumerate(MAGIC)]
 with ProcessPoolExecutor(max_workers=max(1,workers)) as pool:
  results=list(pool.map(render_one,tasks,chunksize=12))
 assert len(results)==448
 bounds=[[None]*21 for _ in range(21)]
 for c,f,_,bbox in results[:441]:bounds[c-1][f-1]=bbox
 meta={'version':2,'mode':'original-vector','grid':[21,21],'cell':[WIDTH,HEIGHT],
       'catalog':[4096,2304], 'atlas':[4096,2304], 'cell_thumb':[192,96],
       'grid_origin':[32,92], 'magic_origin':[720,2144], 'magic_step':472,
       'margin':MARGIN,
       'sprite_pattern':'sprites/C%02d_F%02d.png','magic_pattern':'sprites/M%d.png',
       'magic_pairs':MAGIC,'bounds':bounds,'images':448,
       'source':'Procedural SVG illustration; previous user-supplied pixel atlas preserved separately.'}
 (root/'manifest.json').write_text(json.dumps(meta,indent=2,ensure_ascii=False),encoding='utf8')
 build_catalog(folder,root/'catalog_4k.png')
 # Preview human readable; six entirely different body + fin combinations.
 examples=[(1,1),(2,12),(3,15),(4,21),(14,7),(21,17)]
 sheet=Image.new('RGB',(1500,625),(9,42,62));d=ImageDraw.Draw(sheet)
 for i,(c,f) in enumerate(examples):
  px=(i%3)*500;py=(i//3)*310
  d.rounded_rectangle((px+8,py+14,px+490,py+306),radius=18,fill=(18,70,90),outline=(51,119,140),width=2)
  fish=Image.open(folder/f'C{c:02d}_F{f:02d}.png').convert('RGBA')
  sheet.paste(fish,(px,py+38),fish)
  d.text((px+25,py+17),f'C{c} + F{f}',font=font(24),fill=(235,246,242))
 sheet.save(root/'examples.png')
 print('Created',len(results),'transparent high-detail original sprites;',root/'catalog_4k.png',flush=True)
 return meta

if __name__=='__main__':
 parser=argparse.ArgumentParser()
 parser.add_argument('--out',default='assets/fish/hd')
 parser.add_argument('--workers',type=int,default=min(4,os.cpu_count() or 2))
 args=parser.parse_args()
 run(args.out,args.workers)