export function installQualityDialog({data,signal,onOpen=()=>{},onClose=()=>{}}){
 const dialog=document.querySelector('#quality-dialog'),button=document.querySelector('#quality-details'),body=document.querySelector('#quality-tiles'),summary=document.querySelector('#quality-summary');
 button.hidden=false;const terrain=data.terrain;
 summary.textContent=`標高はDEM由来の20m格子です。全体 DEM由来 ${Number(terrain.sourceDerivedPercent).toFixed(2)}% / 補間 ${Number(terrain.interpolatedPercent).toFixed(2)}%。測量精度を示すものではありません。`;
 const records=Array.isArray(terrain.coverageByTile)?terrain.coverageByTile:Object.entries(terrain.coverageByTile??{}).map(([tile,counts])=>({tile,...counts}));
 for(const tile of records){const row=document.createElement('tr');const key=tile.tile??tile.key??[tile.z??14,tile.x,tile.y].join('/');for(const value of [key,`${Number(tile.sourceDerivedPercent??(tile.total?tile.sourceDerived/tile.total*100:0)).toFixed(2)}%`,`${Number(tile.interpolatedPercent??(tile.total?tile.interpolated/tile.total*100:0)).toFixed(2)}%`]){const cell=document.createElement('td');cell.textContent=String(value);row.append(cell);}body.append(row);}
 const close=()=>{if(!dialog.hasAttribute('open'))return;if(typeof dialog.close==='function')dialog.close();else{dialog.removeAttribute('open');onClose();}};
 dialog.addEventListener('close',onClose,{signal});button.addEventListener('click',()=>{onOpen();if(typeof dialog.showModal==='function')dialog.showModal();else dialog.setAttribute('open','');},{signal});
 document.querySelector('#quality-close').addEventListener('click',()=>{close();button.focus();},{signal});
 dialog.addEventListener('click',event=>{if(event.target===dialog){const box=dialog.getBoundingClientRect();if(event.clientX<box.left||event.clientX>box.right||event.clientY<box.top||event.clientY>box.bottom)close();}},{signal});
 return close;
}
