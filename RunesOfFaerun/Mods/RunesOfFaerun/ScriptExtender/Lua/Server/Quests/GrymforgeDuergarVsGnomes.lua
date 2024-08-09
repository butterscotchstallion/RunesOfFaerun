local handler = {}

local function ShowQuestDialog()
    local characterGUID = Osi.GetHostCharacter()
    if not RunesOfFaerun.QuestHandler.state.isShowingDialog then
        RunesOfFaerun.QuestHandler.state.isShowingDialog = true
        local message = Osi.ResolveTranslatedString('hb0111faeg00cfg471fg8df3g8b16427eb06c')
        Osi.OpenMessageBoxYesNo(characterGUID, message)
    end
end

--Least likely, but maybe they did this in stealth or something
local function HandleGnomeDead()
    Info('Handling Gnome dead quest')
end

--Most common path
--It is possible to kill only one of the duegar
local function HandleDuegarDead()
    Info('Handling Duegar dead quest')

    local spawnUUID = RunesOfFaerun.QuestHandler.SpawnQuestGiver()

    if spawnUUID then
        ShowQuestDialog()
    end
end

--Damn, is this person a Dark Urge or what?
local function HandleAllDead()
    Info('Handling all dead quest')
end

--[[
Handles quest possibilities
--]]
---@param quest table
local function OnCombatEnded(quest)
    Debug('[GrymforgeDuergarVsGnomes] Handling OnCombatEnded')

    --[[
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
    --]]
    local deadCharacters = {}
    for characterGUID, state in pairs(quest.characters) do
        if state.dead then
            deadCharacters[characterGUID] = true
        end
    end

    local gnomeDead = deadCharacters['S_UND_ElevatorGnome_348c5bc8-c514-41d7-a997-c8e58814d765']
    local duegarDead = deadCharacters['S_UND_ElevatorGuard_001_986cb3be-bb31-4aa8-85c0-1f9a315760af'] or
        deadCharacters['S_UND_ElevatorGuard_002_472eba90-f5e8-48cb-ad55-2397e0013a2d']
    local isAllDead = gnomeDead and duegarDead

    if isAllDead then
        HandleAllDead()
    elseif gnomeDead then
        HandleGnomeDead()
    elseif duegarDead then
        HandleDuegarDead()
    end
end

handler.OnCombatEnded = OnCombatEnded

RunesOfFaerun.Quests.GrymforgeDuergarVsGnomes = handler
