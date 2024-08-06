local utils = {}

local function SaveEntityToFile(targetName, entity)
    --%localappdata%\Larian Studios\Baldur's Gate 3\Script Extender
    local filename = targetName .. ".json"
    Ext.IO.SaveFile(filename, Ext.DumpExport(entity:GetAllComponents()))
    RunesOfFaerun.Info('Saved target entity to %localappdata%\\Larian Studios\\Baldur\'s Gate 3\\Script Extender\\' ..
        filename)
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

---@param tplId string Root Template string
local function GetGUIDFromTpl(tplId)
    return string.sub(tplId, -36)
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

utils.SummonRunePouch = SummonRunePouch
utils.SaveEntityToFile = SaveEntityToFile
utils.PrintVersionMessage = PrintVersionMessage
utils.GetGUIDFromTpl = GetGUIDFromTpl
utils.GetDisplayNameFromEntity = GetDisplayNameFromEntity

RunesOfFaerun.Utils = utils
