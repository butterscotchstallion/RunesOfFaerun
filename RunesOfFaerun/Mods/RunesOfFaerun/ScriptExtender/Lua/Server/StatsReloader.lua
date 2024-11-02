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

local function UnescapeXML(str)
    str = string.gsub(str, '&lt;', '<')
    str = string.gsub(str, '&gt;', '>')
    str = string.gsub(str, '&quot;', '"')
    str = string.gsub(str, '&apos;', "'")
    str = string.gsub(str, '&#(%d+);', function(n) return string.char(n) end)
    str = string.gsub(str, '&#x(%d+);', function(n) return string.char(tonumber(n, 16)) end)
    str = string.gsub(str, '&amp;', '&') -- Be sure to do this after all others
    return str
end

local function ReloadLocale()
    local anyReloaded = false
    local folder = Ext.Mod.GetMod(ModuleUUID).Info.Directory
    local filePath = ("Mods/%s/Localization/English/%s-English.xml"):format(folder, folder)
    local locale = Ext.IO.LoadFile(filePath, "data")
    if locale ~= nil and locale ~= "" then
        for handle, version, content in string.gmatch(locale, '%s*<content contentuid="([^\r\n]+)" version="([^\r\n]+)">([^\r\n]+)</content>') do
            content = UnescapeXML(content)
            if Ext.Loca.UpdateTranslatedString(handle, content) then
                anyReloaded = true
            else
                Ext.Utils.PrintError(("Failed to update tstring handle(%s) content(%s)"):format(handle, content))
            end
        end
    end
    if anyReloaded then
        Ext.Utils.Print(("Reloaded %s"):format(filePath))
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

    ReloadLocale()
end

Ext.Events.ResetCompleted:Subscribe(OnReset)
