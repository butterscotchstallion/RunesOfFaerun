local hdh = {
    RUNE_TAG = '659f6688-8b4c-42f2-97c4-3485962f4a9c',
    ENHANCEMENT_RUNE_TAG = '4a349b52-43b3-4999-83af-0272b284d0d9',
    RUNE_HELP_HANDLE = 'h36d9c75c51b04a74a311479f87fa04b3c802',
    ENHANCEMENT_RUNE_HELP_HANDLE = 'h0e7339d361b64bd299f1c63f4909bd07006f',
    hasDiscoveredRune = false,
    hasDiscoveredEnhancementRune = false
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

        RunesOfFaerun.ModVarsHandler.UpdateConfig(updatedConfig)
        Debug('Saved rune discovery flags')
    end
end

local function IsRune(tplId)
    local tagMap = RunesOfFaerun.Utils.GetTagMapByTplId(tplId)
    if tagMap then
        return tagMap[hdh.RUNE_TAG]
    end
end

local function IsEnhancementRune(tplId)
    local tagMap = RunesOfFaerun.Utils.GetTagMapByTplId(tplId)
    if tagMap then
        return tagMap[hdh.ENHANCEMENT_RUNE_TAG]
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
    SaveDiscoveryFlags()
end

hdh.ResetRuneDiscoveries = ResetRuneDiscoveries
hdh.IsRune = IsRune
hdh.OnRuneDiscovered = OnRuneDiscovered

RunesOfFaerun.HelpDialogHandler = hdh
