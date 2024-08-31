local ch = {
    visuals = {
        MUMMY = "0fd9c8b4-7ba5-8d90-e90c-e8ebc01da057"
    },
    MUMMY_UNLOCK_NAME = "mummy"
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
    if visuals and visuals[ch.MUMMY_UNLOCK_NAME] then
        return true
    end
end

local function SetMummyVisual(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    UpdateVisual(entity, ch.visuals.MUMMY)
    SaveCustomVisual(ch.MUMMY_UNLOCK_NAME)
end

local function HasNurseTag(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    local tagMap = RunesOfFaerun.Utils.GetTagMapFromEntity(entity)
    _D(tagMap)

    return tagMap[RunesOfFaerun.Tags.NURSE] ~= nil
end

---@param characterGUID GUIDSTRING
local function ApplyMummyTransformationIfUnlocked(characterGUID)
    local isNurse = HasNurseTag(characterGUID)
    local mummyUnlocked = HasMummyVisualUnlocked()
    if mummyUnlocked and isNurse then
        RunesOfFaerun.CosmeticHandler.SetMummyVisual(characterGUID)
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

ch.ApplyMaterialOverride = ApplyMaterialOverride
ch.ApplyMummyTransformationIfUnlocked = ApplyMummyTransformationIfUnlocked
ch.SetMummyVisual = SetMummyVisual
ch.UpdateVisual = UpdateVisual
ch.GetUnlockedVisuals = GetUnlockedVisuals

RunesOfFaerun.CosmeticHandler = ch
