"""Bundle the second concept; V1 assets and originals remain unchanged."""
import base64
import hashlib
import json
from pathlib import Path
import re

HERE=Path(__file__).resolve().parent
PROJECT=HERE.parents[4]
DEST=Path('/Users/noctambul/.codex/visualizations/2026/11/25/01a212f6-de98-7b93-8e21-79790fc70a73/tequila-v02-bottle-v2.html')
fragment=(HERE/'concept.template.html').read_text()
for key,name in {'CLOSE':'close.jpg','FAR':'far.jpg','TITLE':'title.jpg'}.items():
    p=HERE.parent/'v1'/'assets'/name
    fragment=fragment.replace(f'__TK_{key}__','data:image/jpeg;base64,'+base64.b64encode(p.read_bytes()).decode())
assert '__TK_' not in fragment and len(fragment.encode())<1_000_000
assert not re.search(r'<(?:html|head|body)\b|<!doctype',fragment,re.I)
assert '\\"' not in fragment and '\\n' not in fragment
(HERE/'concept.html').write_text(fragment)
DEST.write_text(fragment)
(HERE/'check-script.js').write_text('\n'.join(re.findall(r'<script>(.*?)</script>',fragment,re.S)))
sources=['output/camera/2026-11-25-wider/after-close.png','output/camera/2026-11-25-wider/after-far.png','output/ui/2026-11-25-menu-intro-dash/title.png']
manifest={
    'issue':64,'version':'v2','status':'maquette_a_examiner_direction_validee',
    'direction':'Bouteille graphique sans chiffres ; ivresse cumulative ; marquage du porteur indépendant et prioritaire.',
    'sources':[{'path':p,'sha256':hashlib.sha256((PROJECT/p).read_bytes()).hexdigest()}for p in sources],
    'method':'Composition par code sur captures existantes ; bouteille et effets dessinés dans la maquette ; aucune génération IA ni modification Godot.',
    'states':['ground','poncho','garcia','ghost','return','low','result','tie','title'],
    'cameras':['close','far'],'fragment_bytes':len(fragment.encode()),'selected_reference':None,
}
(HERE/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'fragment':str(DEST),'bytes':len(fragment.encode()),'states':len(manifest['states'])},ensure_ascii=False))
