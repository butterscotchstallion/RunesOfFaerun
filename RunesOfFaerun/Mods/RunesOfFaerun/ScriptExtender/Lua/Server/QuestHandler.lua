local qh = {
    state = {
        questGiversActive = {

        },
        isShowingDialog = false
    }
}

QUEST_GIVER_GHOST = '8443f632-b498-4856-b74a-c24a51be9c34'

local function GetAllQuests()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    return config.quests or {}
end

local function GetIncompleteQuests()
    local allQuests = GetAllQuests()
    local quests = {}
    for questName, data in pairs(allQuests) do
        if not data.state.completed then
            quests[questName] = data
        end
    end
    return quests
end

---@param questID string
local function GetQuestData(questID)
    local quests = GetIncompleteQuests()
    return quests[questID] or {}
end

--[[
Most quests will be active by default, but followups and quests
that can only be discovered through a certain path will be inactive
by default.
--]]
local function AddQuests()
    local totalQuests = 0
    local quests = {
        GrymforgeDuergarVsGnomes = {
            characters = {
                ['S_UND_ElevatorGnome_348c5bc8-c514-41d7-a997-c8e58814d765'] = {
                    name = 'Stickpit',
                    dead = false
                },
                ['S_UND_ElevatorGuard_002_472eba90-f5e8-48cb-ad55-2397e0013a2d'] = {
                    name = 'Ward Pistle',
                    dead = false
                },
                ['S_UND_ElevatorGuard_001_986cb3be-bb31-4aa8-85c0-1f9a315760af'] = {
                    name = 'Ward Magmar',
                    dead = false
                }
            },
            state = {
                completed = false,
                active = true
            }
        }
    }

    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    config.quests = config.quests or {}

    for questName, data in pairs(quests) do
        config.quests[questName] = data
        totalQuests = totalQuests + 1
        RunesOfFaerun.Debug(string.format('Added quest "%s"', questName))
    end

    if totalQuests > 0 then
        RunesOfFaerun.Debug(string.format('Added %s quests', totalQuests))
        RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
    end
end

--[[
Updates quests and returns updated quests
--]]
---@param characterGUID string
---@return quests table
local function UpdateQuestsOnCharacterDeath(characterGUID)
    local quests = GetIncompleteQuests()
    local updates = 0
    RunesOfFaerun.Debug('Updating quests...')

    --[[
    Example structure
    {
        GrymforgeDuergarVsGnomes = {
            characters = {
                ['S_UND_ElevatorGnome_348c5bc8-c514-41d7-a997-c8e58814d765'] = {
                    name = 'Stickpit',
                    dead = false
                },
                ['S_UND_ElevatorGuard_002_472eba90-f5e8-48cb-ad55-2397e0013a2d'] = {
                    name = 'Ward Pistle',
                    dead = false
                },
                ['S_UND_ElevatorGuard_001_986cb3be-bb31-4aa8-85c0-1f9a315760af'] = {
                    name = 'Ward Magmar',
                    dead = false
                }
            }
        }
    }
    --]]
    for questName, data in pairs(quests) do
        if data.characters[characterGUID] then
            quests[questName].characters[characterGUID].dead = true
            updates = updates + 1
            RunesOfFaerun.Debug(
                string.format(
                    '[%s] %s marked as %sDEAD%s',
                    questName,
                    data.characters[characterGUID].name,
                    RunesOfFaerun.log.COLORS['red'],
                    RunesOfFaerun.log.COLORS['end']
                )
            )
        end
    end

    if updates > 0 then
        local config = RunesOfFaerun.ModVarsHandler.GetConfig()
        config.quests = quests
        --UpdateConfig will print updated config
        RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
    else
        RunesOfFaerun.Debug('Failed to find a character to update! Check characterGUID')
        --_D(quests)
    end

    return quests
end

local function OnDied(characterGUID)
    RunesOfFaerun.Debug(characterGUID .. ' died')
    UpdateQuestsOnCharacterDeath(characterGUID)

    --Probably won't happen but let's be prepared
    if qh.state.questGiversActive[characterGUID] then
        qh.state.questGiversActive[characterGUID] = false
    end
end

local function Initialize()
    RunesOfFaerun.Debug('Initializing quests...')
    AddQuests()
end

local function ResetQuests()
    RunesOfFaerun.Debug('Resetting quests')
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    config.quests = {}
    RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
    AddQuests()
end

local function GetNamedQuestHandlerMap()
    local quests = GetIncompleteQuests()
    local questMap = {}
    for questName, data in pairs(quests) do
        if RunesOfFaerun.Quests[questName] then
            foundCombatEndedHandler = true
            questMap[questName] = {
                handler = RunesOfFaerun.Quests[questName],
                quest = data
            }
        else
            Debug(questName)
        end
    end
    return questMap
end

--Called when combat has ended
local function OnCombatEnded()
    local questMap = GetNamedQuestHandlerMap()
    for questName, quest in pairs(questMap) do
        --Should we check if the quest is active or something first?
        questMap[questName].handler.OnCombatEnded(questMap[questName].quest)
    end
end

--[[
 "RotationQuat" :
    [
        0.0,
        0.84889668226242065,
        0.0,
        0.52855885028839111
    ],
    "Scale" :
    [
        1.0,
        1.0,
        1.0
    ],
    "Translate" :
    [
        -604.72119140625,
        5.2900390625,
        378.54287719726562
    ]
]]
local function RotateEntity(entityGUID)
    local entity = Ext.Entity.Get(entityGUID)

    if entity then
        entity.Transform.Transform.RotationQuat = {
            0.0,
            0.84889668226242065,
            0.0,
            0.52855885028839111
        }
        entity:Replicate('Transform')
        Debug('Updated entity rotation')
    end
end

local function SpawnQuestGiver()
    local x = -604.68005371094
    local y = 5.2900390625
    local z = 378.66064453125

    Debug('Attempting to spawn quest giver')

    local spawnUUID = Osi.CreateAt(QUEST_GIVER_GHOST, x, y, z, 0, 1, '')

    if spawnUUID then
        Info('Quest giver spawned')

        qh.state.questGiversActive[spawnUUID] = true

        Osi.ShowMapMarker(Osi.GetHostCharacter(), "3f082e30-2c2a-41ea-8162-087a37a7c5a3", 1)

        RotateEntity(spawnUUID)

        return spawnUUID
    else
        Critical('Failed to spawn quest giver!')
        return nil
    end
end

local function CheckIfQuestAuraAffectsPartyMember(characterGUID)
    local partyMemberMap = RunesOfFaerun.EntityHandler.GetPartyMembersMap()

    if partyMemberMap[characterGUID] then
        RunesOfFaerun.QuestHandler.ShowQuestDialog(characterGUID)
    end
end

local function ShowQuests()
    _D(GetAllQuests())
end

local function ShowIncompleteQuests()
    _D(GetIncompleteQuests())
end

qh.CheckIfQuestAuraAffectsPartyMember = CheckIfQuestAuraAffectsPartyMember
qh.SpawnQuestGiver = SpawnQuestGiver
qh.OnCombatEnded = OnCombatEnded
qh.GetIncompleteQuests = GetIncompleteQuests
qh.GetQuestData = GetQuestData
qh.OnDied = OnDied
qh.ResetQuests = ResetQuests
qh.Initialize = Initialize
qh.ShowQuests = ShowQuests
qh.ShowIncompleteQuests = ShowIncompleteQuests
qh.GetNamedQuestHandlerMap = GetNamedQuestHandlerMap

RunesOfFaerun.QuestHandler = qh
