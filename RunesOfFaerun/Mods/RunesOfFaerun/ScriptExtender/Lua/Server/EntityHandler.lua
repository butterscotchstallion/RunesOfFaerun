local eh = {}

SLIMY_COMPANION_GUID = '6e831db4-2531-48a8-ab87-445c5b0032a8'
NURSE_COMPANION_GUID = '027611f4-16bf-45f2-a782-ed5606bd676d'

eh.GetHostEntityMaxHP = function()
    local entity = Ext.Entity.Get(Osi.GetHostCharacter())
    if entity then
        if entity.Health then
            return entity.Health.MaxHp
        end
    end
end

eh.SetEntityHP = function(guid, hpValue)
    local entity = Ext.Entity.Get(guid)
    if entity and entity.Health then
        entity.Health.MaxHp = hpValue
        entity.Health.Hp = hpValue
        entity:Replicate('Health')
        RunesOfFaerun.Info('Set ' .. guid .. ' HP to ' .. hpValue)
    else
        RunesOfFaerun.Critical('Could not set HP of ' .. guid)
    end
end

eh.SetEntityMaxHPToHostMaxHP = function(entityGUID)
    local hostHP = eh.GetHostEntityMaxHP()
    if hostHP then
        eh.SetEntityHP(entityGUID, hostHP)
    end
end

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
        [SLIMY_COMPANION_GUID] = true,
        [NURSE_COMPANION_GUID] = true
    }

    if companions[rootGUID] then
        eh.SetEntityLevelToHostLevel(instanceGUID)
    else
        RunesOfFaerun.Info(rootGUID .. ' is not a known entity')
    end
end

RunesOfFaerun.EntityHandler = eh
