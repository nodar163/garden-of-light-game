(function () {
  'use strict';
  let sdk = null, ready = false, gameReady = false, wantedPlay = false, playing = false;
  let sdkPaused = false, ad = null, counter = 0, lastAd = -Infinity;
  const queue = [];
  const paused = () => sdkPaused || document.hidden || !!ad;
  function sync() {
    const next = ready && gameReady && wantedPlay && !paused();
    if (next !== playing) {
      playing = next;
      try { sdk?.features?.GameplayAPI?.[next ? 'start' : 'stop'](); } catch (_) {}
    }
  }
  const finish = (current, error) => {
    if (ad !== current) return;
    ad = null;
    clearTimeout(current.timer);
    queue.push({type:'closed', token:current.token, error:!!error, rewarded:current.rewarded});
    sync();
  };
  window.JackPlatform = {
    config() { return JSON.stringify({enabled:true, available:ready, language:sdk?.environment?.i18n?.lang || 'ru'}); },
    state() { return JSON.stringify({paused:paused(), events:queue.splice(0)}); },
    ready() { const loading=document.getElementById?.('status'); if(loading) loading.style.visibility='hidden'; gameReady = true; if (ready) sdk.features.LoadingAPI.ready(); sync(); },
    gameplay(value) { wantedPlay = !!value; sync(); },
    request(kind, token) {
      if (!ready || ad || paused()) return false;
      if (kind === 'interstitial' && performance.now() - lastAd < 60000) return false;
      const current = {token, rewarded:false, timer:null, opened:false};
      ad = current; sync();
      // Watch only a request that never opened. Never resume underneath an open ad.
      current.timer = setTimeout(() => { if (!current.opened) finish(current,true); }, 15000);
      const callbacks = {
        onOpen() { if (ad !== current) return; current.opened=true; lastAd=performance.now(); clearTimeout(current.timer); },
        onRewarded() {
          if (ad !== current || current.rewarded) return;
          current.rewarded=true; queue.push({type:'reward',token});
        },
        onClose() { finish(current,false); },
        onError() { finish(current,true); }
      };
      try {
        if (kind === 'interstitial') sdk.adv.showFullscreenAdv({callbacks});
        else sdk.adv.showRewardedVideo({callbacks});
      } catch (_) { finish(current,true); }
      return true;
    }
  };
  document.addEventListener('visibilitychange',sync);
  const script = document.createElement('script');
  script.src = '/sdk.js'; script.async = true;
  script.onload = async () => {
    try {
      sdk = await YaGames.init(); ready = true;
      sdk.on('game_api_pause',() => { sdkPaused=true; sync(); });
      sdk.on('game_api_resume',() => { sdkPaused=false; sync(); });
      if (gameReady) sdk.features.LoadingAPI.ready();
      sync();
    } catch (_) { queue.push({type:'sdk_error'}); }
  };
  script.onerror = () => queue.push({type:'sdk_error'});
  document.head.appendChild(script);
})();
