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

--Needs a symlink leading to your localization XML file
--in the BG3 Data folder
---@param files string[]
local function LoadLoca(files)
    for _, file in ipairs(files) do
        local fileName = string.format("Localization/English/%s.xml", file)
        local contents = Ext.IO.LoadFile(fileName, "data")

        if contents then
            for line in string.gmatch(contents, "([^\r\n]+)\r*\n") do
                local handle, value = string.match(line, '<content contentuid="(%w+)".->(.+)</content>')
                if handle ~= nil and value ~= nil then
                    value = value:gsub("&[lg]t;", {
                        ['&lt;'] = "<",
                        ['&gt;'] = ">"
                    })
                    Ext.Loca.UpdateTranslatedString(handle, value)
                end
            end
        else
            Debug(string.format("%s does not exist in the Data folder", fileName))
        end
    end
end

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

    LoadLoca({ "RunesOfFaerun" })
end

Ext.Events.ResetCompleted:Subscribe(OnReset)
