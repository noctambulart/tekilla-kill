"""Normalize the additions to the approved saloon kit, preserving aspect ratios."""
from pathlib import Path
import hashlib
import json
from PIL import Image
from prepare_saloon_study import isolated_props, binary

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'output/arena/2026-11-25-village-v6/source'
DEST = ROOT / 'godot/scenes/arroyo_seco/assets/village_v6'
LIMITS = [('store_counter', 128, 42), ('produce', 30, 28), ('goods', 64, 28),
          ('goods_v', 24, 96), ('tools', 64, 32), ('trough', 64, 24),
          ('house_small', 160, 140), ('bush', 32, 24)]


def main():
    DEST.mkdir(parents=True, exist_ok=True)
    sheet = binary(SOURCE / 'props-raw.png')
    assets = {}
    for bounds, (kind, width, height) in zip(isolated_props(sheet, rows=2), LIMITS):
        crop = sheet.crop(bounds)
        scale = min(width * 3 / crop.width, height * 3 / crop.height)
        size = (round(crop.width * scale), round(crop.height * scale))
        crop.resize(size, Image.Resampling.NEAREST).save(DEST / f'{kind}.png')
        assets[kind] = {'world_size': [n / 3 for n in size], 'native_size': size,
                        'source_bounds': bounds, 'uniform_scale': scale,
                        'source': str((SOURCE / 'props-raw.png').relative_to(ROOT))}
    floors = Image.open(SOURCE / 'floors-raw.png').convert('RGB')
    for index, kind in enumerate(['wood', 'earth']):
        panel = floors.crop((round(index * floors.width / 2) + 5, 5,
                             round((index + 1) * floors.width / 2) - 5, floors.height - 5))
        panel.resize((768, 768), Image.Resampling.NEAREST).save(DEST / f'{kind}.png')
    record = {'issue': 60, 'tool': 'image_gen.imagegen',
              'style_reference': 'godot/scenes/arroyo_seco/saloon_study/assets/house.png',
              'normalization': 'Whole connected silhouettes, uniform fit, binary alpha, nearest-neighbor.',
              'sources': {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in [SOURCE / 'props-raw.png', SOURCE / 'floors-raw.png']}, 'assets': assets}
    (DEST / 'provenance.json').write_text(json.dumps(record, ensure_ascii=False, indent=2) + '\n')
    print('Village V6 additions: eight props and two materials exported without stretching.')


if __name__ == '__main__':
    main()
