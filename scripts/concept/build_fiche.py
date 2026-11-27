import json
"""Rebuild the retained concept sheet and its image selection manifest."""

from pathlib import Path

from PIL import Image
from pypdf import PdfReader
from reportlab.lib.colors import HexColor
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas

root=Path(__file__).resolve().parents[2]
manifest_path=root/'docs/assets/concept/sources.json'
manifest=json.loads(manifest_path.read_text())
manifest['images']=[r for r in manifest['images'] if r['role'] not in ('wanted','ramiro')]
manifest['description']='Fiche unique du concept, avec une sélection de dix graphismes issus des trois ensembles historiques.'
images={r['role']:root/r['file'] for r in manifest['images']}
pdf=root/'output/pdf/tequila-kill-fiche.pdf'
W,H=595.28,841.89
c=canvas.Canvas(str(pdf),pagesize=(W,H),pageCompression=1)
c.setTitle('Tequila Kill - Fiche de concept unifiée')
c.setAuthor('Tequila Kill')
c.setSubject('Arroyo Seco, Arizona - Archives originales et versions Unity v1/v3')
def rect(x,y,w,h,color):
    c.setFillColor(HexColor(color));c.rect(x,H-y-h,w,h,stroke=0,fill=1)
def text(x,y,value,size=10,color='#30271e',bold=False):
    c.setFillColor(HexColor(color));c.setFont('Helvetica-Bold' if bold else 'Helvetica',size);c.drawString(x,H-y,value)
def label(x,y,value):text(x,y,value,9,'#9c492c',True)
def image(key,x,y,w,h):
    im=Image.open(images[key]).convert('RGBA')
    factor=min(w/im.width,h/im.height)
    iw,ih=im.width*factor,im.height*factor
    if factor>1:
        multiple=max(1,int(factor*2+0.999))
        im=im.resize((im.width*multiple,im.height*multiple),Image.Resampling.NEAREST)
    c.drawImage(ImageReader(im),x+(w-iw)/2,H-y-h+(h-ih)/2,iw,ih,mask='auto')

rect(0,0,W,H,'#f5ecd9');rect(0,0,W,126,'#29251f');rect(32,25,28,4,'#eaa04d')
text(72,31,'LE CONCEPT EN IMAGES',8,'#d4bea0',True)
text(32,70,'TEQUILA',31,'#fff2d9',True);text(32,105,'KILL',31,'#fff2d9',True)
text(401,66,'COMBAT EN ARÈNE',12,'#eaa04d',True)
text(401,85,'PIXEL ART • VUE DU DESSUS',8.5,'#fff2d9',True)
text(401,105,'JUSQU’À 16 JOUEURS VISÉS',8.5,'#d4bea0')
text(32,154,'Une bouteille. Un village. Un seul vainqueur.',16,bold=True)
text(32,178,'À Arroyo Seco, petit village fictif de l’Arizona, il ne reste qu’une bouteille.',11)
text(32,194,'Empare-toi d’elle : celui qui en boit le plus remporte la partie.',11)
label(32,224,'LE VILLAGE');label(410,224,'L’OBJECTIF')
image('arena',32,237,352,211.2)
image('bottle',410,237,153,159.375)
text(32,462,'Arène de la version Unity v3 reconstituée depuis la scène.',8,'#685b4b')
text(410,416,'La dernière tequila.',10,bold=True)
label(32,492,'LES COMBATTANTS');label(289,492,'LA SÉLECTION')
image('poncho',32,505,100,100);image('garcia',151,505,100,100)
text(32,622,'EL PONCHO',9,bold=True);text(151,622,'GARCIA',9,bold=True)
image('selection',289,505,274,154.125)
label(32,697,'LES PETITS DÉTAILS')
for i,(key,title) in enumerate([('hat','Sombrero'),('crate','Caisse'),('fence','Barrière'),('table','Table'),('life','Vie')]):
    x=32+i*109
    rect(x,714,95,70,'#e5d7b9');image(key,x+19.5,721,56,56)
    text(x+2,801,title,8,'#685b4b')
rect(32,815,531,.6,'#c4b18d')
text(32,830,'Concept en préparation • Visuels des archives originales et des versions Unity v1 / v3',7.5,'#685b4b')
c.showPage();c.save()
reader=PdfReader(pdf)
assert len(reader.pages)==1
content=reader.pages[0].extract_text()
assert 'WESTERN' not in content and 'Don Ramiro' not in content
assert 'Arroyo Seco' in content
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
print(json.dumps({'file':str(pdf),'pages':1,'images':len(images)}))
