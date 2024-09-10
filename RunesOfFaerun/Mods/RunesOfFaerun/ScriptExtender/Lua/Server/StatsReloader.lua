local modPath = 'Public/RunesOfFaerun/Stats/Generated/Data/'
local filesToReload = {
    'Character.txt',
    'Object.txt',
    'Passive.txt',
    'Projectile.txt',
    'Shout.txt',
    'Status.txt',
    'Target.txt',
}

local function OnReset()
    if filesToReload and #filesToReload then
        for _, filename in pairs(filesToReload) do
            if filename then
                local filePath = string.format('%s%s', modPath, filename)
                if string.len(filename) > 0 then
                    Debug(string.format('RELOADING %s', filePath))
                    Ext.Stats.LoadStatsFile(filePath, false)
                else
                    Critical(string.format('Invalid file: %s', filePath))
                end
            end
        end
    end
end

Ext.Events.ResetCompleted:Subscribe(OnReset)
