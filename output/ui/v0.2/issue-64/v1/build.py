"""Bundle the literal concept fragment and existing local assets for inline review."""
import base64
import hashlib
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
PROJECT = HERE.parents[4]
DEST = Path('/Users/noctambul/.codex/visualizations/2026/11/25/01a212f6-de98-7b93-8e21-79790fc70a73/tequila-v02-bottle.html')
fragment = (HERE / 'concept.template.html').read_text()
mapping = {'CLOSE': 'close.jpg', 'FAR': 'far.jpg', 'BOTTLE': 'bottle.png', 'TITLE': 'title.jpg'}
for key, name in mapping.items():
    path = HERE / 'assets' / name
    mime = 'image/png' if name.endswith('.png') else 'image/jpeg'
    fragment = fragment.replace(f'__TK_{key}__', f'data:{mime};base64,' + base64.b64encode(path.read_bytes()).decode())
assert '__TK_' not in fragment
assert len(fragment.encode()) < 1_000_000
assert not re.search(r'<(?:html|head|body)\b|<!doctype', fragment, re.I)
assert '\\"' not in fragment and '\\n' not in fragment
(HERE / 'concept.html').write_text(fragment)
DEST.write_text(fragment)
source_paths = [
    'output/camera/2026-11-25-wider/after-close.png',
    'output/camera/2026-11-25-wider/after-far.png',
    'godot/scenes/intro/assets/bottle.png',
    'output/ui/2026-11-25-menu-intro-dash/title.png',
]
manifest = {
    'issue': 64, 'version': 'v1', 'status': 'propositions_ecartees_par_le_producteur',
    'superseded_by': '../v2/manifest.json',
    'sources': [{'path': p, 'sha256': hashlib.sha256((PROJECT / p).read_bytes()).hexdigest()} for p in source_paths],
    'variants': ['Scores près des joueurs', 'Scores avec la réserve'],
    'cameras': ['rapproché', 'éloigné'],
    'states': ['au sol', 'Poncho porteur', 'Garcia porteur', 'Poncho fantôme', 'victoire de Poncho', 'victoire partagée', 'retour au titre'],
    'method': 'Captures v0.1 réutilisées et composition des ajouts par code ; aucune génération d’image IA ni exécution Godot.',
    'fragment_bytes': len(fragment.encode()),
    'selected_reference': None,
}
(HERE / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
scripts = re.findall(r'<script>(.*?)</script>', fragment, re.S)
(HERE / 'check-script.js').write_text('\n'.join(scripts))
print(json.dumps({'fragment': str(DEST), 'bytes': len(fragment.encode()), 'variants': len(manifest['variants']), 'states': len(manifest['states'])}, ensure_ascii=False))
