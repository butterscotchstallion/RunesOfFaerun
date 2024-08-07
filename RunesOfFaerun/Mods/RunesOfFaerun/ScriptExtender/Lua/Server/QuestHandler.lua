local qh = {}

local function GetQuests()
    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    return config.quests or {}
end

---@param questID string
local function GetQuestData(questID)
    local quests = GetQuests()
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
            }
        }
    }

    local config = RunesOfFaerun.ModVarsHandler.GetConfig()
    config.quests = config.quests or {}

    for questName, data in pairs(quests) do
        if not config.quests[questName] then
            config.quests[questName] = data
            totalQuests = totalQuests + 1
            RunesOfFaerun.Debug(string.format('Added quest "%s"', questName))
        end
    end

    if totalQuests > 0 then
        RunesOfFaerun.Debug(string.format('Added %s quests', totalQuests))
        RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
    end

    _D(RunesOfFaerun.ModVarsHandler.GetConfig().quests)
end

---@param characterGUID string
local function UpdateQuestsOnCharacterDeath(characterGUID)
    local quests = GetQuests()
    local updates = 0
    RunesOfFaerun.Debug('Updating quests...')

    --[[
    Example structure
    {
        GrymforgeDuergarVsGnomes = {
            characters = {
                ['S_UND_ElevatorGnome'] = {
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
                    'Set quest character %s [%s] as dead for %s',
                    data.characters[characterGUID].name,
                    characterGUID,
                    questName
                )
            )
        end
    end

    if updates > 0 then
        local config = RunesOfFaerun.ModVarsHandler.GetConfig()
        config.quests = quests
        RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
    else
        RunesOfFaerun.Debug('Failed to find a character to update! Check characterGUID')
    end
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
    config = {}
    config.quests = {}
    RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
    AddQuests()
end

qh.GetQuests = GetQuestData
qh.GetQuestData = GetQuestData
qh.OnDied = OnDied
qh.ResetQuests = ResetQuests
qh.Initialize = Initialize

RunesOfFaerun.QuestHandler = qh
