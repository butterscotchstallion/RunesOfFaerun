local st = {
    stacks = {},
    progressions = {
        STATUS_ROF_STACKABLE_SPLATTERED_1 = {
            [2] = "STATUS_ROF_STACKABLE_SPLATTERED_2",
            [3] = "STATUS_ROF_STACKABLE_SPLATTERED_3"
        }
    }
}

local function ApplyProgressiveStatus(characterGUID, statusName, numStacks)
    if st.progressions[statusName] and st.progressions[statusName][numStacks] then
        local progressionStatus = st.progressions[statusName][numStacks]
        Debug(
            string.format(
                "Applying progression status %s [%s stacks]",
                progressionStatus,
                numStacks
            )
        )
        Osi.ApplyStatus(characterGUID, progressionStatus, 18)
    end
end

---@param characterGUID GUIDSTRING
---@param statusName string
---@param increment boolean
local function ModifyStacks(characterGUID, statusName, increment)
    local incrementValue = 1

    if not increment then
        incrementValue = -1
    end

    if #st.stacks == 0 or not st.stacks[characterGUID] then
        st.stacks[characterGUID] = {}
        st.stacks[characterGUID][statusName] = 1
    end

    local numStacks = st.stacks[characterGUID][statusName] + incrementValue

    if numStacks < 0 then
        numStacks = 0
    end

    st.stacks[characterGUID][statusName] = numStacks

    --Debug(string.format("%s is now at %s stacks", statusName, numStacks))

    ApplyProgressiveStatus(characterGUID, statusName, numStacks)
end

local function IncrementStacks(characterGUID, statusName)
    --Debug('Incrementing ' .. statusName)
    ModifyStacks(characterGUID, statusName, true)
end

local function DecrementStacks(characterGUID, statusName)
    --Debug('Decrementing ' .. statusName)
    ModifyStacks(characterGUID, statusName, false)
end

local function IsStackableStatus(statusName)
    return statusName and statusName:find("STATUS_ROF_STACKABLE_") == 1
end

st.IsStackableStatus = IsStackableStatus
st.IncrementStacks = IncrementStacks
st.DecrementStacks = DecrementStacks

RunesOfFaerun.StackTracker = st
