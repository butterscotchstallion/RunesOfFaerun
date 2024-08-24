local ch = {
    visuals = {
        MUMMY = "0fd9c8b4-7ba5-8d90-e90c-e8ebc01da057"
    },
    visualUpdates = {

    }
}

local function GetCustomVisualsFromConfig(config)
    return config.customVisuals or {}
end

local function SaveCustomVisual(characterGUID, visualResourceID)
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local visuals = GetCustomVisualsFromConfig(config)
    visuals[characterGUID] = visualResourceID
    config.customVisuals = visuals
    RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
end

local function UpdateVisual(entity, visual)
    if entity then
        entity.ServerCharacter.Template.CharacterVisualResourceID = visual
        entity:Replicate('GameObjectVisual')
    end
end

local function SetMummyVisual(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    UpdateVisual(entity, ch.visuals.MUMMY)
    SaveCustomVisual(characterGUID, ch.visuals.MUMMY)
end

local function UpdateCustomVisualsFromConfig()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local visuals = GetCustomVisualsFromConfig(config)
    for uuid, visualResourceID in pairs(visuals) do
        local entity = Ext.Entity.Get(uuid)

        if entity and not ch.visualUpdates[uuid] then
            UpdateVisual(entity, visualResourceID)

            --In case the summon died, and exists, re-apply the status
            if visualResourceID == ch.visuals.MUMMY then
                Osi.ApplyStatus(uuid, "STATUS_APPLY_MUMMY_TRANSFORM", -1, 1)
            end

            ch.visualUpdates[uuid] = true

            Debug('Updated visual for ' .. RunesOfFaerun.Utils.GetDisplayNameFromEntity(entity))
        else
            Debug(string.format("Could not find entity with UUID %s", uuid))
        end
    end
end

ch.UpdateCustomVisualsFromConfig = UpdateCustomVisualsFromConfig
ch.SetMummyVisual = SetMummyVisual
ch.UpdateVisual = UpdateVisual

RunesOfFaerun.CosmeticHandler = ch
