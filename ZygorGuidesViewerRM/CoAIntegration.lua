-- Conquest Reborn integration. Maintainer: Uncle Bone (github.com/downingwow).
-- Native 3.3.5a APIs only. No map reparenting, replacement, or channel ownership.
local ZGV=ZygorGuidesViewer
if not ZGV then return end
local A={version='1.0.1-CoA',chunks={},cache={},cacheOrder={},pending={},elapsed=0}
ZGV.CoA=A
local function validID(id) id=tonumber(id); return id and id>0 and id==math.floor(id) and id<2147483647 and id end
local function text(s,n) return tostring(s or ''):gsub('[%c|]',' '):sub(1,n or 180) end
local function say(s) if ZGV.Print then ZGV:Print('CoA: '..s) end end
function A:IsEnabled()
 local _,token=UnitClass('player')
 return (ZGV.IsCoAClient and ZGV.IsCoAClient()) or (ZGV.ItemScore and ZGV.ItemScore.CoAClassSpecs and ZGV.ItemScore.CoAClassSpecs[token]) or false
end
function A:RegisterChunk(kind,lo,hi,data,packed)
 self.chunks[kind]=self.chunks[kind] or {}
 table.insert(self.chunks[kind],{lo=lo,hi=hi,data=data,packed=packed})
end
-- Fixed 16-bit LZW in base64. Decompress one 256-record page at a time.
local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local values={};for i=1,#alphabet do values[alphabet:sub(i,i)]=i-1 end
function A:ChunkData(chunk)
 if not chunk.packed then return chunk.data end
 if self.decodedChunk==chunk then return self.decodedData end
 local bytes={};local data=chunk.data
 for i=1,#data,4 do
  local a,b,c,d=values[data:sub(i,i)],values[data:sub(i+1,i+1)],values[data:sub(i+2,i+2)],values[data:sub(i+3,i+3)]
  local n=a*262144+b*4096+(c or 0)*64+(d or 0)
  bytes[#bytes+1]=string.char(math.floor(n/65536)%256)
  if c then bytes[#bytes+1]=string.char(math.floor(n/256)%256) end
  if d then bytes[#bytes+1]=string.char(n%256) end
 end
 data=table.concat(bytes);local dict={};local nextCode=256;local previous;local out={}
 local function reset() dict={};for i=0,255 do dict[i]=string.char(i) end;nextCode=256;previous=nil end
 reset()
 for i=1,#data,2 do
  local code=data:byte(i)*256+data:byte(i+1)
  if code==65535 then reset()
  else
   local entry=dict[code] or (code==nextCode and previous and previous..previous:sub(1,1))
   assert(entry,'Invalid CoA archive page')
   out[#out+1]=entry
   if previous and nextCode<65535 then dict[nextCode]=previous..entry:sub(1,1);nextCode=nextCode+1 end
   previous=entry
  end
 end
 self.decodedChunk=chunk;self.decodedData=table.concat(out);return self.decodedData
end
function A:Load(kind)
 if not ({quests=true,npcs=true,items=true,spells=true,talents=true})[kind] then return false end
 if self.chunks[kind] then return true end
 say('Embedded archive '..kind..' is missing. Reinstall the complete ZygorGuidesViewerRM folder.')
 return false
end
function A:Decode(line)
 local id,name,detail,hash=line:match('^(%d+)\t([^\t]*)\t([^\t]*)\t(.*)$')
 if not id then return end
 return {id=tonumber(id),name=name,detail=detail,source='Exiles archive; historical reference',sha256=hash}
end
function A:GetRecord(kind,id,load)
 id=validID(id); if not id then return end
 if kind=='quests' and self.db then
  if self.db.quests[id] then return self.db.quests[id] end
  if self.db.sharedQuests and self.db.sharedQuests[id] then return self.db.sharedQuests[id] end
 end
 local key=kind..':'..id
 if self.cache[key] then return self.cache[key] end
 if not self.chunks[kind] and load then self:Load(kind) end
 for _,chunk in ipairs(self.chunks[kind] or {}) do
  if id>=chunk.lo and id<=chunk.hi then
   local data=self:ChunkData(chunk)
   local row=data:match('^'..id..'\t[^\n]*') or data:match('\n('..id..'\t[^\n]*)')
   local record=row and self:Decode(row)
   if record then
    self.cache[key]=record; table.insert(self.cacheOrder,key)
    if #self.cacheOrder>128 then self.cache[table.remove(self.cacheOrder,1)]=nil end
   end
   return record
  end
 end
end
local function init()
 ZygorCoAObserved=type(ZygorCoAObserved)=='table' and ZygorCoAObserved or {}
 local db=ZygorCoAObserved
 db.schema=1; db.realms=type(db.realms)=='table' and db.realms or {}
 local realm=GetRealmName() or 'Unknown'
 db.realms[realm]=db.realms[realm] or {quests={},npcs={},spells={},settings={sharing=true,tooltips=true}}
 A.db=db.realms[realm]; A.db.settings=A.db.settings or {sharing=true,tooltips=true}
end
function A:Position()
 -- Uses existing Astrolabe CoA translations; never changes the displayed map.
 if not ZGV.GetCoAPlayerMapPosition then return end
 local m,x,y=ZGV.GetCoAPlayerMapPosition()
 if m and type(m)=='number' and x and y then return {map=m,x=x,y=y,system='LibRover',zone=ZGV.GetPlayerZoneText()} end
end
function A:Quest(id,name,level)
 if not self.db or not self:IsEnabled() then return end
 id=validID(id); if not id then return end
 local q=self.db.quests[id] or {id=id,source='Observed on '..(GetRealmName() or '?')}
 q.name=text(name~='' and name or q.name); q.level=tonumber(level) or q.level
 q.seen=time(); q.locale=GetLocale(); self.db.quests[id]=q
 return q
end
function A:ScanQuests()
 if not self.db or not self:IsEnabled() then return end
 for i=1,GetNumQuestLogEntries() do
  local name,level,tag,group,header,collapsed,done,daily,id=GetQuestLogTitle(i)
  if not header and id then
   local q=self:Quest(id,name,level)
   if q then
    q.objectives={}
    for j=1,GetNumQuestLeaderBoards(i) do
     local s,kind,complete=GetQuestLogLeaderBoard(j,i)
     q.objectives[j]={text=text(s,500),kind=kind} -- progress/completion stays character-local in ZGV
    end
   end
  end
 end
end
local function npcID(unit)
 local guid=UnitGUID(unit)
 if not guid then return end
 return validID(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)')) or (guid:match('^0xF13') and validID(tonumber(guid:sub(7,10),16)))
end
function A:CaptureQuest(event)
 if not self:IsEnabled() or not self.db then return end
 local id=GetQuestID and GetQuestID()
 local q=self:Quest(id,GetTitleText and GetTitleText() or '')
 if not q then return end
 local unit=UnitGUID('npc') and 'npc' or nil
 local contact=unit and {id=npcID(unit),name=text(UnitName(unit)),position=self:Position()} or nil
 if event=='QUEST_DETAIL' then q.giver=contact end
 if event=='QUEST_COMPLETE' then q.turnin=contact end
 q.description=text(GetQuestText and GetQuestText() or q.description,4000)
 q.objectiveText=text(GetObjectiveText and GetObjectiveText() or q.objectiveText,2000)
 local rewards={}
 for _,kind in ipairs({'reward','choice'}) do
  local count=(kind=='reward' and GetNumQuestRewards() or GetNumQuestChoices()) or 0
  for i=1,count do
   local link=GetQuestItemLink(kind,i)
   local item=link and validID(link:match('item:(%d+)'))
   if item then rewards[#rewards+1]={id=item,kind=kind} end
  end
 end
 -- Only replace rewards when the reward pane exposes them; empty detail panes aren't deletion evidence.
 if event=='QUEST_COMPLETE' or #rewards>0 then q.rewards=rewards end
 if contact then self:QueueQuest(q, event=='QUEST_DETAIL' and 'giver' or 'turnin') end
end
function A:ScanSpells()
 if not self.db or not self:IsEnabled() then return end
 for tab=1,GetNumSpellTabs() do
  local _,_,offset,count=GetSpellTabInfo(tab)
  for i=offset+1,offset+count do
   local link=GetSpellLink(i,BOOKTYPE_SPELL or 'spell')
   local id=link and validID(link:match('spell:(%d+)'))
   if id then self.db.spells[id]={name=text(GetSpellName(i,BOOKTYPE_SPELL or 'spell')),seen=time()} end
  end
 end
end
function A:Channel()
 local name=LootCollector and LootCollector.chatChannel or 'BBLC25C'
 local id,actual=GetChannelName(name)
 if id and id>0 and type(actual)=='string' and actual:lower()==name:lower() then return id,name end
end
local function enc(s) return (text(s):gsub('([^%w %-%._])',function(c)return string.format('%%%02X',string.byte(c))end)) end
local function dec(s) return (s:gsub('%%(%x%x)',function(h)return string.char(tonumber(h,16))end)) end
function A:QueueQuest(q,role)
 if not self.db.settings.sharing then return end
 local c=q[role]; if not c or not validID(c.id) then return end
 local msg=table.concat({'ZGCOA1',q.id,role,c.id,enc(q.name),enc(c.name)},'~')
 q.sharedMessages=q.sharedMessages or {}
 if #msg>240 or q.sharedMessages[role]==msg then return end
 local key=q.id..':'..role
 -- Coalesce by quest. Never rebroadcast received data and never join/leave a channel.
 if not self.pending[key] then
  local count=0; for _ in pairs(self.pending) do count=count+1 end
  if count>=100 then return end
 end
 self.pending[key]=msg
end
function A:Receive(msg,sender,channel)
 if not self.db or not self.db.settings.sharing or type(msg)~='string' or #msg>240 then return end
 local _,name=self:Channel()
 if not name or type(channel)~='string' or channel:lower()~=name:lower() then return end
 local qid,role,nid,qn,nn=msg:match('^ZGCOA1~(%d+)~(%a+)~(%d+)~([^~]*)~([^~]*)$')
 qid=validID(qid); nid=validID(nid)
 if not qid or not nid or (role~='giver' and role~='turnin') then return end
 self.received=self.received or {}; self.receiveCount=self.receiveCount or 0
 if self.received[msg] or self.receiveCount>=100 then return end
 self.received[msg]=true; self.receiveCount=self.receiveCount+1
 local bucket=self.db.sharedQuests or {}; self.db.sharedQuests=bucket
 local count=0;for _ in pairs(bucket) do count=count+1 end
 if not bucket[qid] and count>=5000 then return end
 local q=bucket[qid] or {id=qid,name=text(dec(qn)),source='Peer report; unverified'}
 q.reportedBy=text(sender,80)
 q[role]={id=nid,name=text(dec(nn))}; bucket[qid]=q -- never overwrites local observations
end
function A:Flush()
 self.received={}; self.receiveCount=0
 if not self.db or not self.db.settings.sharing then return end
 local channel=self:Channel(); if not channel then return end
 local id,msg=next(self.pending)
 if id then
  local ok=pcall(SendChatMessage,msg,'CHANNEL',nil,channel)
  if ok then
   self.pending[id]=nil
   local qid,role=id:match('^(%d+):(%a+)$');local q=self.db.quests[tonumber(qid)]
   if q then q.sharedMessages=q.sharedMessages or {};q.sharedMessages[role]=msg end
  end
 end
end
-- Archive browser uses standard frames, compatible with DragonUI and default UI.
function A:Show(content)
 if not self.window then
  local f=CreateFrame('Frame','ZygorCoAArchiveBrowser',UIParent)
  f:SetWidth(680); f:SetHeight(420); f:SetPoint('CENTER'); f:SetFrameStrata('DIALOG')
  f:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=32,insets={left=8,right=8,top=8,bottom=8}})
  f:EnableMouse(true); f:SetMovable(true); f:RegisterForDrag('LeftButton'); f:SetScript('OnDragStart',f.StartMoving); f:SetScript('OnDragStop',f.StopMovingOrSizing)
  local close=CreateFrame('Button',nil,f,'UIPanelCloseButton'); close:SetPoint('TOPRIGHT',-4,-4)
  local title=f:CreateFontString(nil,'OVERLAY','GameFontNormal'); title:SetPoint('TOPLEFT',20,-18); title:SetText('Conquest Reborn - Archive / Observations')
  local scroll=CreateFrame('ScrollFrame','ZygorCoAArchiveScroll',f,'UIPanelScrollFrameTemplate'); scroll:SetPoint('TOPLEFT',20,-45);scroll:SetPoint('BOTTOMRIGHT',-35,20)
  local edit=CreateFrame('EditBox',nil,scroll);edit:SetMultiLine(true);edit:SetFontObject(ChatFontNormal);edit:SetWidth(615);edit:SetAutoFocus(false);edit:SetScript('OnEscapePressed',function()f:Hide()end)
  scroll:SetScrollChild(edit); f.edit=edit; self.window=f
  table.insert(UISpecialFrames,'ZygorCoAArchiveBrowser')
 end
 self.window.edit:SetText(content);self.window.edit:SetCursorPosition(0);self.window:Show()
end
local function summary(q)
 local lines={q.name or '?',q.source or 'Observed'}
 if q.detail then lines[#lines+1]=q.detail end
 if q.description then lines[#lines+1]=q.description end
 if q.objectiveText then lines[#lines+1]=q.objectiveText end
 for _,o in ipairs(q.objectives or {}) do lines[#lines+1]=o.text end
 for _,role in ipairs({'giver','turnin'}) do
  local c=q[role]; if c then lines[#lines+1]=role..': '..(c.name or '?')..' #'..tostring(c.id or '?') end
 end
 for _,r in ipairs(q.rewards or {}) do lines[#lines+1]=r.kind..' item #'..r.id end
 if q.reportedBy then lines[#lines+1]='Reported by: '..q.reportedBy end
 if q.sha256 then lines[#lines+1]='Page SHA256: '..q.sha256 end
 return table.concat(lines,'\n')
end
function A:Command(msg)
 local command,rest=(msg or ''):match('^(%S*)%s*(.-)$')
 if command=='sharing' or command=='tooltips' then
  self.db.settings[command]=rest~='off';say(command..' '..(self.db.settings[command] and 'on' or 'off'));return
 end
 if command=='log' then
  self:ScanQuests(); local out={}
  for i=1,GetNumQuestLogEntries() do
   local _,_,_,_,header,_,_,_,id=GetQuestLogTitle(i)
   local q=not header and self.db.quests[id]; if q then out[#out+1]='#'..id..' '..summary(q) end
  end
  self:Show(table.concat(out,'\n\n')); return
 end
 if command=='peers' then
  local out={'Unverified peer quest contacts'}
  for id,q in pairs(self.db.sharedQuests or {}) do out[#out+1]='#'..id..' '..summary(q) end
  self:Show(table.concat(out,'\n\n'));return
 end
 if command=='export' then
  local out={'ZGCOA1 export - peer reports, no completion state'}
  for id,q in pairs(self.db.quests) do
   for _,role in ipairs({'giver','turnin'}) do local c=q[role]
    if c and validID(c.id) then out[#out+1]=table.concat({'ZGCOA1',id,role,c.id,enc(q.name),enc(c.name)},'~') end
   end
  end
  self:Show(table.concat(out,'\n'));return
 end
 if command=='import' then
  local _,channel=self:Channel()
  -- Import uses the same strict parser without executing pasted text. Works offline.
  local old=self.Channel; self.Channel=function()return 1,'IMPORT'end
  self:Receive(rest,'manual','IMPORT');self.Channel=old;say('Import processed (valid contact records merge as unverified peer data).');return
 end
 if ({quests=true,npcs=true,items=true,spells=true,talents=true})[command] then
  if not self:Load(command) then return end
  local id=validID(rest)
  if id then local q=self:GetRecord(command,id);self:Show(q and ('#'..id..' '..summary(q)) or 'No record found.');return end
  if #rest<3 then say('Search requires at least 3 characters or a numeric ID.');return end
  self.search={kind=command,query=rest:lower(),chunk=1,offset=1,hits={},count=0};say('Searching '..command..'...');return
 end
 say(self.version..' | /zcoa log | peers | quests/npcs/items/spells/talents <ID or name> | sharing/tooltips on/off | export | import <ZGCOA1 line>')
end
function A:SearchTick()
 local s=self.search;if not s then return end
 local chunks=self.chunks[s.kind]
 local chunk=chunks[s.chunk]
 if not chunk then self:Show(table.concat(s.hits,'\n\n')..'\nMatches shown: '..s.count);self.search=nil;return end
 -- At most 20 records per frame, so large archive searches yield to the game.
 for i=1,20 do
  local data=self:ChunkData(chunk)
  local last=data:find('\n',s.offset,true)
  if not last then s.chunk=s.chunk+1;s.offset=1;return end
  local line=data:sub(s.offset,last-1);s.offset=last+1
  local name=line:match('^%d+\t([^\t]*)') or ''
  if name:lower():find(s.query,1,true) then
   local q=self:Decode(line);s.hits[#s.hits+1]='#'..q.id..' '..summary(q);s.count=s.count+1
   if s.count>=30 then self:Show(table.concat(s.hits,'\n\n')..'\nShowing first 30 matches; narrow your search.');self.search=nil;return end
  end
 end
end
local frame=CreateFrame('Frame')
frame:RegisterEvent('PLAYER_LOGIN')
frame:SetScript('OnEvent',function(_,event,...)
 if event=='PLAYER_LOGIN' then
  init()
  if not A:IsEnabled() then return end
  for _,e in ipairs({'QUEST_LOG_UPDATE','QUEST_DETAIL','QUEST_COMPLETE','SPELLS_CHANGED','PLAYER_TARGET_CHANGED','CHAT_MSG_CHANNEL'}) do frame:RegisterEvent(e) end
  A.questDirty=true; A.spellDirty=true
 elseif event=='QUEST_LOG_UPDATE' then A.questDirty=true
 elseif event=='SPELLS_CHANGED' then A.spellDirty=true
 elseif event=='QUEST_DETAIL' or event=='QUEST_COMPLETE' then A:CaptureQuest(event)
 elseif event=='CHAT_MSG_CHANNEL' then local msg,sender,_,_,_,_,_,_,channel=...;A:Receive(msg,sender,channel)
 elseif event=='PLAYER_TARGET_CHANGED' then
  local id=npcID('target')
  if id and not UnitIsPlayer('target') then A.db.npcs[id]={name=text(UnitName('target')),level=UnitLevel('target'),position=A:Position(),seen=time()} end
 end
end)
frame:SetScript('OnUpdate',function(_,elapsed)
 A:SearchTick();A.elapsed=A.elapsed+elapsed
 if A.elapsed<2 then return end
 A.elapsed=0
 if A.questDirty then A.questDirty=nil;A:ScanQuests() end
 if A.spellDirty then A.spellDirty=nil;A:ScanSpells() end
 A:Flush()
end)
SLASH_ZYGORCOA1='/zcoa'
SlashCmdList.ZYGORCOA=function(msg) if not A.db then init() end A:Command(msg) end
-- Observed quest names override the stock translation only in the observed locale.
local getName=ZGV.GetQuestName
ZGV.GetQuestName=function(self,id)
 local qid=type(id)=='table' and (id[1] or id[2]) or id
 local q=A.db and A.db.quests[tonumber(qid)]
 if A:IsEnabled() and q and q.locale==GetLocale() and q.name~='' then return q.name end
 return getName(self,id)
end
if GameTooltip and GameTooltip.HookScript then
 GameTooltip:HookScript('OnTooltipSetUnit',function(tip)
  if not A.db or not A.db.settings.tooltips or not A:IsEnabled() then return end
  local _,unit=tip:GetUnit();local id=unit and npcID(unit);if not id then return end
  tip:AddLine('CoA NPC #'..id,0.5,0.9,1)
  local n=0
  for _,q in pairs(A.db.quests) do
   if (q.giver and q.giver.id==id) or (q.turnin and q.turnin.id==id) then tip:AddLine('Observed quest: '..q.name,0.5,1,0.5);n=n+1;if n>=6 then break end end
  end
  tip:Show()
 end)
end
function A:GetOptionsTable()
 local function get(key) if not A.db then init() end return A.db.settings[key] end
 local function set(key,v) if not A.db then init() end A.db.settings[key]=v end
 return {type='group',name='Conquest Reborn',args={
  info={type='description',order=1,name='Live quest learning is automatic on CoA. Archive records are historical references. Packed archive data loads with the addon. Reference pages decompress only when needed.'},
  sharing={type='toggle',order=2,name='Share observed quest contacts',desc='Uses the existing LootCollector channel when joined. No new channel is joined.',get=function()return get('sharing')end,set=function(_,v)set('sharing',v)end},
  tooltips={type='toggle',order=3,name='Observed quest NPC tooltips',get=function()return get('tooltips')end,set=function(_,v)set('tooltips',v)end},
  log={type='execute',order=4,name='View current quest observations',func=function()A:Command('log')end},
  help={type='description',order=5,name='/zcoa quests <ID or name>\n/zcoa npcs <ID or name>\n/zcoa items <ID or name>\n/zcoa spells <ID or name>\n/zcoa talents <tree name>\nMaintainer: Uncle Bone - github.com/downingwow'},
 }}
end
