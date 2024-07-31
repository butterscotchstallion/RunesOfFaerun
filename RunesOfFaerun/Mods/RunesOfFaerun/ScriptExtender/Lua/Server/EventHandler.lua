--[[

Event Handler

--]]
local SPELL_STEAL_SUCCESS_SPELL_NAME = 'Target_SpellSteal_Success'
local spellStealInfo = {
    spell = nil,
    enemy = nil,
    interrupter = nil
}

local function OnSessionLoaded()
    RunesOfFaerun.Utils.PrintVersionMessage()
end

local function OnEnteredLevel(templateName, rootGUID, level)
    local isKnownEntity = templateName:find('ROF_') == 1
    if isKnownEntity then
        --RunesOfFaerun.Info('Handling ' .. templateName)
        local instanceGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(templateName)
        RunesOfFaerun.EntityHandler.HandleByGUID(rootGUID, instanceGUID)
    end
end

---@param caster string (template name)
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
local function OnCastedSpell(casterTpl, spellName, spellType, spellElement, storyActionID)
    if spellName == SPELL_STEAL_SUCCESS_SPELL_NAME then
        local casterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(casterTpl)
        RunesOfFaerun.SpellHandler.OnSpellStealCasted(spellStealInfo.spell, casterGUID, spellStealInfo.enemy)
    end
end

local function GetInterruptNameFromInterruptComponent(interruptComponent)
    if interruptComponent.InterruptData then
        --field_10 = Entity that casted the interrupt
        return interruptComponent.InterruptData.Spell
    end
end

local function OnInterruptActionStateCreated(state)
    RunesOfFaerun.Debug('InterruptActionState created!')

    local interruptComponents = state:GetAllComponents()
    local actionState = interruptComponents.InterruptActionState
    local actions = actionState.Actions
    for _, action in pairs(actions) do
        local interruptName = GetInterruptNameFromInterruptComponent(action.Interrupt:GetAllComponents())

        if interruptName == "Target_ROF_Spell_Steal" then
            local event = actionState.Event.Event
            local interruptedSpell = event.Spell.OriginatorPrototype

            --Enemy caster
            local spellSourceComponents = actionState.Event.Source:GetAllComponents()
            local spellSourceUUID = spellSourceComponents.Uuid.EntityUuid
            local spellSourceName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(spellSourceComponents)
            spellSourceName = spellSourceName .. ' (' .. spellSourceUUID .. ')'

            --Interrupter
            local interrupterComponents = actionState.Event.Target:GetAllComponents()
            local interrupterUUID = interrupterComponents.Uuid.EntityUuid
            local interrupterName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(interruptComponents)
            interrupterName = interrupterName .. '(' .. interrupterUUID .. ')'

            --This is used when the counterspell succeeds
            spellStealInfo.spell = interruptedSpell
            spellStealInfo.enemy = spellSourceUUID

            RunesOfFaerun.Debug(spellSourceName ..
                ' casted ' .. interruptedSpell .. ' and was interrupted by ' .. interrupterName)
            break
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", OnEnteredLevel)
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", OnCastedSpell)
Ext.Entity.OnCreate("InterruptActionState", OnInterruptActionStateCreated, nil)
