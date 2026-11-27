"""Extract the study's generated props without changing their aspect ratios.

Python + Pillow, no generation API. Original sheets and exact prompts remain in
output/. Collision footprints are separate from the image's transparent canvas.
"""
from pathlib import Path
import hashlib
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'output/arena/2026-11-25-saloon-study'
DEST = ROOT / 'godot/scenes/arroyo_seco/saloon_study/assets'
LIMITS = [
    ('bar', 208, 76), ('table', 42, 42), ('stool', 16, 20), ('barrel', 24, 28),
    ('chair_n', 18, 25), ('chair_s', 18, 25), ('chair_w', 18, 25), ('chair_e', 18, 25),
    ('couch', 80, 44), ('pot', 16, 20), ('house', 160, 160), ('shelf', 40, 20),
]
WALLS = [('wall_h', 96, 28), ('wall_v', 18, 96), ('post', 18, 28), ('front', 80, 28),
         ('fence_h', 96, 24), ('fence_v', 14, 96), ('pillar', 18, 28), ('plaster', 96, 28)]


def isolated_props(sheet, columns=4, rows=3):
    # Some generated assets cross their nominal cell boundary. Find complete
    # connected silhouettes on the full sheet instead of cutting their edges
    # or accidentally including a fragment of the neighbouring prop.
    alpha = sheet.getchannel('A').tobytes()
    width, height = sheet.size
    visited = bytearray(width * height)
    slots = {}
    for origin, value in enumerate(alpha):
        if not value or visited[origin]:
            continue
        pending = [origin]
        visited[origin] = 1
        count = 0
        xmin = xmax = origin % width
        ymin = ymax = origin // width
        while pending:
            at = pending.pop()
            x, y = at % width, at // width
            count += 1
            xmin, xmax, ymin, ymax = min(xmin, x), max(xmax, x), min(ymin, y), max(ymax, y)
            neighbours = []
            if x: neighbours.append(at - 1)
            if x + 1 < width: neighbours.append(at + 1)
            if y: neighbours.append(at - width)
            if y + 1 < height: neighbours.append(at + width)
            for other in neighbours:
                if alpha[other] and not visited[other]:
                    visited[other] = 1
                    pending.append(other)
        if count < 500:
            continue
        col = min(columns - 1, int((xmin + xmax) / 2 / width * columns))
        row = min(rows - 1, int((ymin + ymax) / 2 / height * rows))
        slot = row * columns + col
        if slot not in slots or count > slots[slot][0]:
            slots[slot] = (count, (xmin, ymin, xmax + 1, ymax + 1))
    assert len(slots) == columns * rows, slots
    return [slots[index][1] for index in range(columns * rows)]


def binary(path):
    image = Image.open(path).convert('RGBA')
    image.putalpha(image.getchannel('A').point(lambda a: 255 if a >= 128 else 0))
    # Clear RGB hidden under alpha0 as well, avoiding misleading preview halos.
    return Image.alpha_composite(Image.new('RGBA', image.size), image)


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    sheet = binary(SOURCE / 'props-raw.png')
    assets = {}
    walls = binary(SOURCE / 'walls-raw.png')
    pieces = [(sheet.crop(bounds), bounds, spec) for bounds, spec in zip(isolated_props(sheet), LIMITS)]
    pieces += [(walls.crop(bounds), bounds, spec) for bounds, spec in zip(isolated_props(walls, rows=2), WALLS)]
    for crop, bounds, (kind, width, height) in pieces:
        if kind == 'bar':
            crop = binary(SOURCE / 'bar-low-raw.png')
            bounds = crop.getbbox()
            crop = crop.crop(bounds)
        scale = min(width * 3 / crop.width, height * 3 / crop.height)
        size = (round(crop.width * scale), round(crop.height * scale))
        crop.resize(size, Image.Resampling.NEAREST).save(DEST / f'{kind}.png')
        assets[kind] = {'source_bounds': bounds, 'native_size': size,
                        'source': str((SOURCE / ('bar-low-raw.png' if kind == 'bar' else
                                    ('walls-raw.png' if kind in {item[0] for item in WALLS} else 'props-raw.png'))).relative_to(ROOT)),
                        'world_size': [n / 3 for n in size], 'uniform_scale': scale,
                        'anchor': 'bottom-center', 'orientation': 'drawn, never rotated'}
    floors = Image.open(SOURCE / 'floors-raw.png').convert('RGB')
    for index, kind in enumerate(['sand', 'stone']):
        panel = floors.crop((round(index * floors.width / 2), 0,
                             round((index + 1) * floors.width / 2), floors.height))
        # Discard the generated panel boundary's few mixed-colour edge pixels.
        panel = panel.crop((5, 5, panel.width - 5, panel.height - 5))
        panel.resize((768, 768), Image.Resampling.NEAREST).save(DEST / f'{kind}.png')
    provenance = {'issue': 60, 'tool': 'image_gen.imagegen',
                  'normalization': 'Binary alpha; occupied bounds; uniform fit; nearest-neighbor. No painting.',
                  'sources': {name: hashlib.sha256((SOURCE / name).read_bytes()).hexdigest()
                              for name in ['props-raw.png', 'floors-raw.png', 'walls-raw.png', 'bar-low-raw.png']}, 'assets': assets}
    (DEST / 'provenance.json').write_text(json.dumps(provenance, ensure_ascii=False, indent=2) + '\n')
    print('Saloon study: 12 props, eight architectural pieces, two terrain materials; uniform scale.')


if __name__ == '__main__':
    main()
