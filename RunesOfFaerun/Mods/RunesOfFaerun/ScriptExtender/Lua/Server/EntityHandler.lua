local eh = {}

SLIMY_COMPANION_GUID = '6e831db4-2531-48a8-ab87-445c5b0032a8'

---@param entityGUID guid
eh.SetEntityLevelToHostLevel = function(entityGUID)
    local hostLevel = tonumber(Osi.GetLevel(Osi.GetHostCharacter()))
    if hostLevel then
        Ext.OnNextTick(function()
            Osi.SetLevel(entityGUID, hostLevel)
            RunesOfFaerun.Info('Set ' .. entityGUID .. ' level to ' .. hostLevel)
        end)
    end
end

---@param rootGUID guid
---@param instanceGUID guid
eh.HandleByGUID = function(rootGUID, instanceGUID)
    local companions = {
        [SLIMY_COMPANION_GUID] = true
    }

    if companions[rootGUID] then
        eh.SetEntityLevelToHostLevel(instanceGUID)
    else
        RunesOfFaerun.Info(rootGUID .. ' is not a known entity')
    end
end

RunesOfFaerun.EntityHandler = eh
