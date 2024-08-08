local qh = {}

local function GetIncompleteQuests()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    local allQuests = config.quests or {}
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
                completed = false
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
        _D(quests)
    end

    return quests
end

local function OnDied(characterGUID)
    RunesOfFaerun.Debug(characterGUID .. ' died')
    UpdateQuestsOnCharacterDeath(characterGUID)
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

--Called when combat has ended
local function OnCombatEnded()
    local quests = GetIncompleteQuests()

    for questName, _ in pairs(quests) do
        if RunesOfFaerun.Quests[questName] then
            RunesOfFaerun.Quests[questName].OnCombatEnded(quests[questName])
        end
    end
end

qh.OnCombatEnded = OnCombatEnded
qh.GetIncompleteQuests = GetIncompleteQuests
qh.GetQuestData = GetQuestData
qh.OnDied = OnDied
qh.ResetQuests = ResetQuests
qh.Initialize = Initialize

RunesOfFaerun.QuestHandler = qh
