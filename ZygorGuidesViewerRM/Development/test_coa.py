from lupa.lua51 import LuaRuntime
from pathlib import Path
import json,zipfile,gzip
lua=LuaRuntime(unpack_returned_tuples=True)
check=lua.eval('function(s,n) local f,e=loadstring(s,n);return f~=nil,e end')
root=Path(__file__).resolve().parents[2]
fail=[]
for p in root.rglob('*.lua'):
 ok,e=check(p.read_text(encoding='utf-8-sig',errors='replace'),str(p))
 if not ok: fail.append((str(p),e))
print('LUA COMPILE',len(list(root.rglob('*.lua'))),'files; failures:',len(fail))
for row in fail[:30]:print(row)
lua.execute('''
frames={};time=function()return 123 end;GetLocale=function()return 'enUS'end
GetRealmName=function()return 'Conquest Reborn'end;UnitClass=function()return 'Chronomancer','CHRONOMANCER'end
ZygorGuidesViewer={Print=function()end,GetQuestName=function(_,id)return 'Stock'..tostring(id)end,IsCoAClient=function()return true end,GetCoAPlayerMapPosition=function()return 37,.4,.5 end,GetPlayerZoneText=function()return 'Elwynn Forest'end}
CreateFrame=function()local f={RegisterEvent=function()end,SetScript=function(self,e,fn)self[e]=fn end};frames[#frames+1]=f;return f end
SlashCmdList={}; sent={};GetChannelName=function()return 4,'BBLC25C'end
SendChatMessage=function(msg,dist,lang,id) sent[#sent+1]={msg,dist,id} end
UnitGUID=function(unit) if unit=='npc' then return '0xF130003C5D000001' end end
UnitName=function()return 'Test NPC'end
UnitIsPlayer=function()return false end;UnitLevel=function()return 10 end
GetNumQuestLogEntries=function()return 1 end
GetQuestLogTitle=function()return 'Live Quest',10,nil,nil,false,false,false,false,999001 end
GetNumQuestLeaderBoards=function()return 1 end
GetQuestLogLeaderBoard=function()return 'Test objective: 0/1','monster',false end
GetNumSpellTabs=function()return 1 end
GetSpellTabInfo=function()return 'Spells',nil,0,1 end
GetSpellLink=function()return '|Hspell:800001|h[Test]|h'end
GetSpellName=function()return 'Time Test'end
GetQuestID=function()return 999001 end;GetTitleText=function()return 'Live Quest'end
GetQuestText=function()return 'Quest description'end;GetObjectiveText=function()return 'Objective'end
GetNumQuestRewards=function()return 1 end;GetNumQuestChoices=function()return 1 end
GetQuestItemLink=function(kind)return kind=='reward' and '|Hitem:900001|h[Test]|h' or '|Hitem:900002|h[Choice]|h'end
''')
lua.execute((root/'ZygorGuidesViewerRM/CoAIntegration.lua').read_text())
lua.execute('''
frames[1].OnEvent(nil,'PLAYER_LOGIN');frames[1].OnUpdate(nil,2)
A=ZygorGuidesViewer.CoA
assert(A.db.quests[999001].name=='Live Quest')
assert(A.db.spells[800001].name=='Time Test')
assert(ZygorGuidesViewer:GetQuestName(999001)=='Live Quest')
assert(ZygorGuidesViewer:GetQuestName(99)=='Stock99')
A:CaptureQuest('QUEST_DETAIL');A:CaptureQuest('QUEST_COMPLETE')
assert(A.db.quests[999001].giver.position.map==37)
assert(A.db.quests[999001].giver.position.x==.4)
assert(#A.db.quests[999001].rewards==2)
A:Flush();assert(#sent==1 and sent[1][3]==4)
A:Flush();assert(#sent==2)
A:Flush();assert(#sent==2)
A:CaptureQuest('QUEST_DETAIL');A:CaptureQuest('QUEST_COMPLETE');A:Flush();assert(#sent==2)
A:Receive('ZGCOA1~999002~giver~55~Peer%7CQuest~NPC','Peer','wrong');assert(not A.db.sharedQuests)
A:Receive('ZGCOA1~999002~giver~55~Peer%7CQuest~NPC','Peer','BBLC25C')
assert(A.db.sharedQuests[999002].name=='Peer Quest')
assert(not A.db.quests[999002])
assert(next(A.pending)==nil)
A:Receive('ZGCOA1~0~giver~55~Bad~NPC','Peer','BBLC25C');assert(not A.db.sharedQuests[0])
A:Receive('ZGCOA1~999001~giver~55~Overwrite~NPC','Peer','BBLC25C');assert(A.db.quests[999001].name=='Live Quest')
''')
lua.execute("table.insert=table.insert; tinsert=table.insert; ZygorGuidesViewer.startups={};ZygorGuidesViewer.ItemScore={Items={},GearFinder={ScoreDungeonItems=function()return 123 end}}")
lua.execute((root/'ZygorGuidesViewerRM/ZygorQuestLootDB.lua').read_text())
lua.execute("ZygorGuidesViewer.startups[1][2]();assert(ZygorGuidesViewer.ItemScore.GearFinder:ScoreDungeonItems()==123);local block=ZygorGuidesViewer.ItemScore.Items[1];assert(#block==1 and #block[1].ALL==2 and block[1].ALL[1]==900001)")
print('PASS Gear Finder uses observed quest rewards, excludes stock quest rewards on CoA')
print('PASS live quests, rewards, spellbook, map multi-returns, local names, sharing, dedup, malformed traffic, peer isolation')
# Compile/load all packed reference records; exercise decompression boundary/reset paths.
for kind in ['quests','npcs','items','spells','talents']:
 folder=root/'ZygorGuidesViewerRM'/'CoAArchive'/kind
 for p in sorted(folder.glob('Data*.lua')): lua.execute(p.read_text())
 chunks=lua.globals().A.chunks[kind]
 count=0
 for i in range(1,len(chunks)+1):
  chunk=chunks[i];data=lua.globals().A.ChunkData(lua.globals().A,chunk)
  lines=data.splitlines();count+=len(lines)
  assert int(lines[0].split('\t')[0])==chunk.lo
  assert int(lines[-1].split('\t')[0])==chunk.hi
  assert len(lines)<=256
  for line in lines: assert len(line.split('\t'))==4
 sample=lua.globals().A.GetRecord(lua.globals().A,kind,chunks[1].lo,False)
 assert sample and sample.name and len(sample.sha256)==64
 print('PASS archive',kind,count,'records;',len(chunks),'pages')
assert not fail,fail
