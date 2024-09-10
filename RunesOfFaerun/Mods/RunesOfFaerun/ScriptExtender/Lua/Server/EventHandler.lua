--[[

Event Handler

--]]
local thrownObjCounter = 0
local spellStealInfo = {
    spell = nil,
    enemy = nil,
    interrupter = nil
}
local spellStealSuccessCasted = false

local function OnSessionLoaded()
    RunesOfFaerun.Utils.PrintVersionMessage()
    --RunesOfFaerun.QuestHandler.Initialize()
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

local function OnInterruptActionStateCreated(state, type, comp)
    Ext.OnNextTick(function()
        local interruptComponents = state:GetAllComponents()
        local actionState = interruptComponents.InterruptActionState

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
    end)
end

local function OnDying(characterGUID)
    --RunesOfFaerun.QuestHandler.OnDying(characterGUID)
end

local function OnCombatEnded(_)
    --[[
    Ext.Timer.WaitFor(4000, function()
        RunesOfFaerun.QuestHandler.OnCombatEnded()
    end, nil)
    ]]
    RunesOfFaerun.SpellHandler.ClearValidSpellCache()
    RunesOfFaerun.SpellHandler.ClearAmnesiaStatuses()
end

local function OnMessageBoxYesNoClosed(character, message, result)
    Debug(string.format('Message box closed: %s %s %s', character, message, result))
end

local function OnTemplateAddedTo(objectTemplate, templateId, inventoryHolder, addType)
    local isRune = RunesOfFaerun.HelpDialogHandler.IsRune(templateId)

    if isRune then
        RunesOfFaerun.HelpDialogHandler.OnRuneDiscovered(templateId, inventoryHolder)
    end

    if RunesOfFaerun.HelpDialogHandler.IsRunePouch(templateId) then
        RunesOfFaerun.HelpDialogHandler.OnRunePouchDiscovered(templateId, inventoryHolder)
    end

    if RunesOfFaerun.ItemSpawned then
        Debug(string.format('%s [%s] spawned', templateId, RunesOfFaerun.Utils.GetGUIDFromTpl(templateId)))
    end
end

local function OnStatusApplied(object, status, _, _)
    local characterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(object)

    if status == 'STATUS_ROF_TEMP_AMNESIA_TECHNICAL' then
        RunesOfFaerun.SpellHandler.HandleAmnesiaApplied(object)
    end

    if status == 'STATUS_ROF_TRANSFORMED' then
        RunesOfFaerun.SpellHandler.HandleDuplicitousTransformation(object)
    end

    if status == 'STATUS_APPLY_MUMMY_TRANSFORM' then
        RunesOfFaerun.Upgrader.SetMummyVisual(characterGUID)
    end

    if status == 'STATUS_APPLY_CRUSHING_FLIGHT' then
        RunesOfFaerun.Upgrader.AddBadgerCrushingFlightUpgrade()
    end

    if status == "STATUS_APPLY_PEACHY_RUNE" then
        local guid = RunesOfFaerun.Utils.GetGUIDFromTpl(object)
        local bigForeheadTattoo = "b27939ea-dd65-4119-982d-3bc693bd16de"
        local bigFaceTattoo = "1297c544-792a-4f82-9420-675f4c856012"
        local eyesTattoo = "1297c544-792a-4f82-9420-675f4c856012"
        local someTattoo = '15e83d34-ed3b-4979-8cbe-5aa4d4e30a92'
        RunesOfFaerun.Upgrader.ApplyMaterialOverride(guid, "e5b7d8df-a595-4e90-906a-7c3372e976f7")
    end

    if status == 'STATUS_ROF_GR_TECHNICAL' then
        RunesOfFaerun.SpellHandler.HandleGrimRenewalApplied(characterGUID)
    end

    if RunesOfFaerun.StackTracker.IsStackableStatus(status) then
        RunesOfFaerun.StackTracker.IncrementStacks(characterGUID, status)
    end
end

local function OnStatusRemoved(object, status, _, _)
    local characterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(object)

    if RunesOfFaerun.SpellHandler.IsAmnesiaStatus(status) then
        RunesOfFaerun.SpellHandler.HandleAmnesiaRemoved(characterGUID)
    end

    if RunesOfFaerun.StackTracker.IsStackableStatus(status) then
        RunesOfFaerun.StackTracker.DecrementStacks(characterGUID, status)
    end
end

local function OnLevelGameplayStarted(_, _)
    local summons = RunesOfFaerun.Utils.GetPlayerSummons()
    if summons and #summons > 0 then
        for _, characterGUID in pairs(summons) do
            RunesOfFaerun.Upgrader.ApplyMummyTransformationIfUnlocked(characterGUID)
        end
    end
end

local function OnShortRest()
    --[[
    Check for Runic Invigoration and if any party member has it,
    then heal all ROF summons to full.
    ]]
    if RunesOfFaerun.EntityHandler.HasRunicInvigoration() then
        RunesOfFaerun.EntityHandler.HealRunicSummonsToFull()
    end
end

local function OnHitThrownObjectCreated(entity)
    thrownObjCounter = thrownObjCounter + 1
    local thrownObjComponent = entity:GetAllComponents()
    _D(thrownObjComponent)
    local hitThrownObj = thrownObjComponent.HitThrownObject.ThrownObject

    RunesOfFaerun.Utils.SaveEntityToFile('thrown-obj-' .. thrownObjCounter, hitThrownObj)

    if thrownObjCounter == 3 then
        local thrownObjComponents = hitThrownObj:GetAllComponents()
        local deathComponent = thrownObjComponents.Death
        --_D(deathComponent.Target:GetAllComponents())
        RunesOfFaerun.Utils.SaveEntityToFile('death', deathComponent.Target)
    end
end

local function OnSpellCastStateDestroyed(spellEntity)
    if spellEntity.SpellCastState.SpellId.Prototype == "Throw_Throw" then
        local thrower = spellEntity.SpellCastState.Caster
        local primaryTarget = nil
        local thrownObject = nil
        local targets = spellEntity.SpellCastState.Targets
        if targets and targets[1] then
            if targets[1] and targets[1].Target then
                primaryTarget = targets[1].Target
            end
            if targets[1].Target2 then
                thrownObject = targets[1].Target2.Target
            end
        end

        RunesOfFaerun.ThrownHandler.OnThrown(thrownObject, primaryTarget, thrower)
    end
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
Ext.Osiris.RegisterListener("EnteredLevel", 3, "after", OnEnteredLevel)
Ext.Osiris.RegisterListener("CastedSpell", 5, "after", OnCastedSpell)
Ext.Osiris.RegisterListener("Dying", 1, "after", OnDying)
Ext.Osiris.RegisterListener("CombatEnded", 1, "after", OnCombatEnded)
Ext.Osiris.RegisterListener("StatusApplied", 4, "after", OnStatusApplied)
Ext.Osiris.RegisterListener("StatusRemoved", 4, "after", OnStatusRemoved)
Ext.Osiris.RegisterListener("MessageBoxYesNoClosed", 3, "after", OnMessageBoxYesNoClosed)
Ext.Osiris.RegisterListener("TemplateAddedTo", 4, "after", OnTemplateAddedTo)
Ext.Osiris.RegisterListener("LevelGameplayStarted", 2, "after", OnLevelGameplayStarted)
Ext.Osiris.RegisterListener("ShortRested", 1, "after", OnShortRest)
Ext.Entity.OnCreate("InterruptActionState", OnInterruptActionStateCreated, nil, nil, nil)
Ext.Entity.OnDestroy("SpellCastState", OnSpellCastStateDestroyed, nil, nil, nil)
