--[[

Event Handler

--]]
local spellState = {}
local SPELL_STEAL_SPELL_NAME = 'Target_ROF_Spell_Steal'

local function OnSessionLoaded()
    RunesOfFaerun.Utils.PrintVersionMessage()
end

local function OnEnteredLevel(templateName, rootGUID, level)
    local isKnownEntity = templateName:find('ROF_') == 1
    if isKnownEntity then
        RunesOfFaerun.Info('Handling ' .. templateName)
        local instanceGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(templateName)
        RunesOfFaerun.EntityHandler.HandleByGUID(rootGUID, instanceGUID)
    end
end

--[[
When spell steal is used, store the target for later use once
the spell has confirmed to have succeeded
--]]
local function OnUsingSpellOnTarget(caster, target, spell, spellType, spellElement, storyActionID)
    if spell == SPELL_STEAL_SPELL_NAME then
        spellState[caster] = target
    end
end

local function OnCastedSpell(caster, spell, spellType, spellElement, storyActionID)
    if spell == SPELL_STEAL_SPELL_NAME and spellState[caster] then
        spellState[caster] = nil

        local entity = Ext.Entity.Get(caster)
        for _, interrupt in pairs(entity.InterruptContainer.Interrupts) do
            local interruptComponent = interrupt:GetAllComponents()

            if interruptComponent.InterruptData then
                if interruptComponent.InterruptData.field_18 == 'Target_ROF_Spell_Steal' then
                    _D(interruptComponent)
                end
            end
        end
        --RunesOfFaerun.SpellHandler.OnSpellStealCasted()
    end
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", OnEnteredLevel)
Ext.Osiris.RegisterListener("UsingSpellOnTarget", 6, "after", OnUsingSpellOnTarget)
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", OnCastedSpell)
