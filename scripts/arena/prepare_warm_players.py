"""Normalize the complete warm-palette character atlases, without repainting.

One scale and palette per complete character, matching the shipped body sizes,
aim pivot and ground anchor. Source sheets are retained intact. Python + Pillow.
"""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'output/arena/2026-11-25-saloon-study/character-warm'
DEST = ROOT / 'godot/scenes/character/assets/saloon_warm'
CELL = 144


def pack(frames, path):
    strip = Image.new('RGBA', (CELL * len(frames), CELL))
    for index, frame in enumerate(frames):
        strip.alpha_composite(frame, (index * CELL, 0))
    strip.save(path)


def prepare(style):
    source = SOURCE / 'source' / f'{style}-raw.png'
    image = Image.open(source).convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    image = Image.alpha_composite(Image.new('RGBA', image.size), image)
    crops = []
    for row in range(2):
        for col in range(6):
            cell = image.crop((round(col * image.width / 6), round(row * image.height / 2),
                               round((col + 1) * image.width / 6), round((row + 1) * image.height / 2)))
            assert cell.getbbox(), (style, row, col)
            crops.append(cell.crop(cell.getbbox()))
    height = 108 if style == 'poncho' else 96
    scale = min(96 / max(p.width for p in crops), height / max(p.height for p in crops))
    frames = []
    for crop in crops:
        size = (round(crop.width * scale), round(crop.height * scale))
        piece = crop.resize(size, Image.Resampling.NEAREST)
        hat = piece.crop((0, 0, piece.width, round(piece.height * 0.55))).getbbox()
        center = (hat[0] + hat[2]) / 2
        frame = Image.new('RGBA', (CELL, CELL))
        frame.alpha_composite(piece, (round(72 - center), 126 - size[1]))
        frames.append(frame)
    # Quantize the whole atlas once, so colours do not flicker between poses.
    joined = Image.new('RGBA', (CELL * 12, CELL))
    for index, frame in enumerate(frames):
        joined.alpha_composite(frame, (index * CELL, 0))
    alpha = joined.getchannel('A')
    joined = joined.quantize(colors=128, method=Image.Quantize.FASTOCTREE,
                             dither=Image.Dither.NONE).convert('RGBA')
    joined.putalpha(alpha)
    frames = [joined.crop((i * CELL, 0, (i + 1) * CELL, CELL)) for i in range(12)]
    idle = frames[6]
    walk = frames[:6]
    walk[0] = idle.copy()
    dash = frames[7:11]
    dash[0] = idle.copy()
    dash[-1] = idle.copy()
    dest = DEST / style
    dest.mkdir(parents=True, exist_ok=True)
    quality = {}
    for state, poses in [('idle', [idle]), ('walk', walk), ('dash', dash)]:
        unique = len({pose.tobytes() for pose in poses})
        assert unique >= (1 if state == 'idle' else 3)
        assert all(pose.getbbox()[3] == 126 for pose in poses), 'Shared ground anchor'
        pack(poses, dest / f'{state}.png')
        hats = []
        for pose in poses:
            hat = Image.new('RGBA', (CELL, CELL))
            hat.paste(pose.crop((0, 0, CELL, 93)), (0, 0))
            hats.append(hat)
        pack(hats, dest / f'hat_{state}.png')
        quality[state] = {'frames': len(poses), 'distinct': unique}
    return {'source': str(source.relative_to(ROOT)),
            'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
            'shared_scale': scale, 'ground_anchor': [72, 126], 'aim_pivot': [72, 78],
            'palette_colours': 128, 'quality': quality}


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    characters = {style: prepare(style) for style in ['poncho', 'garcia']}
    for name in ['arm_idle.png', 'walk_arm.png', 'fire.png']:
        shutil.copy2(DEST.parent / 'village/poncho' / name, DEST / 'poncho' / name)
    provenance = {'issue': 60, 'tool': 'image_gen.imagegen', 'cell': [144, 144],
                  'draw_size_world': [48, 48], 'ground_y_world': 16,
                  'style_reference': 'godot/scenes/arroyo_seco/saloon_study/assets/house.png',
                  'characters': characters,
                  'weapon': 'Existing aiming/recoil strip unchanged.',
                  'scope': 'Saloon study; previous character artwork retained for comparison.'}
    (DEST / 'provenance.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + '\n')
    print('Warm players: two full animation sets, shared scale/palette and ground anchor preserved.')


if __name__ == '__main__':
    main()
