export function raceFeedback(previous, current, beforeCheckpoint, checkpoint) {
  if(previous==='countdown'&&current==='running')return 'GO!';
  if(current==='running'&&checkpoint>beforeCheckpoint)return 'CHECKPOINT!';
  return null;
}
export function showCelebration(text,{reducedMotion=false,goal=false}={}) {
  if(typeof document==='undefined')return;
  document.querySelector('#drive-celebration')?.remove();
  const layer=document.createElement('div');layer.id='drive-celebration';layer.setAttribute('role','status');
  Object.assign(layer.style,{position:'fixed',inset:'0',display:'grid',placeItems:'center',pointerEvents:'none',zIndex:'100',overflow:'hidden'});
  const banner=document.createElement('div');banner.textContent=text;
  Object.assign(banner.style,{whiteSpace:'pre-line',textAlign:'center',fontSize:goal?'clamp(24px,6vw,48px)':'clamp(22px,5vw,38px)',fontWeight:'900',color:'#fff',textShadow:'0 3px 0 #4d3191, 0 0 18px #ed64c0',background:'#452b80dd',border:'3px solid #ffe27b',borderRadius:'22px',padding:'18px 24px',transform:'rotate(-3deg)',boxShadow:'0 0 40px #ffc84a88'});
  layer.append(banner);document.body.append(layer);
  if(!reducedMotion){
    banner.animate([{transform:'scale(.6) rotate(-8deg)',opacity:0},{transform:'scale(1.08) rotate(2deg)',opacity:1,offset:.22},{transform:'scale(1) rotate(-3deg)',opacity:1}],{duration:550,easing:'ease-out'});
    if(goal)for(let i=0;i<32;i++){
      const confetti=document.createElement('i');Object.assign(confetti.style,{position:'absolute',left:(i*3.13)+'%',top:'45%',width:'10px',height:'18px',background:['#ffda5c','#fb7ac0','#65e8d0','#86adff'][i%4],borderRadius:'3px'});layer.append(confetti);
      confetti.animate([{transform:'translate(0,0) rotate(0)',opacity:1},{transform:'translate('+((i%7-3)*35)+'px,-180px) rotate(220deg)',opacity:1,offset:.4},{transform:'translate('+((i%7-3)*55)+'px,380px) rotate(700deg)',opacity:0}],{duration:1800+i%5*100,easing:'ease-out',fill:'forwards'});
    }
  }
  setTimeout(()=>layer.remove(),goal?2800:1100);
}