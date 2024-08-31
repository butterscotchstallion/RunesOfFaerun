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

---@param characterGUID GUIDSTRING
local function ApplyMummyTransformationIfUnlocked(characterGUID)
    local isNurse = HasNurseTag(characterGUID)
    local mummyUnlocked = HasMummyVisualUnlocked()
    if mummyUnlocked and isNurse then
        RunesOfFaerun.Upgrader.SetMummyVisual(characterGUID)
        Osi.ApplyStatus(characterGUID, "STATUS_APPLY_MUMMY_TRANSFORM", -1, 1)
        Debug("Applied mummy transformation to " .. characterGUID)
    else
        Debug(string.format("Mummy unlocked: %s; isNurse: %s", mummyUnlocked, isNurse))
    end
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
