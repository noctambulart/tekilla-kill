from pathlib import Path
import base64
import json
import subprocess
from html import escape

folder = Path(__file__).resolve().parent.parent
data = json.loads((folder / '08-zones-marche.geometry.json').read_text())
background = base64.b64encode((folder / 'source' / '08-map-background.jpg').read_bytes()).decode()
blocked = []
for points in data['blocked_polygons']:
    blocked.append(f'<polygon points="{points}" fill="black"/>')
for x, y, width, height in data['blocked_rects']:
    blocked.append(f'<rect x="{x}" y="{y}" width="{width}" height="{height}" fill="black"/>')
for line in data['blocked_lines']:
    blocked.append(f'<polyline points="{line["points"]}" stroke="black" stroke-width="{line["width"]}" stroke-linejoin="round" fill="none"/>')
bands = []
markers = []
for point in data['review_points']:
    parts = []
    for x, y, width, height in point['bands']:
        parts.append(f'<rect x="{x}" y="{y}" width="{width}" height="{height}" rx="7"/>')
    bands.append(f'<g class="review-band" data-point="{point["id"]}">{"".join(parts)}</g>')
    x, y = point['marker']
    markers.append(f'<g class="static-marker"><circle cx="{x}" cy="{y}" r="21" fill="#fff5dc" stroke="#a44b00" stroke-width="3"/><text x="{x}" y="{y + 8}" text-anchor="middle" fill="#4d280f" font-size="27" font-weight="500" font-family="sans-serif">{point["id"]}</text></g>')
svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1585 992" width="1585" height="992" class="annotation-svg" role="img" aria-label="Zones de marche proposées sur la maquette du village. Les seuils à ouvrir ou élargir sont repérés de un à quatre.">
<defs><mask id="village-walk-mask" maskUnits="userSpaceOnUse" x="0" y="0" width="1585" height="992"><rect width="1585" height="992" fill="black"/><path d="{data['walk_boundary']}" fill="white"/>{''.join(blocked)}</mask></defs>
<image href="data:image/jpeg;base64,{background}" width="1585" height="992"/>
<g id="walk-layer" opacity="0.32"><rect width="1585" height="992" fill="#23ae78" mask="url(#village-walk-mask)"/></g>
<g id="review-layer" fill="#f1a12a" fill-opacity="0.32" stroke="#a44b00" stroke-width="3" stroke-dasharray="8 5">{''.join(bands)}</g>
{''.join(markers)}
</svg>'''
(folder / '08-zones-marche.svg').write_text(svg)
subprocess.run(['rsvg-convert', str(folder / '08-zones-marche.svg'), '-o', str(folder / '08-zones-marche.png')], check=True)
inline_svg = svg.replace('width="1585" height="992" class="annotation-svg"', 'class="annotation-svg"')
inline_svg = inline_svg.replace('fill="#23ae78"', 'fill="var(--green)"')
inline_svg = inline_svg.replace('fill="#f1a12a"', 'fill="var(--orange)"').replace('stroke="#a44b00"', 'stroke="var(--orange)"')
inline_svg = inline_svg.replace('id="walk-layer"', 'id="walk-layer-arroyo"').replace('id="review-layer"', 'id="review-layer-arroyo"')
template_path = folder / 'source' / 'passages-fragment.template.html'
if template_path.exists():
    fragment = template_path.read_text().replace('<!--MAP_SVG-->', inline_svg)
    fragment = fragment.replace('<!--REVIEW_DATA-->', json.dumps(data['review_points'], ensure_ascii=False))
    destination = Path('/Users/noctambul/.codex/visualizations/2026/11/22/01a2035b-8dee-7ab3-b980-041e01c31c6b/arroyo-zones-de-marche.html')
    destination.write_text(fragment)
    assert destination.stat().st_size < 1_000_000
    print(f'Fragment : {destination.stat().st_size} octets')
print('Annotation vectorielle et PNG générés ; source artistique inchangée.')
