--[[
#########################################
#           Runes of Faerun             #
#########################################
--]]
MOD_NAME = "RunesOfFaerun"
RunesOfFaerun = {
    logLevel = "INFO",
    Quests = {},
    ItemSpawned = false,
}

if Ext.Debug.IsDeveloperMode() then
    RunesOfFaerun.logLevel = "DEBUG"
end

Ext.Require('Server/Tags.lua')
Ext.Require('Server/MuffinLogger.lua')
Ext.Require('Server/Utils.lua')
Ext.Require('Server/Upgrader.lua')
Ext.Require('Server/EventHandler.lua')
Ext.Require('Server/EntityHandler.lua')
Ext.Require('Server/SpellHandler.lua')
Ext.Require('Server/SECommands.lua')
Ext.Require('Server/ModVarsHandler.lua')
Ext.Require('Server/HelpDialogHandler.lua')
Ext.Require('Server/StatusHandler.lua')
Ext.Require('Server/ThrownHandler.lua')
Ext.Require('Server/StatsReloader.lua')
Ext.Require('Server/StackTracker.lua')
Ext.Require('Server/ActionModifier.lua')

-- Specific quest event handlers
Ext.Require('Server/Quests/GrymforgeDuergarVsGnomes.lua')

Ext.Require('Server/QuestHandler.lua')
