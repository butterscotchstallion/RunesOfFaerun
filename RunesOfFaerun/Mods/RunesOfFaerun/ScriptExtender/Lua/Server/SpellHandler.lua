--[[

Spell Handler

--]]
local sh = {
    addedSpells = {
        --GUID -> spell
    },
    amnesiaSpells = {

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
---@return spell The spell that was removed
local function RemoveSpellFromSpellBook(entity, spellName)
    if entity.SpellBook then
        local foundSpell = nil
        for i, spell in pairs(entity.SpellBook.Spells) do
            if spell.Id.OriginatorPrototype == spellName then
                foundSpell = spell
                entity.SpellBook.Spells[i] = nil
                break
            end
        end

        if foundSpell then
            entity:Replicate('SpellBook')
            RunesOfFaerun.Info('RemoveFromSpellBook: Found spell "' .. spellName .. '" and replicated!')
            return foundSpell
        else
            RunesOfFaerun.Critical('RemoveFromSpellBook: Spell "' .. spellName .. '" does not exist in SpellBook')
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

local function AddSpellToSpellBook(entity, spell)
    if entity.SpellBook then
        local spellName = spell.Id.OriginatorPrototype
        entity.SpellBook.Spells[#entity.SpellBook.Spells + 1] = spell
        entity:Replicate('SpellBook')
        RunesOfFaerun.Info('Added spell "' ..
            spellName .. '" to ' .. RunesOfFaerun.Utils.GetDisplayNameFromEntity(entity))
    else
        RunesOfFaerun.Critical('Entity has no SpellBook')
    end
end

---@param characterGUID GUIDSTRING
---@param entity entity
---@param spell spell
--Removes spell from several areas at once
local function RemoveSpellFromEntity(characterGUID, entity, spell)
    local spellName = spell.Id.OriginatorPrototype
    --RunesOfFaerun.Debug('Removing spell "' .. spellName .. '" from ' .. characterGUID)

    return RemoveSpellFromSpellBook(entity, spellName)
    --RemoveSpellFromAddedSpells(entity, spellName)
    --RemoveSpellFromSpellBookPrepares(entity, spellName)
    --RemoveSpellFromSpellContainer(entity, spellName)
end

---@param characterGUID GUIDSTRING
---@param entity entity
---@param spellName string
local function AddSpellToEntity(characterGUID, entity, spell)
    AddSpellToSpellBook(entity, spell)
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
    local nsemfhuecooifldiimtrofst = true
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

    local updatedStatus = Ext.Stats.Get(statusName, -1, true, persist)
    if updatedStatus and nsemfhuecooifldiimtrofst then
        Osi.ApplyStatus(characterGUID, statusName, 1)
        RunesOfFaerun.Debug('Applied unlock status "' .. statusName .. '" to ' .. characterGUID)
    else
        RunesOfFaerun.Debug('Status doesnt exist yet?')
    end
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
            local iscfm = true
            local resources = ec.Resources
            local updatedResource = false

            --Iterate resources and modify the first one that has
            --one of the resources in UseCosts
            for resourceUUID, resourceInfo in pairs(spellCosts) do
                if resources[resourceUUID] and iscfm then
                    RunesOfFaerun.Debug('Resource ' .. resourceUUID .. ' exists')

                    for _, resource in pairs(resources[resourceUUID]) do
                        local levelMatch = resource.Level == resourceInfo.level
                        local resourceIDMatch = resource.ResourceUUID == resourceUUID
                        if resourceIDMatch and levelMatch then
                            local oldResourceValue = resource.Amount
                            local newResourceValue = math.abs(oldResourceValue - resourceInfo.amount)
                            resource.Amount = newResourceValue
                            entity:Replicate('ActionResources')

                            RunesOfFaerun.Debug(
                                string.format('Changed entity resource %s (%s) from %s to %s',
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
    UnlockStolenSpell(casterGUID, spellName)
    ModifyEntitySpellSlots(spellName, enemyGUID)
end

--[[
Don't choose randomly from these spells
]]
local function GetDenySpellMap()
    return {
        --Target_MainHandAttack = true,
        --Projectile_MainHandAttack = true,
        --Projectile_PiercingShot = true,
        Projectile_Jump = true,
        Target_Dip = true,
        Shout_Hide = true,
        Target_Shove = true,
        Throw_Throw = true,
        Throw_ImprovisedWeapon = true,
        Shout_Dash = true,
        Target_Help = true,
        Shout_Disengage = true,
        Target_DancingLights = true,
        Shout_Dodge = true,
        --Perform spells
        Shout_Bard_Perform_Stargazing_Lyre = true,
        Shout_Bard_Perform_ThePower_Lyre = true,
        Shout_Bard_Perform_Lyre = true,
        Shout_SCL_SpiderLyre_Perform = true,
        Shout_Bard_Perform_BardDance_Lyre = true,
        --Mod spells
        FOCUSDYES_CreatePledge = true,
        Teleport_All = true,
        AE_Spell_Container = true,
        Shout_Open_Mirror = true,
        Shout_Open_Creation = true,
        Target_Grapple = true,
    }
end

local function IsSpellInDenyList(spell)
    if spell then
        local denySpellMap = GetDenySpellMap()
        return denySpellMap[spell.Id.OriginatorPrototype]
    end
    return false
end

--Finds a random spell in the spell book that isn't in the deny list
---@param characterGUID GUIDSTRING
local function GetRandomSpellFromSpellBook(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)

    if entity and entity.SpellBook then
        local attempts = 0
        local maxAttempts = 49
        local randomSpell = nil
        local isDenied = true
        while isDenied do
            randomSpell = entity.SpellBook.Spells[math.random(#entity.SpellBook.Spells)]
            isDenied = IsSpellInDenyList(randomSpell)
            attempts = attempts + 1

            --This probably should never happen but let's be safe
            if attempts >= maxAttempts then
                return nil
            end
        end

        if randomSpell then
            Debug('Found random spell "' ..
                randomSpell.Id.Prototype .. '" not in deny list in ' .. attempts .. ' attempts')
        end

        return randomSpell
    else
        RunesOfFaerun.Critical('Entity has no SpellBook')
    end
end

---@param characterTpl string
local function HandleAmnesiaApplied(characterTpl)
    local characterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(characterTpl)
    --Debug('Handling Amnesia on ' .. characterGUID)

    local randomSpell = GetRandomSpellFromSpellBook(characterGUID)

    if randomSpell then
        local entity = Ext.Entity.Get(characterGUID)
        local spellCopy = Ext.Types.Serialize(randomSpell)
        if entity then
            local spellName = spellCopy.Id.OriginatorPrototype

            --RunesOfFaerun.StatusUpdater.GetTempAmnesiaStatusFromEntity(entity)

            RemoveSpellFromEntity(characterGUID, entity, spellCopy)

            sh.amnesiaSpells[characterGUID] = spellCopy

            Debug('Set amnesia spell ' .. spellName)
        else
            Critical('Could not get entity for ' .. characterGUID)
        end
    else
        Critical('Error getting random spell')
    end
end

--Add spells that were removed to the entity
---@param characterTpl string
local function HandleAmnesiaRemoved(characterTpl)
    local characterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(characterTpl)

    --Debug('Handling Amnesia removed on ' .. characterGUID)

    local spell = sh.amnesiaSpells[characterGUID]
    local entity = Ext.Entity.Get(characterGUID)
    if spell and entity then
        AddSpellToEntity(characterGUID, entity, spell)
    else
        Critical('Could not find spell to remove for ' .. characterGUID)
    end
end

sh.HandleAmnesiaRemoved = HandleAmnesiaRemoved
sh.HandleAmnesiaApplied = HandleAmnesiaApplied
sh.RemoveSpellFromSpellContainer = RemoveSpellFromSpellContainer
sh.RemoveSpellFromSpellBook = RemoveSpellFromSpellBook
sh.RemoveSpellFromAddedSpells = RemoveSpellFromAddedSpells
sh.OnSpellStealCasted = OnSpellStealCasted

RunesOfFaerun.SpellHandler = sh
