"""Build the editable Arroyo Seco layout and copy its archived source art.

Run from any directory with Python 3. No external dependencies or image edits.
The Godot scene renders this geometry and uses the same rectangles for physics.
"""
from pathlib import Path
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[2]
SCENE = ROOT / "godot/scenes/arroyo_seco"
OUTPUT = ROOT / "output/arena/2026-11-23"
SCENE.mkdir(parents=True, exist_ok=True)
OUTPUT.mkdir(parents=True, exist_ok=True)


def walls_for(name, polygon, doors, material="stone", thickness=.5):
    walls = []
    for edge, (a, b) in enumerate(zip(polygon, polygon[1:] + polygon[:1])):
        horizontal = a[1] == b[1]
        axis = 0 if horizontal else 1
        start, end = sorted([a[axis], b[axis]])
        spans = sorted(doors.get(edge, []))
        for lo, hi in spans + [[end, end]]:
            if lo > start:
                rect = ([start, a[1] - thickness / 2, lo - start, thickness]
                        if horizontal else [a[0] - thickness / 2, start, thickness, lo - start])
                walls.append(dict(id=f"{name}-{edge}-{len(walls)}", rect=rect, material=material))
            start = hi
    return walls


perimeter = [[0,3],[2,3],[2,0],[25,0],[25,2],[31,2],[31,7],[32,7],
             [32,17],[29,17],[29,20],[4,20],[4,18],[0,18]]
buildings = [
    dict(id="saloon", name="Saloon", polygon=[[3,4],[8,4],[8,5],[15,5],[15,14],[3,14]],
         doors={0:[[5,7]],3:[[11,13]],4:[[11,13]]}, label=[11.5,6], floor="stone"),
    dict(id="shop", name="Épicerie", polygon=[[24,9],[29,9],[29,10],[30,10],[30,15],[24,15]],
         doors={4:[[27,29]],5:[[11,13]]}, label=[25,10.5], floor="stone"),
    dict(id="shed", name="Remise", polygon=[[5,16],[11,16],[11,18.5],[9,18.5],[9,19],[5,19]],
         doors={1:[[16.25,18.25]],4:[[6,8]]}, label=[8,16.5], floor="wood"),
    dict(id="yard", name="Enclos", polygon=[[22,2],[29,2],[29,7],[23,7],[23,5.5],[22,5.5]],
         doors={2:[[25,27]],5:[[3,5]]}, label=[26,3], floor="earth", material="fence"),
]
walls = walls_for("perimeter", perimeter, {}, thickness=.5)
for b in buildings:
    walls += walls_for(b["id"], b["polygon"], b["doors"], b.get("material","stone"),
                       .25 if b.get("material") == "fence" else .5)

props = []
def prop(name, kind, rect, breakable=False):
    props.append(dict(id=name, kind=kind, rect=rect, breakable=breakable))

prop("bar-long", "counter", [4,7,6,.75])
prop("bar-return", "counter", [9.25,7.75,.75,2.25])
prop("bar-shelf", "shelf", [3.5,4.75,.6,1.5])
prop("couch", "couch", [3.75,12.5,3,1])
prop("poker-table", "table", [5.25,9.25,1.5,1.5])
prop("side-table", "table", [11.5,7.5,1.5,1.5])
for i, rect in enumerate([[4.125,9.625,.75,.75],[6.875,9.625,.75,.75],
                          [5.625,11,.75,.75],[13.25,7.875,.75,.75]]):
    prop(f"chair-{i+1}","chair",rect,True)
for i, rect in enumerate([[16.5,8.5,1,1],[20,13.5,1,1],[13,16,1,1],
                          [26.5,5,1,1],[5.5,17,1,1],[6.5,17,1,1]]):
    prop(f"crate-{i+1}","crate",rect,True)
for i, rect in enumerate([[14,5.75,.5,.5],[24.75,14,.5,.5],[10.25,18,.5,.5]]):
    prop(f"pot-{i+1}","pot",rect,True)
prop("shop-shelf-north","shelf",[24.75,9.5,3.5,.5])
prop("shop-shelf-east","shelf",[29,10.5,.5,3])
prop("shop-table","table",[26.25,11.25,1.5,1.5])
prop("shop-chair","chair",[28,13,.75,.75],True)
prop("saloon-barrel","barrel",[13.5,12.75,1,1])
prop("yard-barrel","barrel",[27.5,4.75,1,1])
prop("shed-barrel","barrel",[8.5,17.25,1,1])
prop("courtyard-cart","cart",[8.5,1.5,3.125,1])

layout = dict(
    version=3, name="Arroyo Seco — rue du saloon", tile_px=32, size_tiles=[32,20],
    status="Première carte visitable ; équilibre, tir, casse et caméra de partie à éprouver.",
    perimeter=perimeter, buildings=buildings, walls=walls, props=props,
    bottle=[18,12], spawns=[[18,17],[18,7],[23,12],[13,12]],
    labels=[dict(text="Cour arrière",position=[11,2.5]),dict(text="Rue principale",position=[20,10])],
    routes=[
        dict(id="saloon",name="Poursuite dans le saloon", points=[[18,12],[12,12],[11,10.5],[11,6],[6,6],[6,3]],
             intent="Entrer par la rue, contourner le comptoir et ressortir dans la cour."),
        dict(id="intercept",name="Interception par la ruelle",points=[[18,12],[18,6],[18,3],[6,3]],
             intent="Anticiper la sortie de cour ; le porteur peut revenir vers les deux accès de rue."),
        dict(id="shop",name="Traversée de l’épicerie",points=[[21,12],[25,12],[25.75,13.25],[25.75,14.25],[28,14.25],[28,16],[22,16],[21,12]],
             intent="Quitter un angle de tir par la sortie sud, sans se retrouver dans une pièce à entrée unique."),
    ],
    design_notes=[
        "Trois bâtiments de tailles différentes ; saloon à trois accès, commerce et remise à deux accès, enclos à deux passages.",
        "Quatre départs à cinq tuiles de la bouteille par des approches libres ; cela ne prouve pas l’équilibre tactique.",
        "Murs, comptoir, tables et gros meubles permanents ; caisses, chaises et pots prévus cassables, sans implémentation de casse ici.",
        "Les dimensions proviennent de la grille 32 px. Portes : au moins 2 tuiles ; collision actuelle des personnages : rayon 8 px.",
        "Vue verticale, mobilier historique, sable peu contrasté et dallage bleu-gris, inspirés du concept 06.",
        "Le marqueur de bouteille est un repère de plan, sans ramassage ni consommation. Une seule bouteille, pas de bouteilles de décor.",
        "Aucune prétention d’équilibrage à trois/quatre ni de caméra adaptative de partie ; le mode de visite permet de vérifier le lieu.",
    ],
    handoff={"27":"Plan, passages, obstacles, départs et intentions de parcours dans ce fichier et le plan annoté.",
             "28":"Scène d’arène et visite avec les commandes existantes ; tirs réels et interactions à compléter après #20.",
             "29":"Brancher les résistances et états cassés, puis éprouver les poursuites à deux.",
             "41":"Sol, murs, seuils et identités des lieux à harmoniser sur cette géométrie après examen.",
             "42":"Chair/crate/pot ont des empreintes précises ici ; états cassés à produire sans déplacer leurs ancrages.",
             "43":"Habillage initial réutilisant les archives ; intégration finale à faire sur le tracé éprouvé."},
    references=["output/concept-art/2026-11-22/06-scene-habitee-identites.png",
                "output/arena/2026-11-23/arroyo-seco-scene-v2.png"])
# V4 expands distances and room footprints, while preserving native tile/actor scale.
# Furniture is placed by its scaled center, with deliberate new pixel footprints.
SPACE_SCALE = 1.5
def expanded(point):
    return [round(value * SPACE_SCALE, 4) for value in point]

layout["version"] = 4
layout["size_tiles"] = [48, 30]
layout["perimeter"] = [expanded(point) for point in perimeter]
layout["spawn_distance_px"] = 240
layout["bottle"] = expanded(layout["bottle"])
layout["spawns"] = [expanded(point) for point in layout["spawns"]]
for building in buildings:
    building["polygon"] = [expanded(point) for point in building["polygon"]]
    building["label"] = expanded(building["label"])
    building["doors"] = {edge:[expanded(span) for span in spans]
                         for edge, spans in building["doors"].items()}
for label in layout["labels"]:
    label["position"] = expanded(label["position"])
for route in layout["routes"]:
    route["points"] = [expanded(point) for point in route["points"]]
for item in props:
    x,y,w,h = item["rect"]
    cx,cy = expanded([x+w/2,y+h/2])
    w,h = {"crate":[1.25,1.25],"barrel":[1.25,1.25],"chair":[1,1],
           "pot":[.75,.75],"table":[2,2],"couch":[4,1.5],"cart":[4,1.5]}.get(item["kind"], [w,h])
    if item["kind"] in ("counter","shelf"):
        if w > h:
            w,h = w*SPACE_SCALE, 1 if item["kind"] == "counter" else .6
        else:
            w,h = (1 if item["kind"] == "counter" else .6),h*SPACE_SCALE
    item["rect"] = [round(cx-w/2,4),round(cy-h/2,4),round(w,4),round(h,4)]
bar = next(item for item in props if item["id"] == "bar-long")["rect"]
bar_return = next(item for item in props if item["id"] == "bar-return")["rect"]
bar_return[0],bar_return[1] = bar[0]+bar[2]-bar_return[2],bar[1]+bar[3]
# A third poker table furnishes the expanded room without closing chase routes.
prop("poker-table-south", "table", [12,17.5,2,2])
prop("poker-chair-west", "chair", [10.5,18,1,1], True)
prop("poker-chair-east", "chair", [14.5,18,1,1], True)
prop("poker-chair-north", "chair", [12.5,15.75,1,1], True)
prop("street-crate-north", "crate", [24.5,14,1.25,1.25], True)
prop("street-crate-south", "crate", [30,24.5,1.25,1.25], True)
walls = walls_for("perimeter",layout["perimeter"],{},thickness=.5)
for building in buildings:
    walls += walls_for(building["id"],building["polygon"],building["doors"],
                       building.get("material","stone"), .25 if building.get("material") == "fence" else .5)
layout["walls"] = walls
layout["decor"] = [dict(kind="rug",rect=[5.75,17.25,4.5,1.25])]
layout["design_notes"][1] = "Quatre départs à 7,5 tuiles / 240 px de la bouteille, trajets libres à vérifier ; équilibre tactique à éprouver."
layout["design_notes"][3] = "Terrain 32 px ; portes agrandies à 3 tuiles ; personnage et rayon de collision de 8 px inchangés."
layout["design_notes"].append("V4 : dimensions +50 % sur chaque axe, surface ×2,25 ; meuble en sprites natifs plus lisibles, visite rapprochée par défaut.")
(SCENE / "layout.json").write_text(json.dumps(layout, ensure_ascii=False, indent=2)+"\n")
(OUTPUT / "plan-v4.json").write_text(json.dumps(layout, ensure_ascii=False, indent=2)+"\n")

assets = SCENE / "assets"
assets.mkdir(exist_ok=True)
enviro = "archives-originales/TheMexicanTequilaWar/Sprites/Enviro/"
sources = {"terrain_atlas.png":enviro+"Sand_Tileset.png", "crate.png":enviro+"Crate_Wood.png",
           "chair.png":enviro+"Chair.png", "table.png":enviro+"Table_Large.png", "couch.png":enviro+"couch.png",
           "barrel.png":"output/anciens-graphismes/images/2da85ea1009cb3f12be3.png",
           "cart.png":"output/anciens-graphismes/images/cb8f1dc9d4d2ef621ea4.png"}
provenance = []
for target, source in sources.items():
    source_path=ROOT/source
    shutil.copyfile(source_path, assets/target)
    provenance.append(dict(file=target,source=source,sha256=hashlib.sha256(source_path.read_bytes()).hexdigest(),
                           note="Copie sans retouche. Baril et charrette : aperçus Pyxel de l’inventaire historique, IDs 137 et 146."))
sheet = assets/"environment-v4.png"
if sheet.exists():
    provenance.append(dict(file=sheet.name, source="image_gen.imagegen (built-in)",
                           sha256=hashlib.sha256(sheet.read_bytes()).hexdigest(),
                           prompt="output/arena/2026-11-23/atlas-v4-prompt.txt",
                           note="Planche originale de 8 sprites sur alpha, grille 4 × 2 ; régions détourées lues par Godot, aucune retouche des archives."))
(assets/"provenance.json").write_text(json.dumps(provenance,ensure_ascii=False,indent=2)+"\n")
print(f"Carte : {len(walls)} murs, {len(props)} objets, 4 départs ; sources archivées copiées.")
