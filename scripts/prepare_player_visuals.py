"""Package existing Poncho art and normalize Garcia strips. Requires Pillow.

Uses one scale/palette per strip and the same source ground anchor (24,40).
The runtime aligns the source aim pivot (24,26) to the existing actor origin,
so guns and real projectiles agree without changing physics or shot rules.
"""
import hashlib
import json
import shutil
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOT = ROOT / 'output/sprites/players/issue-58'
SOURCE = LOT / 'source'
DEST = ROOT / 'godot/scenes/character/assets'
PONCHO = ROOT / 'output/sprites/poncho/issue-38/exports/v4'


def clean(path):
    im = Image.open(path).convert('RGBA')
    im.putalpha(im.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    return im


def pack(frames, path):
    atlas = Image.new('RGBA', (48 * len(frames), 48))
    for n, frame in enumerate(frames):
        assert frame.size == (48, 48) and frame.getbbox()
        assert set(frame.getchannel('A').tobytes()) <= {0, 255}
        atlas.alpha_composite(frame, (n * 48, 0))
    atlas.save(path)


def hat(frame):
    mask = Image.new('RGBA', (48, 48))
    mask.paste(frame.crop((0, 0, 48, 32)), (0, 0))
    return mask


def normalize_strip(name, count, palette, seed):
    raw = clean(SOURCE / f'garcia-{name}-raw.png')
    crops = []
    for n in range(count):
        cell = raw.crop((round(n*raw.width/count), 0, round((n+1)*raw.width/count), raw.height))
        bounds = cell.getbbox()
        if not bounds:
            raise ValueError(f'Empty {name} cell {n}')
        crops.append(cell.crop(bounds))
    scale = min(32/max(c.width for c in crops), 29/max(c.height for c in crops))
    frames = []
    for crop in crops:
        dims = tuple(max(1, round(d*scale)) for d in crop.size)
        frame = Image.new('RGBA', (48,48))
        frame.alpha_composite(crop.resize(dims,Image.Resampling.NEAREST), (24-dims[0]//2,40-dims[1]))
        alpha = frame.getchannel('A')
        frame = frame.convert('RGB').quantize(palette=palette,dither=Image.Dither.NONE).convert('RGBA')
        frame.putalpha(alpha)
        frames.append(frame)
    frames[0] = seed.copy()
    frames[-1 if name == 'dash' else 3] = seed.copy()
    distinct = len({f.tobytes() for f in frames})
    if distinct < 3:
        raise ValueError(f'Insufficient distinct {name} poses')
    return frames, {'scale':scale,'frames':count,'unique_frames':distinct}


def main():
    for style in ['poncho','garcia']:
        (DEST/style).mkdir(parents=True,exist_ok=True)
    provenance = {'issue':58,'frame_size':[48,48],'ground_anchor':[24,40],
        'runtime_anchor':[24,26],'aim_pivot':[24,26],'source_files':{},'garcia_strips':{},
        'scope':'Locomotion in existing playable scenes; #39/#40 still own final Garcia combat/action art.',
        'weapon':'Shared provisional Poncho V4 held-weapon art, not final Garcia shotgun art.',
        'normalization':'One shared scale per strip, nearest-neighbor, binary alpha, shared seed palette; no repainting.'}
    for name in ['idle','walk','dash','arm_idle','walk_arm','fire']:
        shutil.copyfile(PONCHO/f'{name}.png',DEST/'poncho'/f'{name}.png')
        p=PONCHO/f'{name}.png'
        provenance['source_files'][str(p.relative_to(ROOT))]=hashlib.sha256(p.read_bytes()).hexdigest()
    for name,count in [('idle',1),('walk',6),('dash',4)]:
        pack([clean(PONCHO/f'occlusion/{name}/{n:02d}.png') for n in range(count)],DEST/'poncho'/f'hat_{name}.png')
    raw=clean(SOURCE/'garcia-seed-raw.png')
    crop=raw.crop(raw.getbbox())
    scale=min(32/crop.width,29/crop.height)
    dims=tuple(round(d*scale) for d in crop.size)
    seed=Image.new('RGBA',(48,48))
    seed.alpha_composite(crop.resize(dims,Image.Resampling.NEAREST),(24-dims[0]//2,40-dims[1]))
    seed=seed.quantize(colors=24,method=Image.Quantize.FASTOCTREE,dither=Image.Dither.NONE).convert('RGBA')
    seed.save(DEST/'garcia/idle.png')
    pack([hat(seed)],DEST/'garcia/hat_idle.png')
    palette=seed.convert('RGB').quantize(colors=24,dither=Image.Dither.NONE)
    for name,count in [('walk',6),('dash',4)]:
        frames,meta=normalize_strip(name,count,palette,seed)
        pack(frames,DEST/'garcia'/f'{name}.png')
        pack([hat(f) for f in frames],DEST/'garcia'/f'hat_{name}.png')
        provenance['garcia_strips'][name]=meta
    for p in sorted(SOURCE.glob('*-raw.png')):
        provenance['source_files'][str(p.relative_to(ROOT))]=hashlib.sha256(p.read_bytes()).hexdigest()
    (DEST/'provenance.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(provenance['garcia_strips'],indent=2))


if __name__ == '__main__':
    main()
