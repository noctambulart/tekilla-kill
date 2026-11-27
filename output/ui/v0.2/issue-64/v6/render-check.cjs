const fs=require('fs'),path=require('path');
const {JSDOM}=require('/tmp/tequila-concept-render/node_modules/jsdom');
const {createCanvas,Image}=require('/tmp/tequila-concept-render/node_modules/@napi-rs/canvas');
const folder=__dirname,html=fs.readFileSync(path.join(folder,'concept.html'),'utf8');
const dom=new JSDOM(html,{runScripts:'outside-only'}),win=dom.window;
let loads=0,now=100,queued=new Map(),nextFrame=1;
const natives=new Map();
win.HTMLCanvasElement.prototype.getContext=function(){
 if(!natives.has(this)){
  const native=createCanvas(this.width,this.height),context=native.getContext('2d'),draw=context.drawImage.bind(context);
  context.drawImage=(source,...args)=>draw(natives.get(source)||source,...args);
  natives.set(this,native);
 }
 return natives.get(this).getContext('2d');
};
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
win.eval(win.document.querySelector('script').textContent.replace('const observer=', 'root.__flight=starFlight; const observer='));
const assert=(value,message)=>{if(!value)throw new Error(message);};
const state=win.document.getElementById('tk64-v6-state'),camera=win.document.getElementById('tk64-v6-camera'),stage=win.document.querySelector('.tk-game'),canvas=stage.querySelector('canvas');
const set=(el,v)=>{el.value=v;el.dispatchEvent(new win.Event('change'));};
const out=path.join(folder,'previews');fs.mkdirSync(out,{recursive:true});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 for(let i=0;i<100&&loads<7;i++)await delay(20);
 assert(loads===7,'Captures, bottle and character sprites loaded');
 assert(stage.dataset.bottleStyle==='tequila-original','Original tequila bottle reused');
 const flight=win.document.getElementById('tk64-v6').__flight;
 const births=Array.from({length:12},(_,i)=>flight(i,12,0));
 assert(new Set(births.map(p=>`${Math.round(p.originX)},${Math.round(p.originY)}`)).size>=8,'Stars originate across the silhouette');
 assert(Math.max(...births.map(p=>p.originY))-Math.min(...births.map(p=>p.originY))>18,'Emission spans upper and lower body');
 const launch=flight(0,12,0),apex=flight(0,12,.45),landing=flight(0,12,1.3),reborn=flight(0,12,1.35);
 assert(apex.y<launch.y&&landing.y>launch.y,'Stars rise then fall below their emission point');
 assert(launch.originX!==reborn.originX||launch.originY!==reborn.originY,'Respawn changes the emission point');
 assert(launch.originX===apex.originX&&launch.originY===landing.originY,'Emission point remains stable within a flight');
 assert(births.some(p=>p.x<p.originX)&&births.some(p=>p.x>p.originX),'Stars spread to both sides');
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
 const sober=win.document.querySelector('[data-drunk-preview="0"]'),drunk=win.document.querySelector('[data-drunk-preview="2"]');
 const soberBefore=natives.get(sober).toBuffer('image/png'),drunkBefore=natives.get(drunk).toBuffer('image/png');
 const motion=win.document.getElementById('tk64-v6-motion');motion.click();
 for(let i=0;i<20;i++){const frames=Array.from(queued.values());queued.clear();now+=50;frames.forEach(fn=>fn(now));if(i%5===0)fs.writeFileSync(path.join(out,`stars-frame-${i}.png`),natives.get(drunk).toBuffer('image/png'));}
 assert(!natives.get(drunk).toBuffer('image/png').equals(drunkBefore),'Drunkenness stars move over time');
 assert(natives.get(sober).toBuffer('image/png').equals(soberBefore),'Sober comparison stays free of stars');
 assert(stage.dataset.bottleY!==before,'Held bottle moves vertically');motion.click();assert(queued.size===0,'Animation stops');
 const levels=Array.from(win.document.querySelectorAll('[data-drunk-preview]'));
 assert(levels.length===3,'Three drunkenness comparisons');
 assert(levels.map(el=>el.dataset.renderedLevel).join(',')==='0,1,2','Distinct drunkenness levels');
 levels.forEach(el=>fs.writeFileSync(path.join(out,`ivresse-${el.dataset.drunkPreview}.png`),natives.get(el).toBuffer('image/png')));
 const report={renderedStates:rendered,assets:loads,originalBottle:true,drunkennessLevels:3,variedOrigins:true,originChangesOnRespawn:true,stableFlightOrigin:true,starsRiseThenFall:true,starsMove:true,soberHasNoStars:true,noNumericScore:true,possessionIndependent:true,ghostSuppression:true,ghostRestoration:true,bottleBobbing:true,animationStops:true,replay:true,title:true,tie:true,manualReview:'Voir README.md'};
 fs.writeFileSync(path.join(folder,'render-check.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));dom.window.close();
})().catch(e=>{console.error(e);process.exitCode=1;dom.window.close();});
