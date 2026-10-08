// Local test server only. Never ship this fake SDK in the Yandex archive.
window.YaGames = {init:async()=>({
  environment:{i18n:{lang:'ru'}}, on:()=>{},
  features:{LoadingAPI:{ready:()=>{}},GameplayAPI:{start:()=>{},stop:()=>{}}},
  adv:{showRewardedVideo({callbacks}) { mockAd(callbacks,true); },showFullscreenAdv({callbacks}) { mockAd(callbacks,false); }}
})};
function mockAd(callbacks,rewarded) {
  callbacks.onOpen();
  const panel=document.createElement('section');
  panel.style='position:fixed;inset:0;z-index:99999;background:#183e34;color:white;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:24px;font:24px sans-serif';
  const title=document.createElement('p'); title.textContent='ТЕСТОВАЯ реклама — без настоящего ролика'; panel.appendChild(title);
  const finish=document.createElement('button'); finish.textContent=rewarded?'Завершить тестовый просмотр':'Закрыть тестовый блок'; finish.style='padding:24px;font-size:24px';
  finish.onclick=()=>{if(rewarded)callbacks.onRewarded();panel.remove();callbacks.onClose(true);}; panel.appendChild(finish);
  if(rewarded){const cancel=document.createElement('button');cancel.textContent='Закрыть без награды';cancel.style='padding:24px;font-size:24px';cancel.onclick=()=>{panel.remove();callbacks.onClose(true);};panel.appendChild(cancel);}
  document.body.appendChild(panel);
}
