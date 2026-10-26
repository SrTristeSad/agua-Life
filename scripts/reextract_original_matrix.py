#!/usr/bin/env python3
"""Reconstrói a matriz original aprovada em caixas separadas sem peixes vizinhos.
Mantém a arte original, sem inventar sprites ou substituir as cores.
Requisitos no build: Pillow, numpy, opencv-python-headless.
"""
import argparse, json
from pathlib import Path
from io import BytesIO
import cv2
import numpy as np
from PIL import Image

X=[80,154,229,304,378,452,527,602,676,750,825,900,974,1048,1123,1198,1272,1346,1421,1496,1570]
Y=[50,88,123,159,191,230,269,303,342,376,409,446,480,510,547,583,617,653,687,723,765]
CW,CH=192,96
MW,MH=576,204

def source_image(path):
    path=Path(path)
    if path.is_file():
        im=Image.open(path)
    else:
        part1=Path(str(path)+'.part01')
        part2=Path(str(path)+'.part02')
        if not part1.is_file() or not part2.is_file():
            raise FileNotFoundError('Missing source matrix or both .part01/.part02')
        im=Image.open(BytesIO(part1.read_bytes()+part2.read_bytes()))
    if im.size!=(1672,941): raise ValueError('Wrong input dimensions: '+str(im.size))
    return im.convert('RGB')

def bounds_for(row,col):
    cx,cy=X[col],Y[row]
    left=round((cx+X[col-1])/2)+1 if col else 39
    right=round((cx+X[col+1])/2)-1 if col<20 else 1648
    top=round((cy+Y[row-1])/2)+1 if row else 30
    bottom=round((cy+Y[row+1])/2)-1 if row<20 else 786
    return (left,top,right,bottom)

def remove_other_fish(region,seed_x,seed_y):
    a=np.asarray(region,dtype=np.uint8)
    h,w=a.shape[:2]
    dark=(a[:,:,0]<40)&(a[:,:,1]<85)&(a[:,:,2]<125)
    cold=a[dark]
    background=np.median(cold,axis=0) if len(cold)>40 else np.array([3.,30.,57.])
    difference=np.linalg.norm(a.astype(np.float32)-background,axis=2)
    fg=np.uint8(difference>23)
    n,labels,stats,centers=cv2.connectedComponentsWithStats(fg,8)
    candidates=[]
    for i in range(1,n):
        bx,by,bw,bh,area=stats[i]
        if area<10: continue
        cx,cy=centers[i]
        dist=((cx-seed_x)/max(1,w*.37))**2*.32+((cy-seed_y)/max(1,h*.39))**2*.55
        candidates.append((area/(1+dist),i))
    if not candidates:return Image.new('RGBA',(w,h)),0
    chosen=max(candidates)[1]
    mask=np.uint8(labels==chosen)
    # Recupera só detalhes pequenos que ficam realmente juntos do corpo.
    near=cv2.dilate(mask,np.ones((3,3),np.uint8))
    for i in range(1,n):
        if i==chosen: continue
        if stats[i,4]>max(35,int(stats[chosen,4]*.05)):continue
        other=np.uint8(labels==i)
        if np.any((near>0)&(other>0)):mask[other>0]=1
    mask=cv2.morphologyEx(mask,cv2.MORPH_CLOSE,np.ones((2,2),np.uint8))
    mask=cv2.dilate(mask,np.ones((3,3),np.uint8))
    alpha=np.clip((difference-7)/21,0,1)*mask.astype(np.float32)
    alpha[0,:]*=.15;alpha[-1,:]*=.15
    alpha[:,0]*=.15;alpha[:,-1]*=.15
    rgb=np.clip((a.astype(np.float32)-background[None,None,:]*(1-alpha[:,:,None]))/
                np.maximum(alpha[:,:,None],.24),0,255)
    image=np.uint8(np.concatenate((rgb,alpha[:,:,None]*255),axis=2))
    return Image.fromarray(image,'RGBA'),int(np.count_nonzero(alpha>.15))

def center_sprite(image,width,height):
    bb=image.getbbox()
    if not bb:return Image.new('RGBA',(width,height)),[0,0,0,0]
    piece=image.crop(bb)
    scale=min(width*.84/piece.width,height*.79/piece.height)
    size=(max(1,round(piece.width*scale)),max(1,round(piece.height*scale)))
    scaled=piece.convert('RGBa').resize(size,Image.Resampling.LANCZOS).convert('RGBA')
    x=(width-size[0])//2;y=(height-size[1])//2
    canvas=Image.new('RGBA',(width,height))
    canvas.alpha_composite(scaled,(x,y))
    return canvas,[x,y,x+size[0],y+size[1]]

def build(source,old_atlas,output):
    original=source_image(source)
    baseline=Image.open(old_atlas).convert('RGBA')
    if baseline.size!=(2688,1480):raise ValueError('Legacy atlas size mismatch')
    atlas=Image.new('RGBA',(4032,2220))
    rows=[];audit=[]
    for row in range(21):
        boxes=[]
        for col in range(21):
            left,top,right,bottom=bounds_for(row,col)
            source_patch=np.asarray(original.crop((left,top,right,bottom)))
            extracted,count=remove_other_fish(source_patch,X[col]-left,Y[row]-top)
            if count<100:raise RuntimeError('Empty or damaged cell C%d F%d'%(row+1,col+1))
            cleaned,bbox=center_sprite(extracted,CW,CH)
            atlas.alpha_composite(cleaned,(col*CW,row*CH))
            boxes.append(bbox)
            audit.append({'body':row+1,'fin':col+1,'pixels':count,'source_crop':[left,top,right,bottom]})
        rows.append(boxes)
    magics=[]
    for n in range(7):
        part=baseline.crop((n*384,21*64,(n+1)*384,21*64+136))
        box=part.getbbox()
        if not box:raise RuntimeError('Missing magic fish '+str(n))
        cleaned,bbox=center_sprite(part,MW,MH)
        atlas.alpha_composite(cleaned,(n*MW,21*CH))
        magics.append(bbox)
    old_data=json.loads(Path(str(old_atlas).replace('.png','.json')).read_text(encoding='utf-8'))
    meta={'version':3,'source':'user-approved original matrix','no_redraw':True,
          'grid':[21,21],'cell':[CW,CH],'magic':[MW,MH],
          'atlas':[4032,2220],'bounds':rows,'magic_bounds':magics,
          'magic_pairs':old_data['magic_pairs'],
          'method':'strict-cell-intervals-plus-core-component',
          'limitation':'Source has overlapping fish in F12/F15/F21; hidden fin pixels are not recoverable.'}
    output=Path(output);output.parent.mkdir(parents=True,exist_ok=True)
    atlas.save(output,optimize=True)
    output.with_suffix('.json').write_text(json.dumps(meta,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
    output.with_suffix('.audit.json').write_text(json.dumps(audit,separators=(',',':'))+'\n',encoding='utf-8')
    print('OK extracted 441 fish and 7 magic fish, no adjacent-cell fragments')
if __name__=='__main__':
    ap=argparse.ArgumentParser()
    ap.add_argument('--source',default='assets/fish/matrix/source_matrix.png')
    ap.add_argument('--old-atlas',default='assets/fish/matrix/atlas_441.png')
    ap.add_argument('--out',default='assets/fish/matrix/atlas_original_clean_4k.png')
    a=ap.parse_args()
    build(a.source,a.old_atlas,a.out)
