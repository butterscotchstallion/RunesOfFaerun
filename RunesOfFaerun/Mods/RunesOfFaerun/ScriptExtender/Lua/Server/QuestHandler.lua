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
                ['348c5bc8-c514-41d7-a997-c8e58814d765'] = {
                    name = 'Stickpit',
                    dead = false
                },
                ['472eba90-f5e8-48cb-ad55-2397e0013a2d'] = {
                    name = 'Ward Pistle',
                    dead = false
                },
                ['986cb3be-bb31-4aa8-85c0-1f9a315760af'] = {
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

        _D(RunesOfFaerun.ModVarsHandler.GetConfig())
    end
end

---@param characterGUID string
local function UpdateQuestsOnCharacterDeath(characterGUID)
    local quests = GetQuests()
    local updates = 0
    RunesOfFaerun.Debug('Updating quests...')

    for _, questName in pairs(quests) do
        for questName, data in pairs(quests[questName]) do
            if data[characterGUID] then
                quests[questName].data[characterGUID].dead = true
                updates = updates + 1
                RunesOfFaerun.Debug(
                    string.format(
                        'Set quest character %s [%s] as dead for %s',
                        data[characterGUID].name,
                        characterGUID,
                        questName
                    )
                )
            end
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
    config.quests = {}
    RunesOfFaerun.ModVarsHandler.UpdateConfig(config)
    AddQuests()
end

qh.GetQuests = GetQuestData
qh.GetQuestData = GetQuestData
qh.OnDied = OnDied
qh.ResetQuests = ResetQuests

Initialize()

RunesOfFaerun.QuestHandler = qh
