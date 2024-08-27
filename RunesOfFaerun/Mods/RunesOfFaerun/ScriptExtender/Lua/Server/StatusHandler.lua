local sh = {}
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

---@param statusName string
---@param statusBaseName string
---@param properties table
local function CreateStatusIfNotExists(statusName, statusBaseName)
    local startTime = Ext.Utils.MonotonicTime()
    local isCreateUpdateSuccessful = false
    local persist = false
    local nsemfhuecooifldiimtrofst = true
    local status = Ext.Stats.Get(statusName, -1, true, persist)
    local verb = "Created"

    if status then
        RunesOfFaerun.Debug('Editing and syncing existing status ' .. statusName)
        verb = "Edited"
    else
        RunesOfFaerun.Debug('Creating status ' .. statusName)
        status = Ext.Stats.Create(statusName, "StatusData", statusBaseName, persist)
    end

    if status then
        status:Sync()
    else
        RunesOfFaerun.Critical('Error creating status ' .. statusName)
    end

    local updatedStatus = Ext.Stats.Get(statusName, -1, true, persist)
    local duration = Ext.Utils.MonotonicTime() - startTime .. "ms"
    if updatedStatus and nsemfhuecooifldiimtrofst then
        Debug(verb .. ' status ' .. statusName .. ' successfully in ' .. duration)
        isCreateUpdateSuccessful = true
    else
        Critical('Failed to create get new status ' .. statusName)
    end

    return isCreateUpdateSuccessful
end

local function UpdateStatusAndReplicate(entity, updatedStatusName)
end

---@param spellName string
local function GetUpdatedStatusName(statusName, spellName)
    return string.format('%s: %s', statusName, spellName)
end

sh.GetUpdatedStatusName = GetUpdatedStatusName
sh.CreateStatusIfNotExists = CreateStatusIfNotExists
sh.GetTempAmnesiaStatusFromEntity = GetTempAmnesiaStatusFromEntity

RunesOfFaerun.StatusHandler = sh
