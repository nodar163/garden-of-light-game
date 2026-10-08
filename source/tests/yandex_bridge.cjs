// SDK test doubles stay outside upload archive. No real ad impressions are made.
const vm = require('node:vm'), fs = require('node:fs'), assert = require('node:assert/strict');
let cb, clock=0, readyCount=0, play=0, stop=0;
const listeners={}, timers=new Map();
const sdk={environment:{i18n:{lang:'en'}},on:(event,fn)=>listeners[event]=fn,
  features:{LoadingAPI:{ready:()=>readyCount++},GameplayAPI:{start:()=>play++,stop:()=>stop++}},
  adv:{showRewardedVideo:({callbacks})=>cb=callbacks,showFullscreenAdv:({callbacks})=>cb=callbacks}};
let script;
const context={window:{},document:{hidden:false,addEventListener:(name,fn)=>listeners[name]=fn,createElement:()=>({}),head:{appendChild:s=>script=s}},
  performance:{now:()=>clock},setTimeout:fn=>{const id=timers.size+1; timers.set(id,fn);return id;},clearTimeout:id=>timers.delete(id),YaGames:{init:async()=>sdk},JSON};
vm.runInNewContext(fs.readFileSync('platform/yandex_bridge.js','utf8'),context);
(async()=>{
 const api=context.window.JackPlatform;
 assert.equal(api.request('coins','before'),false);
 api.ready(); await script.onload(); assert.equal(readyCount,1);
 assert.equal(JSON.parse(api.config()).language,'en'); api.gameplay(true); assert.equal(play,1);
 assert.equal(api.request('coins','one'),true); assert.equal(api.request('coins','two'),false);
 cb.onOpen(); cb.onRewarded(); cb.onRewarded(); cb.onClose(); cb.onRewarded();
 let events=JSON.parse(api.state()).events; assert.equal(events.filter(x=>x.type==='reward').length,1); assert.equal(events.filter(x=>x.type==='closed').length,1);
 assert.equal(api.request('interstitial','cooldown'),false);
 clock=61000; assert.equal(api.request('interstitial','inter'),true); cb.onClose(false); assert.equal(JSON.parse(api.state()).paused,false);
 assert.equal(api.request('hint','cancel'),true); cb.onClose(); assert.equal(JSON.parse(api.state()).events.some(x=>x.type==='reward'),false);
 assert.equal(api.request('coins','timeout'),true); const late=cb; for(const fn of [...timers.values()])fn(); late.onRewarded(); assert.equal(JSON.parse(api.state()).events.some(x=>x.type==='reward'),false);
 listeners.game_api_pause(); assert.equal(JSON.parse(api.state()).paused,true); assert.equal(api.request('coins','paused'),false); listeners.game_api_resume();
 context.document.hidden=true; listeners.visibilitychange(); assert.equal(JSON.parse(api.state()).paused,true);
 context.document.hidden=false; listeners.visibilitychange(); assert.equal(JSON.parse(api.state()).paused,false);
 assert(stop>0); console.log('Yandex bridge callback, pause, duplicate, timeout and cooldown checks passed');
})().catch(error=>{console.error(error);process.exitCode=1;});
