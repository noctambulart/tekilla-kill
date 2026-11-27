const fs=require('fs'),path=require('path');
const {JSDOM}=require('/tmp/tequila-concept-render/node_modules/jsdom');
const {createCanvas,Image}=require('/tmp/tequila-concept-render/node_modules/@napi-rs/canvas');
const folder=__dirname,html=fs.readFileSync(path.join(folder,'concept.html'),'utf8');
const dom=new JSDOM(html,{runScripts:'outside-only'}),win=dom.window;
let loads=0,now=100,queued=new Map(),nextFrame=1;
const natives=new Map();
win.HTMLCanvasElement.prototype.getContext=function(){if(!natives.has(this))natives.set(this,createCanvas(1920,1080));return natives.get(this).getContext('2d');};
win.HTMLCanvasElement.prototype.getBoundingClientRect=function(){return {width:1024,height:576};};
win.ResizeObserver=class{observe(){} disconnect(){}};
win.matchMedia=()=>({matches:false});
win.requestAnimationFrame=fn=>{const id=nextFrame++;queued.set(id,fn);return id;};
win.cancelAnimationFrame=id=>queued.delete(id);
win.Image=class extends Image{
 constructor(){super();this.onload=()=>{};}
 set src(value){this._loaded=false;const onload=this.onload;super.onload=()=>{this._loaded=true;loads++;onload();};super.src=value;}
 get naturalWidth(){return this.width;}get naturalHeight(){return this.height;}get complete(){return this._loaded;}
};
win.eval(win.document.querySelector('script').textContent);
const assert=(value,message)=>{if(!value)throw new Error(message);};
const state=win.document.getElementById('tk64-v2-state'),camera=win.document.getElementById('tk64-v2-camera'),stage=win.document.querySelector('.tk-game'),canvas=stage.querySelector('canvas');
const set=(el,v)=>{el.value=v;el.dispatchEvent(new win.Event('change'));};
const out=path.join(folder,'previews');fs.mkdirSync(out,{recursive:true});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 for(let i=0;i<100&&loads<3;i++)await delay(20);
 assert(loads===3,'Three existing captures loaded');
 let rendered=0;
 for(const view of ['close','far'])for(const scene of ['ground','poncho','garcia','ghost','return','low','result','tie','title']){
  set(camera,view);set(state,scene);
  assert(stage.querySelector('.tk-ending').hidden!==['result','tie'].includes(scene),'Result visibility');
  assert(!/\d+\s*%|pour cent/i.test(stage.textContent+canvas.getAttribute('aria-label')),'No numeric score in the product UI');
  if(scene==='garcia'){assert(stage.dataset.holder==='2','Garcia is the marked target');assert(stage.dataset.drunk1==='2'&&stage.dataset.drunk2==='1','Drunkenness independent of possession');}
  if(scene==='ghost')assert(stage.dataset.drunk1==='0','No drunkenness sparkles while ghost');
  if(scene==='return')assert(stage.dataset.drunk1==='2','Drunkenness restored after ghost');
  if(!['result','tie','title'].includes(scene))fs.writeFileSync(path.join(out,`${view}-${scene}.png`),natives.get(canvas).toBuffer('image/png'));
  rendered++;
 }
 set(state,'tie');assert(stage.querySelector('h2').textContent==='Victoire partagée','Tie result');
 stage.querySelector('[data-action="replay"]').click();assert(state.value==='ground','Replay');
 set(state,'result');stage.querySelector('[data-action="title"]').click();assert(state.value==='title','Return to title');
 set(state,'garcia');const before=stage.dataset.bottleY;
 const motion=win.document.getElementById('tk64-v2-motion');motion.click();
 for(let i=0;i<20;i++){const frames=Array.from(queued.values());queued.clear();now+=50;frames.forEach(fn=>fn(now));}
 assert(stage.dataset.bottleY!==before,'Held bottle moves vertically');motion.click();assert(queued.size===0,'Animation stops');
 const report={renderedStates:rendered,assets:loads,noNumericScore:true,possessionIndependent:true,ghostSuppression:true,ghostRestoration:true,bottleBobbing:true,animationStops:true,replay:true,title:true,tie:true,manualReview:'Voir README.md'};
 fs.writeFileSync(path.join(folder,'render-check.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));dom.window.close();
})().catch(e=>{console.error(e);process.exitCode=1;dom.window.close();});
