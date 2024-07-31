--[[

Spell Handler

--]]
local sh = {
    addedSpells = {
        --GUID -> spell
    }
}

---@param entity table
---@param spellName string
local function RemoveSpellFromAddedSpells(entity, spellName)
    if entity.AddedSpells then
        if entity.AddedSpells.Spells and #entity.AddedSpells.Spells > 0 then
            local spellExists = false
            local addedSpells = entity.AddedSpells.Spells
            local filteredSpells = {}
            for _, spell in pairs(addedSpells) do
                if spell.SpellId.OriginatorPrototype == spellName then
                    spellExists = true
                    break
                else
                    if spell and spell.SpellId then
                        table.insert(filteredSpells, spell)
                    end
                end
            end

            if spellExists then
                RunesOfFaerun.Info('Found spell "' .. spellName .. '"!')
                RunesOfFaerun.Info('Setting filtered spells and replicating: ')

                entity.addedSpells.Spells = filteredSpells
                entity:Replicate('AddedSpells')
            else
                RunesOfFaerun.Debug('Spell "' .. spellName .. '" does not exist in AddedSpells')
            end
        else
            RunesOfFaerun.Debug('Added spells exists but is empty')
        end
    else
        RunesOfFaerun.Critical('Entity has no AddedSpells!')
    end
end

---@param entity table
---@param spellName string
local function RemoveSpellFromSpellBook(entity, spellName)
    if entity.SpellBook then
        local spellExists = false
        for i, spell in pairs(entity.SpellBook.Spells) do
            if spell.Id.OriginatorPrototype == spellName then
                entity.SpellBook.Spells[i] = nil
                spellExists = true
                break
            end
        end

        if spellExists then
            entity:Replicate('SpellBook')
            RunesOfFaerun.Info('Found spell "' .. spellName .. '" and replicated!')
        else
            RunesOfFaerun.Critical('Spell "' .. spellName .. '" does not exist in SpellBook')
        end
    else
        RunesOfFaerun.Critical('Entity has no SpellBook')
    end
end

---@param entity table
---@param spellName string
local function RemoveSpellFromSpellBookPrepares(entity, spellName)

end

---@param entity table
---@param spellName string
local function RemoveSpellFromSpellContainer(entity, spellName)

end

--Removes spell from several areas at once
local function RemoveSpellFromEntity(guid, entity, spellName)
    RunesOfFaerun.Debug('Removing spell "' .. spellName .. '" from ' .. guid)

    RemoveSpellFromSpellBook(entity, spellName)
    RemoveSpellFromAddedSpells(entity, spellName)
    --sh.addedSpells[guid] = nil
end

---Apply unlock status with new spell for one turn
---@param guid GUIDSTRING
---@param spellName string
local function AddSpell(guid, spellName)
    Osi.AddSpell(guid, spellName, 1, 1)

    if not sh.addedSpells[guid] then
        sh.addedSpells[guid] = {}
    end

    --[[
    This structure allows us to easily check if a spell
    has been added and eliminates the possibility of
    duplicates
    --]]
    sh.addedSpells[guid][spellName] = true
end

---Delays a function call for a given number of ticks.
---Server runs at a target of 30hz, so each tick is ~33ms and 30 ticks is ~1 second. This IS synced between server and client.
---Credit: Cephelos @ Larian
---@param ticks integer
---@param fn function
local function SP_DelayCallTicks(ticks, fn)
    local ticksPassed = 0
    local eventID
    eventID = Ext.Events.Tick:Subscribe(function()
        ticksPassed = ticksPassed + 1
        if ticksPassed >= ticks then
            fn()
            Ext.Events.Tick:Unsubscribe(eventID)
        end
    end)
end

---@param unlockSpellName string
local function GetUnlockSpellBoost(unlockSpellName)
    --[[
    data "Boosts" "UnlockSpellVariant(SpellId('Projectile_Jump'),ModifyUseCosts(Replace,BonusActionPoint,0,0,BonusActionPoint))"

    to my understanding, it's
    ModifyUseCosts(Replace, [new resource], [amount of new resource], [something about spell slots], [resource being replaced])

    "UnlockSpellVariant(
        GreaterNecromancySpellFilter(),
        ModifyIconGlow(),
        ModifyTooltipDescription(),
        ModifyUseCosts(Replace,SpellSlot,0,-1,SpellSlot),
        ModifyUseCosts(Replace,WarlockSpellSlot,0,-1,WarlockSpellSlot),
        ModifyUseCosts(Replace,SpellSlotsGroup,0,-1,SpellSlotsGroup)
    )
    --]]
    local unlockBoost = ''
    unlockBoost = unlockBoost .. "UnlockSpell('" .. unlockSpellName .. "');"
    unlockBoost = unlockBoost .. "UnlockSpellVariant("
    unlockBoost = unlockBoost .. string.format("SpellId('%s')),", unlockSpellName)
    unlockBoost = unlockBoost .. 'ModifyUseCosts(Replace,SpellSlot,0,-1,SpellSlot)'
    unlockBoost = unlockBoost .. ")"
    return unlockBoost
end

--[[
Creates a new status that unlocks the stolen spell with no
use cost
]]
---@param characterGUID GUIDSTRING
---@param unlockSpell string
local function UnlockStolenSpell(characterGUID, unlockSpell)
    local persist = false
    local statusName = "ROF_STOLEN_SPELL_UNLOCK_" .. unlockSpell
    local statusBase = 'STATUS_ROF_STOLEN_SPELL_UNLOCK_BASE'
    local status = Ext.Stats.Get(statusName, -1, true, false)

    if not status then
        status = Ext.Stats.Create(statusName, "StatusData", statusBase, persist)
        status.SyncStat()
    end

    status.Boosts = GetUnlockSpellBoost(unlockSpell)
    status:Sync()

    RunesOfFaerun.Debug('Unlock boost: ' .. status.Boosts)

    SP_DelayCallTicks(6, function()
        RunesOfFaerun.Debug('Applied unlock status "' .. statusName .. '" to ' .. characterGUID)
        Osi.ApplyStatus(characterGUID, statusName, 5)
    end)
end

--[[
- Remove Spell from caster
- Add the spell to the target
--]]
---@param spellName GUIDSTRING
---@param casterGUID GUIDSTRING
---@param enemyGUID GUIDSTRING
local function OnSpellStealCasted(spellName, casterGUID, enemyGUID)
    --NOTE: seems like we shouldn't actually remove it, and the counterspell
    --addresses the detail of preventing it from being casted
    --AddSpell(casterGUID, spellName)
    RunesOfFaerun.Debug('Spell steal casted, sending ' .. spellName)
    UnlockStolenSpell(casterGUID, spellName)
end

--[[
Removes any spells that were stolen after each turn has ended
--]]
local function RemoveStolenSpells(guid)
    if sh.addedSpells[guid] then
        RunesOfFaerun.Debug('Removing stolen spells for ' .. guid)

        local entity = Ext.Entity.Get(guid)

        for spell, _ in pairs(sh.addedSpells) do
            RemoveSpellFromEntity(guid, entity, spell)
        end
    end
end

--sh.RemoveStolenSpells = RemoveStolenSpells
sh.RemoveSpellFromSpellContainer = RemoveSpellFromSpellContainer
sh.RemoveSpellFromSpellBook = RemoveSpellFromSpellBook
sh.RemoveSpellFromAddedSpells = RemoveSpellFromAddedSpells
sh.OnSpellStealCasted = OnSpellStealCasted

RunesOfFaerun.SpellHandler = sh
