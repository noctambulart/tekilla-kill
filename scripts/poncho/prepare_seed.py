"""Normalize the generated seed without repainting it; keep the raw source intact."""

import argparse
import hashlib
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[2]
LOT = ROOT / "output/sprites/poncho/issue-38"
SOURCE = LOT / "source/seed-v1-raw.png"
FRAME_SIZE = 48
ANCHOR = (24, 24)
# Measured center of the overhead hat, rather than the bottom of the fringe.
SOURCE_PIVOT = (631, 589)
SHARED_SCALE = 32 / 732


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", choices=["v1", "v2"], default="v1")
    version = parser.parse_args().version
    source = LOT / f"source/seed-{version}-raw.png"
    raw = Image.open(source).convert("RGBA")
    alpha = raw.getchannel("A").point(lambda a: 255 if a >= 128 else 0)
    raw.putalpha(alpha)
    bounds = alpha.getbbox()
    if bounds is None:
        raise ValueError("Empty generated image")
    cropped = raw.crop(bounds)
    pivot = SOURCE_PIVOT if version == "v1" else ((bounds[0] + bounds[2]) / 2, bounds[3])
    scale = SHARED_SCALE if version == "v1" else min(32 / cropped.width, 34 / cropped.height)
    anchor = ANCHOR if version == "v1" else (24, 40)
    size = tuple(round(side * scale) for side in cropped.size)
    resized = cropped.resize(size, Image.Resampling.NEAREST)
    offset = tuple(
        round(anchor[i] - (pivot[i] - bounds[i]) * scale)
        for i in range(2)
    )
    if any(offset[i] < 0 or offset[i] + size[i] > FRAME_SIZE for i in range(2)):
        raise ValueError("Normalization would clip the sprite")
    frame = Image.new("RGBA", (FRAME_SIZE, FRAME_SIZE), (0, 0, 0, 0))
    frame.alpha_composite(resized, offset)
    # Palette reduction is deterministic; no dithering, smoothing or redrawing.
    frame = frame.quantize(colors=24, method=Image.Quantize.FASTOCTREE,
                           dither=Image.Dither.NONE).convert("RGBA")
    export = LOT / f"exports/poncho-idle-seed-{version}.png"
    export.parent.mkdir(parents=True, exist_ok=True)
    frame.save(export)
    frame.resize((384, 384), Image.Resampling.NEAREST).save(LOT / f"review/seed-{version}-x8.png")

    review = Image.new("RGB", (960, 480), "#f0e0bc")
    draw = ImageDraw.Draw(review)
    font_paths = [Path('/System/Library/Fonts/Supplemental/Arial.ttf'),
                  Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf')]
    font_path = next((path for path in font_paths if path.exists()), None)
    title_font = ImageFont.truetype(str(font_path), 25) if font_path else ImageFont.load_default(size=25)
    label_font = ImageFont.truetype(str(font_path), 17) if font_path else ImageFont.load_default(size=17)
    draw.text((28, 20), f"PONCHO — POSE ÉTALON {version.upper()}", fill="#39251b", font=title_font)
    draw.text((28, 59), "Sombrero paille · couronne olive · poncho brun frangé", fill="#604633", font=label_font)
    for x, y, preview_scale, label in [(60, 185, 1, "48 × 48 · taille native"),
                               (270, 155, 2, "Agrandissement ×2"),
                               (580, 105, 6, "Agrandissement ×6")]:
        side = FRAME_SIZE * preview_scale
        tile = max(8, 4 * preview_scale)
        for yy in range(y, y + side, tile):
            for xx in range(x, x + side, tile):
                color = "#d7b77e" if ((xx-x)//tile + (yy-y)//tile) % 2 else "#e7c991"
                draw.rectangle((xx, yy, min(xx+tile-1, x+side-1), min(yy+tile-1, y+side-1)), fill=color)
        review.paste(frame.resize((side, side), Image.Resampling.NEAREST), (x, y),
                     frame.resize((side, side), Image.Resampling.NEAREST))
        draw.text((x-8, y+side+15), label, fill="#39251b", font=label_font)
    draw.text((28, 432), "Corps seul · arme/bras séparés · pose candidate avant animations", fill="#604633", font=label_font)
    review.save(LOT / f"review/seed-{version}-review.png")

    qa = {
        "source": str(source.relative_to(ROOT)),
        "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
        "export": str(export.relative_to(ROOT)),
        "frame_size": list(frame.size), "anchor": list(anchor),
        "source_pivot": list(pivot), "source_content_bbox": list(bounds),
        "scale": scale, "normalized_offset": list(offset),
        "content_bbox": list(frame.getbbox()),
        "alpha_values": [i for i, count in enumerate(frame.getchannel("A").histogram()) if count],
        "visible_colors": sum(1 for count, color in frame.getcolors(48 * 48) if color[3]),
        "normalization": "nearest-neighbor, alpha threshold 128, 24-color octree, no dithering",
        "status": "superseded candidate" if version == "v1" else "faithful extraction of producer-selected silhouette; not integrated into gameplay",
    }
    if qa["alpha_values"] != [0, 255]:
        raise ValueError("Export must have binary alpha")
    (LOT / f"source/seed-{version}-export.json").write_text(json.dumps(qa, indent=2) + "\n")
    print(json.dumps(qa, ensure_ascii=False))


if __name__ == "__main__":
    main()
