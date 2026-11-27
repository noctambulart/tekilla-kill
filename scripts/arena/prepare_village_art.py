"""Normalize issue60's generated sheets; never repaint the source artwork.

Run with Python + Pillow. Shared scale/ground anchor/palette for each complete
character strip; fixed production frames. Original PNGs and prompts are retained.
"""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LOT = ROOT / 'output/arena/2026-11-25-integration'
SCENE = ROOT / 'godot/scenes/arroyo_seco/assets/village'
PLAYERS = ROOT / 'godot/scenes/character/assets/village'
CELL = 144
KINDS = [
    ('crate',36,36), ('barrel',36,36), ('table',56,56), ('couch',112,44), ('chair',24,28),
    ('pot',24,26), ('cart',104,48), ('counter',128,32), ('house_wood',240,176), ('house_adobe',240,176),
    ('goods',96,32), ('trough',80,32), ('cactus',24,42), ('rocks',56,32), ('tools',80,36),
    ('mugs',64,24), ('crate_broken',36,28), ('chair_broken',28,22), ('pot_broken',24,18), ('store_counter',144,40),
]


def binary(image):
    image = image.convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda a:255 if a >=128 else 0))
    return image


def tiles(path,columns,rows):
    sheet=binary(Image.open(path))
    result=[]
    for row in range(rows):
        for col in range(columns):
            result.append(sheet.crop((round(col*sheet.width/columns),round(row*sheet.height/rows),
                                      round((col+1)*sheet.width/columns),round((row+1)*sheet.height/rows))))
    return result


def pack(frames,path):
    joined=Image.new('RGBA',(CELL*len(frames),CELL))
    for i,frame in enumerate(frames):joined.alpha_composite(frame,(i*CELL,0))
    joined.save(path)


def body(style):
    source=LOT/'source'/f'{style}-raw.png'
    cells=tiles(source,6,2)
    crops=[cell.crop(cell.getbbox()) for cell in cells]
    height=108 if style=='poncho' else 96
    scale=min(96/max(c.width for c in crops),height/max(c.height for c in crops))
    frames=[]
    for crop in crops:
        size=(max(1,round(crop.width*scale)),max(1,round(crop.height*scale)))
        piece=crop.resize(size,Image.Resampling.NEAREST)
        # Align the hat, not the swaying fabric below it, on the common aiming x.
        upper=piece.crop((0,0,piece.width,round(piece.height*.55)))
        bounds=upper.getbbox()
        hat_center=(bounds[0]+bounds[2])/2
        frame=Image.new('RGBA',(CELL,CELL))
        frame.alpha_composite(piece,(round(72-hat_center),126-size[1]))
        frames.append(frame)
    joined=Image.new('RGBA',(CELL*12,CELL))
    for i,frame in enumerate(frames):joined.alpha_composite(frame,(i*CELL,0))
    alpha=joined.getchannel('A')
    joined=joined.quantize(colors=64,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert('RGBA')
    joined.putalpha(alpha)
    frames=[joined.crop((i*CELL,0,(i+1)*CELL,CELL)) for i in range(12)]
    idle=frames[6]
    walk=frames[:6]; walk[0]=idle.copy()
    dash=frames[7:11]; dash[0]=idle.copy(); dash[-1]=idle.copy()
    dest=PLAYERS/style;dest.mkdir(parents=True,exist_ok=True)
    quality={}
    for state,poses in [('idle',[idle]),('walk',walk),('dash',dash)]:
        assert all(p.getbbox() for p in poses)
        unique=len({p.tobytes() for p in poses})
        assert unique >= (1 if state=='idle' else 3)
        pack(poses,dest/f'{state}.png')
        hats=[]
        for pose in poses:
            mask=Image.new('RGBA',(CELL,CELL))
            mask.paste(pose.crop((0,0,CELL,93)),(0,0))
            hats.append(mask)
        pack(hats,dest/f'hat_{state}.png')
        quality[state]={'frames':len(poses),'distinct':unique}
    return {'source':str(source.relative_to(ROOT)),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),
            'shared_scale':scale,'ground_anchor':[72,126],'aim_pivot':[72,78],'quality':quality}


def main():
    SCENE.mkdir(parents=True,exist_ok=True)
    source=LOT/'source/environment-raw.png'
    cells=tiles(source,5,4)
    items={}
    for cell,(kind,width,height) in zip(cells,KINDS):
        if kind=='table':
            # A dedicated edit removes the seed's attached chairs; each chair
            # remains an independent prop with its own matching collision.
            cell=binary(Image.open(LOT/'source/table-raw.png'))
        bounds=cell.getbbox()
        assert bounds,kind
        crop=cell.crop(bounds)
        crop=crop.resize((width*3,height*3),Image.Resampling.NEAREST)
        crop.save(SCENE/f'{kind}.png')
        items[kind]={'path':f'res://scenes/arroyo_seco/assets/village/{kind}.png',
                     'native_size':[width*3,height*3],'base_world_size':[width,height]}
        if kind=='table':
            table_source=LOT/'source/table-raw.png'
            items[kind].update(source=str(table_source.relative_to(ROOT)),
                               sha256=hashlib.sha256(table_source.read_bytes()).hexdigest())
    provenance={'issue':60,'source':str(source.relative_to(ROOT)),
                'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'grid':[5,4],
                'normalization':'Alpha threshold128, occupied bounds, nearest-neighbor export; source untouched.',
                'items':items}
    (SCENE/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n')
    characters={style:body(style) for style in ['poncho','garcia']}
    # Keep the existing aiming/recoil layer, which is already tied to real shots.
    for name in ['arm_idle.png','walk_arm.png','fire.png']:
        shutil.copy2(PLAYERS.parent/'refined/poncho'/name,PLAYERS/'poncho'/name)
    (PLAYERS/'provenance.json').write_text(json.dumps({'issue':60,'cell':[144,144],
        'draw_size_world':[48,48],'ground_y_world':16,'characters':characters,
        'weapon':'Existing common provisional weapon/recoil layer, copied without change.'},ensure_ascii=False,indent=2)+'\n')
    print('Village artwork:20 objects and two normalized animated characters exported.')


if __name__=='__main__':main()
