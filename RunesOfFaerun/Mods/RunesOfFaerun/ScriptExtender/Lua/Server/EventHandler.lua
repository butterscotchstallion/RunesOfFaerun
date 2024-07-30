--[[

Event Handler

--]]
local SPELL_STEAL_SUCCESS_SPELL_NAME = 'Target_SpellSteal_Success'

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

---@param caster GUIDSTRING
---@param spell string
---@param spellType string
---@param spellElement string
---@param storyActionID integer
local function OnCastedSpell(casterGUID, spellName, spellType, spellElement, storyActionID)
    if spellName == SPELL_STEAL_SUCCESS_SPELL_NAME then
        --[[
        RunesOfFaerun.Debug('Spell steal successful! Iterating interrupts')

        local entity = Ext.Entity.Get(caster)
        for _, interrupt in pairs(entity.InterruptContainer.Interrupts) do
            local interruptComponent = interrupt:GetAllComponents()

            if interruptComponent.InterruptData then
                --field_18 = Interrupt spell name
                --field_10 = Entity that casted the interrupt
                if interruptComponent.InterruptData.field_18 == 'Target_ROF_Spell_Steal' then
                    RunesOfFaerun.Debug('Found spell steal interrupt data, dumping...')
                    _D(interruptComponent)
                    --_D(interruptComponent.InterruptData.field_10:GetAllComponents())
                    --RunesOfFaerun.Utils.SaveEntityToFile(caster .. '_interrupt_data',
                    --    interruptComponent.InterruptData.field_10)
                end
            end
        end
        --]]
        --RunesOfFaerun.SpellHandler.OnSpellStealCasted()
    end
end

local function GetInterruptNameFromInterruptComponent(interruptComponent)
    if interruptComponent.InterruptData then
        --field_10 = Entity that casted the interrupt
        return interruptComponent.InterruptData.Spell
    end
end

local function OnInterruptActionStateCreated(state)
    --RunesOfFaerun.Utils.SaveEntityToFile("interrupt-state", state)
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
            RunesOfFaerun.Debug(spellSourceUUID .. ' casted ' .. interruptedSpell .. ' and was interrupted')
            break
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", OnEnteredLevel)
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", OnCastedSpell)
Ext.Entity.OnCreate("InterruptActionState", OnInterruptActionStateCreated, nil)
