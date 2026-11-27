"""Bundle V6 with the static bottle scaled and rendered like the held bottle."""
import base64
import hashlib
import json
from pathlib import Path
import re

HERE=Path(__file__).resolve().parent
PROJECT=HERE.parents[4]
DEST=Path('/Users/noctambul/.codex/visualizations/2026/11/25/01a212f6-de98-7b93-8e21-79790fc70a73/tequila-v02-bottle-v6.html')
fragment=(HERE/'concept.template.html').read_text()
assets={
    'CLOSE':HERE.parent/'v1/assets/close.jpg',
    'FAR':HERE.parent/'v1/assets/far.jpg',
    'TITLE':HERE.parent/'v1/assets/title.jpg',
    'BOTTLE':HERE/'assets/bottle.png',
    'PONCHO':PROJECT/'godot/scenes/character/assets/saloon_warm/poncho/idle.png',
    'HAT':PROJECT/'godot/scenes/character/assets/saloon_warm/poncho/hat_idle.png',
    'ARM':PROJECT/'godot/scenes/character/assets/saloon_warm/poncho/arm_idle.png',
}
for key,p in assets.items():
    mime='image/jpeg' if p.suffix=='.jpg' else 'image/png'
    fragment=fragment.replace(f'__TK_{key}__',f'data:{mime};base64,'+base64.b64encode(p.read_bytes()).decode())
assert '__TK_' not in fragment and len(fragment.encode())<1_000_000
assert not re.search(r'<(?:html|head|body)\b|<!doctype',fragment,re.I)
assert '\\"' not in fragment and '\\n' not in fragment
(HERE/'concept.html').write_text(fragment)
DEST.write_text(fragment)
(HERE/'check-script.js').write_text('\n'.join(re.findall(r'<script>(.*?)</script>',fragment,re.S)))
sources=['output/camera/2026-11-25-wider/after-close.png','output/camera/2026-11-25-wider/after-far.png','output/ui/2026-11-25-menu-intro-dash/title.png','godot/scenes/intro/assets/bottle.png','godot/scenes/character/assets/saloon_warm/poncho/idle.png','godot/scenes/character/assets/saloon_warm/poncho/hat_idle.png','godot/scenes/character/assets/saloon_warm/poncho/arm_idle.png']
manifest={
    'issue':64,'version':'v6','status':'maquette_a_examiner_direction_validee',
    'direction':'Bouteille graphique sans chiffres ; ivresse cumulative ; marquage du porteur indépendant et prioritaire.',
    'sources':[{'path':p,'sha256':hashlib.sha256((PROJECT/p).read_bytes()).hexdigest()}for p in sources],
    'method':'Captures et sprites actuels réutilisés ; bouteille de tequila existante réemployée avec niveau graphique ; aucune génération IA ni modification Godot.',
    'drunkenness_comparison':['Sobre','Quelques gorgées','Bien ivre'],
    'drunkenness_effect':{'shape':'petites étoiles à cinq branches','motion':'départs variés sur la silhouette, montée puis chute en cloche','origins':'chapeau, épaules, torse et côtés ; changement à chaque réémission','lifetime_seconds':1.35,'illustrative_counts':[0,4,12],'approval':'proposition à examiner'},
    'bobbing':{'v2_radians_per_second':2.5,'v6_radians_per_second':3.8,'v6_period_seconds':round(2*3.141592653589793/3.8,3)},
    'states':['ground','poncho','garcia','ghost','return','low','result','tie','title'],
    'cameras':['close','far'],'fragment_bytes':len(fragment.encode()),'selected_reference':None,
    'selected_particle_reference':{'version':'v5','approved_on':'2026-11-26','record':'../v5/validation.json','scope':'particules d’ivresse uniquement'},
    'bottle_harmonization':{'static_height_before':130,'static_height':88,'held_height_close':68.85,'rendering':'même dessin, palette, niveau et halo que la bouteille du porteur','approval':'proposition à examiner'},
}
(HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'fragment':str(DEST),'bytes':len(fragment.encode()),'states':len(manifest['states'])},ensure_ascii=False))
