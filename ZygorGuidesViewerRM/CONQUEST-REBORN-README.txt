Zygor Guides Viewer RM - Conquest Reborn integration test build
Version 1.0.2-CoA | Maintainer: Uncle Bone | https://github.com/downingwow

INSTALL
Exit WoW. Back up your current ZygorGuidesViewerRM folder and SavedVariables.
Replace the existing ZygorGuidesViewerRM folder with the one folder in this ZIP.
Everything, including all five archive categories, is inside this folder.
If upgrading from v1.0.0, remove the old ZygorCoAArchive_items,
ZygorCoAArchive_npcs, ZygorCoAArchive_quests, ZygorCoAArchive_spells and
ZygorCoAArchive_talents folders from Interface/AddOns. They are no longer used.
Existing Zygor settings and observations keep their original SavedVariables.

MEMORY / LOADING CHANGE
WoW 3.3.5a cannot load a nested folder as a separate on-demand addon. The packed
archive strings now load at login with Zygor. This increases initial memory
use and may increase login/reload time compared with the separate-pack build.
Archive pages still decompress only when needed, with one decoded page and
128 record lookups cached. All reference categories and searches are retained.

NEW FUNCTIONALITY
- Realm-separated account-wide observed quest names, objectives, contacts,
  reward IDs, NPC sightings and spellbook records in ZygorCoAObserved.
- Live observed quest titles override stock quest titles in the guide engine,
  only in the locale in which the title was observed.
- On detected CoA clients, Gear Finder's quest reward source uses observed
  reward/choice items instead of the stock AzerothCore quest reward list.
  Open the quest reward pane to capture rewards; quest-log scanning supplies
  quest levels. Live item cache/tooltip resolution is still required to score.
- Observed quest NPC contacts appear in NPC tooltips.
- Zygor's Interface Options includes a Conquest Reborn settings section.
- Contact sharing uses ZGCOA1 messages on LootCollector's current channel
  (BBLC25C by default), only when already joined. This addon never joins,
  leaves, renames or hides any channel. Maximum one outgoing contact per two
  seconds; pending queue capped at 100 contacts. Received contacts remain
  unverified peer reports and never overwrite observations or rebroadcast.
  This build shares quest/NPC contact IDs and names, not archive bulk data,
  map coordinates, reward lists, personal completion or character progress.
- Existing CoA map translations, class stat weights, talent advisor and
  guide data retained. Existing Blizzard map frames are not modified by the
  new integration, so DragonUI need not be disabled.

COMMANDS
/zcoa                         Help and version
/zcoa log                     Current quest observations
/zcoa peers                   Unverified received quest contacts
/zcoa quests 1                Look up a quest ID
/zcoa quests <name>           Search archived quest titles
/zcoa npcs <ID or name>       Search NPC references
/zcoa items <ID or name>      Search item references
/zcoa spells <ID or name>     Search spell references
/zcoa talents <tree name>     Search historical talent trees
/zcoa sharing off             Disable incoming/outgoing contact sharing
/zcoa tooltips off            Disable observed NPC tooltip additions
/zcoa export                  Copyable contact-record lines
/zcoa import <ZGCOA1 line>    Merge one contact line as unverified peer data
Use 'on' instead of 'off' to re-enable a setting. Imports follow the sharing
setting; enable sharing to import. Import each exported contact line separately.
Text is validated, never executed. NPC contact positions stored locally are
player positions near the NPC, not exact NPC spawn coordinates.

REFERENCE DATA
10,776 quests; 41,817 NPCs; 115,373 items; 214,152 positive spell IDs;
155 talent-tree pages. Tree lookup numeric IDs are local archive row numbers;
the tree display shows original spell IDs and layout, not a recommended build.
Packed reference pages decompress only as needed. Large name searches run over multiple frames and show at most
30 matches. Searches require at least three characters. Live observed quests
win ID lookups; archived-name searches remain historical results.

Data source: supplied ascension-data-main.zip, Exiles/coa-db mirror snapshot
6bcecd0faa6c2e7084d8015e1d931431c30e3013a9122810d593868196a3578b.
Attribution: Exiles database, Duff-SPP, hertigservices. See provenance JSON
and data license. Source artifact hashes were verified before conversion.
Each reference retains its source page SHA256. This is a compact gameplay
projection, not a lossless archive of every source field or dataset. No WDB
release packs, raw SQL spawn database, community build imports, Worldforged
pickup catalogs or DBC snapshots are converted in this build.

LIMITS / IN-GAME VERIFICATION
This is an integration test build, not a claim of complete realm validation.
Archive entries are historical third-party references; IDs, listed loot rates,
talent layouts and level-dependent item display values may differ today.
Archive item text is never converted into guessed scoring stats. Archive
reference fields do not replace live observations. Stock leveling routes,
non-quest boss/vendor/crafting sources and pre-existing gear/talent advice
remain legacy content and are not made realm-authoritative by this update.
Quest contacts do not automatically rewrite routes or synthesize prerequisites.
Questie-X, DBM-CoA, MRT-CoA and LootCollector databases are not scraped or
modified. They may consume the documented read API below; matching channel
membership alone does not make them understand ZGCOA1 contact records.
Live DragonUI/default UI behavior, quest pane event timing, custom spellbook
behavior and channel transport require testing on the game client.

FIRST TEST
1. Log in with DragonUI enabled. Check /zcoa and Zygor options for version.
2. Open /zcoa log, accept a quest and open its reward pane. Check recorded
   title, NPC contacts and reward IDs. Check Gear Finder's quest source.
3. Try /zcoa quests 1 and /zcoa spells Frostbolt. Check archive labels.
4. Test a second addon user already on LootCollector's shared channel.
   New contacts should merge as peer reports without duplicate transmissions.
5. /reload and confirm observations/settings persist. Also test default UI.

READ API FOR OTHER ADDONS
local api = ZygorGuidesViewer and ZygorGuidesViewer.CoA
api:GetRecord('quests', questID, false) -- observation first, then loaded archive
api:GetRecord('npcs', npcID, true)      -- reads the embedded NPC reference index
api:GetRecord('items', itemID, true)
api:GetRecord('spells', spellID, true)
Records expose name/source/detail and archive sha256 where applicable.
Treat returned tables as read-only. Observation schema is version 1;
ZygorCoAObserved.realms[realm] separates realm data. No completion state is
shared across characters. Companion addons need explicit adapters to consume
these records. There is no claim of automatic Questie/DBM/MRT data exchange.

VERSION 1.0.2 - UI COMPATIBILITY
- Optional ElvUI and DragonUI detection without requiring either UI addon.
- UI mode exposed as ZygorGuidesViewer.CoAUI.Mode for future integrations.
- Leaves guide frame positioning, scaling, tooltips and UI replacement settings intact.
- No claim of in-game validation: test on ElvUI, DragonUI and default UI.
