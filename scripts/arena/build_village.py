"""Build village V6 from the accepted saloon, in logical world units.

The JSON is authoritative for floors, openings, props, ground footprints, spawns
and routes. Old V5 is preserved in output/arena/2026-11-25-village-v6/before/.
"""
from pathlib import Path
import copy
import json

ROOT = Path(__file__).resolve().parents[2]
SCENE = ROOT / 'godot/scenes/arroyo_seco'
OUTPUT = ROOT / 'output/arena/2026-11-25-village-v6'


def rectangle(points):
    x, y, w, h = points
    return [[x, y], [x+w, y], [x+w, y+h], [x, y+h]]


def walls_for_polygon(name, polygon, fence=False, thickness=12):
    result = []
    for index, (a, b) in enumerate(zip(polygon, polygon[1:]+polygon[:1])):
        if a[1] == b[1]:
            rect = [min(a[0], b[0]), a[1]-thickness/2, abs(a[0]-b[0]), thickness]
        else:
            assert a[0] == b[0]
            rect = [a[0]-thickness/2, min(a[1], b[1]), thickness, abs(a[1]-b[1])]
        result.append(dict(id=f'{name}-{index}', rect=rect, fence=fence))
    return result


def room_walls(room):
    x,y,w,h = room['rect']
    result = []
    spans = {'north':(x,x+w,y,True), 'east':(y,y+h,x+w,False),
             'south':(x,x+w,y+h,True), 'west':(y,y+h,x,False)}
    thickness = 8 if room['floor']=='earth' else 12
    for side,(low,high,fixed,horizontal) in spans.items():
        start = low
        doors = room['doors'].get(side, [])
        assert len(doors) in (0,2)
        gaps = [doors] if doors else []
        for first,last in gaps+[[high,high]]:
            assert start<=first<=last<=high,(room['id'],side)
            if first>start:
                r = ([start,fixed-thickness/2,first-start,thickness] if horizontal
                     else [fixed-thickness/2,start,thickness,first-start])
                result.append(dict(id=f"{room['id']}-{side}-{len(result)}",rect=r,
                                   fence=room['floor']=='earth',front=side=='south'))
            start=last
    return result


def build():
    study = json.loads((SCENE/'saloon_study/layout.json').read_text())
    rooms = [
        dict(id='saloon',name='Saloon',rect=[80,272,448,352],floor='stone',
             doors={'north':[280,376],'east':[440,568],'south':[280,424]}),
        dict(id='shop',name='Épicerie',rect=[872,384,384,288],floor='stone',
             doors={'west':[468,596],'east':[472,552],'south':[1000,1128]}),
        dict(id='shed',name='Remise',rect=[112,736,288,160],floor='wood',
             doors={'north':[208,304],'east':[776,856],'south':[224,320]}),
        dict(id='yard',name='Enclos',rect=[1064,128,264,176],floor='earth',
             doors={'west':[176,256],'south':[1136,1232]}),
    ]
    perimeter = [[16,208],[64,208],[64,16],[608,16],[608,0],[816,0],[816,16],
                 [1360,16],[1360,112],[1424,112],[1424,704],[1360,704],[1360,944],
                 [816,944],[816,960],[608,960],[608,944],[80,944],[80,864],[16,864]]
    walls = walls_for_polygon('perimeter',perimeter,True,8)
    for room in rooms:
        walls += room_walls(room)
    fences = [[344,64,8,112],[344,172,48,8],[80,160,24,8],
              [808,64,8,128],[808,188,16,8],[848,776,8,128],[848,900,24,8],
              [1136,784,136,8],[1268,784,8,120],[1184,900,88,8],
              [816,320,8,64],[816,320,64,8]]
    for index, r in enumerate(fences):
        walls.append(dict(id=f'courtyard-{index}',rect=r,fence=True))
    props = []
    # Reuse the exact accepted saloon furniture, translated without scaling.
    for data in study['props']:
        if data['id'] in ['house','street-pot','cart']:
            continue
        item = copy.deepcopy(data)
        item['id'] = 'saloon-'+item['id']
        item['position'] = [item['position'][0]+16,item['position'][1]+32]
        props.append(item)
    def prop(id, kind, x,y,width=None,**values):
        item=dict(id=id,kind=kind,position=[x,y],breakable=kind in ['crate','pot','chair_n','chair_s','chair_w','chair_e'])
        if width is not None:item['width']=width
        item.update(values);props.append(item)
    prop('home-west','house',136,48)
    prop('home-north','house_wood',424,32,160)
    prop('home-east','house_small',832,48)
    prop('home-south','house',896,752)
    prop('shop-counter','store_counter',1032,448)
    prop('shop-back-west','goods',920,400)
    prop('shop-back-east','goods',1032,400)
    prop('shop-side','goods_v',1216,392,footprints=[[2,10,20,82]])
    prop('shop-produce-a','produce',1160,616)
    prop('shop-produce-b','produce',1196,616)
    prop('shop-barrel','barrel',888,404)
    prop('shop-pot','pot',1204,640)
    prop('loading-crate-a','crate',1292,528,24)
    prop('loading-crate-b','crate',1292,560,24)
    prop('loading-barrel','barrel',1292,624)
    prop('shed-crate-a','crate',128,756,24)
    prop('shed-crate-b','crate',128,790,24)
    prop('shed-barrel-a','barrel',160,852)
    prop('shed-barrel-b','barrel',190,852)
    prop('shed-tools','tools',312,748)
    prop('shed-pot','pot',368,856)
    prop('yard-trough','trough',1104,152)
    prop('yard-crate','crate',1256,256,24)
    prop('yard-barrel','barrel',1292,200)
    prop('rear-cart','cart',432,192,72)
    prop('courtyard-pot','pot',944,888)
    prop('street-crate','crate',784,352,24)
    prop('saloon-entry-pot','pot',552,604)
    prop('shop-entry-pot','pot',840,640)
    decor=[]
    def decoration(kind,x,y,width=None):
        d=dict(kind=kind,position=[x,y])
        if width is not None:d['width']=width
        decor.append(d)
    decoration('crate_broken',1292,256,24)
    decoration('pot_broken',1200,704,18)
    for x,y in [(40,192),(40,512),(56,816),(120,924),(408,928),(1376,768),(1384,144),(1264,48)]:
        decoration('cactus',x,y,20)
    for x,y in [(112,40),(312,96),(592,48),(1000,72),(1000,184),(1360,320),
                (1360,680),(1080,888),(1152,824),(432,704),(72,696),(136,688)]:
        decoration('bush',x,y)
    for x,y in [(24,224),(360,40),(592,104),(1368,680),(1328,904),(432,904)]:
        decoration('rocks',x,y,44)
    routes = [
      dict(id='saloon',name='Traversée du saloon',points=[[704,536],[560,520],[480,504],[360,504],[360,304],[328,304],[328,240],[704,240],[704,536]]),
      dict(id='west',name='Contournement ouest',points=[[704,536],[576,688],[48,688],[48,240],[328,240],[704,240],[704,536]]),
      dict(id='east',name='Contournement est',points=[[704,536],[800,688],[1376,688],[1376,344],[1008,344],[840,344],[840,400],[816,432],[704,536]]),
      dict(id='shop',name='Traversée de l’épicerie',points=[[704,536],[920,536],[1072,536],[1072,704],[800,712],[704,536]]),
      dict(id='shed',name='Traversée de la remise',points=[[576,688],[256,688],[256,816],[432,816],[576,688]]),
      dict(id='yard',name='Traversée de l’enclos',points=[[1008,344],[1008,224],[1184,224],[1184,344],[1008,344]]),
    ]
    layout=dict(version=6,name='Arroyo Seco — village chaleureux',tile_px=32,size_tiles=[45,30],
                size=[1440,960],coordinate_units='logical_world_pixels',grounded_characters=True,
                actor_foot_offset=[0,16],source_concept='output/concept-art/2026-11-25/09-village-passages-fondu.png',
                approved_reference='output/arena/2026-11-25-saloon-study/character-warm/house-after.png',
                perimeter=perimeter,rooms=rooms,walls=walls,props=props,decor=decor,
                rugs=[dict(rect=[212,568,56,32])],bottle=[704,520],
                spawns=[[672,232],[736,808],[992,488],[416,488]],routes=routes,
                status='Direction de la zone étalon validée ; carte complète à essayer.',
                notes=['Le saloon reprend sa géométrie et son mobilier validés, sans agrandissement.',
                       'Coordonnées en unités monde ; les routes représentent les pieds, les départs le pivot existant.',
                       'Ouvertures multiples et boucles libres avec le mobilier intact.',
                       'Casse visuelle seulement ; dégâts/destruction des objets dans29/43.'])
    OUTPUT.mkdir(parents=True,exist_ok=True)
    text=json.dumps(layout,ensure_ascii=False,indent=2)+'\n'
    (SCENE/'layout.json').write_text(text)
    (OUTPUT/'layout-v6.json').write_text(text)
    print(f"Village V6: {len(rooms)} lieux, {len(walls)} structures, {len(props)} objets et {len(decor)} décors; 1440×960.")


if __name__=='__main__':build()
