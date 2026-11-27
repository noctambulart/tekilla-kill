"""Bundle V11: neutral ghost, winner percentage and local retro audio previews."""
import base64
import hashlib
import json
from pathlib import Path
import re

HERE=Path(__file__).resolve().parent
PROJECT=HERE.parents[4]
DEST=Path('/Users/noctambul/.codex/visualizations/2026/11/25/01a212f6-de98-7b93-8e21-79790fc70a73/tequila-v02-bottle-v11.html')
fragment=(HERE/'concept.template.html').read_text()
assets={
    'CLOSE':HERE.parent/'v1/assets/close.jpg',
    'FAR':HERE.parent/'v1/assets/far.jpg',
    'TITLE':HERE.parent/'v1/assets/title.jpg',
    'BOTTLE':HERE/'assets/bottle.png',
    'PONCHO':PROJECT/'godot/scenes/character/assets/saloon_warm/poncho/idle.png',
    'HAT':PROJECT/'godot/scenes/character/assets/saloon_warm/poncho/hat_idle.png',
    'ARM':PROJECT/'godot/scenes/character/assets/saloon_warm/poncho/arm_idle.png',
    'TAKE':PROJECT/'output/audio/v0.2/issue-65/v1/take.wav',
    'DROP':PROJECT/'output/audio/v0.2/issue-65/v1/drop.wav',
    'EMPTY':PROJECT/'output/audio/v0.2/issue-65/v1/empty.wav',
}
for key,p in assets.items():
    mime={'.jpg':'image/jpeg','.png':'image/png','.wav':'audio/wav'}[p.suffix]
    fragment=fragment.replace(f'__TK_{key}__',f'data:{mime};base64,'+base64.b64encode(p.read_bytes()).decode())
assert '__TK_' not in fragment and len(fragment.encode())<1_000_000
assert not re.search(r'<(?:html|head|body)\b|<!doctype',fragment,re.I)
assert '\\"' not in fragment and '\\n' not in fragment
(HERE/'concept.html').write_text(fragment)
DEST.write_text(fragment)
(HERE/'check-script.js').write_text('\n'.join(re.findall(r'<script>(.*?)</script>',fragment,re.S)))
sources=['output/camera/2026-11-25-wider/after-close.png','output/camera/2026-11-25-wider/after-far.png','output/ui/2026-11-25-menu-intro-dash/title.png','godot/scenes/intro/assets/bottle.png','godot/scenes/character/assets/saloon_warm/poncho/idle.png','godot/scenes/character/assets/saloon_warm/poncho/hat_idle.png','godot/scenes/character/assets/saloon_warm/poncho/arm_idle.png']
manifest={
    'issue':64,'version':'v11','status':'concepts_valides_integration_a_realiser',
    'direction':'Round sans chiffres ; pourcentage du gagnant au résultat temporaire ; fantôme presque noir et blanc ; sons rétro locaux.',
    'sources':[{'path':p,'sha256':hashlib.sha256((PROJECT/p).read_bytes()).hexdigest()}for p in sources],
    'method':'Captures et sprites actuels réutilisés ; bouteille de tequila existante réemployée avec niveau graphique ; aucune génération IA ni modification Godot.',
    'drunkenness_comparison':['Sobre','Quelques gorgées','Bien ivre'],
    'drunkenness_effect':{'shape':'petites étoiles à cinq branches','motion':'départs variés sur la silhouette, montée puis chute en cloche','origins':'chapeau, épaules, torse et côtés ; changement à chaque réémission','lifetime_seconds':1.35,'illustrative_counts':[0,4,12],'approval':'forme validée V5 ; réglages du producteur repris en V11'},
    'bobbing':{'radians_per_second':4,'period_seconds':round(2*3.141592653589793/4,3)},
    'producer_animation_tuning':{'starHeight':1.1,'starSpread':1.05,'starSize':1.1,'bobSpeed':4},
    'states':['ground','poncho','garcia','ghost','return','low','result','result_garcia','tie','title'],
    'cameras':['close','far'],'fragment_bytes':len(fragment.encode()),'selected_reference':'v11','validation':'validation.json',
    'selected_particle_reference':{'version':'v5','approved_on':'2026-11-26','record':'../v5/validation.json','scope':'particules d’ivresse uniquement'},
    'selected_static_bottle_reference':{'version':'v10','approved_on':'2026-11-26','record':'../v10/validation.json','scope':'bouteille fixe et cadre ovale'},
    'carrier_approved_on':'2026-11-26',
    'review_pending':[],
    'audio_manifest':'../../../../audio/v0.2/issue-65/v1/manifest.json',
    'audio':[{'path':str(p.relative_to(PROJECT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in assets.values() if p.suffix=='.wav'],
    'bottle_harmonization':{'static_height':100,'previous_static_height':132,'frame_width':86.4,'frame_height':124.8,'rendering':'bouteille contenue dans le contour extérieur, léger contact des angles avec le bord intérieur ; cadre V8 conservé','approval':'bouteille fixe et cadre validés le 26 novembre 2026'},
}
(HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'fragment':str(DEST),'bytes':len(fragment.encode()),'states':len(manifest['states'])},ensure_ascii=False))
