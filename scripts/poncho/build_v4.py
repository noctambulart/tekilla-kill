"""V4: position the existing animated hand behind the brim, as in the concept."""

import copy
import hashlib
import json

from PIL import Image, ImageChops, ImageDraw

import build_v3 as rig
from build_lot import LOT, REVIEW, SIZE, atlas, clean, font

EXPORT = LOT / "exports/v4"
RUN_TRACK = [(0,0),(-1,1),(0,0),(1,-1),(0,-1),(-1,-1)]
AIM = (24, 26)


def hand_visibility(arm, body):
    hat = rig.hat_front(body)
    visible = arm.copy()
    visible.putalpha(ImageChops.multiply(arm.getchannel("A"), ImageChops.invert(hat.getchannel("A"))))
    total = exposed = metal = 0
    for y in range(48):
        for x in range(48):
            r,g,b,a = arm.getpixel((x,y))
            if not a:
                continue
            is_visible = bool(visible.getpixel((x,y))[3])
            if r > 90 and g > 50 and r > g*1.2 and g > b*1.2:
                total += 1
                exposed += int(is_visible)
            if is_visible and min(r,g,b) > 100 and max(r,g,b)-min(r,g,b) < 60:
                metal += 1
    return visible, {"skin_visible":exposed,"skin_total":total,
                     "skin_hidden_fraction":round(1-exposed/total,3) if total else 1,
                     "visible_metal_pixels":metal}


def main():
    EXPORT.mkdir(parents=True,exist_ok=True)
    previous = json.loads((LOT/"exports/v3/manifest.json").read_text())
    manifest = copy.deepcopy(previous)
    manifest.update({"version":"v4","aim_pivot":list(AIM),
        "locomotion_weapon_offsets":RUN_TRACK,
        "feedback":"The hand belongs behind/under the hat as in the silhouette concept, not hanging below it.",
        "aim":"rotate arm layers around (24,26); the hat_front masks the palm and sleeve",
        "source":"Original V2 gun/hand art, animated by the locomotion attachment track behind the existing hat; V3 body art unchanged"})
    quality,animations = {},{}
    for name,entry in manifest["animations"].items():
        frames = []
        folder = EXPORT/name
        folder.mkdir(exist_ok=True)
        for i in range(entry["frames"]):
            frame = clean(LOT/f"exports/v3/{name}/{i:02d}.png")
            if entry["layer"] == "right_arm_weapon":
                if name in ["fire","reload"]:
                    frame = clean(LOT/f"exports/v2/{name}/{i:02d}.png")
                else:
                    frame = clean(LOT/"exports/v2/fire/00.png")
                    if name in ["walk_arm","sprint_arm"]:
                        moved = Image.new("RGBA",SIZE)
                        moved.alpha_composite(frame,RUN_TRACK[i])
                        if sum(frame.getchannel("A").histogram()[1:]) != sum(moved.getchannel("A").histogram()[1:]):
                            raise ValueError("Arm correction clipped the source layer")
                        frame = moved
            frame.save(folder/f"{i:02d}.png")
            frames.append(frame)
            alpha = [n for n,count in enumerate(frame.getchannel("A").histogram()) if count]
            if alpha != [0,255]:
                raise ValueError("Unexpected alpha")
        atlas(frames).save(EXPORT/f"{name}.png")
        animations[name] = frames
        quality[name] = {"sha256":hashlib.sha256((EXPORT/f"{name}.png").read_bytes()).hexdigest(),
                         "unique_frames":len({f.tobytes() for f in frames})}
        if entry["layer"] == "body":
            out = EXPORT/"occlusion"/name
            out.mkdir(parents=True,exist_ok=True)
            for i,frame in enumerate(frames):
                rig.hat_front(frame).save(out/f"{i:02d}.png")
    metrics,visible_arms = [],[]
    for body,arm in zip(animations["walk"],animations["walk_arm"]):
        visible,metric = hand_visibility(arm,body)
        if metric["skin_hidden_fraction"] < 0.75:
            raise ValueError("Palm is still too exposed beside the hat")
        if metric["visible_metal_pixels"] < 8:
            raise ValueError("The hat hides the complete weapon")
        metrics.append(metric)
        visible_arms.append(visible)
    if len({im.tobytes() for im in visible_arms}) < 3:
        raise ValueError("Visible weapon motion was lost")
    quality["under_hat"] = {"right_facing_walk_frames":metrics,
        "distinct_visible_arm_states":len({im.tobytes() for im in visible_arms}),
        "body_pixels_unchanged":True}
    (EXPORT/"manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n")
    (EXPORT/"quality.json").write_text(json.dumps(quality,indent=2)+"\n")
    rig.AIM = AIM
    idle = animations["idle"][0]
    comparison,actions = [],[]
    old_arms = [clean(LOT/f"exports/v3/walk_arm/{i:02d}.png") for i in range(6)]
    for tick in range(72):
        image = Image.new("RGB",(640,240),"#eeddb8")
        draw = ImageDraw.Draw(image)
        draw.text((14,8),"Poncho · Main masquée sous le chapeau, comme sur la proposition",font=font(15),fill="#39251b")
        for col,label in enumerate(["V3 · main trop basse","V4 · main masquée","V4 · course"]):
            phase = int(tick*(12 if col==2 else 8)/24)%6
            body = animations["walk"][phase]
            arm = old_arms[phase] if col==0 else animations["walk_arm"][phase]
            actor = rig.compose(body,arm).resize((192,192),Image.Resampling.NEAREST)
            image.paste(actor,(10+col*212,15),actor)
            draw.text((20+col*212,215),label,font=font(13),fill="#39251b")
        comparison.append(image)
        image = Image.new("RGB",(640,360),"#eeddb8")
        draw = ImageDraw.Draw(image)
        draw.text((14,8),"PONCHO · V4 · La main reste derrière le bord du chapeau",font=font(16),fill="#39251b")
        for n,(name,label) in enumerate([("walk","Marche"),("sprint","Course"),("dash","Dash"),
                                        ("fire","Tir / recul"),("reload","Rechargement"),("drink","Boisson")]):
            entry = manifest["animations"][name]
            phase = int(tick*entry["fps_preview"]/24)%entry["frames"]
            body = animations[name][phase] if entry["layer"]=="body" else idle
            arm = animations[name+"_arm"][phase] if name in ["walk","sprint"] else (
                animations[name][phase] if name in ["fire","reload"] else animations["arm_idle"][0])
            bottle = animations["drink"][phase] if name=="drink" else None
            actor = rig.compose(body,arm,bottle).resize((144,144),Image.Resampling.NEAREST)
            x,y = 28+n%3*210,34+n//3*160
            draw.rectangle((x-8,y+8,x+166,y+140),fill="#d2ac73")
            image.paste(actor,(x,y),actor)
            draw.text((x+8,y+138),label,font=font(13),fill="#39251b")
        actions.append(image)
    for name,images in [("comparison",comparison),("actions",actions)]:
        images[0].save(REVIEW/f"poncho-v4-{name}.png")
        images[0].save(REVIEW/f"poncho-v4-{name}.gif",save_all=True,append_images=images[1:],duration=42,loop=0,disposal=2)
    single = Image.new("RGB",(384,384),"#eeddb8")
    actor = rig.compose(idle,animations["arm_idle"][0]).resize((384,384),Image.Resampling.NEAREST)
    single.paste(actor,(0,0),actor)
    single.save(REVIEW/"poncho-v4.png")
    print(json.dumps(quality["under_hat"]))


if __name__ == "__main__":
    main()
