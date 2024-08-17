local su = {}
local TEMP_AMNESIA_STATUS = 'STATUS_ROF_TEMP_AMNESIA'

--This has a StackId so there should only be one on an entity
local function GetTempAmnesiaStatusFromEntity(entity)
    local status = nil
    if entity then
        local statusContainer = entity.StatusContainer

        if statusContainer then
            for statusEntityName, statusName in pairs(statusContainer.Statuses) do
                if statusName == TEMP_AMNESIA_STATUS then
                    local statusComponents = statusEntityName
                    RunesOfFaerun.Utils.SaveEntityToFile('amnesia-status-components', statusComponents)
                    break
                end
            end
        end
    end
    return status
end

local function UpdateStatusAndReplicate(entity, updatedStatusName)

end

---@param spellName string
local function GetUpdatedStatusName(statusName, spellName)
    return string.format('%s: %s', statusName, spellName)
end

su.GetTempAmnesiaStatusFromEntity = GetTempAmnesiaStatusFromEntity

RunesOfFaerun.StatusUpdater = su
