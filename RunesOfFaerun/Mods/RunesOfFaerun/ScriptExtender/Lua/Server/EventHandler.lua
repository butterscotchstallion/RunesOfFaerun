local function OnSessionLoaded()
    RunesOfFaerun.Utils.PrintVersionMessage()
end

Ext.Events.SessionLoaded:Subscribe(OnSessionLoaded)
