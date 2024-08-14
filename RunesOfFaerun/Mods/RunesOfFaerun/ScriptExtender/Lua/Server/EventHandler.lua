--[[

Event Handler

--]]
local spellStealInfo = {
    spell = nil,
    enemy = nil,
    interrupter = nil
}
local spellStealSuccessCasted = false

local function OnSessionLoaded()
    RunesOfFaerun.Utils.PrintVersionMessage()
    RunesOfFaerun.QuestHandler.Initialize()
end

local function OnEnteredLevel(templateName, rootGUID, level)
    local isKnownEntity = templateName:find('ROF_') == 1
    if isKnownEntity then
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
    if spellName == 'Target_SpellSteal_Success' then
        spellStealSuccessCasted = true
        local casterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(casterTpl)

        if spellStealInfo.spell and spellStealInfo.enemy then
            --TODO: check this, it often doesn't seem to be available
            if spellStealInfo.spellSourceUUID then
                local caster = Ext.Entity.Get(spellStealInfo.spellSourceUUID)
                local casterName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(caster)
                local interrupterName = 'Unknown (Projectile)'
                if spellStealInfo.interrupterUUID then
                    local interrupter = Ext.Entity.Get(spellStealInfo.interrupterUUID)
                    interrupterName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(interrupter)
                end
                RunesOfFaerun.Debug(casterName ..
                    ' casted ' .. spellStealInfo.spell .. ' and was interrupted by ' .. interrupterName)
            end

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

    --Debug('Interrupt action state created')
    --RunesOfFaerun.Utils.SaveEntityToFile('interrupt-08-12', state)

    if actionState then
        local actions = actionState.Actions
        for _, action in pairs(actions) do
            local interruptName = GetInterruptNameFromInterruptComponent(action.Interrupt:GetAllComponents())

            if interruptName == "Target_ROF_Spell_Steal" then
                local event = actionState.Event.Event
                local interruptedSpell = event.Spell.OriginatorPrototype

                --Enemy caster
                local spellSourceComponents = actionState.Event.Source:GetAllComponents()
                local spellSourceUUID = spellSourceComponents.Uuid.EntityUuid

                --This is used if/when the counterspell succeeds
                spellStealInfo.spell = interruptedSpell
                spellStealInfo.enemy = spellSourceUUID
                spellStealInfo.interrupterUUID = nil

                --Interrupter
                --Target will be NULL if it's a projectile like Fireball
                if actionState.Event.Target then
                    local interrupterComponents = actionState.Event.Target:GetAllComponents()
                    local interrupterUUID = interrupterComponents.Uuid.EntityUuid
                    spellStealInfo.interrupterUUID = interrupterUUID
                else
                    RunesOfFaerun.Debug('ActionState.Event has no Target. Projectile?')
                end

                break
            end
        end
    else
        Critical(
            'InterruptActionState does not have expected structure! Spellsteal will not be able to acquire the interrupted spell :(')
    end
end

local function OnDying(characterGUID)
    RunesOfFaerun.QuestHandler.OnDying(characterGUID)
end

local function OnCombatEnded(_)
    Ext.Timer.WaitFor(4000, function()
        RunesOfFaerun.QuestHandler.OnCombatEnded()
    end, nil)
end

local function OnStatusApplied(object, status, causee, storyActionID)
    --RunesOfFaerun.QuestHandler.CheckIfQuestAuraAffectsPartyMember(object)

    if status == 'ROF_AMNESIA' then
        RunesOfFaerun.SpellHandler.HandleAmnesia(object)
    end
end

local function OnMessageBoxYesNoClosed(character, message, result)
    Debug(string.format('Message box closed: %s %s %s', character, message, result))
end

local function OnTemplateAddedTo(objectTemplate, object2, inventoryHolder, addType)
    local isRune = RunesOfFaerun.HelpDialogHandler.IsRune(object2)

    if isRune then
        RunesOfFaerun.HelpDialogHandler.OnRuneDiscovered(object2, inventoryHolder)
    end
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", OnEnteredLevel)
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", OnCastedSpell)
Ext.Osiris.RegisterListener("Dying", 1, "after", OnDying)
Ext.Osiris.RegisterListener("CombatEnded", 1, "after", OnCombatEnded)
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", OnStatusApplied)
Ext.Osiris.RegisterListener("MessageBoxYesNoClosed", 3, "after", OnMessageBoxYesNoClosed)
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", OnTemplateAddedTo)
Ext.Entity.OnCreate("InterruptActionState", OnInterruptActionStateCreated, nil)
