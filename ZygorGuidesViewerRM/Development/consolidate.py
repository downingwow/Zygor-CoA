from pathlib import Path
import shutil
root=Path('work'); main=root/'ZygorGuidesViewerRM'; archive=main/'CoAArchive';archive.mkdir(exist_ok=True)
lines=['<Ui xmlns="http://www.blizzard.com/wow/ui/">']
for kind in ['quests','npcs','items','spells','talents']:
 source=root/('ZygorCoAArchive_'+kind);target=archive/kind
 if source.exists():
  target.mkdir(exist_ok=True)
  for p in source.iterdir():
   if p.suffix=='.lua' or p.name=='DATA-LICENSE.txt':shutil.move(str(p),str(target/p.name))
  shutil.rmtree(source)
 for p in sorted(target.glob('Data*.lua')):lines.append('  <Script file="'+kind+'\\'+p.name+'"/>')
lines.append('</Ui>');(archive/'Archive.xml').write_text('\n'.join(lines)+'\n')
p=main/'files.xml';s=p.read_text()
if 'CoAArchive\\Archive.xml' not in s:s=s.replace('<Script file="CoAIntegration.lua"/>','<Script file="CoAIntegration.lua"/>\n\t<Include file="CoAArchive\\Archive.xml"/>')
p.write_text(s)
p=main/'CoAIntegration.lua';s=p.read_text();s=s.replace(" local ok,err=LoadAddOn('ZygorCoAArchive_'..kind)\n if not ok then say('Archive '..kind..' unavailable: '..tostring(err)); return false end\n return self.chunks[kind]~=nil"," say('Embedded archive '..kind..' is missing. Reinstall the complete ZygorGuidesViewerRM folder.')\n return false")
s=s.replace('Reference packs load only when searched and stay loaded until reload.','Packed archive data loads with the addon. Reference pages decompress only when needed.')
p.write_text(s)
