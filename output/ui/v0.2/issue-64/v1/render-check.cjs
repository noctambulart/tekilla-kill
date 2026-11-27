// Offline rendering of the actual concept script; no browser or Godot process.
const fs=require('fs');
const path=require('path');
const {JSDOM}=require('/tmp/tequila-concept-render/node_modules/jsdom');
const {createCanvas,Image}=require('/tmp/tequila-concept-render/node_modules/@napi-rs/canvas');
const folder=__dirname;
const html=fs.readFileSync(path.join(folder,'concept.html'),'utf8');
const dom=new JSDOM(html,{runScripts:'outside-only'});
const win=dom.window;
let loads=0;
const natives=new Map();
win.HTMLCanvasElement.prototype.getContext=function(){
 if(!natives.has(this))natives.set(this,createCanvas(1920,1080));
 return natives.get(this).getContext('2d');
};
win.HTMLCanvasElement.prototype.getBoundingClientRect=function(){return {width:1024,height:576,x:0,y:0};};
win.ResizeObserver=class{observe(){} disconnect(){}};
win.Image=class extends Image{
 constructor(){super();this.onload=()=>{};}
 set src(value){this._loaded=false;const onload=this.onload;super.onload=()=>{this._loaded=true;loads++;onload();};super.src=value;}
 get naturalWidth(){return this.width;}
 get naturalHeight(){return this.height;}
 get complete(){return this._loaded;}
};
const source=win.document.querySelector('script').textContent;
win.eval(source);
const assert=(value,message)=>{if(!value)throw new Error(message);};
const state=win.document.getElementById('tk64-state');
const camera=win.document.getElementById('tk64-camera');
const games=Array.from(win.document.querySelectorAll('.tk64-game'));
const set=(el,value)=>{el.value=value;el.dispatchEvent(new win.Event('change'));};
const out=path.join(folder,'previews');fs.mkdirSync(out,{recursive:true});
const delay=ms=>new Promise(resolve=>setTimeout(resolve,ms));
(async()=>{
 for(let i=0;i<100&&loads<4;i++)await delay(20);
 assert(loads===4,`Assets loaded: ${loads}/4`);
 let renders=0;
 for(const view of ['close','far']){
  set(camera,view);
  for(const scenario of ['ground','poncho','garcia','ghost','result','tie','title']){
   set(state,scenario);
   for(const game of games){
    const expected=['result','tie'].includes(scenario);
    assert(game.querySelector('.tk64-result').hidden!==expected,`Result visibility: ${view}/${scenario}`);
    const canvas=game.querySelector('canvas');
    assert(canvas.getAttribute('aria-label').includes('Maquette'),`Accessible label: ${scenario}`);
    if(['ground','poncho','garcia','ghost'].includes(scenario)){
     fs.writeFileSync(path.join(out,`${game.dataset.design}-${view}-${scenario}.png`),natives.get(canvas).toBuffer('image/png'));
    }
    renders++;
   }
  }
 }
 set(state,'tie');
 assert(games[0].querySelector('h2').textContent==='Victoire partagée','Tie title');
 assert(games[0].querySelector('[data-score="1"]').textContent==='50 %','Tie score');
 games[0].querySelector('[data-action="replay"]').click();
 assert(state.value==='ground','Replay returns to a new round');
 set(state,'result');
 games[0].querySelector('[data-action="title"]').click();
 assert(state.value==='title','Return to title');
 // Exercise a narrow host using the exact same composition code.
 win.HTMLCanvasElement.prototype.getBoundingClientRect=function(){return {width:320,height:180,x:0,y:0};};
 set(state,'poncho');set(camera,'close');
 for(const game of games)fs.writeFileSync(path.join(out,`${game.dataset.design}-narrow.png`),natives.get(game.querySelector('canvas')).toBuffer('image/png'));
 const report={method:'Rendu local du script réel via Canvas/DOM ; pas un navigateur ni Godot',renderedStates:renders,assets:loads,replay:true,title:true,tie:true,manualReview:'Voir README.md'};
 fs.writeFileSync(path.join(folder,'render-check.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify(report));
 dom.window.close();
})().catch(error=>{console.error(error);process.exitCode=1;dom.window.close();});
