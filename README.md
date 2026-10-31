# Zygor-CoA — Guided Questing and CoA Reference Tools

> **[⬇ Download v1.0.2]( https://github.com/downingwow/Zygor-CoA/releases/download/v1.0.2/Zygor-CoA-v1.0.2.zip )**


A Conquest Reborn adaptation of Zygor Guides Viewer Remastered for the Ascension 3.3.5a client. It combines the guide viewer and navigation interface with CoA quest observations, custom-class integration and a searchable historical reference archive.

## Features

- Step-based guide viewing and navigation using the included guide data.
- CoA map translations, custom-class stat weights and talent-advisor integration.
- Realm-separated observations of quest names, objectives, NPC contacts, rewards, sightings and spellbook records.
- Observed quest titles can override stock titles in the locale in which they were recorded.
- On detected CoA clients, Gear Finder uses observed quest reward items; live item-cache data is still needed for scoring.
- NPC tooltip contact information and a Conquest Reborn settings section.
- Searchable historical quest, NPC, item, spell and talent references, decoded in pages as needed.
- Optional bounded contact sharing using `ZGCOA1` on LootCollector's current channel, only when already joined. It never joins, leaves or replaces channels. Peer reports stay unverified and do not overwrite observations.

## Installation

Install **v1.0.2** by extracting the single `ZygorGuidesViewerRM` folder from the release ZIP into `Interface/AddOns`. Do not rename it. Back up the old folder and SavedVariables first. When upgrading from the earlier separate-pack layout, remove the obsolete `ZygorCoAArchive_items`, `_npcs`, `_quests`, `_spells` and `_talents` addon folders after backing them up. The new archive lives inside the viewer folder.

## Commands

- `/zcoa` — help and version.
- `/zcoa log` — quest observations; `/zcoa peers` — received contact reports.
- `/zcoa quests <ID or name>`, `/zcoa npcs <ID or name>`, `/zcoa items <ID or name>`, `/zcoa spells <ID or name>` — reference lookups.
- `/zcoa talents <tree name>` — historical talent references.
- `/zcoa sharing off` and `/zcoa tooltips off` — feature controls; use `on` to restore.
- `/zcoa export` and `/zcoa import <ZGCOA1 line>` — validated contact-record exchange.

## Status and limits

This remains an **integration test build**. Historical archive data may differ from the current realm; talent layouts are references, not recommended builds. The archive strings load at login because nested folders cannot be independent on-demand addons on 3.3.5a. This increases initial memory and loading time. Large searches span multiple frames and limit displayed matches. Locally stored NPC contact coordinates represent the player's position near the NPC, not exact spawn coordinates. DragonUI need not be disabled.

See `ZygorGuidesViewerRM/CONQUEST-REBORN-README.txt` and the bundled provenance/license files for detailed archive scope. Original viewer by **Sinus Pi**; archive sources include Exiles, Duff-SPP and hertigservices as documented in the package. This repository does not imply affiliation with those projects.

## Compatibility and support

Target: Ascension Conquest of Azeroth / Conquest Reborn, legacy WoW 3.3.5a (Interface 30300). Source and package checks do not establish live realm compatibility. Report the addon version, UI addons, and full Lua error when filing an issue. Preserve your WTF SavedVariables when updating.

Maintainer: **Uncle Bone** · [GitHub support](https://github.com/downingwow). This is a community-maintained adaptation. Original authors retain their credits; bundled license and third-party attribution notices remain applicable.
