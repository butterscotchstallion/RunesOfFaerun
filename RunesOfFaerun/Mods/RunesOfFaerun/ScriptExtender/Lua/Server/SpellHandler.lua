--[[

Spell Handler

--]]
local sh = {
    addedSpells = {
        --GUID -> spell
    },
    amnesiaSpells = {

    },
    amnesiaStatuses = {},
    temporaryAmnesiaResolvedDisplayName = nil,
    validSpellCache = {}
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
                Debug('Found spell "' .. spellName .. '"!')

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
        local startTime = Ext.Utils.MonotonicTime()
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
            local duration = Ext.Utils.MonotonicTime() - startTime .. 'ms'
            RunesOfFaerun.Debug('RemoveFromSpellBook: Removed spell "' .. spellName .. '" and replicated in ' .. duration)
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
        RunesOfFaerun.Debug('Added spell "' ..
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
    local statusName = 'ROF_STOLEN_SPELL_UNLOCK_' .. unlockSpell
    local statusBase = 'STATUS_ROF_STOLEN_SPELL_UNLOCK_BASE'

    local success = RunesOfFaerun.StatusHandler.CreateStatusIfNotExists(statusName, statusBase, {
        Boosts = GetUnlockSpellBoost(unlockSpell)
    })

    if success then
        Osi.ApplyStatus(characterGUID, statusName, 1)
        RunesOfFaerun.Debug('Applied unlock status "' .. statusName .. '" to ' .. characterGUID)
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
        Shout_Dash_NPC = true,
        Target_Help = true,
        Shout_Disengage = true,
        Target_DancingLights = true,
        Shout_Dodge = true,
    }
end

local function IsSpellInDenyList(spell)
    if spell then
        local denySpellMap = GetDenySpellMap()
        return denySpellMap[spell.Id.OriginatorPrototype]
    end
    return false
end

local function ClearValidSpellCache()
    sh.validSpellCache = {}
    Debug('Cleared valid spell cache')
end

local function GetValidSpellsFromSpellBook(characterGUID, spellbook)
    local startTime = Ext.Utils.MonotonicTime()
    if sh.validSpellCache[characterGUID] then
        Debug(string.format('Returning spell cache (%s spells)', #sh.validSpellCache[characterGUID]))
        return sh.validSpellCache[characterGUID]
    else
        local entity = Ext.Entity.Get(characterGUID)

        Debug(string.format('Building valid spell cache for %s', RunesOfFaerun.Utils.GetDisplayNameFromEntity(entity)))

        local validSpells = {}
        local startSpellListTime = Ext.Utils.MonotonicTime()
        for _, spell in pairs(spellbook) do
            if not IsSpellInDenyList(spell) then
                table.insert(validSpells, Ext.Types.Serialize(spell))
            end
        end
        sh.validSpellCache[characterGUID] = validSpells
        Debug(string.format("Built spell list in %sms", Ext.Utils.MonotonicTime() - startSpellListTime))

        local elapsedSecs = Ext.Utils.MonotonicTime() - startTime
        Debug(
            string.format(
                "Built spell cache [%s/%s] valid spells. Completed in %sms",
                #validSpells,
                #spellbook,
                elapsedSecs
            )
        )

        return validSpells
    end
end

--Finds a random spell in the spell book that isn't in the deny list
---@param characterGUID GUIDSTRING
local function GetRandomSpellFromSpellBook(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    if entity and entity.SpellBook then
        local startTime = Ext.Utils.MonotonicTime()
        local validSpells = GetValidSpellsFromSpellBook(characterGUID, entity.SpellBook.Spells)
        if #validSpells > 0 then
            local randomSpell = validSpells[math.random(#validSpells)]
            if randomSpell then
                local duration = (Ext.Utils.MonotonicTime() - startTime) .. 'ms'
                Debug('Found random spell "' ..
                    randomSpell.Id.Prototype .. '" not in deny list in ' .. duration)
            end
            return randomSpell
        end
    else
        RunesOfFaerun.Critical('Entity has no SpellBook')
    end
end

local function GetTempAmnesiaResolvedDisplayName()
    --TODO: fix this if we ever have some translations
    return "Temporary Amnesia"
    --[[
    local displayName = sh.temporaryAmnesiaResolvedDisplayName
    if not displayName then
        displayName = Osi.ResolveTranslatedString("h7669884ba01e48239bb6e5c5dfb5969e7d1e")
        sh.temporaryAmnesiaResolvedDisplayName = displayName
    end
    return displayName
    ]]
end

local function IsAmnesiaStatus(status)
    return sh.amnesiaStatuses[status]
end

---@param characterGUID GUIDSTRING
---@param spell table
local function CreateOrApplyAmnesiaStatus(characterGUID, spell)
    local startTime = Ext.Utils.MonotonicTime()
    local spellName = spell.Id.OriginatorPrototype
    local warnOnError = false
    local spellStatsEntry = Ext.Stats.Get(spellName, -1, nil, warnOnError)
    local spellDisplayName = Osi.ResolveTranslatedString(spellStatsEntry.DisplayName)
    local amnesiaStatus = 'STATUS_ROF_TEMP_AMNESIA_BASE'
    --Temporary Amnesia
    local baseName = GetTempAmnesiaResolvedDisplayName()
    --Detailed status includes the name of the spell that was forgotten
    local detailedStatus = string.format('STATUS_ROF_TEMP_AMNESIA_%s', spellName)
    local detailedStatusValue = RunesOfFaerun.StatusHandler.GetUpdatedStatusName(baseName, spellDisplayName)
    local updatedHandleReturnValue = Ext.Loca.UpdateTranslatedString(
        "h7669884ba01e48239bb6e5c5dfb5969e7d1e",
        detailedStatusValue
    )

    if not updatedHandleReturnValue then
        Debug('Error updating display name handle')
    end

    local success = RunesOfFaerun.StatusHandler.CreateStatusIfNotExists(
        detailedStatus,
        amnesiaStatus
    )

    if success then
        amnesiaStatus = detailedStatus
        sh.amnesiaStatuses[amnesiaStatus] = true
    end

    --Each turn is six seconds, so if we want three turns, that is 18 seconds
    local durationNumTurns = 18

    Osi.ApplyStatus(characterGUID, amnesiaStatus, durationNumTurns)

    Debug("Applied status in " .. Ext.Utils.MonotonicTime() - startTime .. "ms")
end

local function ClearAmnesiaStatuses()
    sh.amnesiaStatuses = {}
    Debug('Cleared Amnesia statuses')
end

---@param characterTpl string
local function HandleAmnesiaApplied(characterTpl)
    local startTime = Ext.Utils.MonotonicTime()
    local characterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(characterTpl)
    --randomSpell is already serialized
    local randomSpell = GetRandomSpellFromSpellBook(characterGUID)
    if randomSpell then
        local entity = Ext.Entity.Get(characterGUID)
        if entity then
            local spellName = randomSpell.Id.OriginatorPrototype

            CreateOrApplyAmnesiaStatus(characterGUID, randomSpell)
            RemoveSpellFromEntity(characterGUID, entity, randomSpell)

            sh.amnesiaSpells[characterGUID] = randomSpell

            Debug('HandleAmnesiaApplied: Set amnesia spell ' ..
                spellName .. ' in ' .. Ext.Utils.MonotonicTime() - startTime .. 'ms')
        else
            Critical('HandleAmnesiaApplied: Could not get entity for ' .. characterGUID)
        end
    else
        Critical('HandleAmnesiaApplied: Error getting random spell')
    end
end

--Add spells that were removed to the entity
---@param characterTpl string
local function HandleAmnesiaRemoved(characterGUID)
    --Debug('Handling Amnesia removed on ' .. characterGUID)
    local spell = sh.amnesiaSpells[characterGUID]
    local entity = Ext.Entity.Get(characterGUID)
    if spell and entity then
        AddSpellToEntity(characterGUID, entity, spell)
    else
        Critical('HandleAmnesiaRemoved: Could not find spell to remove for ' .. characterGUID)
    end
end

local function HandleDuplicitousTransformation(characterTpl)
    local characterGUID = RunesOfFaerun.Utils.GetGUIDFromTpl(characterTpl)
    local entity = Ext.Entity.Get(characterGUID)
    if entity then
        local transformations = {
            "POLYMORPH_CHEESE",
            "POLYMORPH_SHAPECHANGER",
            "POLYMORPH_SHEEP",
            "SCL_PIXIEBELL_FROG",
            "SCL_PIXIEBELL_BOAR",
            "SCL_PIXIEBELL_DEEPROTHE",
            "GREMISHKA_MAGICALLERGY_PANTHER",
            "WILDSHAPE_RAT_SECRET",
            "LOW_LODGE_SPIDER",
            "HAV_DevilishOX_POLYMORPH_DIREWOLF",
        }
        local randomTransformation = transformations[math.random(#transformations)]
        local displayName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(entity)
        Debug(string.format('Transforming %s using "%s"', displayName, randomTransformation))

        Osi.ApplyStatus(characterGUID, randomTransformation, 3)
    end
end

local function GetEntitySpellSlots(characterGUID, displayName)
    local entity = Ext.Entity.Get(characterGUID)
    local spellSlotResourceUUID = "d136c5d9-0ff0-43da-acce-a74a07f8d6bf"
    local actionResources = entity.ActionResources
    local slots = {}
    if entity and actionResources then
        local resources = actionResources.Resources
        local spellSlots = resources[spellSlotResourceUUID]

        if spellSlots then
            for _, slot in pairs(spellSlots) do
                table.insert(slots, slot.Level)
            end
        else
            Debug(displayName .. " has no spell slots :(")
        end
    end
    return slots
end

local function GetRandomSpellSlotFromEntity(characterGUID, displayName)
    local slots = GetEntitySpellSlots(characterGUID, displayName)
    local randomSlot = nil
    if slots and #slots > 0 then
        randomSlot = slots[math.random(#slots)]
    end
    return randomSlot
end

local function GetRandomGRStatusName(characterGUID, displayName)
    local spellSlotLevel = GetRandomSpellSlotFromEntity(characterGUID, displayName)
    if spellSlotLevel then
        return string.format("STATUS_ROF_GR_%s", spellSlotLevel)
    end
end

local function HandleGrimRenewalApplied(characterGUID)
    local entity = Ext.Entity.Get(characterGUID)
    local displayName = RunesOfFaerun.Utils.GetDisplayNameFromEntity(entity)
    local statusName = GetRandomGRStatusName(characterGUID, displayName)

    if statusName then
        Osi.ApplyStatus(characterGUID, statusName, -1, 1)
        Debug(string.format("Applied %s to %s", statusName, displayName))
    else
        Critical("Could not get random GR status!")
    end

    local tagMap = RunesOfFaerun.Utils.GetTagMapFromEntity(entity)
    local isROFSummon = tagMap[RunesOfFaerun.Tags.ROF_SUMMON]

    if isROFSummon then
        Debug("Applying Bloodthirsty to ROF summon " .. displayName)
        Ext.OnNextTick(function()
            Osi.ApplyStatus(characterGUID, "STATUS_ROF_Bloodthirsty", 0, 1)
        end)
    else
        Debug("Not a ROF summon?")
        _D(tagMap)
    end
end

sh.HandleGrimRenewalApplied = HandleGrimRenewalApplied
sh.IsAmnesiaStatus = IsAmnesiaStatus
sh.ClearAmnesiaStatuses = ClearAmnesiaStatuses
sh.ClearValidSpellCache = ClearValidSpellCache
sh.HandleDuplicitousTransformation = HandleDuplicitousTransformation
sh.HandleAmnesiaRemoved = HandleAmnesiaRemoved
sh.HandleAmnesiaApplied = HandleAmnesiaApplied
sh.RemoveSpellFromSpellContainer = RemoveSpellFromSpellContainer
sh.RemoveSpellFromSpellBook = RemoveSpellFromSpellBook
sh.RemoveSpellFromAddedSpells = RemoveSpellFromAddedSpells
sh.OnSpellStealCasted = OnSpellStealCasted

RunesOfFaerun.SpellHandler = sh
