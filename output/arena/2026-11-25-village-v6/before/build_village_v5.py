"""Build the editable V5 village selected in concept09, without changing art.

One JSON supplies floors, openings, solid rectangles, decorations and routes to
Godot. V4 and the selected concept remain archived in output/. Python stdlib only.
"""
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'godot/scenes/arroyo_seco/layout.json'
OUTPUT=ROOT/'output/arena/2026-11-25-integration'


def walls_for(name,polygon,doors,material='adobe',thickness=.5):
    result=[]
    for edge,(a,b) in enumerate(zip(polygon,polygon[1:]+polygon[:1])):
        horizontal=a[1]==b[1]
        assert horizontal or a[0]==b[0],(name,a,b)
        axis=0 if horizontal else 1
        start,end=sorted((a[axis],b[axis]))
        for low,high in sorted(doors.get(edge,[]))+[[end,end]]:
            assert start<=low<=high<=end,(name,edge,low,high)
            if low>start:
                rect=([start,a[1]-thickness/2,low-start,thickness] if horizontal
                      else [a[0]-thickness/2,start,thickness,low-start])
                result.append(dict(id=f'{name}-{edge}-{len(result)}',rect=rect,material=material))
            start=high
    return result


def build():
    perimeter=[[.5,8],[4,8],[4,.5],[28,.5],[28,0],[35,0],[35,.5],[60,.5],
               [60,4],[63.5,4],[63.5,31.5],[58,31.5],[58,39.9],[35,39.9],
               [35,40],[28,40],[28,39.9],[6,39.9],[6,37],[.5,37]]
    buildings=[
        dict(id='saloon',name='Saloon',polygon=[[4,11],[26,11],[26,18],[24,18],[24,29],[4,29]],
             doors={0:[[14,18]],3:[[18.5,24]],4:[[10,17]]},label=[8,13],floor='stone'),
        dict(id='shop',name='Épicerie',polygon=[[42,15],[60,15],[60,29],[42,29]],
             doors={1:[[18,20.5]],2:[[48,54]],3:[[20,25]]},label=[45,17.5],floor='stone'),
        dict(id='shed',name='Remise',polygon=[[7,32],[20,32],[20,38],[7,38]],
             doors={0:[[11,15]],1:[[34,37]],2:[[12,16]]},label=[11,33],floor='wood'),
        dict(id='yard',name='Enclos',polygon=[[48,5],[61,5],[61,13],[50,13],[50,11],[48,11]],
             doors={2:[[52,56]],5:[[8,10.5]]},label=[53,7],floor='earth',material='fence'),
    ]
    walls=walls_for('perimeter',perimeter,{},'rock',.5)
    # The two ends of the main road remain visibly closed gameplay boundaries.
    for wall in walls:
        x,y,w,h=wall['rect']
        if w>=6 and (abs(y)<.3 or abs(y-40)<.3):wall['material']='fence'
    for b in buildings:
        walls+=walls_for(b['id'],b['polygon'],b['doors'],b.get('material','adobe'),
                         .35 if b.get('material')=='fence' else .5)
    houses=[dict(id='home-west',rect=[7,1,9,6],kind='house_adobe'),
            dict(id='home-north',rect=[20,0,7,6],kind='house_wood'),
            dict(id='home-east',rect=[36,1,9,7],kind='house_wood'),
            dict(id='home-south',rect=[42,32,10,7],kind='house_adobe')]
    for home in houses:
        walls.append(dict(id=home['id'],rect=home['rect'],material='house',kind=home['kind']))
    fences=[([16.5,2.5,2,.35]),([18.5,2.5,.35,4]),([16.5,7,2,.35]),
            ([18.8,5,1.1,.35]),([34.3,3,.35,4.5]),([34.3,7.5,1.4,.35]),
            ([38,34,.35,4.5]),([38,38.5,3.5,.35]),([52,34.5,5.5,.35]),
            ([57.5,34.5,.35,4]),([53,38.5,4.5,.35])]
    for i,rect in enumerate(fences):walls.append(dict(id=f'courtyard-fence-{i}',rect=rect,material='fence'))
    props=[]
    def prop(name,kind,rect,broken=False):
        props.append(dict(id=name,kind=kind,rect=rect,breakable=kind in ['chair','crate','pot'],
                          visual_state='broken' if broken else 'intact'))
    prop('bar-long','counter',[6.3,14.4,12,1.2])
    prop('bar-return','counter',[17.1,15.6,1.2,3.2])
    prop('bar-mugs-west','mugs',[8.5,11.6,2.5,.9])
    prop('bar-mugs-east','mugs',[19,11.6,2.5,.9])
    prop('saloon-couch','couch',[6.3,27,4.2,1.45])
    prop('saloon-barrel-west','barrel',[4.7,14.2,1.2,1.2])
    prop('saloon-barrel-south','barrel',[22.1,27.5,1.2,1.2])
    prop('saloon-pot','pot',[24.1,12.2,.85,.9])
    for name,x,y in [('poker-west',6.5,21),('poker-east',22.1,16),('poker-south',20,24.8)]:
        prop(name,'table',[x,y,1.75,1.75])
        prop(name+'-chair-west','chair',[x-.95,y+.35,.75,.875])
        prop(name+'-chair-east','chair',[x+1.95,y+.35,.75,.875])
        prop(name+'-chair-north','chair',[x+.5,y-1.1,.75,.875])
    prop('store-counter','store_counter',[49,19,7,1.5])
    prop('store-goods-west','goods',[46.7,16.2,3.7,1.15])
    prop('store-goods-east','goods',[52,16.2,3.7,1.15])
    prop('store-goods-side','goods',[57,17.2,1.1,4])
    prop('store-produce','goods',[54.3,26.3,3.7,1.15])
    prop('store-barrel','barrel',[42.8,16,1.2,1.2])
    prop('loading-crate-a','crate',[60.6,20.7,1.2,1.2])
    prop('loading-crate-b','crate',[60.6,22.1,1.2,1.2])
    prop('loading-barrel','barrel',[60.7,25,1.2,1.2])
    prop('yard-trough','trough',[51,6.7,3.2,1.2])
    prop('yard-crate','crate',[57.1,10,1.2,1.2])
    prop('yard-barrel','barrel',[59,8.3,1.2,1.2])
    prop('shed-crate-a','crate',[8,33.1,1.2,1.2])
    prop('shed-crate-b','crate',[8,34.6,1.2,1.2])
    prop('shed-barrel-a','barrel',[9.5,36,1.2,1.2])
    prop('shed-barrel-b','barrel',[11,36,1.2,1.2])
    prop('shed-tools','tools',[15.7,32.7,2.8,1.2])
    prop('shed-pot','pot',[18.6,36.7,.8,.9])
    prop('rear-cart','cart',[20,7.25,4,1.5])
    prop('yard-loading-crate','crate',[39.4,11.3,1.2,1.2])
    prop('saloon-entry-pot','pot',[26.2,28.1,.8,.9])
    prop('store-entry-pot','pot',[39.7,28.2,.8,.9])
    decor=[dict(kind='rug',rect=[10.8,27,4,1.35]),
           dict(kind='crate_broken',rect=[59,10.2,1.2,1.2]),
           dict(kind='pot_broken',rect=[55.5,30.2,1,.75]),
           dict(kind='boardwalk',rect=[2.5,16,1.4,12.5]),
           dict(kind='boardwalk',rect=[60.1,17,1.8,10]),
           dict(kind='boardwalk',rect=[24.3,12,1.4,5.5])]
    for x,y in [(2,3),(3,14),(1.5,20),(2,32),(5,38),(18,39),(60.5,34),(62,7),(48,2),(55,1)]:
        decor.append(dict(kind='cactus',rect=[x,y,.8,1.4]))
    for x,y in [(5,1),(17,3),(29,1),(34,2),(59,1),(62,31),(57,39),(21,38.5)]:
        decor.append(dict(kind='rocks',rect=[x,y,1.75,1]))
    routes=[
      dict(id='saloon',name='Traversée du saloon et sortie arrière',points=[[32,23],[25,22],[20,22],[20,13.2],[16,13.2],[16,9.5],[29,9.5],[32,13],[32,23]]),
      dict(id='west',name='Contournement ouest',points=[[32,23],[28,30.5],[22,30.5],[2,30.5],[2,9.5],[29,9.5],[32,13],[32,23]]),
      dict(id='east',name='Contournement est',points=[[32,23],[39,30.7],[62.4,30.7],[62.4,14],[40,14],[39,16],[32,23]]),
      dict(id='store',name='Traversée de l’épicerie',points=[[32,23],[43,23],[47,23],[51,24],[51,30.5],[39,30.5],[32,23]]),
    ]
    layout=dict(version=5,name='Arroyo Seco — village du saloon',tile_px=32,size_tiles=[64,40],
        source_concept='output/concept-art/2026-11-25/09-village-passages-fondu.png',
        status='Intégration du concept retenu ; essais du producteur et équilibrage à poursuivre.',
        perimeter=perimeter,buildings=buildings,houses=houses,walls=walls,props=props,decor=decor,
        bottle=[32,23],spawns=[[32,32.5],[32,13.5],[41.5,23],[22.5,23]],
        labels=[dict(text='Place du village',position=[29,27]),dict(text='Rue principale',position=[29,15])],
        routes=routes,
        design_notes=['Carte64×40 : agrandissement du terrain, pas des personnages.',
                      'Même géométrie pour sols, passages et obstacles ; chaque lieu a plusieurs ouvertures.',
                      'Les caisses, chaises et pots sont visuellement cassables ; logique de destruction dans29/43.',
                      'Maisons fermées et arrière-cours structurent les deux contournements.'])
    OUTPUT.mkdir(parents=True,exist_ok=True)
    text=json.dumps(layout,ensure_ascii=False,indent=2)+'\n'
    DEST.write_text(text);(OUTPUT/'layout-v5.json').write_text(text)
    print(f'Village V5 :64×40,{len(walls)} obstacles de structure,{len(props)} objets,4 lieux accessibles et4 maisons.')


if __name__=='__main__':build()
