local function OnSessionLoaded()
    RunesOfFaerun.Utils.PrintVersionMessage()
end

local function OnEnteredLevel(templateName, rootGUID, level)
    local isKnownEntity = templateName:find('ROF_') == 1
    if isKnownEntity then
        RunesOfFaerun.Info('Handling ' .. templateName)
        local instanceGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(templateName)
        RunesOfFaerun.EntityHandler.HandleByGUID(rootGUID, instanceGUID)
    end
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", OnEnteredLevel)
