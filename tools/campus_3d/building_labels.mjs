import * as THREE from 'three';

// Campus building IDs come from the GLBs; facility descriptions are maintained here.
export const CAMPUS_PLANS = {
 tsudanuma:{name:'津田沼',max:9,url:'https://chibatech.ac.jp/about/institute/campus/tsudanuma.html',plan:'https://chibatech.ac.jp/about/institute/campus/dl53f300000014qt-img/dl53f30000002vv4.png'},
 narashino:{name:'新習志野',max:13,url:'https://kmsk.is.it-chiba.ac.jp/portal/whole/gakubu/campus_map.pdf',plan:'https://kmsk.is.it-chiba.ac.jp/portal/whole/gakubu/campus_map.pdf'},
};
const TSUDANUMA_BUILDING_DETAILS = {
 1:'事務室・研究室など',
 2:'大教室・研究室など',
 3:'学生食堂・購買など',
 4:'談話室・工作センター・部室',
 5:'図書館など',
 6:'講義室など',
 7:'パナソニック・千葉工業大学産学連携センター・コンピュータ演習室・研究室など',
 8:'未来ロボット研究センター・惑星探査研究センターなど',
 9:'学生実験室',
};
export function verifiedBuilding(metadata){
 const id=String(metadata?.building_id??'');if(!/^\d{1,2}$/.test(id))return null;
 const campus=metadata.campus==='Shin-Narashino'?'narashino':typeof metadata.geometry_note==='string'?'tsudanuma':null;
 const number=Number(id);if(!campus||number<1||number>CAMPUS_PLANS[campus].max)return null;
 return{campus,number,label:`${number}号館`,key:`${campus}:${number}`,source:CAMPUS_PLANS[campus].url,description:campus==='tsudanuma'?TSUDANUMA_BUILDING_DETAILS[number]:''};
}
export function placeLabelCandidates(candidates,{width,height,occupied=[],max=width<500?8:12}={}){
 const accepted=[],rects=[...occupied];
 for(const item of [...candidates].sort((a,b)=>a.distance-b.distance)){
  if(accepted.length>=max)break;if(item.depth<-1||item.depth>1||item.distance>1800)continue;
  const labelWidth=item.width??62,labelHeight=item.height??32;
  const offsets=item.landmark?[0,labelHeight+8,-labelHeight-8]:[0];
  const rect=offsets.map(offset=>({x:item.x-labelWidth/2,y:item.y-labelHeight/2+offset,width:labelWidth,height:labelHeight})).find(rect=>
   rect.x>=4&&rect.x+rect.width<=width-4&&rect.y>=4&&rect.y+rect.height<=height-4&&
   !rects.some(r=>rect.x<r.x+r.width+5&&rect.x+rect.width+5>r.x&&rect.y<r.y+r.height+5&&rect.y+rect.height+5>r.y));
  if(!rect)continue;
  accepted.push({...item,rect});rects.push(rect);
 }
 return accepted;
}
export function createBuildingLabels({scene,camera,canvas,onOpen=()=>{},onOverlay=()=>{}}){
 const layer=document.createElement('div');layer.id='building-labels';layer.setAttribute('aria-label','号館ラベル');Object.assign(layer.style,{position:'fixed',inset:'0',pointerEvents:'none',zIndex:'8'});document.body.append(layer);
 const style=document.createElement('style');style.textContent='.campus-building-label{position:absolute;min-width:62px;min-height:32px;padding:4px 8px;border:1px solid #547da8;border-radius:14px;background:#fffef2f2;color:#153d61;font:700 13px system-ui;box-shadow:0 2px 5px #18355430;pointer-events:auto;touch-action:manipulation}.campus-building-label:focus-visible{outline:3px solid #ffac35}.campus-building-detail{position:fixed;z-index:2;left:50%;top:50%;transform:translate(-50%,-50%);width:min(310px,82vw);max-height:calc(100% - 24px);overflow:auto;background:#fff;border:2px solid #487ac0;border-radius:18px;padding:16px;color:#193752;box-shadow:0 12px 45px #15294555;pointer-events:auto;font:14px system-ui;line-height:1.5}.campus-building-detail h3{margin:0 40px 0 0;font-size:16px}.campus-building-detail p{margin:12px 0 0;overflow-wrap:anywhere}.campus-building-close{position:absolute;top:6px;right:6px;min-height:44px;min-width:44px;width:44px;height:44px;padding:0;border:0;background:transparent;color:#193752;font:28px system-ui}.campus-building-close:focus-visible{outline:3px solid #1565c0}';document.head.append(style);
 const detail=document.createElement('section');detail.className='campus-building-detail';detail.id='building-detail';detail.hidden=true;detail.setAttribute('role','dialog');detail.setAttribute('aria-label','号館の詳細');const title=document.createElement('h3'),description=document.createElement('p'),close=document.createElement('button');close.type='button';close.className='campus-building-close';close.setAttribute('aria-label','閉じる');close.textContent='×';detail.append(title,description,close);layer.append(detail);
 const labels=new Map();let alive=true,lastScan=-Infinity,active=null,returnFocus=null;
 const attached=o=>{for(let p=o;p;p=p.parent){if(!p.visible)return false;if(p===scene)return true;}return false;};
 function closeDetails(){if(detail.hidden)return false;detail.hidden=true;active=null;onOverlay(false);if(returnFocus?.isConnected)returnFocus.focus({preventScroll:true});returnFocus=null;return true;}
 close.addEventListener('click',e=>{e.preventDefault();e.stopPropagation();closeDetails();});
 function open(item){returnFocus=document.activeElement;onOpen();active=item.key;title.textContent=`${CAMPUS_PLANS[item.campus].name}キャンパス ${item.label}`;description.textContent=item.description??'';description.hidden=!description.textContent;detail.hidden=false;onOverlay(true);close.focus({preventScroll:true});}
 function addLabel(object,info,key=object.uuid){
  if(labels.has(key))return;
  const button=document.createElement('button');button.type='button';button.className='campus-building-label';button.textContent=info.label;button.setAttribute('aria-label',`${CAMPUS_PLANS[info.campus].name} ${info.label}`);button.dataset.campus=info.campus;if(info.number)button.dataset.buildingId=String(info.number);if(info.landmark)button.dataset.landmark=info.landmark;if(info.width)button.style.width=`${info.width}px`;button.hidden=true;button.addEventListener('click',e=>{e.preventDefault();e.stopPropagation();open(info);});layer.append(button);labels.set(key,{...info,object,button});
 }
 function scan(now){if(now-lastScan<500)return;lastScan=now;scene.traverse(object=>{const info=verifiedBuilding(object.userData);if(!info)return;addLabel(object,info);if(info.campus==='tsudanuma'&&info.number===7)addLabel(object,{campus:'tsudanuma',key:'tsudanuma:bus-terminal',label:'バスターミナル',landmark:'bus-terminal',description:'7号館と道路の間',width:128},`${object.uuid}:bus-terminal`);});}
 function update(){if(!alive)return;scan(performance.now());const bounds=canvas.getBoundingClientRect(),width=bounds.width,height=bounds.height,candidates=[];scene.updateMatrixWorld();camera.updateMatrixWorld();
  for(const label of labels.values()){label.button.hidden=true;if(!attached(label.object))continue;const box=new THREE.Box3().setFromObject(label.object);if(box.isEmpty())continue;const anchor=box.getCenter(new THREE.Vector3());if(label.landmark==='bus-terminal')anchor.set(box.max.x+4,box.min.y+3,anchor.z-10);else anchor.y=box.max.y+3;const distance=anchor.distanceTo(camera.position),projected=anchor.project(camera);candidates.push({...label,x:(projected.x+1)*width/2,y:(1-projected.y)*height/2,depth:projected.z,distance});}
  const occupied=[...document.querySelectorAll('.toolbar,.controls,#toolbar,#modes,#race-panel,#pedals,#directions,#sticks,#region-quality,#quality-details,#fullscreen')].filter(e=>!e.hidden&&e.offsetWidth&&e.offsetHeight).map(e=>{const r=e.getBoundingClientRect();return{x:r.x-bounds.x,y:r.y-bounds.y,width:r.width,height:r.height};});
  for(const label of placeLabelCandidates(candidates,{width,height,occupied})){label.button.hidden=false;label.button.style.left=`${bounds.x+label.rect.x}px`;label.button.style.top=`${bounds.y+label.rect.y}px`;}
 }
 return{update,closeDetails,get open(){return!detail.hidden;},get state(){return{active,open:!detail.hidden,buildings:[...labels.values()].map(l=>({campus:l.campus,number:l.number,label:l.label,landmark:l.landmark,description:l.description,visible:!l.button.hidden,source:l.source}))};},dispose(){if(!alive)return;alive=false;closeDetails();layer.remove();style.remove();labels.clear();}};
}
