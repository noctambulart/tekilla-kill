"""Export newly drawn detail at 3 texels per logical pixel; preserve world size.

Pillow only. The generated sheets are retained intact. Each complete character
sheet uses one scale and one 64-color palette, binary alpha and common anchors.
"""
import hashlib
import json
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
LOT = ROOT / 'output/sprites/players/issue-58/v2'
DEST = ROOT / 'godot/scenes/character/assets/refined'
CELL = 144
DENSITY = 3
QUALITY = {}


def sheet_cells(name):
    source = LOT/'source'/f'{name}-refined-raw.png'
    image = Image.open(source).convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    crops = []
    for row in range(2):
        for col in range(6):
            tile = image.crop((round(col*image.width/6),round(row*image.height/2),
                               round((col+1)*image.width/6),round((row+1)*image.height/2)))
            if not tile.getbbox():
                raise ValueError(f'Empty {name} cell {row},{col}')
            crops.append(tile.crop(tile.getbbox()))
    return crops, source


def pack(frames, path):
    image = Image.new('RGBA',(CELL*len(frames),CELL))
    for n,frame in enumerate(frames):
        assert frame.getbbox() and set(frame.getchannel('A').tobytes()) == {0,255}
        image.alpha_composite(frame,(CELL*n,0))
    image.save(path)
    return image


def reduce_palette(frames):
    # One palette for the entire sheet; alpha is kept separately and restored.
    joined = Image.new('RGBA',(CELL*len(frames),CELL))
    for n,frame in enumerate(frames):
        joined.alpha_composite(frame,(CELL*n,0))
    alpha = joined.getchannel('A')
    joined = joined.quantize(colors=64,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert('RGBA')
    joined.putalpha(alpha)
    return [joined.crop((n*CELL,0,(n+1)*CELL,CELL)) for n in range(len(frames))]


def normalize(name, weapon=False):
    crops,source=sheet_cells(name)
    max_size=(45,24) if weapon else (96,90)
    scale=min(max_size[0]/max(c.width for c in crops),max_size[1]/max(c.height for c in crops))
    frames=[]
    for crop in crops:
        size=tuple(max(1,round(side*scale)) for side in crop.size)
        piece=crop.resize(size,Image.Resampling.NEAREST)
        frame=Image.new('RGBA',(CELL,CELL))
        at=(93,78-size[1]//2) if weapon else (72-size[0]//2,120-size[1])
        assert at[0]+size[0]<=CELL and at[1]+size[1]<=CELL
        frame.alpha_composite(piece,at)
        frames.append(frame)
    frames=reduce_palette(frames)
    QUALITY[name]={'source':str(source.relative_to(ROOT)),
        'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'shared_scale':scale,
        'native_bbox':list(frames[6].getbbox()),
        'visible_colors':sum(1 for count,color in frames[6].getcolors(CELL*CELL) if color[3]),
        'world_body_width':(frames[6].getbbox()[2]-frames[6].getbbox()[0])/DENSITY}
    return frames


def export_body(style):
    frames=normalize(style)
    idle=frames[6]
    walk=frames[:6]
    dash=frames[7:11]
    walk[0]=idle.copy()
    walk[3]=idle.copy()
    dash[0]=idle.copy()
    dash[-1]=idle.copy()
    folder=DEST/style
    folder.mkdir(parents=True,exist_ok=True)
    for state,poses in [('idle',[idle]),('walk',walk),('dash',dash)]:
        distinct=len({p.tobytes() for p in poses})
        assert distinct>=3 if len(poses)>1 else distinct==1
        pack(poses,folder/f'{state}.png')
        masks=[]
        for pose in poses:
            mask=Image.new('RGBA',(CELL,CELL))
            mask.paste(pose.crop((0,0,CELL,96)),(0,0))
            masks.append(mask)
        pack(masks,folder/f'hat_{state}.png')
        QUALITY[style][state]={'frames':len(poses),'distinct':distinct}


def export_weapon():
    frames=normalize('weapon',True)
    idle=frames[6]
    # Preserve the movement track validated on Poncho V4 in logical pixels.
    track=[(0,0),(-1,1),(0,0),(1,-1),(0,-1),(-1,-1)]
    walking=[]
    for x,y in track:
        frame=Image.new('RGBA',(CELL,CELL))
        frame.alpha_composite(idle,(x*DENSITY,y*DENSITY))
        assert frame.getchannel('A').histogram()[255]==idle.getchannel('A').histogram()[255]
        walking.append(frame)
    folder=DEST/'poncho'
    pack([idle],folder/'arm_idle.png')
    pack(walking,folder/'walk_arm.png')
    fire=frames[7:11]
    fire[0]=idle.copy()
    fire[-1]=idle.copy()
    pack(fire,folder/'fire.png')


def comparison():
    image=Image.new('RGB',(1000,340),'#eedcb3')
    draw=ImageDraw.Draw(image)
    font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',20)
    draw.text((24,16),'Même taille à l’écran · détail des dessins repris pour le 1080p',fill='#392a22',font=font)
    for i,(style,refined) in enumerate([('poncho',False),('poncho',True),('garcia',False),('garcia',True)]):
        base=DEST/style if refined else DEST.parent/style
        body=Image.open(base/'idle.png').convert('RGBA')
        gun_base=DEST/'poncho' if refined else DEST.parent/'poncho'
        gun=Image.open(gun_base/'arm_idle.png').convert('RGBA')
        mask=Image.open(base/'hat_idle.png').convert('RGBA')
        body.alpha_composite(gun)
        body.alpha_composite(mask)
        body=body.resize((CELL,CELL),Image.Resampling.NEAREST)
        x=48+i*245
        image.paste(body,(x,90),body)
        label=style.capitalize()+(' · repris' if refined else ' · précédent')
        draw.text((20+i*245,255),label,fill='#392a22',font=font)
    (LOT/'review').mkdir(exist_ok=True)
    image.save(LOT/'review/native-comparison.png')


def main():
    export_body('poncho')
    export_body('garcia')
    export_weapon()
    provenance={'issue':58,'version':'refined-v2','source_cell':[CELL,CELL],
        'draw_size_world':[48,48],'texels_per_logical_pixel':DENSITY,
        'source_ground_anchor':[72,120],'source_aim_pivot':[72,78],
        'runtime_anchor_world':[24,26],
        'contract':'Higher drawing density inside the same world-space footprint; 1:1 texels at 1080p, nearest-neighbor reduction at smaller windows or overview zoom.',
        'quality':QUALITY,'weapon_scope':'Still a common provisional prop layer, not final Garcia shotgun action art.'}
    (DEST/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n')
    comparison()
    print(json.dumps(QUALITY,ensure_ascii=False,indent=2))


def game_comparison():
    """Juxtapose unscaled crops of actual Godot captures, not mockups."""
    review=LOT/'review'
    paths=[review/'legacy/directions-in-game.png',review/'directions-in-game.png']
    if not all(p.exists() for p in paths):
        return
    renders=[Image.open(p).convert('RGB') for p in paths]
    assert all(im.size==(1920,1080) for im in renders)
    image=Image.new('RGB',(1000,365),'#eedcb3')
    draw=ImageDraw.Draw(image)
    font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf',20)
    draw.text((20,12),'Captures Godot en 1080p · même cadrage, taille et direction',font=font,fill='#392a22')
    for col,(style,version) in enumerate([(0,0),(0,1),(1,0),(1,1)]):
        top=300+style*396
        crop=renders[version].crop((30,top,240,top+270))
        image.paste(crop,(20+col*245,78))
        label=('Poncho' if style==0 else 'Garcia')+(' · repris' if version else ' · précédent')
        draw.text((20+col*245,48),label,font=font,fill='#392a22')
    image.save(review/'godot-before-after.png')


if __name__=='__main__':
    if '--compare-only' in sys.argv:
        game_comparison()
    else:
        main()
        game_comparison()
