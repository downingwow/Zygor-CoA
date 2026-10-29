import zipfile,gzip,json,pathlib,hashlib,base64,struct
root=pathlib.Path('work'); z=zipfile.ZipFile('sources/ascension-data-main.zip')
base=next(n.rsplit('/',1)[0]+'/' for n in z.namelist() if '/exiles-db/' in n and n.endswith('/manifest.json'))
manifest=json.loads(z.read(base+'manifest.json')); counts={}
def clean(x): return ' '.join(str(x or '').replace('|','/').split())
def dump(s): return json.dumps(s,ensure_ascii=False).replace('\\/', '/')
def compress(text):
 data=text.encode('utf-8'); dictionary={bytes([i]):i for i in range(256)}; nxt=256; codes=[]; w=b''
 for c in data:
  wc=w+bytes([c])
  if wc in dictionary: w=wc; continue
  codes.append(dictionary[w])
  if nxt<65535: dictionary[wc]=nxt; nxt+=1
  else: codes.append(65535); dictionary={bytes([i]):i for i in range(256)}; nxt=256
  w=bytes([c])
 if w: codes.append(dictionary[w])
 return base64.b64encode(struct.pack('>'+str(len(codes))+'H',*codes)).decode()
def readable(v):
 if isinstance(v,list):return '; '.join(readable(x) for x in v)
 if not isinstance(v,dict):return str(v)
 if 'key' in v and 'label' in v:return str(v['label'])+' ('+str(v.get('type','reference'))+' #'+str(v['key'])+')'
 parts=[]
 if v.get('entity'):parts.append(readable(v['entity']))
 for k in ['label','chance','observed','spell','id','school','cast','cooldown','difficulty','name','detail','value']:
  if v.get(k) is not None:parts.append(k+': '+str(v[k]))
 if v.get('notes'):parts.append(readable(v['notes']))
 if v.get('header') is not None:
  header=v['header']
  for row in v.get('rows',[]):parts.append(', '.join((str(header[i])+': ' if i<len(header) else '')+str(x) for i,x in enumerate(row)))
 if not parts:return json.dumps(v,ensure_ascii=False,separators=(',',':'))
 return '; '.join(parts)
for kind in ['quests','npcs','items','spells']:
 folder=root/('ZygorCoAArchive_'+kind); folder.mkdir(exist_ok=True)
 data=z.read(base+kind+'.jsonl.gz'); assert hashlib.sha256(data).hexdigest()==manifest['artifacts'][kind+'.jsonl.gz']['sha256']
 rows=[]
 for line in gzip.decompress(data).splitlines():
  d=json.loads(line)
  try: id=int(d['key'])
  except: continue
  if id<=0: continue
  name=clean(d.get('name')); parts=[]
  def add(label,v):
   if v: parts.append(label+': '+clean(v))
  if kind=='quests':
   for k,v in d.get('meta',[]): add(k,v)
   for f in d.get('fields',[]): add(f['field'],f.get('text'))
   for v in d.get('list_items',[]): add('Listed',v)
   for r in d.get('references',[]): add(r.get('type','ref')+' #'+r.get('key',''),r.get('label'))
  elif kind=='npcs':
   add('Levels',d.get('levels'))
   for k,v in d.get('meta',{}).items(): add(k,v)
   for k in ['drops','pickpocket','quests','casts']:
    for r in d.get(k,[]): add(k, readable(r))
  elif kind=='items':
   add('Quality', d.get('quality')); add('Archive display level',d.get('default_level'))
   for r in d.get('tooltip',[]): add('Tooltip',r.get('text'))
   for r in d.get('sources',[]): add('Source',readable(r))
   for t in d.get('structure',{}).get('tables',[]): add('Table',readable(t))
  else:
   add('Description',d.get('description'))
   for k,v in d.get('info',{}).items(): add(k,v)
   for k in ['effects','taught_by','cast_by_npcs']:
    for v in d.get(k,[]): add(k,readable(v))
  # Page hash and exact snapshot retained. No item stat reconstruction from prose.
  rows.append((id,'\t'.join([str(id),name,clean(' / '.join(parts)),d.get('source_sha256','')])))
 rows.sort(); chunks=[]
 for i in range(0,len(rows),256):
  batch=rows[i:i+256]; text='\n'.join(r[1] for r in batch)+'\n'
  chunks.append('A:RegisterChunk('+dump(kind)+','+str(batch[0][0])+','+str(batch[-1][0])+','+dump(compress(text))+',true)\n')
 (folder/'Data.lua').write_text('local A=ZygorGuidesViewer.CoA\n'+''.join(chunks))
 (folder/(folder.name+'.toc')).write_text('## Interface: 30300\n## Title: Zygor CoA Archive - '+kind+'\n## Notes: Historical Exiles database references. Not live realm verification.\n## Author: Uncle Bone; data: Exiles / Duff-SPP / hertigservices\n## Version: 1.0.1-CoA\n## Dependencies: ZygorGuidesViewerRM\n## LoadOnDemand: 1\nData.lua\n')
 (folder/'DATA-LICENSE.txt').write_bytes(z.read('ascension-data-main/LICENSE'))
 counts[kind]=len(rows)
 print(kind,len(rows),(folder/'Data.lua').stat().st_size)
main=root/'ZygorGuidesViewerRM'
(main/'CoA-Archive-Provenance.json').write_text(json.dumps({'archive_zip_sha256':'805c24ad5534ee96d1c5765c779b9ed5b00a3421c70bf0d138222e6cd63b005c','source':manifest['source'],'semantics':manifest['semantics'],'artifacts':manifest['artifacts'],'included_counts':counts},indent=2))
(main/'CoA-Data-License.txt').write_bytes(z.read('ascension-data-main/LICENSE'))
