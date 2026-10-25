#!/usr/bin/env python3
"""Recorta a matriz 21x21 escolhida pelo usuário em um atlas RGBA.
Preserva pixels desenhados; não inventa peixes nem interpola 441 sprites à mão.
Requisitos apenas para o exportador: Pillow + NumPy + OpenCV.
"""
from pathlib import Path
from io import BytesIO
import argparse, json
import cv2
import numpy as np
from PIL import Image

ROWS=21;COLS=21
X0,STEP_X=80.,74.5
YS=[50,88,123,159,191,230,269,303,342,376,409,446,480,510,547,583,617,653,687,723,765]
CW,CH=128,64
MAGIC_BOUNDS=[(15,252),(252,488),(488,722),(722,952),(952,1185),(1185,1418),(1418,1671)]
MW,MH=384,136
SOURCE_SIZE=(1672,941)

def sprite_from_crop(region, anchor_x=None, anchor_y=None, min_area=15):
 a=np.asarray(region.convert('RGB'),dtype=np.float32);h,w=a.shape[:2]
 border=np.concatenate([a[:3].reshape(-1,3),a[-3:].reshape(-1,3),a[:,:3].reshape(-1,3),a[:,-3:].reshape(-1,3)])
 cold=border[(border[:,0]<22)&(border[:,1]<85)&(border[:,2]<125)]
 bg=np.median(cold if len(cold)>35 else border,axis=0)
 diff=np.sqrt(np.sum((a-bg)**2,axis=2))
 binary=(diff>13).astype('uint8')
 n,lbl,stats,centers=cv2.connectedComponentsWithStats(binary,8)
 if n<2:return Image.new('RGBA',region.size)
 # A cor neon de uma cauda vizinha pode aparecer no crop; escolha o grupo
 # que coincide com o centro previsto do peixe, não um fragmento na borda.
 midx=w/2 if anchor_x is None else anchor_x
 midy=h/2 if anchor_y is None else anchor_y
 candidates=[]
 for i in range(1,n):
  x,y,bw,bh,area=stats[i]
  if area<min_area:continue
  cx,cy=centers[i]
  d=((cx-midx)/max(1,w*.45))**2+((cy-midy)/max(1,h*.50))**2
  candidates.append((area/(1+2.8*d),i))
 if not candidates:return Image.new('RGBA',region.size)
 _,primary=max(candidates)
 main=(lbl==primary).astype('uint8')
 bx,by,bw,bh,ba=stats[primary]
 for i in range(1,n):
  if i==primary:continue
  x,y,ww,hh,area=stats[i]
  cx,cy=centers[i]
  # Detalhes verdadeiros só se muito próximos da anatomia, sem tocar
  # bordas do crop (onde fragmentos de vizinhos aparecem).
  near=(x<bx+bw+3 and x+ww>bx-3 and y<by+bh+3 and y+hh>by-3)
  safe=(x>4 and y>5 and x+ww<w-4 and y+hh<h-5)
  close_to_center=(abs(cy-midy)<19 and abs(cx-midx)<48)
  if near and safe and close_to_center and area>=max(min_area,int(ba*.035)):
   main[lbl==i]=1
 main=cv2.morphologyEx(main,cv2.MORPH_CLOSE,np.ones((2,2),np.uint8))
 alpha=np.where(main>0,np.clip((diff-7)/18,0,1),0)
 fringe=cv2.dilate(main,np.ones((3,3),np.uint8))
 alpha=np.where((fringe>0)&(diff>7),np.maximum(alpha,np.clip((diff-7)/22,0,1)),alpha)
 recovered=(a-bg*(1-alpha[:,:,None]))/np.maximum(.12,alpha[:,:,None])
 rgba=np.dstack([np.clip(recovered,0,255),np.clip(alpha*255,0,255)])
 return Image.fromarray(rgba.astype('uint8'),'RGBA')

def normalize(sprite,width,height):
 box=sprite.getbbox()
 if box is None:return Image.new('RGBA',(width,height)),None
 # Normaliza os centros dos peixes para nadarem dentro do mesmo espaço.
 piece=sprite.crop(box)
 dest=Image.new('RGBA',(width,height),(0,0,0,0))
 if piece.width>width or piece.height>height:
  piece.thumbnail((width,height),Image.Resampling.LANCZOS)
 left=(width-piece.width)//2;top=(height-piece.height)//2
 dest.paste(piece,(left,top))
 return dest,(left,top,left+piece.width,top+piece.height)

def run(source,target):
 src_file=Path(source)
 if src_file.is_file():
  src=Image.open(src_file).convert('RGB')
 else:
  first=Path(str(src_file)+'.part01')
  second=Path(str(src_file)+'.part02')
  if not first.is_file() or not second.is_file():
   raise FileNotFoundError('Nem imagem original nem seus dois fragmentos foram encontrados: '+str(src_file))
  src=Image.open(BytesIO(first.read_bytes()+second.read_bytes())).convert('RGB')
 if src.size!=SOURCE_SIZE:raise ValueError(f'Matriz de {SOURCE_SIZE} pixels necessária, recebida {src.size}')
 result=Image.new('RGBA',(ROWS*CW,ROWS*CH+MH))
 bounds=[]
 for row in range(ROWS):
  arr=[]
  for col in range(COLS):
   xc=round(X0+col*STEP_X);yc=YS[row]
   # F21 tem nadadeiras e cabeças mais longas que outros tipos.
   # A janela não invade os títulos, mesmo na primeira e última linha.
   sx=xc-55 if col==20 else xc-53
   ex=xc+82 if col==20 else xc+54
   sy=yc-29;ey=yc+30
   patch=src.crop((sx,sy,ex,ey))
   cx=xc-sx+(20 if col==20 else 7)
   extracted=sprite_from_crop(patch,anchor_x=cx,anchor_y=yc-sy)
   # A folha recebida tem caudas volumosas que invadem linhas vizinhas.
   # Atenuamos somente pontas na zona onde elas se sobrepoem, mantendo
   # toda a anatomia mais proxima do centro original de cada linha.
   rgba=np.array(extracted,dtype=np.uint8)
   maximum=23 if col in (11,14,20) else 20
   for py in range(rgba.shape[0]):
    dist=abs(py-(yc-sy))
    if dist>maximum:
     fade=max(0.0,1-(dist-maximum)/3)
     rgba[py,:,3]=np.uint8(np.round(rgba[py,:,3].astype(float)*fade))
   extracted=Image.fromarray(rgba,'RGBA')
   tile,box=normalize(extracted,CW,CH)
   if box is None:raise ValueError('Vazio: C'+str(row+1)+'F'+str(col+1))
   result.alpha_composite(tile,(col*CW,row*CH))
   arr.append(box)
  bounds.append(arr)
 magic=[]
 for i,(sx,ex) in enumerate(MAGIC_BOUNDS):
  patch=src.crop((sx,834,ex,940))
  extracted=sprite_from_crop(patch,anchor_x=(ex-sx)/2,anchor_y=55,min_area=20)
  tile,box=normalize(extracted,MW,MH)
  if box is None:raise ValueError('M'+str(i)+' vazio')
  # Fixar sete mágicos em uma faixa de altura MH. O espaço horizontal
  # reservado para cada um é MW e pode ser maior que a matriz principal.
  result.alpha_composite(tile,(i*MW,ROWS*CH))
  magic.append(box)
 target=Path(target);target.parent.mkdir(parents=True,exist_ok=True)
 result.save(target,optimize=True)
 metadata={'version':1,'source_size':list(SOURCE_SIZE),'grid':[21,21],
  'cell':[CW,CH],'magic':[MW,MH], 'atlas':list(result.size),
  'matrix_order':'rows=body 1..21; columns=fins 1..21',
  'row_centers':YS,'column_centers':[round(X0+i*STEP_X) for i in range(21)],
  'bounds':bounds,'magic_bounds':magic,
  'magic_pairs':[[21,17],[15,15],[12,12],[11,10],[6,9],[14,7],[8,8]],
  'source_is_user_supplied':True,
  'notes':'The game cuts the transparent atlas into independently animated parts at runtime.'}
 target.with_suffix('.json').write_text(json.dumps(metadata,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
 preview=Image.new('RGB',(1170,756),(10,58,77))
 for r in range(6):
  for c in range(7):
   row=(r*3+c)%21;col=(r+c*3)%21
   tile=result.crop((col*CW,row*CH,(col+1)*CW,(row+1)*CH))
   tile=tile.resize((150,72),Image.Resampling.LANCZOS)
   preview.paste(tile,(5+c*166,12+r*122),tile)
 preview.save(target.with_name('preview_samples.png'))
 print('441 peixes e 7 mágicos extraídos; RGBA',result.size,'bytes',target.stat().st_size)
 return result

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('source');p.add_argument('output')
 a=p.parse_args();run(a.source,a.output)