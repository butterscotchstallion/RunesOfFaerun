--[[
Commands for SE console
]]
local commands = {
    {
        --Credit: This command is based on code provided by FallenStar.
        name = 'DumpEntity',
        params = 'uuid, filename',
        ---@param cmd string
        ---@param uuid string
        ---@param filename string
        func = function(cmd, uuid, filename)
            local hostGUID = tostring(Osi.GetHostCharacter())
            if not uuid then
                uuid = hostGUID
            end
            local entity = Ext.Entity.Get(uuid)
            filename = (filename or uuid) .. '.json'
            --Will be saved under %localappdata%\Larian Studios\Baldur's Gate 3\Script Extender
            Ext.IO.SaveFile(filename, Ext.DumpExport(entity:GetAllComponents()))
            RunesOfFaerun.Debug(string.format('Saved dump file: %s', filename))
        end
    },
    {
        name = 'RemoveSpell',
        params = 'uuid, spellName',
        ---@param cmd string
        ---@param uuid string
        ---@param spellName string
        func = function(cmd, uuid, spellName)
            if uuid and spellName then
                local entity = Ext.Entity.Get(uuid)
                for _, interrupt in pairs(entity.InterruptContainer.Interrupts) do
                    _D(interrupt:GetAllComponents())
                end
                --RunesOfFaerun.SpellHandler.RemoveSpellFromAddedSpells(entity, spellName)
                RunesOfFaerun.SpellHandler.RemoveSpellFromSpellBook(entity, spellName)
            else
                RunesOfFaerun.Critical('Invalid arguments')
            end
        end
    },
    {
        name = 'spawncaster',
        params = '',
        func = function()
            RunesOfFaerun.EntityHandler.SpawnHostileSpellSlinger()
        end
    },
    {
        name = 'spawnrunepouch',
        params = '',
        func = function()
            RunesOfFaerun.Utils.SummonRunePouch()
        end
    },
    {
        name = 'resetquests',
        params = '',
        func = function()
            RunesOfFaerun.QuestHandler.ResetQuests()
        end
    },
    {
        name = 'spawnquestgiver',
        params = 'uuid',
        func = function(_, uuid)
            RunesOfFaerun.QuestHandler.SpawnQuestGiver(uuid)
        end
    },
    {
        name = 'showquests',
        params = '',
        func = function()
            RunesOfFaerun.QuestHandler.ShowQuests()
        end
    },
    {
        name = 'showincompletequests',
        params = '',
        func = function()
            RunesOfFaerun.QuestHandler.ShowIncompleteQuests()
        end
    },
    {
        name = 'killgrymforgeduegar',
        params = '',
        func = function()
            Osi.Die('472eba90-f5e8-48cb-ad55-2397e0013a2d', 16, Osi.GetHostCharacter(), 1, 1)
            Osi.Die('986cb3be-bb31-4aa8-85c0-1f9a315760af', 16, Osi.GetHostCharacter(), 1, 1)
            RunesOfFaerun.QuestHandler.OnCombatEnded()
        end
    },
    {
        name = 'showquestmap',
        params = '',
        func = function()
            _D(RunesOfFaerun.QuestHandler.GetNamedQuestHandlerMap())
        end
    },
    {
        name = 'resetrunediscoveries',
        params = '',
        func = function()
            RunesOfFaerun.HelpDialogHandler.ResetRuneDiscoveries()
        end
    },
    {
        name = 'amnesia',
        params = '',
        func = function()
            Osi.ApplyStatus(Osi.GetHostCharacter(), 'STATUS_ROF_AMNESIA', 10, 1)
        end
    }
}

local function RegisterCommands()
    for _, command in ipairs(commands) do
        --RunesOfFaerun.Debug(string.format('Registered command "%s"', command.name))
        Ext.RegisterConsoleCommand(command.name, command.func)
    end
end

RegisterCommands()
