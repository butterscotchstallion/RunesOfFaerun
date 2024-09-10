--[[

September 9th 2024 - Not yet implemented in SE, for now :(

]]
local am = {}
local ACTION_TYPES = {
    CONSUME = 7
}
--ServerItem.Template.OnUsePeaceActions
local function GetOnUsePeaceActionForConsume(statusOnConsume)
    return {
        Animation = "",
        Conditions = "",
        Consume = true,
        IsHiddenStatus = false,
        StatsId = statusOnConsume,
        StatusDuration = 10,
        Type = "Consume"
    }
end

local function AddConsumeAction(objectGUID)
    local entity = Ext.Entity.Get(objectGUID)

    if entity then
        --Add actions
        --[[
        "ActionType" :
        {
            "ActionTypes" :
            [
                7
            ]
        }
        ]]
        local ec = entity:GetAllComponents()
        ec.Health.Hp = 500
        local actionTypes = Ext.Types.Serialize(ec.ActionType.ActionTypes)
        --ec.ActionType.ActionTypes[#ec.ActionType.ActionTypes + 1] = GetOnUsePeaceActionForConsume('DRUNK')
        --actionTypes[#actionTypes + 1] = GetOnUsePeaceActionForConsume('DRUNK')
        table.insert(actionTypes, 7)
        ec.ActionType.ActionTypes = actionTypes

        --UseAction
        local useActionsComponent = entity:GetComponent('UseAction')

        if useActionsComponent then
            local actions = Ext.Types.Serialize(useActionsComponent.UseActions)

            actions[#actions + 1] = GetOnUsePeaceActionForConsume('DRUNK')

            entity.UseAction.UseActions = actions

            entity:Replicate('UseAction')
            entity:Replicate('Health')

            Debug('Added action')
        else
            Debug('No use actions for entity')
        end
    else
        Critical('Failed to get entity!')
    end
end

am.AddConsumeAction = AddConsumeAction

RunesOfFaerun.ActionModifier = am
