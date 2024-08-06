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
    }
}

local function RegisterCommands()
    for _, command in ipairs(commands) do
        --RunesOfFaerun.Debug(string.format('Registered command "%s"', command.name))
        Ext.RegisterConsoleCommand(command.name, command.func)
    end
end

RegisterCommands()
