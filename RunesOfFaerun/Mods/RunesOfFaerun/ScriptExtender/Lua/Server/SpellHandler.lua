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
end

---Delays a function call for a given number of ticks.
---Server runs at a target of 30hz, so each tick is ~33ms and 30 ticks is ~1 second.
---This IS synced between server and client.
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

--Returns the boost to unlock the spell
---@param unlockSpellName string
local function GetUnlockSpellBoost(unlockSpellName)
    --[[
    Examples
    ------------------------------------------------------------------
    data "Boosts" "UnlockSpellVariant(
        SpellId('Projectile_Jump'),
        ModifyUseCosts(Replace,BonusActionPoint,0,0,BonusActionPoint)
    )"

    ModifyUseCosts(
        Replace,
        [new resource],
        [amount of new resource],
        [something about spell slots],
        [resource being replaced]
    )

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
    unlockBoost = unlockBoost .. "UnlockSpell(" .. unlockSpellName .. ");"
    unlockBoost = unlockBoost .. "UnlockSpellVariant("
    unlockBoost = unlockBoost .. string.format("SpellId('%s'),", unlockSpellName)
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
    local persist = true
    local statusName = 'ROF_STOLEN_SPELL_UNLOCK_' .. unlockSpell
    local statusBase = 'STATUS_ROF_STOLEN_SPELL_UNLOCK_BASE'
    local status = Ext.Stats.Get(statusName, -1, true, persist)

    if status then
        RunesOfFaerun.Debug('Editing and syncing existing status ' .. statusName)
    else
        RunesOfFaerun.Debug('Creating status ' .. statusName)
        status = Ext.Stats.Create(statusName, "StatusData", statusBase, persist)
    end

    if status then
        status.Boosts = GetUnlockSpellBoost(unlockSpell)
    else
        RunesOfFaerun.Debug('Error creating status ' .. statusName)
    end

    status:Sync()

    --RunesOfFaerun.Debug('Unlock boost: ' .. status.Boosts)

    --SP_DelayCallTicks(1, function()
    local updatedStatus = Ext.Stats.Get(statusName, -1, true, persist)
    if updatedStatus then
        Osi.ApplyStatus(characterGUID, statusName, 1)
        RunesOfFaerun.Debug('Applied unlock status "' .. statusName .. '" to ' .. characterGUID)
    else
        RunesOfFaerun.Debug('Status doesnt exist yet?')
    end
    --end)
end

--[[
{
        "Amount" : 1.0,
        "ResourceGroup" : "03b17647-161a-42e1-9660-5ba517e80ad2",
        "Resources" :
        [
                "d136c5d9-0ff0-43da-acce-a74a07f8d6bf", <-- spell slot
                "e9127b70-22b7-42a1-b172-d02f828f260a",
                "77fcde9b-9cda-4fbc-8806-393e26b2f3e1",
                "89cc7450-2fc1-42a4-a525-abe61e1957be"
        ],
        "SubResourceId" : 3 <--- level of spell slot
}
--]]
---Replace this with map
---@param resourceUUID UUID
---@param useCosts table
local function GetResourceInfoByResourceUUID(useCosts)
    local resourceMap = {}
    for _, resource in pairs(useCosts) do
        if resource.Resources then
            for _, uuid in pairs(resource.Resources) do
                resourceMap[uuid] = {
                    amount = resource.Amount,
                    level = resource.SubResourceId
                }
            end
        end
    end
    return resourceMap
end

---@param spellName string
local function GetSpellUseCostsResources(spellName)
    local cachedSpell = Ext.Stats.GetCachedSpell(spellName)
    if cachedSpell then
        local cachedSpellUseCosts = cachedSpell.UseCosts
        local resourceMap = GetResourceInfoByResourceUUID(cachedSpellUseCosts)
        local spellCosts = {}

        for _, resourceInfo in pairs(cachedSpellUseCosts) do
            if resourceInfo.Resources then
                for _, resourceUUID in pairs(resourceInfo.Resources) do
                    local staticActionResources = Ext.StaticData.Get(resourceUUID, "ActionResource")

                    --We only want spell resources here
                    if staticActionResources and staticActionResources.IsSpellResource then
                        spellCosts[resourceUUID] = resourceMap[resourceUUID]
                    end
                end
            else
                RunesOfFaerun.Debug('No resources!')
            end
        end

        --Sort so that spell slots come first, since those are most likely
        --to be the resource used
        table.sort(spellCosts, function(a, b) return a > b end)

        return spellCosts
    else
        RunesOfFaerun.Debug('Cached spell not found: ' .. spellName)
    end
end

--[[
Modifies spell slots based on the use cost of the spell that was casted

1. Get resource UUIDs based on spell
2. Modify the first one we find on the
entity's action resources
3. Replicate
4. Print updated resources to confirm

NOTE: also explore getting the preferred casting resource from the spellbook
if the entity has the spell
--]]
local function ModifyEntitySpellSlots(spellName, entityGUID)
    local spellCosts = GetSpellUseCostsResources(spellName)
    local entity = Ext.Entity.Get(entityGUID)

    if entity then
        local ec = entity:GetComponent('ActionResources')
        if ec and ec.Resources then
            local resources = ec.Resources
            local updatedResource = false

            --Iterate resources and modify the first one that has
            --one of the resources in UseCosts
            for resourceUUID, resourceInfo in pairs(spellCosts) do
                if resources[resourceUUID] then
                    RunesOfFaerun.Debug('Resource ' .. resourceUUID .. ' exists')

                    for _, resource in pairs(resources[resourceUUID]) do
                        if resource.ResourceUUID == resourceUUID and resource.Level == resourceInfo.level then
                            local oldResourceValue = resource.Amount
                            local newResourceValue = math.abs(oldResourceValue - resourceInfo.amount)
                            resource.Amount = newResourceValue
                            entity:Replicate('ActionResources')

                            RunesOfFaerun.Debug(
                                string.format('Changed resource %s (%s) from %s to %s',
                                    resource.ResourceUUID,
                                    resource.Level,
                                    oldResourceValue,
                                    newResourceValue
                                )
                            )
                            updatedResource = true
                            break
                        end
                    end
                end

                if updatedResource then
                    break
                end
            end

            if not updatedResource then
                RunesOfFaerun.Debug('Could not find/update resource on entity ' .. entityGUID .. '!')
            end
        else
            RunesOfFaerun.Critical('Could not get action resources for ' .. entityGUID)
        end
    else
        RunesOfFaerun.Critical('Could not get caster entity to modify action resources!')
    end
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
    UnlockStolenSpell(casterGUID, spellName)
    ModifyEntitySpellSlots(spellName, enemyGUID)
end

sh.RemoveSpellFromSpellContainer = RemoveSpellFromSpellContainer
sh.RemoveSpellFromSpellBook = RemoveSpellFromSpellBook
sh.RemoveSpellFromAddedSpells = RemoveSpellFromAddedSpells
sh.OnSpellStealCasted = OnSpellStealCasted

RunesOfFaerun.SpellHandler = sh
