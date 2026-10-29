Validation: Python 3 with lupa.lua51. Run test_coa.py from this directory or any directory after extracting all addon folders together. This simulates client APIs and validates Lua syntax/data; it is not a full WoW client emulator.

Archive rebuild tools are development scripts, not loaded by the addon. They expect a working directory containing sources/ascension-data-main.zip and output into work/. build_talents.py reuses build_archive.py. Source snapshot is identified in the provenance file; it is not bundled again.

After rebuilding staged archive packs, run consolidate.py from the same build workspace to embed them under work/ZygorGuidesViewerRM/CoAArchive and regenerate Archive.xml. The installable output is only ZygorGuidesViewerRM.
