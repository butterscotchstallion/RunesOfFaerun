local th = {}

local function IsRottenFood(templateName)
    local lowerName = templateName:lower()
    local isRottenFood = lowerName:find("rotten")
    local isSpoiledFood = lowerName:find("spoiled")
    return isRottenFood or isSpoiledFood
end

---@param thrownObject entity
---@param target entity
---@param thrower entity
local function OnThrown(thrownObject, target, thrower)
    if thrownObject and target and thrower then
        local targetUUID = target.Uuid.EntityUuid
        --Not perfect but seems to be good enough based on vanilla items
        local thrownObjectName = Osi.ResolveTranslatedString(Osi.GetDisplayName(thrownObject.Uuid.EntityUuid))

        if thrownObjectName and IsRottenFood(thrownObjectName) then
            --Debug(string.format("%s is rotten/spoiled food", thrownObjectName))
            Osi.ApplyStatus(targetUUID, "STATUS_ROF_STACKABLE_SPLATTERED_1", 18)
        else
            Debug('"' .. thrownObjectName .. '" is not rotten?')
        end
    end
end

th.IsRottenFood = IsRottenFood
th.OnThrown = OnThrown

RunesOfFaerun.ThrownHandler = th
