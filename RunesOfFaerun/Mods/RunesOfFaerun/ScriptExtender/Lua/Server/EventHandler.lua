--[[

Event Handler

--]]
local SPELL_STEAL_SUCCESS_SPELL_NAME = 'Target_SpellSteal_Success'
local spellStealInfo = {
    spell = nil,
    enemy = nil,
    interrupter = nil
}
local spellStealSuccessCasted = false

local function OnSessionLoaded()
    RunesOfFaerun.Utils.PrintVersionMessage()

    --local entity = Ext.Entity.Get(Osi.GetHostCharacter())
    --local ec = entity:GetAllComponents()
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
        spellStealSuccessCasted = true
        local casterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(casterTpl)

        if spellStealInfo.spell and spellStealInfo.enemy then
            RunesOfFaerun.SpellHandler.OnSpellStealCasted(spellStealInfo.spell, casterGUID, spellStealInfo.enemy)
        else
            RunesOfFaerun.Critical('Error obtaining spell and enemy!')
        end
    end
end

local function GetInterruptNameFromInterruptComponent(interruptComponent)
    if interruptComponent.InterruptData then
        --field_10 = Entity that casted the interrupt
        return interruptComponent.InterruptData.Spell
    end
end

local function OnInterruptActionStateCreated(state)
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

            RunesOfFaerun.Utils.SaveEntityToFile(spellSourceUUID, Ext.Entity.Get(spellSourceUUID))

            --This is used when the counterspell succeeds
            spellStealInfo.spell = interruptedSpell
            spellStealInfo.enemy = spellSourceUUID

            --Interrupter
            --Target will be NULL if it's a projectile like Fireball
            if actionState.Event.Target then
                local interrupterComponents = actionState.Event.Target:GetAllComponents()
                local interrupterUUID = interrupterComponents.Uuid.EntityUuid
                local interrupterName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(interruptComponents)
                interrupterName = interrupterName .. '(' .. interrupterUUID .. ')'

                RunesOfFaerun.Debug(spellSourceName ..
                    ' casted ' .. interruptedSpell .. ' and was interrupted by ' .. interrupterName)
                break
            else
                RunesOfFaerun.Debug('ActionState.Event has no Target. Projectile?')
            end
        end
    end
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", OnEnteredLevel)
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", OnCastedSpell)
Ext.Entity.OnCreate("InterruptActionState", OnInterruptActionStateCreated, nil)
