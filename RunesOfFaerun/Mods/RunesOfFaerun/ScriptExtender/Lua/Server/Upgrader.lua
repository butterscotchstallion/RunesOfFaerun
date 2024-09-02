local upgrader = {
    visuals = {
        MUMMY = "0fd9c8b4-7ba5-8d90-e90c-e8ebc01da057"
    },
    MUMMY_UNLOCK_NAME = "mummy"
}

local upgradeNames = {
    BADGER = {
        CRUSHING_FLIGHT = "CRUSHING_FLIGHT"
    }
}

local function GetCustomVisualsFromConfig(config)
    return config.customVisuals or {}
end

local function SaveCustomVisual(visualUnlockName)
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local visuals = GetCustomVisualsFromConfig(config)
    visuals[visualUnlockName] = true
    config.customVisuals = visuals
    RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
end

local function UpdateVisual(entity, visual)
    if entity then
        entity.ServerCharacter.Template.CharacterVisualResourceID = visual
        entity:Replicate('GameObjectVisual')
    end
end

local function GetUnlockedVisuals()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local visuals = GetCustomVisualsFromConfig(config)
    return visuals
end

local function HasMummyVisualUnlocked()
    local visuals = GetUnlockedVisuals()
    if visuals and visuals[upgrader.MUMMY_UNLOCK_NAME] then
        return true
    end
end

local function SetMummyVisual(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    UpdateVisual(entity, upgrader.visuals.MUMMY)
    SaveCustomVisual(upgrader.MUMMY_UNLOCK_NAME)
end

local function HasNurseTag(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    local tagMap = RunesOfFaerun.Utils.GetTagMapFromEntity(entity)
    return tagMap[RunesOfFaerun.Tags.NURSE] ~= nil
end

local function ChangeRaceToMummy(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    local mummyRaceUUID = "3c066deb-eaaf-4bbf-b021-61ad0acc51a2"
    entity.Race.Race = mummyRaceUUID
    entity:Replicate('Race')
    Debug("Changed race to MUMMY")
end

local function UpdateDisplayName(characterGUID, newHandle)
    local newDisplayName = Ext.Loca.GetTranslatedString(newHandle)
    Osi.SetStoryDisplayName(characterGUID, newDisplayName)
    --Apparently I should use this?
    --Ext.Loca.UpdateTranslatedString()
    Debug("Updated display name")
end

local function UpdateIcon(characterGUID, iconName, generatePortrait)
    local entity = Ext.Entity.Get(characterGUID)
    entity.ServerCharacter.Template.Icon = iconName
    entity.ServerCharacter.Template.GeneratePortrait = generatePortrait
    pcall(function()
        entity:Replicate()
    end)
    Debug("Updated icon")
end

---@param characterGUID GUIDSTRING
local function ApplyMummyTransformationIfUnlocked(characterGUID)
    --[[
    Need to wait a little bit for tags to be populated because...
    I dunno. It just works (tm)
    ]]
    local displayName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(Ext.Entity.Get(characterGUID))
    Ext.Timer.WaitFor(3000, function()
        local isNurse = HasNurseTag(characterGUID)
        local mummyUnlocked = HasMummyVisualUnlocked()
        if mummyUnlocked and isNurse then
            --Visual
            RunesOfFaerun.Upgrader.SetMummyVisual(characterGUID)
            --Status granting new abilities
            Osi.ApplyStatus(characterGUID, "STATUS_APPLY_MUMMY_TRANSFORM", -1, 1)
            --Race change
            ChangeRaceToMummy(characterGUID)
            --Display Name
            UpdateDisplayName(characterGUID, "h0432b904952f485fb1e2b85c598f50e89fc1")
            --Icon
            UpdateIcon(characterGUID, "c79a0357-1c90-de1e-9f41-c5b5e59aa47c-_(Icon_Mummy)", "Icon_Mummy")

            Debug("Applied mummy transformation to " .. characterGUID)
        else
            Debug(
                string.format(
                    "[%s] Mummy unlocked: %s; isNurse: %s",
                    displayName,
                    mummyUnlocked,
                    isNurse
                )
            )
        end
    end, nil)
end

local function ApplyMaterialOverride(uuid, preset)
    local entity = Ext.Entity.Get(uuid)
    if entity then
        local displayName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(entity)
        Osi.ApplyStatus(uuid, "ASTARION_HAPPY", 10, 1)

        Osi.ClearCustomMaterialOverrides(uuid)
        --Osi.RemoveCustomMaterialOverride(uuid, preset)
        Ext.OnNextTick(function()
            Osi.AddCustomMaterialOverride(uuid, preset)
        end)

        Debug(string.format('Updated material on %s to "%s"', displayName, preset))
    else
        Critical('Invalid UUID: ' .. uuid)
    end
end

local function GetUpgrades()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    return config.upgrades or {}
end

local function HasCrushingFlight()
    local unlockedUpgrades = GetUpgrades()
    return unlockedUpgrades[upgradeNames.BADGER.CRUSHING_FLIGHT]
end

local function ApplyBadgerUpgradesIfUnlocked(characterGUID)
    if HasCrushingFlight() then
        Debug("Applying Crushing Flight upgrade to badger")
        Osi.ApplyStatus(characterGUID, "STATUS_APPLY_CRUSHING_FLIGHT", -1, 1)
    end
end

local function AddUpgrade(upgradeName)
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local upgrades = GetUpgrades()
    upgrades[upgradeName] = true
    config.upgrades = upgrades

    Debug(string.format("Added '%s' upgrade!", upgradeName))

    RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
end

local function AddBadgerCrushingFlightUpgrade()
    AddUpgrade(upgradeNames.BADGER.CRUSHING_FLIGHT)
end

upgrader.AddBadgerCrushingFlightUpgrade = AddBadgerCrushingFlightUpgrade
upgrader.ApplyBadgerUpgradesIfUnlocked = ApplyBadgerUpgradesIfUnlocked
upgrader.ApplyMaterialOverride = ApplyMaterialOverride
upgrader.ApplyMummyTransformationIfUnlocked = ApplyMummyTransformationIfUnlocked
upgrader.SetMummyVisual = SetMummyVisual
upgrader.UpdateVisual = UpdateVisual
upgrader.GetUnlockedVisuals = GetUnlockedVisuals

RunesOfFaerun.Upgrader = upgrader
