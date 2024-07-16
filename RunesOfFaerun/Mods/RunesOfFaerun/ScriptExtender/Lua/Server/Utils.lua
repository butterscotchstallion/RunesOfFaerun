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

utils.SaveEntityToFile = SaveEntityToFile
utils.PrintVersionMessage = PrintVersionMessage
RunesOfFaerun.Utils = utils
