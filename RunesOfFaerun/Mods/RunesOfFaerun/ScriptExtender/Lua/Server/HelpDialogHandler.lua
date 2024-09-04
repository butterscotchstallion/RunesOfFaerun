local hdh = {
    RUNE_HELP_HANDLE = 'h36d9c75c51b04a74a311479f87fa04b3c802',
    ENHANCEMENT_RUNE_HELP_HANDLE = 'h0e7339d361b64bd299f1c63f4909bd07006f',
    RUNE_POUCH_HELP_HANDLE = "hc46d22f307d04c68b19c4aa7550d92856937",
    hasDiscoveredRune = false,
    hasDiscoveredEnhancementRune = false,
    hasDiscoveredRunePouch = false,
}

---@param optionName string
local function GetConfigOption(optionName)
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    return config[optionName]
end

local function SaveDiscoveryFlags()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local updatedConfig = config
    if config then
        updatedConfig.hasDiscoveredEnhancementRune = hdh.hasDiscoveredEnhancementRune
        updatedConfig.hasDiscoveredRune = hdh.hasDiscoveredRune
        updatedConfig.hasDiscoveredRunePouch = hdh.hasDiscoveredRunePouch

        RunesOfFaerun.ModVarsHandler.UpdateConfig(updatedConfig)
        Debug('Saved rune discovery flags')
    end
end

local function IsRune(tplId)
    local tagMap = RunesOfFaerun.Utils.GetTagMapByTplId(tplId)
    if tagMap then
        return tagMap[RunesOfFaerun.Tags.RUNE]
    end
end

local function IsEnhancementRune(tplId)
    local tagMap = RunesOfFaerun.Utils.GetTagMapByTplId(tplId)
    if tagMap then
        return tagMap[RunesOfFaerun.Tags.ENHANCEMENT_RUNE]
    end
end

local function ShowHelpNotification(handle, inventoryHolder)
    Osi.OpenMessageBox(inventoryHolder, Osi.ResolveTranslatedString(handle))
end

local function ShowRuneHelp(inventoryHolder)
    ShowHelpNotification(hdh.RUNE_HELP_HANDLE, inventoryHolder)
end

local function ShowEnhancementRuneHelp(inventoryHolder)
    ShowHelpNotification(hdh.ENHANCEMENT_RUNE_HELP_HANDLE, inventoryHolder)
end

local function HasDiscoveredRune()
    if hdh.hasDiscoveredRune then
        return true
    end

    if GetConfigOption('hasDiscoveredRune') ~= nil then
        return GetConfigOption('hasDiscoveredRune')
    end

    return false
end

local function HasDiscoveredEnhancementRune()
    if hdh.hasDiscoveredEnhancementRune then
        return true
    end

    if GetConfigOption('hasDiscoveredEnhancementRune') ~= nil then
        return GetConfigOption('hasDiscoveredEnhancementRune')
    end

    return false
end

--Check for isRune happens before this, so anything here
--is a rune of some kind
local function OnRuneDiscovered(tplId, inventoryHolder)
    local isEnhancement = IsEnhancementRune(tplId)
    local hasDiscoveredRune = HasDiscoveredRune()
    local hasDiscoveredEnhancementRune = HasDiscoveredEnhancementRune()

    if not hasDiscoveredEnhancementRune or not hasDiscoveredRune then
        if isEnhancement then
            ShowEnhancementRuneHelp(inventoryHolder)
            hdh.hasDiscoveredEnhancementRune = true
        elseif not isEnhancement then
            ShowRuneHelp(inventoryHolder)
            hdh.hasDiscoveredRune = true
        end
        SaveDiscoveryFlags()
    end
end

local function ResetRuneDiscoveries()
    hdh.hasDiscoveredEnhancementRune = false
    hdh.hasDiscoveredRune = false
    hdh.hasDiscoveredRunePouch = false
    SaveDiscoveryFlags()
end

local function ShowRunePouchHelp(characterGUID)
    ShowHelpNotification(hdh.RUNE_POUCH_HELP_HANDLE, characterGUID)
end

local function HasDiscoveredRunePouch()
    if hdh.hasDiscoveredRunePouch then
        return true
    end

    if GetConfigOption('hasDiscoveredRunePouch') ~= nil then
        return GetConfigOption('hasDiscoveredRunePouch')
    end

    return false
end

local function OnRunePouchDiscovered(tplId, characterGUID)
    if not HasDiscoveredRunePouch() then
        Debug("Showing rune pouch help")
        ShowRunePouchHelp(characterGUID)
        hdh.hasDiscoveredRunePouch = true
        SaveDiscoveryFlags()
    end
end

local function IsRunePouch(tplId)
    local itemUUID = RunesOfFaerun.Utils.GetGUIDFromTpl(tplId)
    return Osi.IsTagged(itemUUID, RunesOfFaerun.Tags.RUNE_POUCH) == 1
end

hdh.OnRunePouchDiscovered = OnRunePouchDiscovered
hdh.IsRunePouch = IsRunePouch
hdh.ResetRuneDiscoveries = ResetRuneDiscoveries
hdh.IsRune = IsRune
hdh.OnRuneDiscovered = OnRuneDiscovered

RunesOfFaerun.HelpDialogHandler = hdh
