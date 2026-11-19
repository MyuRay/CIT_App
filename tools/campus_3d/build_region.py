from pathlib import Path
import json,math,struct,zlib,hashlib,datetime,shutil
s=Path(__file__).parent;download=s/'data';r=s.parents[1];out=r/'assets/models/campus';out.mkdir(exist_ok=True)
R=6378137;origin=[140.02138,35.6887746];cos=math.cos(math.radians(origin[1]))
def xy(lon,lat):return [(lon-origin[0])*math.pi/180*R*cos,-(lat-origin[1])*math.pi/180*R]
def lonlat(x,z):return [origin[0]+x/(R*cos)*180/math.pi,origin[1]-z/R*180/math.pi]
def tile(lon,lat,z=15):return [(lon+180)/360*2**z,(1-math.asinh(math.tan(math.radians(lat)))/math.pi)/2*2**z]
def decode_png(p):
 b=p.read_bytes();off=8;compressed=b'';palette=None
 while off<len(b):
  size=struct.unpack_from('>I',b,off)[0];typ=b[off+4:off+8];data=b[off+8:off+8+size];off+=size+12
  if typ==b'IHDR':w,h,depth,color,*_=struct.unpack('>IIBBBBB',data)
  if typ==b'IDAT':compressed+=data
  if typ==b'PLTE':palette=data
 assert depth==8 and color in [2,6,3],(depth,color)
 channels={2:3,6:4,3:1}[color];stride=w*channels;raw=zlib.decompress(compressed);rows=[];prev=bytearray(stride)
 for row in range(h):
  f=raw[row*(stride+1)];data=bytearray(raw[row*(stride+1)+1:(row+1)*(stride+1)])
  for i in range(stride):
   a=data[i-channels] if i>=channels else 0;b=prev[i];c=prev[i-channels] if i>=channels else 0
   if f==1:v=a
   elif f==2:v=b
   elif f==3:v=(a+b)//2
   elif f==4:
    estimate=a+b-c;da,db,dc=abs(estimate-a),abs(estimate-b),abs(estimate-c);v=a if da<=db and da<=dc else b if db<=dc else c
   else:v=0
   data[i]=(data[i]+v)&255
  values=[]
  for x in range(w):
   rgb=data[x*channels:x*channels+3] if color!=3 else palette[data[x]*3:data[x]*3+3];v=rgb[0]*65536+rgb[1]*256+rgb[2]
   values.append(None if v==8388608 else (v if v<8388608 else v-16777216)*.01)
  rows.append(values);prev=data
 return rows
dem={};dem5b={};fallback={};demSources={}
for p in sorted(download.glob('dem*.png'),key=lambda p:1 if p.name.startswith('dem15-') else 0):
 prefix,x,y=p.stem.split('-')
 if prefix=='dem15':dem[int(x),int(y)]=decode_png(p)
 if prefix=='dem5b15':dem5b[int(x),int(y)]=decode_png(p)
 if prefix=='dem14':fallback[int(x),int(y)]=decode_png(p)

def elevation_detail(lon,lat):
 tx,ty=tile(lon,lat);px,py=tx*256-.5,ty*256-.5;ix,iy=math.floor(px),math.floor(py);fx,fy=px-ix,py-iy;values=[];sources=0
 for dx,dy,weight in [(0,0,(1-fx)*(1-fy)),(1,0,fx*(1-fy)),(0,1,(1-fx)*fy),(1,1,fx*fy)]:
  a,b=ix+dx,iy+dy;grid=dem.get((a//256,b//256));v=grid[b%256][a%256] if grid else None;source=1
  if v is None:
   grid=dem5b.get((a//256,b//256));v=grid[b%256][a%256] if grid else None;source=2
  if v is None:
   aa,bb=a//2,b//2;g=fallback.get((aa//256,bb//256));v=g[bb%256][aa%256] if g else None;source=4
  if v is not None:values.append((v,weight));sources|=source
 if len(values)!=4:return None,0
 return sum(v*w for v,w in values),sources

def elevation(lon,lat):return elevation_detail(lon,lat)[0]
bbox=[140.003,35.656,140.028,35.694];minx,minz=xy(bbox[0],bbox[3]);maxx,maxz=xy(bbox[2],bbox[1]);step=20;nx=math.ceil((maxx-minx)/step)+1;nz=math.ceil((maxz-minz)/step)+1
heights=[];sampleSources=[];coverageByTile={}
for iz in range(nz):
 for ix in range(nx):
  lon,lat=lonlat(minx+ix*step,minz+iz*step);h,source=elevation_detail(lon,lat)
  heights.append(round(h,2) if h is not None else None);sampleSources.append(source)
  tx,ty=tile(lon,lat);key=f'15/{math.floor(tx)}/{math.floor(ty)}'
  counts=coverageByTile.setdefault(key,{'total':0,'sourceDerived':0,'interpolated':0,'sourceMasks':{}})
  counts['total']+=1;counts['sourceDerived' if source else 'interpolated']+=1;counts['sourceMasks'][str(source)]=counts['sourceMasks'].get(str(source),0)+1
known=[source!=0 for source in sampleSources];missing=sum(not k for k in known)
assert any(known),'No source elevation coverage; cannot interpolate safely'
# Explicitly marked nearest-neighbour fill plus smoothing for unavailable tiles.
# This is an approximation, never labelled measured terrain.
from collections import deque
queue=deque(i for i,h in enumerate(heights) if h is not None)
while queue:
 i=queue.popleft();ix,iz=i%nx,i//nx
 for j in ([i-1] if ix else [])+([i+1] if ix<nx-1 else [])+([i-nx] if iz else [])+([i+nx] if iz<nz-1 else []):
  if heights[j] is None:heights[j]=heights[i];queue.append(j)
for _ in range(40):
 changed=heights.copy()
 for i,k in enumerate(known):
  if k:continue
  ix,iz=i%nx,i//nx;near=([i-1] if ix else [])+([i+1] if ix<nx-1 else [])+([i-nx] if iz else [])+([i+nx] if iz<nz-1 else [])
  changed[i]=round(sum(heights[j] for j in near)/len(near),2)
 heights=changed
def grid_elevation(x,z):
 ix=max(0,min(nx-1,round((x-minx)/step)));iz=max(0,min(nz-1,round((z-minz)/step)));return heights[iz*nx+ix]
osm=json.loads((s/'data/osm-region.json').read_text('utf-8'));nodes={n['id']:n for n in osm['elements'] if n['type']=='node'};ways=[n for n in osm['elements'] if n['type']=='way'];roads=[];buildings=[];campuses=[];waters=[]
veh={'primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','unclassified','residential','service','trunk','trunk_link','living_street','track'}
def inside(p,poly):
 x,y=p;inside=False
 for a,b in zip(poly,poly[1:]+poly[:1]):
  if (a[1]>y)!=(b[1]>y) and x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:inside=not inside
 return inside
for name,id,ori in [('tsudanuma',55680442,origin),('narashino',156132176,[140.0145,35.6617])]:
 w=next(w for w in ways if w['id']==id);boundary=[xy(nodes[n]['lon'],nodes[n]['lat']) for n in w['nodes']];offset=xy(*ori);campuses.append({'id':name,'osmWayId':id,'origin':ori,'offset':offset,'altitude':elevation(*ori) if elevation(*ori) is not None else grid_elevation(*offset),'altitudeEstimated':elevation(*ori) is None,'boundary':boundary})
for w in ways:
 t=w.get('tags',{});coordinates=[[nodes[n]['lon'],nodes[n]['lat']] for n in w['nodes'] if n in nodes];points=[xy(*p) for p in coordinates]
 if t.get('highway'):
  highway=t['highway'];drive=highway in veh and t.get('motorcar')!='no' and t.get('motor_vehicle')!='no' and t.get('access')!='no' and t.get('area')!='yes' and t.get('tunnel')!='yes'
  if highway in ['motorway','motorway_link','construction','steps']:drive=False
  width=t.get('width');source='OSM width'
  try:width=float(width.replace(' m',''))
  except:
   source='estimated from lanes/class';width=max(3.5,float(t.get('lanes','2').split(';')[0])*3.1) if t.get('lanes','2').split(';')[0].isdigit() else 6.2
   if highway in ['service','track']:width=3.8
   if highway in ['footway','cycleway','path','pedestrian']:width=2
  roads.append({'id':w['id'],'nodes':w['nodes'],'points':points,'name':t.get('name',t.get('ref','')),'highway':highway,'width':width,'widthSource':source,'drive':drive,'private':t.get('access') in ['private','destination','customers'],'tags':{k:v for k,v in t.items() if k in ['access','motorcar','motor_vehicle','oneway','bridge','layer','tunnel','lanes','ref','width']}})
 if t.get('building') and len(points)>=4 and not any(inside(points[0],c['boundary']) for c in campuses):
  height=t.get('height');source='OSM height'
  try:height=float(height.replace(' m',''))
  except:
   source='estimated from levels' if t.get('building:levels') else 'estimated fallback';height=float(t.get('building:levels','2'))*3.1 if t.get('building:levels','2').replace('.','',1).isdigit() else 6.2
  buildings.append({'id':w['id'],'points':points,'height':height,'heightSource':source})
 if t.get('waterway') and len(points)>1:waters.append({'id':w['id'],'points':points,'type':t['waterway']})
routes=[]
for name in ['outward','return']:
 raw=json.loads((download/f'route-{name}.json').read_text('utf-8'));route=raw['routes'][0];routes.append({'id':name,'distance':route['distance'],'points':[xy(*p) for p in route['geometry']['coordinates']],'coordinates':route['geometry']['coordinates'],'names':[step['name'] for leg in route['legs'] for step in leg['steps'] if step['name']],'waypoints':raw['waypoints'],'sourceFile':f'route-{name}.json'})
photos=[]
for p in (r/'assets/models/campus/region').glob('photo*.jpg'):
 prefix,x,y=p.stem.split('-');z=int(prefix[5:]);lon=int(x)/2**z*360-180;lat=math.degrees(math.atan(math.sinh(math.pi*(1-2*int(y)/2**z))));lon2=(int(x)+1)/2**z*360-180;lat2=math.degrees(math.atan(math.sinh(math.pi*(1-2*(int(y)+1)/2**z))));photos.append({'file':p.name,'z':z,'min':xy(lon,lat),'max':xy(lon2,lat2)})
data={'version':1,'origin':origin,'bbox':bbox,'terrain':{'x':minx,'z':minz,'step':step,'nx':nx,'nz':nz,'heights':heights,'known':known,'sampleSources':sampleSources,'sourceMaskLegend':{'0':'interpolated without complete source corners','1':'GSI DEM5A','2':'GSI DEM5B','4':'GSI DEM10','3':'DEM5A and DEM5B','5':'DEM5A and DEM10','6':'DEM5B and DEM10','7':'mixed GSI DEM'},'coverageByTile':coverageByTile,'sourceDerivedPercent':round(sum(known)/len(known)*100,4),'interpolatedPercent':round(missing/len(known)*100,4),'missingSamplesBeforeInterpolation':missing,'source':'GSI DEM5A preferred, DEM5B/DEM10 fallback. Four valid source corners required per bilinear 20m sample; missing samples explicitly marked interpolated. Resampled DEM, not direct field measurement.'},'campuses':campuses,'roads':roads,'buildings':buildings,'waterways':waters,'gates':[{'id':n['id'],'point':xy(n['lon'],n['lat']),'motorcarNo':n.get('tags',{}).get('motorcar')=='no','locked':n.get('tags',{}).get('locked')=='yes','access':n.get('tags',{}).get('access','unknown')} for n in nodes.values() if n.get('tags',{}).get('barrier')=='gate'],'routes':routes,'photos':photos,'osmTimestamp':osm['osm3s']['timestamp_osm_base'],'attribution':'地理院タイルを加工して作成 / © OpenStreetMap contributors, ODbL 1.0','limitations':'Simulation only. Campus heights/facades and road widths, bridge heights can be estimates. No legal-navigation assurance. Photo acquisition dates are not inferred from HTTP dates. Unavailable elevation tiles are interpolated and quality masks retained.'}
(out/'region.json').write_text(json.dumps(data,ensure_ascii=False,separators=(',',':')),'utf-8')
(out/'region-source-manifest.json').write_text(json.dumps({'originAlignment':'Tsudanuma origin inferred from matching existing GLB Site_Base and OSM way55680442. Narashino origin from GLB metadata. See alignment validation.','terrainSampleAnchors':[{'lonlat':p,'altitude':elevation(*p)} for p in [[140.021,35.689],[140.015,35.662]]],'downloadManifest':json.loads((s/'data/download-manifest.json').read_text('utf-8')),'osm':{'timestamp':osm['osm3s']['timestamp_osm_base'],'license':'ODbL 1.0','source':'https://overpass-api.de/api/interpreter','bbox':bbox},'licenseLinks':['https://maps.gsi.go.jp/development/ichiran.html','https://www.gsi.go.jp/kikakuchousei/kikakuchousei40182.html','https://www.openstreetmap.org/copyright'],'accuracyNotes':['DEM is ground elevation, not bridge deck or roof height.','Road width estimates are marked per feature.','Context building heights are measured only when OSM height is present, otherwise estimated.','Original campus building heights and facade layouts retain existing estimate notes.','OSRM routes are independent outward/return candidates, not legal driving instructions.']},ensure_ascii=False,indent=2),'utf-8')
# Preserve reproducible source coverage and the bounded HTTPS recovery evidence.
manifest_path=out/'region-source-manifest.json'
manifest=json.loads(manifest_path.read_text('utf-8'))
manifest['actualDownloadedFiles']=manifest['downloadManifest']['files']
manifest['terrainInterpolatedSamples']=missing;manifest['terrainControlSamples']=[]
manifest['terrainCoverage']={k:data['terrain'][k] for k in ['nx','nz','step','sourceDerivedPercent','interpolatedPercent','coverageByTile','sourceMaskLegend']}
manifest['terrainCoverage'].update({'sampleCount':len(heights),'sourceDerivedSamples':sum(known),'interpolatedSamples':missing,'maskLocation':'region.json terrain.sampleSources and terrain.known, row-major z*nx+x'})
recovery_path=download/'dem-recovery-provenance.json'
if recovery_path.exists():manifest['demRecovery']=json.loads(recovery_path.read_text('utf-8'))
manifest['regionSha256']=hashlib.sha256((out/'region.json').read_bytes()).hexdigest()
manifest['accuracyNotes'].append('Complete source coverage does not remove DEM resampling, 20m render grid, OSM geometry, bridge-deck estimates, or inferred campus facade/height limitations.')
manifest_path.write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8')
shutil.copyfile(manifest_path,r/'docs/campus_3d/region-source-manifest.json')
print(json.dumps({'roads':len(roads),'buildings':len(buildings),'photos':len(photos),'terrainPoints':len(heights),'noData':sum(v is None for v in heights),'campusAltitudes':[c['altitude'] for c in campuses],'bytes':(out/'region.json').stat().st_size}))
