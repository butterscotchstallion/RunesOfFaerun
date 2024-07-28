local sh = {}

--[[
Finds the index of a spell by name in the spell container,
so it can be changed
--]]
---@param spellName string
---@param spellContainer table
---@return number | false
local function GetIndexOfSpellInSpellContainer(spellName, spellContainer)
    local spells = spellContainer.Spells

    if spells and #spells > 0 then
        for index, spell in pairs(spells) do
            if spell.SpellId then
                if spell.SpellId.OriginatorPrototype == spellName then
                    return index
                end
            else
                RunesOfFaerun.Critical('Spell doesnt have a SpellId?')
                break
            end
        end
    else
        RunesOfFaerun.Critical('Empty spell container?!')
    end

    return false
end

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
                _D(filteredSpells)

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
    if entity.SpellBook and entity.SpellBook.Spells then
        local spellExists = false
        local filteredSpells = {}
        for _, spell in pairs(entity.SpellBook.Spells) do
            if spell.Id.OriginatorPrototype == spellName then
                spellExists = true
            else
                table.insert(filteredSpells, spell)
            end
        end

        if spellExists then
            entity.SpellBook.Spells = filteredSpells
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

--[[
- Find spell that was casted
- Set the origin to Osiris to allow it to be
removed by Osi.RemoveSpell
- Osi.RemoveSpell

Test with:

!RemoveSpell uuid spellName
--]]
---@param spellName string
---@param casterGUID string
local function RemoveSpellFromCaster(spellName, casterGUID)
    local entity = Ext.Entity.Get(casterGUID)

    if entity then
        local spellContainer = entity.SpellContainer

        if spellContainer then
            RunesOfFaerun.Info('Searching for spells in entity "' .. casterGUID .. '"')

            local spellIndex = GetIndexOfSpellInSpellContainer(spellName, spellContainer)

            if spellIndex ~= false and spellIndex then
                --Sets the source of the spell as Osiris, allowing it to be removed by Osi.RemoveSpell
                spellContainer.Spells[spellIndex].SpellId.SourceType = 'Osiris'
                entity:Replicate('SpellContainer')

                RunesOfFaerun.Info('Successfully changed spell source of ' .. spellName .. '!')

                Ext.OnNextTick(function()
                    Osi.RemoveSpell(casterGUID, spellName, 1)
                    RunesOfFaerun.Info('Called RemoveSpell on ' .. casterGUID)
                end)
            else
                RunesOfFaerun.Critical('Failed to find spell index of spell "' .. spellName .. '"!')
            end
        else
            RunesOfFaerun.Critical('Entity ' .. casterGUID .. ' did not have a spell container???')
        end
    else
        RunesOfFaerun.Critical('Could not get entity of caster: ' .. casterGUID)
    end
end

--[[
- Remove Spell from caster
- Add the spell to the target
--]]
---@param spellName string
---@param casterGUID string
local function OnSpellStealCasted(spellName, casterGUID)
    --RemoveSpellFromCaster(spellName, casterGUID)
end

sh.RemoveSpellFromSpellContainer = RemoveSpellFromSpellContainer
sh.RemoveSpellFromSpellBook = RemoveSpellFromSpellBook
sh.RemoveSpellFromAddedSpells = RemoveSpellFromAddedSpells
sh.OnSpellStealCasted = OnSpellStealCasted
sh.RemoveSpellFromCaster = RemoveSpellFromCaster

RunesOfFaerun.SpellHandler = sh
