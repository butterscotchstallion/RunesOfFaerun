local handler = {
    NPC_GNOME_TPL      = 'S_UND_ElevatorGnome_348c5bc8-c514-41d7-a997-c8e58814d765',
    NPC_DUEGAR_001_TPL = 'S_UND_ElevatorGuard_001_986cb3be-bb31-4aa8-85c0-1f9a315760af',
    NPC_DUEGAR_002_TPL = 'S_UND_ElevatorGuard_002_472eba90-f5e8-48cb-ad55-2397e0013a2d',
    QUEST_GIVER_UUID   = '8443f632-b498-4856-b74a-c24a51be9c34',
}

local function GetQuestData()
    return {
        characters = {
            [handler.NPC_GNOME_TPL] = {
                name = 'Stickpit',
                dead = false
            },
            [handler.NPC_DUEGAR_001_TPL] = {
                name = 'Ward Pistle',
                dead = false
            },
            [handler.NPC_DUEGAR_002_TPL] = {
                name = 'Ward Magmar',
                dead = false
            }
        },
        state = {
            completed = false,
            active = true
        }
    }
end

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
    Debug('Handling Gnome dead quest')
end

--Most common path
--It is possible to kill only one of the duegar
local function HandleDuegarDead()
    Debug('Handling Duegar dead quest')

    local spawnUUID = RunesOfFaerun.QuestHandler.SpawnQuestGiver(handler.QUEST_GIVER_UUID)

    if spawnUUID then
        ShowQuestDialog()
    end
end

--Damn, is this person a Dark Urge or what?
local function HandleAllDead()
    Debug('Handling all dead quest')
end

--[[
Handles quest possibilities
--]]
---@param quest table
local function OnCombatEnded(quest)
    --Delayed until dialogue/timeline features land in SE
    --[[
    Debug('[GrymforgeDuergarVsGnomes] Handling OnCombatEnded')

    local deadCharacters = {}
    for characterGUID, state in pairs(quest.characters) do
        if state.dead then
            deadCharacters[characterGUID] = true
        end
    end

    local gnomeDead = deadCharacters[handler.NPC_GNOME_TPL]
    local duegarDead = deadCharacters[handler.NPC_DUEGAR_001_TPL] or
        deadCharacters[handler.NPC_DUEGAR_002_TPL]
    local isAllDead = gnomeDead and duegarDead

    if isAllDead then
        HandleAllDead()
    elseif gnomeDead then
        HandleGnomeDead()
    elseif duegarDead then
        HandleDuegarDead()
    else
        Debug('CombatEnded: no characters dead?')
    end
    ]]
end

handler.OnCombatEnded = OnCombatEnded
handler.GetQuestData = GetQuestData

RunesOfFaerun.Quests.GrymforgeDuergarVsGnomes = handler
