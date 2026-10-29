-- Zygor-CoA UI compatibility layer (WoW 3.3.5a).
-- Does not replace Blizzard frames or alter ElvUI/DragonUI settings.
local compat = CreateFrame("Frame")
local function Refresh()
    local z = _G.ZygorGuidesViewer
    if not z then return end
    z.CoAUI = z.CoAUI or {}
    local elv = _G.ElvUI
    local dragon = _G.DragonUI or (_G.IsAddOnLoaded and IsAddOnLoaded("DragonUI"))
    z.CoAUI.ElvUI = (type(elv) == "table") or (_G.IsAddOnLoaded and IsAddOnLoaded("ElvUI")) or false
    z.CoAUI.DragonUI = not not dragon
    z.CoAUI.Mode = z.CoAUI.ElvUI and "ElvUI" or (z.CoAUI.DragonUI and "DragonUI" or "Blizzard")
    -- Deliberately leave Zygor's own guide anchors, skin, scale, and tooltip
    -- ownership intact. UI replacements can manage Blizzard frames safely.
end
compat:RegisterEvent("PLAYER_LOGIN")
compat:RegisterEvent("ADDON_LOADED")
compat:SetScript("OnEvent", function(self, event, addon)
    if event == "PLAYER_LOGIN" or addon == "ElvUI" or addon == "DragonUI" or addon == "ZygorGuidesViewerRM" then
        Refresh()
    end
end)
