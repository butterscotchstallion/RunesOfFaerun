local mvh = {}

Ext.Vars.RegisterModVariable(ModuleUUID, "Config", {})

local function GetConfig()
    local modVars = Ext.Vars.GetModVariables(ModuleUUID)
    local config = {}
    if modVars and modVars.Config then
        config = modVars.Config
    end
    return config
end

local function UpdateConfig(config)
    Ext.Vars.GetModVariables(ModuleUUID).Config = config
    RunesOfFaerun.Debug('Configuration updated!')
    _D(GetConfig())
end

mvh.GetConfig = GetConfig
mvh.UpdateConfig = UpdateConfig

RunesOfFaerun.ModVarsHandler = mvh
