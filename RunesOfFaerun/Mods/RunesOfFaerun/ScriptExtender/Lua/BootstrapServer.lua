--[[
#########################################
#           Runes of Faerun             #
#########################################
--]]
MOD_NAME = "RunesOfFaerun"
RunesOfFaerun = {
    logLevel = 'DEBUG',
    Quests = {}
}

Ext.Require('Server/Tags.lua')
Ext.Require('Server/MuffinLogger.lua')
Ext.Require('Server/Utils.lua')
Ext.Require('Server/CosmeticHandler.lua')
Ext.Require('Server/EventHandler.lua')
Ext.Require('Server/EntityHandler.lua')
Ext.Require('Server/SpellHandler.lua')
Ext.Require('Server/SECommands.lua')
Ext.Require('Server/ModVarsHandler.lua')
Ext.Require('Server/HelpDialogHandler.lua')
Ext.Require('Server/StatusHandler.lua')

-- Specific quest event handlers
Ext.Require('Server/Quests/GrymforgeDuergarVsGnomes.lua')

Ext.Require('Server/QuestHandler.lua')
