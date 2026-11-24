"""Export fixed-size layers, atlases and review animation from whole generated strips."""

import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
LOT = ROOT / "output/sprites/poncho/issue-38"
EXPORT = LOT / "exports/v2"
REVIEW = LOT / "review"
SIZE = (48, 48)
GROUND = (24, 40)
AIM = (24, 26)


def clean(path):
    image = Image.open(path).convert("RGBA")
    image.putalpha(image.getchannel("A").point(lambda a: 255 if a >= 128 else 0))
    return image


def font(size):
    for name in ["/System/Library/Fonts/Supplemental/Arial.ttf",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"]:
        if Path(name).exists():
            return ImageFont.truetype(name, size)
    return ImageFont.load_default(size=size)


def normalize(name, source, count, max_size, placement, palette=None):
    raw = clean(LOT / "source" / source)
    crops = []
    for index in range(count):
        slot = raw.crop((round(index * raw.width / count), 0,
                         round((index + 1) * raw.width / count), raw.height))
        bounds = slot.getbbox()
        if bounds is None:
            raise ValueError(f"Empty {name} frame {index}")
        crops.append(slot.crop(bounds))
    scale = min(max_size[0] / max(im.width for im in crops),
                max_size[1] / max(im.height for im in crops))
    frames = []
    for cropped in crops:
        size = tuple(max(1, round(side * scale)) for side in cropped.size)
        sprite = cropped.resize(size, Image.Resampling.NEAREST)
        frame = Image.new("RGBA", SIZE)
        if placement == "body":
            at = (GROUND[0] - size[0] // 2, GROUND[1] - size[1])
        elif placement == "gun":
            at = (31, 26 - size[1] // 2)
        else:
            at = (6, 30 - size[1])
        if any(at[i] < 0 or at[i] + size[i] > 48 for i in range(2)):
            raise ValueError(f"Clipped {name}")
        frame.alpha_composite(sprite, at)
        if palette:
            alpha = frame.getchannel("A")
            frame = frame.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
            frame.putalpha(alpha)
        frames.append(frame)
    # A single palette across a complete strip, never a different palette per cell.
    if palette is None:
        joined = atlas(frames).quantize(colors=24, method=Image.Quantize.FASTOCTREE,
                                        dither=Image.Dither.NONE).convert("RGBA")
        frames = [joined.crop((i*48, 0, (i+1)*48, 48)) for i in range(count)]
    return frames, {"source": source, "shared_scale": scale, "count": count}


def atlas(frames):
    image = Image.new("RGBA", (48 * len(frames), 48))
    for index, frame in enumerate(frames):
        image.alpha_composite(frame, (48 * index, 0))
    return image


def composed(body, gun=None, drink=None, angle=0):
    image = Image.new("RGBA", SIZE)
    if gun is not None:
        gun = gun.rotate(-angle, resample=Image.Resampling.NEAREST, center=AIM)
    if gun is not None and math.sin(math.radians(angle)) < -0.1:
        image.alpha_composite(gun)
    image.alpha_composite(body)
    if gun is not None and math.sin(math.radians(angle)) >= -0.1:
        image.alpha_composite(gun)
    if drink is not None:
        image.alpha_composite(drink)
    return image


def main():
    EXPORT.mkdir(parents=True, exist_ok=True)
    seed = clean(LOT / "exports/poncho-idle-seed-v2.png")
    body_palette = seed.convert("RGB").quantize(colors=24, dither=Image.Dither.NONE)
    walk, walk_meta = normalize("walk", "walk-v2-raw.png", 6, (32, 34), "body", body_palette)
    dash, dash_meta = normalize("dash", "dash-cutout-v2-raw.png", 4, (32, 34), "body", body_palette)
    weapon, weapon_meta = normalize("weapon", "gun-motion-v2-raw.png", 8, (16, 12), "gun")
    drink, drink_meta = normalize("drink", "drink-v2-raw.png", 4, (12, 14), "drink")
    walk[0] = seed.copy()
    walk[3] = seed.copy()
    dash[0] = seed.copy()
    dash[-1] = seed.copy()
    animations = {
        "idle": ([seed], 1, "body", True),
        "walk": (walk, 8, "body", True),
        "sprint": (walk, 12, "body", True),
        "dash": (dash, 20, "body", False),
        "fire": (weapon[:4], 18, "right_arm_weapon", False),
        "reload": (weapon[4:], 8, "right_arm_weapon", True),
        "drink": (drink, 6, "left_arm_bottle", True),
    }
    manifest = {
        "character": "Poncho", "version": "v2", "issue": 38,
        "reference": "output/concept-art/2026-11-22/07-recherche-silhouettes.png",
        "frame_size": list(SIZE), "ground_anchor": list(GROUND), "aim_pivot": list(AIM),
        "body_orientation": "upright concept projection; do not rotate the whole body",
        "aim": "rotate right_arm_weapon around aim_pivot; behind body when aiming upward",
        "timing": "fps are art-preview suggestions, not gameplay cooldowns or reload rules",
        "effects": "ghost/desaturation and damage tint are runtime presentation; external VFX in #47",
        "integration": "not integrated into playable characters; #40 remains separate",
        "sources": [walk_meta, dash_meta, weapon_meta, drink_meta], "animations": {},
    }
    qa = {}
    for name, (frames, fps, layer, loop) in animations.items():
        folder = EXPORT / name
        folder.mkdir(exist_ok=True)
        for index, frame in enumerate(frames):
            frame.save(folder / f"{index:02d}.png")
            alpha = [i for i, count in enumerate(frame.getchannel("A").histogram()) if count]
            if alpha != [0, 255] or frame.getbbox() is None:
                raise ValueError(f"Invalid alpha/content: {name}/{index}")
        atlas(frames).save(EXPORT / f"{name}.png")
        manifest["animations"][name] = {"atlas": f"{name}.png", "frames": len(frames),
            "fps_preview": fps, "layer": layer, "loop": loop,
            "anchor": list(GROUND), "frames_directory": name}
        qa[name] = {"unique_frames": len({im.tobytes() for im in frames}),
            "bounds": [list(im.getbbox()) for im in frames],
            "sha256": hashlib.sha256((EXPORT / f"{name}.png").read_bytes()).hexdigest()}
        if len(frames) > 1 and qa[name]["unique_frames"] < 3:
            raise ValueError(f"Insufficient distinct poses: {name}")
    (EXPORT / "manifest.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n")
    (EXPORT / "quality.json").write_text(json.dumps(qa, indent=2) + "\n")

    labels = [("walk", "Marche"), ("sprint", "Sprint"), ("dash", "Dash"),
              ("fire", "Tir / recul"), ("reload", "Rechargement"), ("drink", "Boisson")]
    previews = []
    for tick in range(48):
        canvas = Image.new("RGB", (640, 360), "#eeddb8")
        drawing = ImageDraw.Draw(canvas)
        drawing.text((14, 8), "PONCHO · Silhouette retenue · Aperçu du lot V2", font=font(16), fill="#39251b")
        for i, (name, label) in enumerate(labels):
            frames, fps, layer, loop = animations[name]
            frame = frames[int(tick * fps / 12) % len(frames)]
            body = frame if layer == "body" else seed
            gun = frame if layer == "right_arm_weapon" else weapon[0]
            actor = composed(body, gun, frame if name == "drink" else None)
            x, y = 28 + (i % 3) * 210, 34 + (i // 3) * 160
            drawing.rectangle((x-8, y+8, x+166, y+140), fill="#d2ac73")
            canvas.paste(actor.resize((144, 144), Image.Resampling.NEAREST), (x, y),
                         actor.resize((144, 144), Image.Resampling.NEAREST))
            drawing.text((x+8, y+138), label, font=font(13), fill="#39251b")
        previews.append(canvas)
    previews[0].save(REVIEW / "poncho-v2-actions.png")
    previews[0].save(REVIEW / "poncho-v2-actions.gif", save_all=True,
                     append_images=previews[1:], duration=83, loop=0, disposal=2)
    directions = Image.new("RGB", (640, 150), "#eeddb8")
    drawing = ImageDraw.Draw(directions)
    drawing.text((14, 10), "Corps droit · visée séparée, huit directions", font=font(16), fill="#39251b")
    for i in range(8):
        actor = composed(seed, weapon[0], angle=i*45)
        at = (8+i*78, 38)
        enlarged = actor.resize((72, 72), Image.Resampling.NEAREST)
        directions.paste(enlarged, at, enlarged)
        drawing.text((at[0]+20, 120), f"{i*45}°", font=font(12), fill="#39251b")
    directions.save(REVIEW / "poncho-v2-directions.png")
    single = Image.new("RGB", (384, 384), "#eeddb8")
    actor = composed(seed, weapon[0]).resize((384, 384), Image.Resampling.NEAREST)
    single.paste(actor, (0, 0), actor)
    single.save(REVIEW / "poncho-v2.png")
    print(json.dumps({"animations": len(animations), "frames": sum(len(v[0]) for v in animations.values()),
                      "qa": qa}, ensure_ascii=False))


if __name__ == "__main__":
    main()
