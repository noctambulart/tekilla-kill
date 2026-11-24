"""V3: synchronized locomotion arms and exact body-pixel brim occlusion."""

import hashlib
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw

from build_lot import LOT, REVIEW, SIZE, GROUND, atlas, clean, font, composed as composed_v2

EXPORT = LOT / "exports/v3"
AIM = (24, 29)
HAT_CUT_Y = 32


def normalize_arms(source, count):
    raw = clean(LOT / "source" / source)
    slots, bounds = [], []
    for i in range(count):
        slot = raw.crop((round(i*raw.width/count), 0, round((i+1)*raw.width/count), raw.height))
        bbox = slot.getbbox()
        if bbox is None:
            raise ValueError(f"Empty arm slot {source}/{i}")
        slots.append(slot)
        bounds.append(bbox)
    union = (min(b[0] for b in bounds), min(b[1] for b in bounds),
             max(b[2] for b in bounds), max(b[3] for b in bounds))
    scale = min(18/(union[2]-union[0]), 11/(union[3]-union[1]))
    frames = []
    # Keep relative positions within the whole strip: per-frame recentering would erase the swing.
    for slot, bbox in zip(slots, bounds):
        content = slot.crop(bbox)
        size = tuple(max(1, round(n*scale)) for n in content.size)
        at = (28+round((bbox[0]-union[0])*scale), 28+round((bbox[1]-union[1])*scale))
        if at[0]+size[0] > 48 or at[1]+size[1] > 48:
            raise ValueError("Arm clips the 48px cell")
        frame = Image.new("RGBA", SIZE)
        frame.alpha_composite(content.resize(size, Image.Resampling.NEAREST), at)
        frames.append(frame)
    joined = atlas(frames).quantize(colors=24, method=Image.Quantize.FASTOCTREE,
                                    dither=Image.Dither.NONE).convert("RGBA")
    return [joined.crop((i*48, 0, (i+1)*48, 48)) for i in range(count)], {
        "source": source, "shared_scale": scale, "union_bounds": union,
        "placement": "strip-relative offsets preserved; nominal origin (28,28)"}


def hat_front(body):
    result = body.copy()
    result.paste((0, 0, 0, 0), (0, HAT_CUT_Y, 48, 48))
    return result


def compose(body, arm, drink=None, angle=0, padded=False):
    padding = 8 if padded else 0
    result = Image.new("RGBA", (48+padding*2,48+padding*2))
    result.alpha_composite(body,(padding,padding))
    if arm is not None:
        layer = Image.new("RGBA", result.size)
        layer.alpha_composite(arm,(padding,padding))
        result.alpha_composite(layer.rotate(-angle, Image.Resampling.NEAREST,
                                           center=(AIM[0]+padding,AIM[1]+padding)))
    if drink is not None:
        result.alpha_composite(drink,(padding,padding))
    # Restore exact source pixels of the brim/crown above the moving arm.
    result.alpha_composite(hat_front(body),(padding,padding))
    return result


def skin_centroid(arm, body):
    hat = hat_front(body)
    points = []
    for y in range(48):
        for x in range(48):
            r, g, b, a = arm.getpixel((x, y))
            if a and not hat.getpixel((x, y))[3] and r > 90 and g > 50 and r > g*1.2 and g > b*1.2:
                points.append((x, y))
    if not points:
        raise ValueError("Holding hand is completely hidden")
    if not any(y >= HAT_CUT_Y for x, y in points):
        raise ValueError("Hand must emerge below the brim")
    return [round(sum(p[i] for p in points)/len(points), 3) for i in range(2)]


def main():
    EXPORT.mkdir(parents=True, exist_ok=True)
    previous = json.loads((LOT / "exports/v2/manifest.json").read_text())
    animations = {}
    for name, entry in previous["animations"].items():
        frames = [clean(LOT / f"exports/v2/{name}/{i:02d}.png") for i in range(entry["frames"])]
        animations[name] = (frames, entry["fps_preview"], entry["layer"], entry["loop"])
    run, run_source = normalize_arms("run-arm-v3-raw.png", 6)
    weapon, weapon_source = normalize_arms("weapon-arm-v3-raw.png", 8)
    animations.update({
        "arm_idle": ([run[0]], 1, "right_arm_weapon", True),
        "walk_arm": (run, 8, "right_arm_weapon", True),
        "sprint_arm": (run, 12, "right_arm_weapon", True),
        "fire": (weapon[:4], 18, "right_arm_weapon", False),
        "reload": (weapon[4:], 8, "right_arm_weapon", True),
    })
    manifest = dict(previous)
    manifest.update({"version": "v3", "aim_pivot": list(AIM), "sources": [run_source, weapon_source],
        "reused_body_source": "../v2/", "animations": {}, "hat_occlusion": {},
        "draw_order": ["body", "right_arm_weapon", "left_arm_bottle", "hat_front"],
        "aim": "rotate arm layers around (24,29), then restore the current body's hat_front",
        "locomotion_sync": {"walk_arm": "walk", "sprint_arm": "sprint"},
        "composition": "Use the same phase/frame for locomotion body and arm. Preserve strip-relative arm offsets.",
        "moving_action_attachment_offsets": [[0,0],[-1,-1],[0,-1],[0,0],[1,0],[0,1]],
        "moving_action_note": "When a fire/reload gesture replaces a locomotion arm, retain the walking shoulder track in aim-local coordinates.",
        "hat_cut_y": HAT_CUT_Y})
    manifest["rotation_bounds"] = "48px cells are layer canvases; do not clip the rotated composed actor to 48x48. Padded review uses 64x64."
    quality = {}
    for name, (frames, fps, layer, loop) in animations.items():
        folder = EXPORT / name
        folder.mkdir(exist_ok=True)
        for i, frame in enumerate(frames):
            frame.save(folder / f"{i:02d}.png")
            alpha = [i for i, n in enumerate(frame.getchannel("A").histogram()) if n]
            if alpha != [0,255] or frame.getbbox() is None:
                raise ValueError(f"Invalid transparency: {name}")
        atlas(frames).save(EXPORT / f"{name}.png")
        entry = {"atlas": f"{name}.png", "frames_directory": name, "frames": len(frames),
                 "fps_preview": fps, "layer": layer, "loop": loop, "anchor": list(GROUND)}
        if name in ["walk_arm", "sprint_arm"]:
            entry["sync_with"] = name.removesuffix("_arm")
        manifest["animations"][name] = entry
        quality[name] = {"unique_frames": len({f.tobytes() for f in frames}),
                         "sha256": hashlib.sha256((EXPORT/f"{name}.png").read_bytes()).hexdigest()}
        if len(frames) > 1 and quality[name]["unique_frames"] < 3:
            raise ValueError(f"Animation lacks distinct poses: {name}")
        if layer == "body":
            hat_dir = EXPORT / "occlusion" / name
            hat_dir.mkdir(parents=True, exist_ok=True)
            for i, frame in enumerate(frames):
                hat_front(frame).save(hat_dir/f"{i:02d}.png")
                if frame.tobytes() != clean(LOT/f"exports/v2/{name}/{i:02d}.png").tobytes():
                    raise ValueError("Body silhouette changed")
            manifest["hat_occlusion"][name] = f"occlusion/{name}"
    walk = animations["walk"][0]
    idle = animations["idle"][0][0]
    drink = animations["drink"][0]
    centroids = [skin_centroid(arm, body) for arm, body in zip(run, walk)]
    if max(p[1] for p in centroids)-min(p[1] for p in centroids) < 1:
        raise ValueError("Holding hand does not move vertically with the run cycle")
    quality["locomotion_hand"] = {"visible_skin_centroids": centroids,
        "vertical_swing_px": max(p[1] for p in centroids)-min(p[1] for p in centroids),
        "below_brim": True, "body_pixels_unchanged": True}
    (EXPORT/"manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n")
    (EXPORT/"quality.json").write_text(json.dumps(quality, indent=2)+"\n")

    old_arm = clean(LOT/"exports/v2/fire/00.png")
    labels = ["V2 · main fixe", "V3 · marche", "V3 · course"]
    comparison = []
    for tick in range(72):
        image = Image.new("RGB", (640,240), "#eeddb8")
        draw = ImageDraw.Draw(image)
        draw.text((14,8), "Poncho · Main sous le chapeau, synchronisée avec les pas", font=font(16), fill="#39251b")
        for column in range(3):
            fps = 12 if column == 2 else 8
            i = int(tick*fps/24)%6
            actor = composed_v2(walk[i], old_arm) if column == 0 else compose(walk[i], run[i])
            actor = actor.resize((192,192), Image.Resampling.NEAREST)
            image.paste(actor, (10+column*212,20), actor)
            draw.text((28+column*212,212), labels[column], font=font(14), fill="#39251b")
        comparison.append(image)
    comparison[0].save(REVIEW/"poncho-v3-comparison.png")
    comparison[0].save(REVIEW/"poncho-v3-comparison.gif",save_all=True,append_images=comparison[1:],duration=42,loop=0,disposal=2)

    labels = [("walk","Marche"),("sprint","Course"),("dash","Dash"),
              ("fire","Tir / recul"),("reload","Rechargement"),("drink","Boisson")]
    preview = []
    for tick in range(72):
        image = Image.new("RGB", (640,360), "#eeddb8")
        draw = ImageDraw.Draw(image)
        draw.text((14,8), "PONCHO · V3 · Bras attaché sous le bord du chapeau",font=font(16),fill="#39251b")
        for n,(name,label) in enumerate(labels):
            frames,fps,layer,loop = animations[name]
            index = int(tick*fps/24)%len(frames)
            body = frames[index] if layer == "body" else idle
            arm = run[index] if name in ["walk","sprint"] else (frames[index] if name in ["fire","reload"] else run[0])
            actor = compose(body,arm,drink[index] if name=="drink" else None).resize((144,144),Image.Resampling.NEAREST)
            x,y = 28+n%3*210,34+n//3*160
            draw.rectangle((x-8,y+8,x+166,y+140),fill="#d2ac73")
            image.paste(actor,(x,y),actor)
            draw.text((x+8,y+138),label,font=font(13),fill="#39251b")
        preview.append(image)
    preview[0].save(REVIEW/"poncho-v3-actions.png")
    preview[0].save(REVIEW/"poncho-v3-actions.gif",save_all=True,append_images=preview[1:],duration=42,loop=0,disposal=2)
    directions = Image.new("RGB",(640,150),"#eeddb8")
    draw = ImageDraw.Draw(directions)
    draw.text((14,10),"V3 · Main sous le chapeau · Visée indépendante",font=font(16),fill="#39251b")
    for i in range(8):
        actor = compose(idle,run[0],angle=i*45,padded=True)
        directions.paste(actor,(8+i*78,38),actor)
        draw.text((28+i*78,120),f"{i*45}°",font=font(12),fill="#39251b")
    directions.save(REVIEW/"poncho-v3-directions.png")
    print(json.dumps({"animations":len(animations),"frames":sum(len(a[0]) for a in animations.values()),"hand":quality["locomotion_hand"]}))


if __name__ == "__main__":
    main()
