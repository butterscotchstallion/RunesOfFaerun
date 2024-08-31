local utils = {}

local function SaveEntityToFile(targetName, entity)
    if entity then
        --%localappdata%\Larian Studios\Baldur's Gate 3\Script Extender
        local filename = targetName .. ".json"
        Ext.IO.SaveFile(filename, Ext.DumpExport(entity:GetAllComponents()))
        RunesOfFaerun.Info('Saved target entity to %localappdata%\\Larian Studios\\Baldur\'s Gate 3\\Script Extender\\' ..
            filename)
    else
        Critical('Attempted to save entity file for nil entity!')
    end
end

local function PrintVersionMessage()
    local mod = Ext.Mod.GetMod(ModuleUUID)
    if mod then
        local version    = mod.Info.ModVersion
        local versionMsg = string.format(
            MOD_NAME .. ' v%s.%s.%s loaded!',
            version[1],
            version[2],
            version[3]
        )
        RunesOfFaerun.Info(versionMsg)
    end
end

---@return table table of UUIDs
local function GetPlayerSummons()
    --Returns table of template names
    local rows = Osi.DB_PlayerSummons:Get(nil)
    local summons = {}
    if rows and #rows > 0 then
        for _, row in pairs(rows) do
            table.insert(summons, RunesOfFaerun.Utils.GetGUIDFromTpl(row[1]))
        end
    end
    return summons
end

---@param tplId string Root Template string
local function GetGUIDFromTpl(tplId)
    return string.sub(tplId, -36)
end

local function GetEntityFromTpl(tplId)
    local uuid = RunesOfFaerun.Utils.GetGUIDFromTpl(tplId)

    if uuid and string.len(uuid) == 36 then
        return Ext.Entity.Get(uuid)
    else
        Critical('Could not get UUID from tpl ' .. tplId)
    end
end

local function GetTagMapFromEntity(entity)
    local tagMap = {}
    if entity and entity.Tag then
        local tags = entity.Tag.Tags
        for _, tagUUID in pairs(tags) do
            tagMap[tagUUID] = true
        end
    else
        Critical('Could not get entity tags')
    end
    return tagMap
end

local function GetTagMapByTplId(tplId)
    local entity = GetEntityFromTpl(tplId)
    return GetTagMapFromEntity(entity)
end

local function GetDisplayNameFromEntity(entity)
    local name = "Unknown"
    if entity.ServerDisplayNameList and entity.ServerDisplayNameList.Names and entity.ServerDisplayNameList.Names[2] then
        name = entity.ServerDisplayNameList.Names[2].Name
    elseif entity and entity.Data and entity.Data.StatsId then
        name = entity.Data.StatsId
    end
    return name
end

local function SummonRunePouch()
    RunesOfFaerun.Debug('Spawning Rune Pouch!')
    Osi.TemplateAddTo("74477542-5ad9-4907-9c1d-e9ef90b26b06", Osi.GetHostCharacter(), 1, 1)
end

utils.GetTagMapFromEntity = GetTagMapFromEntity
utils.GetPlayerSummons = GetPlayerSummons
utils.GetTagMapByTplId = GetTagMapByTplId
utils.SummonRunePouch = SummonRunePouch
utils.SaveEntityToFile = SaveEntityToFile
utils.PrintVersionMessage = PrintVersionMessage
utils.GetGUIDFromTpl = GetGUIDFromTpl
utils.GetDisplayNameFromEntity = GetDisplayNameFromEntity

RunesOfFaerun.Utils = utils
