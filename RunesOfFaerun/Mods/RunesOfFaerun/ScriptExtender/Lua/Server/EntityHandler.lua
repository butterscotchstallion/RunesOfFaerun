local eh = {}

SLIMY_COMPANION_GUID = '6e831db4-2531-48a8-ab87-445c5b0032a8'
NURSE_COMPANION_GUID = '027611f4-16bf-45f2-a782-ed5606bd676d'
GIANT_BADGER_GUID = 'c0369b2e-f495-4831-8e10-9e16ac7b2261'

--Spooky update
GHOST_NURSE = "76597e52-d1b4-43dd-99e9-d06d551f61a5"
GHOST_DOG = "834f22b8-e28d-44b6-b6f2-1f7f7cf5149b"
MYCONID_SPECTER = "6a944046-925f-4a50-add7-9b904abca9b5"

specters = {
    GHOST_DOG,
    GHOST_NURSE,
    MYCONID_SPECTER,
}

eh.GetHostEntityMaxHP = function()
    local entity = Ext.Entity.Get(Osi.GetHostCharacter())
    if entity then
        if entity.Health then
            return entity.Health.MaxHp
        end
    end
end

eh.SetEntityHP = function(guid, hpValue)
    local entity = Ext.Entity.Get(guid)
    if entity and entity.Health then
        local healAmount = hpValue or entity.Health.MaxHp
        entity.Health.MaxHp = healAmount
        entity.Health.Hp = healAmount
        entity:Replicate('Health')
        Debug('Set ' .. guid .. ' HP to ' .. healAmount)
    else
        Critical('Could not set HP of ' .. guid)
    end
end

eh.SetEntityMaxHPToHostMaxHP = function(entityGUID)
    local hostHP = eh.GetHostEntityMaxHP()
    if hostHP then
        eh.SetEntityHP(entityGUID, hostHP)
    end
end

---@param entityGUID guid
eh.SetEntityLevelToHostLevel = function(entityGUID)
    local hostLevel = tonumber(Osi.GetLevel(Osi.GetHostCharacter()))
    if hostLevel then
        Ext.OnNextTick(function()
            Osi.SetLevel(entityGUID, hostLevel)
            RunesOfFaerun.Debug('Set ' .. entityGUID .. ' level to ' .. hostLevel)
        end)
    end
end

---@param rootGUID guid
---@param instanceGUID guid
eh.HandleByGUID = function(rootGUID, instanceGUID)
    local isKnownEntity = Osi.IsTagged(instanceGUID, RunesOfFaerun.Tags.ROF_SUMMON)

    if isKnownEntity then
        eh.SetEntityLevelToHostLevel(instanceGUID)

        --Apply mummy transformation if nurse is here
        if rootGUID == NURSE_COMPANION_GUID then
            Debug("Checking if mummy is unlocked for nurse")
            RunesOfFaerun.Upgrader.ApplyMummyTransformationIfUnlocked(instanceGUID)
        end

        if rootGUID == GIANT_BADGER_GUID then
            RunesOfFaerun.Upgrader.ApplyBadgerUpgradesIfUnlocked(instanceGUID)
        end
    else
        --RunesOfFaerun.Debug(rootGUID .. ' is not a known entity')
    end
end

---@param creatureTplId string
local function SetCreatureHostile(creatureTplId)
    local evilFactionId = 'Evil_NPC_64321d50-d516-b1b2-cfac-2eb773de1ff6'
    Osi.SetFaction(creatureTplId, evilFactionId)
    --RunesOfFaerun.Info(string.format('Set hostile on %s', creatureTplId))
end

--[[
options: {
  hostile = false,
  castFireball = false,
  uuid = nil
}
]]
eh.SpawnHostileSpellSlinger = function(options)
    local uuid = options.uuid or 'be5650d4-e282-4ddd-aa0d-1b9411740302'
    local getPositionFromThisTarget = Osi.GetHostCharacter()

    --Used for specters to summon at the position of the corpse with Death Knell
    --if options.createAtUUIDPosition then
    --    getPositionFromThisTarget = uuid
    --end

    local x, y, z = Osi.GetPosition(getPositionFromThisTarget)

    if x and y and z then
        RunesOfFaerun.Debug(string.format('Creating %s at position %s %s %s', uuid, x, y, z))
        local spawnUUID = Osi.CreateAt(uuid, x, y, z, 0, 1, '')
        if spawnUUID then
            RunesOfFaerun.Debug('Create successful: UUID = ' .. spawnUUID)
            Osi.RequestPing(x, y, z, spawnUUID, Osi.GetHostCharacter())

            if options.hostile then
                SetCreatureHostile(spawnUUID)
            end

            if options.castFireball then
                local newSpell = "Projectile_ROF_Fireball"
                Osi.UseSpell(spawnUUID, newSpell, Osi.GetHostCharacter())
                RunesOfFaerun.Debug('Using ' .. newSpell)
            end

            if options.addAsPartyFollower then
                Osi.AddPartyFollower(spawnUUID, Osi.GetHostCharacter())
            end
        else
            RunesOfFaerun.Debug('Failed to create ' .. uuid)
        end
    end
end

eh.IsAlliedSpecter = function(originalUUID)
    for uuid in pairs(specters) do
        if uuid == originalUUID then
            return true
        end
    end
end

eh.SpawnAlliedSpecter = function(options)
    local specterUUID = options.uuid or specters[math.random(#specters)]

    Debug("Spawning ghost " .. specterUUID)

    eh.SpawnHostileSpellSlinger({
        hostile = false,
        castFireball = false,
        uuid = specterUUID,
        addAsPartyFollower = true,
        createAtUUIDPosition = true,
    })
end

eh.GetPartyMembersMap = function()
    local members = {}
    local players = Osi.DB_Players:Get(nil)
    for _, player in pairs(players) do
        members[player[1]] = true
    end
    return members
end

local function SetEntityHPToFull(characterGUID)
    eh.SetEntityHP(characterGUID, nil)
end

local function HealRunicSummonsToFull()
    local summons = RunesOfFaerun.Utils.GetPlayerSummons()
    local summonTag = "dabdfa1a-ad14-47dc-aaf2-cc09394138d7"
    if summons and #summons > 0 then
        for _, characterGUID in pairs(summons) do
            if Osi.IsTagged(characterGUID, summonTag) == 1 then
                Ext.OnNextTick(function()
                    Osi.ApplyStatus(characterGUID, "STATUS_ROF_RUNIC_INVIGORATION", 1, 1)
                end)
            end
        end
    else
        Debug("No ROF summons present")
    end
end

--Checks if anyone in the party has Runic Invigoration
local function HasRunicInvigoration()
    local partyMembers = RunesOfFaerun.EntityHandler.GetPartyMembersMap()
    local hasRunicInvigoration = false
    for pmTpl, _ in pairs(partyMembers) do
        local guid = RunesOfFaerun.Utils.GetGUIDFromTpl(pmTpl)
        local hasPassive = Osi.HasPassive(guid, "ROF_Runic_Invigoration") == 1
        if hasPassive then
            hasRunicInvigoration = true
            break
        end
    end
    return hasRunicInvigoration
end

local function randomChance(percent)        -- returns true a given percentage of calls
    assert(percent >= 0 and percent <= 100) -- sanity check
    return percent >= math.random(1, 100)   -- 1 succeeds 1%, 50 succeeds 50%,
    -- 100 always succeeds, 0 always fails
end

eh.HasRunicInvigoration = HasRunicInvigoration
eh.HealRunicSummonsToFull = HealRunicSummonsToFull
eh.SetEntityHPToFull = SetEntityHPToFull

RunesOfFaerun.EntityHandler = eh
