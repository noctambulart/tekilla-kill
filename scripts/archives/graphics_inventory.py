"""Read local legacy art and Unity data; export a gallery without running builds.

Run --help for output options. Original files remain read-only inputs.
"""

import argparse
from datetime import datetime, timezone
from pathlib import Path
from collections import Counter, defaultdict
import hashlib, json, math, zipfile, io, html, re, warnings

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE = ROOT / 'archives-originales'
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, default=ROOT / 'output/anciens-graphismes',
                    help='Gallery destination (default: output/anciens-graphismes).')
args = parser.parse_args()
OUT = args.output.expanduser().resolve()
if not ARCHIVE.is_dir():
    parser.error(f'Archives locales absentes : {ARCHIVE}')
if OUT == ARCHIVE or ARCHIVE in OUT.parents:
    parser.error('La galerie doit être enregistrée hors des archives originales.')

try:
    from PIL import Image, ImageDraw, ImageFont
    from psd_tools import PSDImage
    import UnityPy
except ImportError as exc:
    parser.exit(1, f'Dépendance absente : {exc}. Installer scripts/archives/requirements.txt.\n')

warnings.filterwarnings('ignore')
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'images').mkdir(exist_ok=True)
(OUT / 'vignettes').mkdir(exist_ok=True)
(OUT / 'planches').mkdir(exist_ok=True)
records, by_pixels, errors, files, empty = [], {}, [], [], []
fragments = []
def font(size):
    for candidate in ['/System/Library/Fonts/Supplemental/Arial.ttf', 'DejaVuSans.ttf']:
        try:
            return ImageFont.truetype(candidate, size)
        except OSError:
            pass
    return ImageFont.load_default(size=size)

FONT = font(16)
SMALL = font(13)
TITLE = font(28)

def category(name):
    s = name.lower()
    if 'title' in s or 'screenselector' in s:
        return '04-menus-interface'
    if any(w in s for w in ['face', 'portrait', 'tequila', 'ponchonito']) and 'selection' not in s:
        return '01-portraits-bouteilles'
    if any(w in s for w in ['enviro', 'mokeup', 'leveltest', 'floor', 'barrier', 'boxwood', 'crate', 'sand', 'couch', 'chair', 'table', 'carriage', 'barel']):
        return '02-decors-tilesets'
    if any(w in s for w in ['gui', 'selection', 'startscreen', 'hud', 'cursor', 'plank', 'poster', 'nail', 'shooter', 'ammoicon', 'title']):
        return '04-menus-interface'
    return '03-personnages-armes-effets'

def add_image(im, name, source, group, kind, **meta):
    im = im.convert('RGBA')
    if not im.getbbox():
        empty.append(source)
        return
    digest = hashlib.sha256(str(im.size).encode()+im.tobytes()).hexdigest()
    origin = {'source': source, 'kind': kind, **meta}
    if digest in by_pixels:
        rec = by_pixels[digest]
        if origin not in rec['origins']:
            rec['origins'].append(origin)
        return
    dest = 'images/'+digest[:20]+'.png'
    im.save(OUT / dest)
    rec = {'id': len(records)+1, 'name': name, 'category': group, 'file': dest,
           'width': im.width, 'height': im.height, 'pixel_sha256': digest, 'origins': [origin]}
    records.append(rec)
    by_pixels[digest] = rec

def rel(p):
    return str(p.relative_to(ROOT))

all_paths = sorted(p for p in ARCHIVE.rglob('*') if p.is_file())
source_types = {'.png', '.jpg', '.jpeg', '.bmp', '.psd', '.pyxel', '.ttf', '.tpsheet'}
unique_files = {}
for p in all_paths:
    if p.suffix.lower() not in source_types:
        continue
    blob = p.read_bytes()
    digest = hashlib.sha256(blob).hexdigest()
    files.append({'path': rel(p), 'sha256': digest, 'bytes': len(blob), 'extension': p.suffix.lower()})
    unique_files.setdefault(digest, []).append(p)

for n, paths in enumerate(unique_files.values()):
    p = paths[0]
    ext, source = p.suffix.lower(), rel(p)
    try:
        if ext in {'.png', '.jpg', '.jpeg', '.bmp'}:
            for path in paths:
                add_image(Image.open(p), p.stem, rel(path), category(str(p.relative_to(ARCHIVE)).replace('TheMexicanTequilaWar/','')), 'image originale')
        elif ext == '.psd':
            psd = PSDImage.open(p)
            try:
                composite = Image.open(p).convert('RGBA')
            except Exception:
                composite = psd.composite()
            for path in paths:
                add_image(composite, p.stem+' [PSD]', rel(path), category(str(p.relative_to(ARCHIVE)).replace('TheMexicanTequilaWar/','')), 'composite PSD enregistré')
            for index, layer in enumerate(psd.descendants()):
                if layer.is_group():
                    continue
                try:
                    pic = layer.composite(force=True)
                    if pic is not None:
                        fragments.append((pic, p.stem+' / '+layer.name, source+'#calque-'+str(index),
                                          '07-calques-sources', 'calque PSD', {'layer': layer.name, 'visible': layer.visible, 'offset': list(layer.offset)}))
                except Exception as e:
                    errors.append({'source': source+'#'+layer.name, 'error': str(e)})
        elif ext == '.pyxel':
            with zipfile.ZipFile(p) as z:
                d = json.loads(z.read('docData.json'))
                c = d['canvas']
                size = (int(c['width']), int(c['height']))
                canvas = Image.new('RGBA', size)
                layers = c.get('layers', {})
                for k in sorted(layers, key=int, reverse=True):
                    layer = layers[k]
                    filename = 'layer'+str(k)+'.png'
                    pic = Image.open(io.BytesIO(z.read(filename))).convert('RGBA') if filename in z.namelist() else Image.new('RGBA', size)
                    for pos, ref in layer.get('tileRefs', {}).items():
                        tile_name = 'tile'+str(ref['index'])+'.png'
                        if tile_name not in z.namelist():
                            continue
                        tile = Image.open(io.BytesIO(z.read(tile_name))).convert('RGBA')
                        if ref.get('flipX'):
                            tile = tile.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                        if ref.get('rot'):
                            tile = tile.rotate(-90*ref['rot'], expand=True)
                        tw, th = c['tileWidth'], c['tileHeight']
                        x, y = int(pos) % (size[0]//tw)*tw, int(pos)//(size[0]//tw)*th
                        pic.alpha_composite(tile, (x,y))
                    fragments.append((pic.copy(), p.stem+' / '+layer['name'], source+'#'+filename,
                                      '07-calques-sources', 'calque Pyxel', {'visible': not layer.get('hidden',False), 'opacity': layer.get('alpha',255), 'blendMode':layer.get('blendMode')}))
                    if not layer.get('hidden',False):
                        a = layer.get('alpha',255)
                        if a != 255:
                            pic.putalpha(pic.getchannel('A').point(lambda v: v*a//255))
                        canvas.alpha_composite(pic)
                for path in paths:
                    add_image(canvas, p.stem+' [Pyxel]', rel(path), category(str(p.relative_to(ARCHIVE)).replace('TheMexicanTequilaWar/','')), 'aperçu Pyxel reconstitué', note='Calques visibles, opacité et références de tuiles ; aperçu de consultation.')
                for member in z.namelist():
                    if member.startswith('tile') and member.endswith('.png'):
                        pic = Image.open(io.BytesIO(z.read(member))).convert('RGBA')
                        fragments.append((pic, p.stem+' / '+member, source+'#'+member, '07-calques-sources', 'tuile source Pyxel', {}))
        elif ext == '.ttf':
            pic = Image.new('RGBA',(620,135),(241,226,190,255))
            draw = ImageDraw.Draw(pic)
            f = ImageFont.truetype(str(p),40)
            draw.text((15,8),'Tequila Kill',font=f,fill='#33271d')
            draw.text((15,70),'Arroyo Seco 0123456789',font=ImageFont.truetype(str(p),24),fill='#33271d')
            for path in paths:
                add_image(pic,p.stem,rel(path),'08-polices','spécimen de police')
    except Exception as e:
        errors.append({'source':source,'error':str(e)})
    if n % 25 == 0:
        print('Sources', n, '/', len(unique_files), flush=True)

builds = [
    ('Unity v1', ARCHIVE/'TequilaKill_v1/TequilaKill_v1_Data'),
    ('Unity v3', ARCHIVE/'TequilaKill_v3/TequilaKill_v3.0_Data'),
    ('MexicanTekilaWar 0-0-3', ARCHIVE/'TheMexicanTequilaWar/dist/MexicanTekilaWar_0-0-3_Data'),
]
unity_stats = {}
for build, folder in builds:
    print('Extraction',build,flush=True)
    if not folder.is_dir():
        errors.append({'source': rel(folder), 'error': 'Dossier du build absent'})
        unity_stats[build] = {}
        continue
    env = UnityPy.load(*(str(p) for p in sorted(folder.glob('*.assets'))))
    counts = Counter()
    for obj in env.objects:
        if obj.type.name not in {'Texture2D','Sprite'}:
            continue
        kind = obj.type.name
        try:
            data = obj.read()
            name = data.m_Name
            source = rel(folder/obj.assets_file.name)+'#'+kind+':'+str(obj.path_id)
            if kind == 'Texture2D' and (not data.m_Width or not data.m_Height):
                empty.append(source+' [texture sans dimensions, atlas de police dynamique]')
                continue
            note = {}
            try:
                pic = data.image
            except AssertionError:
                if kind != 'Sprite':
                    raise
                from UnityPy.enums import SpritePackingMode
                data.m_RD.settingsRaw = (data.m_RD.settingsRaw & ~2) | (int(SpritePackingMode.kSPMRectangle) << 1)
                pic = data.image
                note = {'note':'Extraction rectangulaire : ancien maillage de découpe non pris en charge.'}
            technical = any(w in name.lower() for w in ['font','arial','default','lightmap','unity','particle','fonttexture'])
            group = '09-textures-techniques' if technical else '05-builds-unity'
            add_image(pic,name,source,group,kind,build=build,path_id=obj.path_id,**note)
            counts[kind] += 1
        except Exception as e:
            errors.append({'source':build+':'+obj.assets_file.name+':'+kind+':'+str(obj.path_id),'name':getattr(data,'m_Name',''),'error':str(e) or type(e).__name__})
    unity_stats[build] = dict(counts)

for args in fragments:
    im,name,source,group,kind,meta = args
    add_image(im,name,source,group,kind,**meta)

for version in ['v1','v3']:
    p=ROOT/'docs/assets'/('unity-'+version)/'arena-reconstituee.png'
    if p.exists():
        add_image(Image.open(p), 'Arène Unity '+version+' [reconstitution]',rel(p),'06-arenes-reconstituees','reconstitution statique existante',note='Composition des scènes archivées, pas une capture en jeu.')

groups = {
 '01-portraits-bouteilles':'Portraits et bouteilles',
 '02-decors-tilesets':'Décors, mobilier et tilesets',
 '03-personnages-armes-effets':'Personnages, armes et effets',
 '04-menus-interface':'Menus et interface',
 '05-builds-unity':'Images supplémentaires des trois builds Unity',
 '06-arenes-reconstituees':'Arènes reconstituées depuis les scènes Unity',
 '07-calques-sources':'Calques et tuiles des sources éditables',
 '08-polices':'Polices présentes dans les archives',
 '09-textures-techniques':'Textures techniques des builds',
}

def checker(w,h):
    im=Image.new('RGB',(w,h),'#d1cbbb')
    draw=ImageDraw.Draw(im)
    for y in range(0,h,12):
        for x in range(0,w,12):
            if (x//12+y//12)%2:
                draw.rectangle((x,y,x+11,y+11),fill='#e3dece')
    return im

def fit(im,w,h):
    box = im.getbbox()
    if box:
        im = im.crop(box)
    scale=min(w/im.width,h/im.height,6)
    if scale>=1:
        scale=max(1,int(scale))
    return im.resize((max(1,int(im.width*scale)),max(1,int(im.height*scale))),Image.Resampling.NEAREST)

sheets=[]
for group,title in groups.items():
    subset=[r for r in records if r['category']==group]
    for start in range(0,len(subset),24):
        chunk=subset[start:start+24]
        rows=math.ceil(len(chunk)/4)
        sheet=Image.new('RGB',(1280,100+rows*242),'#f2eddf')
        draw=ImageDraw.Draw(sheet)
        draw.text((22,15),title,font=TITLE,fill='#392c23')
        draw.text((22,55),f'{start+1}–{start+len(chunk)} / {len(subset)} • Archives originales • aperçu au plus proche voisin',font=FONT,fill='#675b4c')
        for j,r in enumerate(chunk):
            x,y=(j%4)*320+10,(j//4)*242+90
            bg=checker(300,178)
            im=fit(Image.open(OUT/r['file']).convert('RGBA'),292,170)
            bg.paste(im,((300-im.width)//2,(178-im.height)//2),im)
            sheet.paste(bg,(x,y))
            name=r['name']
            while draw.textlength(name,font=FONT)>299:
                name=name[:-2]
            if name!=r['name']:
                name+='…'
            draw.text((x,y+184),f"#{r['id']} {name}",font=FONT,fill='#32271f')
            draw.text((x,y+207),f"{r['width']} × {r['height']} px • {len(r['origins'])} provenance(s)",font=SMALL,fill='#675b4c')
        filename=f'planches/{group}-{start//24+1:02}.png'
        sheet.save(OUT/filename)
        sheets.append({'category':group,'title':title,'file':filename,'count':len(chunk)})

summary = {'original_graphic_files':len(files),'unique_original_files_by_sha256':len(unique_files),
           'file_extensions':dict(Counter(f['extension'] for f in files)),
           'unique_nonempty_previews':len(records),'categories':dict(Counter(r['category'] for r in records)),
           'unity_extractions':unity_stats,'empty_previews':len(empty),'errors':len(errors)}
manifest={'date':datetime.now(timezone.utc).date().isoformat(),'scope':'Archives locales complètes : images, composites PSD, aperçus Pyxel, calques, tuiles, polices et sprites/textures de trois builds Unity. Aucun exécutable lancé. Aucune image générée par IA.',
          'summary':summary,'files':files,'images':records,'contact_sheets':sheets,'empty':empty,'errors':errors}
(OUT/'inventaire.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))

cards=[]
for r in records:
    esc=html.escape
    origins=''.join('<li>'+esc(o['source'])+' — '+esc(o['kind'])+'</li>' for o in r['origins'])
    search=' '.join([r['name'],r['category']]+[o['source']+' '+o.get('build','') for o in r['origins']]).lower()
    thumb = 'vignettes/'+Path(r['file']).name
    fit(Image.open(OUT/r['file']).convert('RGBA'),600,440).save(OUT/thumb)
    cards.append(f'''<article data-category="{r['category']}" data-search="{esc(search,quote=True)}"><a class="preview" href="{r['file']}" target="_blank"><img loading="lazy" src="{thumb}" alt="{esc(r['name'],quote=True)}"></a><h2>#{r['id']} {esc(r['name'])}</h2><p>{r['width']} × {r['height']} px · {len(r['origins'])} provenance(s)</p><details><summary>Origines et formats</summary><ul>{origins}</ul></details></article>''')
options=''.join(f'<option value="{k}">{html.escape(v)} ({summary["categories"].get(k,0)})</option>' for k,v in groups.items())
sheetlinks=''.join(f'<li><a href="{s["file"]}">{html.escape(s["title"])} — planche {s["file"][-6:-4]}</a></li>' for s in sheets)
page='''<!doctype html><html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Tequila Kill — Tous les anciens graphismes</title><style>
*{box-sizing:border-box}body{margin:0;background:#eee8da;color:#30281e;font:16px system-ui,sans-serif}header{padding:28px max(20px,5vw);background:#34291f;color:#f8ead1}h1{font-size:30px;margin:0 0 12px}header p{max-width:1000px;line-height:1.55}a{color:inherit}.controls{position:sticky;top:0;background:#eee8daf2;backdrop-filter:blur(8px);padding:15px 4vw;display:flex;flex-wrap:wrap;gap:12px;z-index:1;border-bottom:1px solid #c1b69f}input,select{font:inherit;padding:10px;border:1px solid #a99c84;border-radius:5px;background:#fffaf0}input{flex:1;min-width:230px}#grid{padding:20px 4vw;display:grid;grid-template-columns:repeat(auto-fill,minmax(270px,1fr));gap:18px}article{background:#fffaf0;border:1px solid #c8bba3;border-radius:7px;overflow:hidden}article[hidden]{display:none}.preview{display:flex;height:225px;align-items:center;justify-content:center;background:repeating-conic-gradient(#d1cbbb 0 25%,#e3dece 0 50%) 0/20px 20px;padding:10px}.preview img{max-width:100%;max-height:100%;image-rendering:pixelated;object-fit:contain}h2{font-size:16px;margin:14px 12px 8px;overflow-wrap:anywhere}article p,details{font-size:13px;margin:12px;color:#655745}details{overflow-wrap:anywhere}details ul{padding-left:15px}summary{cursor:pointer}#count{align-self:center}header details{color:#f8ead1;margin:12px 0}header ul{columns:3}footer{padding:20px 4vw}
</style><header><h1>Tequila Kill — Anciens graphismes</h1><p>INVENTORY_SUMMARY</p><p>Fichiers d'origine conservés sans modification. Les copies et images aux pixels identiques sont regroupées ; chaque provenance reste consultable. Les calques isolés, polices et textures techniques ont leurs propres catégories. Les aperçus Pyxel sont reconstitués ; les arènes existantes sont des compositions statiques, pas des captures de partie.</p><details><summary>Toutes les planches de contact</summary><ul>SHEET_LINKS</ul></details><a href="inventaire.json">Inventaire détaillé et éventuelles limites de lecture</a></header><div class="controls"><input id="search" type="search" placeholder="Rechercher : Poncho, Garcia, bouteille, nom de fichier…" aria-label="Rechercher"><select id="category" aria-label="Catégorie"><option value="">Tout afficher</option>OPTIONS</select><span id="count"></span></div><main id="grid">CARDS</main><footer>Aucun concept art récent n'est inclus. Cliquez sur une image pour ouvrir le PNG ; le damier représente la transparence.</footer><script>
const cards=[...document.querySelectorAll('article')],search=document.querySelector('#search'),category=document.querySelector('#category'),count=document.querySelector('#count');function filter(){const q=search.value.trim().toLowerCase();let n=0;for(const c of cards){c.hidden=!!((category.value&&c.dataset.category!==category.value)||(q&&!c.dataset.search.includes(q)));if(!c.hidden)n++}count.textContent=n+' / '+cards.length+' images'}search.addEventListener('input',filter);category.addEventListener('change',filter);filter();
</script></html>'''
description=f"{len(files)} fichiers graphiques et typographiques retrouvés, {len(unique_files)} contenus de fichiers distincts, {len(records)} aperçus visuels uniques après extraction des sources et de trois builds Unity. Vignettes recadrées sur le contenu visible ; images complètes accessibles au clic. Limite : {len(errors)} entrées du build 0-0-3 non extractibles, car le fichier sharedassets1.assets.resS manque dans l'archive."
page=page.replace('INVENTORY_SUMMARY',description).replace('SHEET_LINKS',sheetlinks).replace('OPTIONS',options).replace('CARDS','\n'.join(cards))
(OUT/'index.html').write_text(page)
print(json.dumps(summary,ensure_ascii=False,indent=2),flush=True)
print('ERRORS',json.dumps(errors,ensure_ascii=False),flush=True)
