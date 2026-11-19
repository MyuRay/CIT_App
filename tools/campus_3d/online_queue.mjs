// Lifecycle cleanup and storage replies must not load a world or start a race.
export function createOnlineQueue({isDisposed,isLoaded,getGame,isRegionLoading,enterRegion,closeOverlay,clock=()=>performance.now()}){
 const pending=[];
 function receive(event){
  if(isDisposed())return;if(typeof event==='string'){try{event=JSON.parse(event);}catch{return;}}
  if(event?.type==='campus-close-overlay'){closeOverlay();return;}
  if((event?.type==='campus-game-session'&&!event.data)||event?.type==='campus-game-leave'){
   pending.length=0;getGame()?.gameOnline(event);return;
  }
  const room=event?.type==='campus-game-session'?event.data:event?.session?.room??event?.session??event?.room;
  const challenge=event?.challenge??(event?.action==='challenge'&&event?.ok?event.data:null);
  const needsWorld=Array.isArray(room?.players)||Boolean(challenge?.challengeId);
  if(!getGame()&&!needsWorld)return;
  pending.push({event,received:clock()});if(pending.length>32)pending.shift();drain();
 }
 function drain(){
  if(isDisposed()||!isLoaded()||!pending.length)return;const game=getGame();
  if(!game){if(!isRegionLoading())enterRegion();return;}
  for(const queued of pending.splice(0)){const event=structuredClone(queued.event),age=clock()-queued.received;for(const value of [event?.data,event?.challenge,event?.session,event?.room])if(value&&Number.isFinite(value.serverNow))value.serverNow+=age;game.gameOnline(event);}
 }
 return{receive,drain,clear(){pending.length=0;},get size(){return pending.length;}};
}
