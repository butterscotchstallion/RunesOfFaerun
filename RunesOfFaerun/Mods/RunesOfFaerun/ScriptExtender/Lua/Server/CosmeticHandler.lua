local ch = {
    visuals = {
        MUMMY = "0fd9c8b4-7ba5-8d90-e90c-e8ebc01da057"
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

local function UpdateVisual(characterGUID, visual)
    local entity = Ext.Entity.Get(characterGUID)
    if entity then
        entity.ServerCharacter.Template.CharacterVisualResourceID = visual
        entity:Replicate('GameObjectVisual')
        Debug('Updated visual on ' .. RunesOfFaerun.Utils.GetDisplayNameFromEntity(entity))
    end
end

local function SetMummyVisual(characterGUID)
    UpdateVisual(characterGUID, ch.visuals.MUMMY)
    SaveCustomVisual(characterGUID, ch.visuals.MUMMY)
end

local function UpdateCustomVisualsFromConfig()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local visuals = GetCustomVisualsFromConfig(config)
    for uuid, visualResourceID in pairs(visuals) do
        UpdateVisual(uuid, visualResourceID)
    end
end

ch.UpdateCustomVisualsFromConfig = UpdateCustomVisualsFromConfig
ch.SetMummyVisual = SetMummyVisual
ch.UpdateVisual = UpdateVisual

RunesOfFaerun.CosmeticHandler = ch
