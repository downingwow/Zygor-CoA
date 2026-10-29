exec(open('dev/build_archive.py').read().split("for kind in ['quests'")[0])
kind='talents';folder=root/('ZygorCoAArchive_'+kind);folder.mkdir(exist_ok=True)
data=z.read(base+kind+'.jsonl.gz');assert hashlib.sha256(data).hexdigest()==manifest['artifacts'][kind+'.jsonl.gz']['sha256']
rows=[]
for i,line in enumerate(gzip.decompress(data).splitlines(),1):
 d=json.loads(line);parts=['Tree key: '+d['key']]
 for t in d.get('talents',[]):parts.append(' / '.join(str(t.get(k,'')) for k in ['name','spell_id','row','column','max_rank']))
 rows.append((i,'\t'.join([str(i),clean(d.get('name')),clean('Columns: name / spell ID / row / column / maximum rank. '+ ' ; '.join(parts)),d['source_sha256']])))
text='\n'.join(r[1] for r in rows)+'\n'
(folder/'Data.lua').write_text('local A=ZygorGuidesViewer.CoA\nA:RegisterChunk("talents",1,'+str(len(rows))+','+dump(compress(text))+',true)\n')
(folder/(folder.name+'.toc')).write_text('## Interface: 30300\n## Title: Zygor CoA Archive - talents\n## Notes: Historical talent tree references; not an automatic talent build.\n## Version: 1.0.1-CoA\n## Dependencies: ZygorGuidesViewerRM\n## LoadOnDemand: 1\nData.lua\n')
(folder/'DATA-LICENSE.txt').write_bytes(z.read('ascension-data-main/LICENSE'))
print('talents',len(rows),'trees')
