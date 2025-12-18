-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Ataxia-DownloadThis > Ataxia > Misc Scripts > Ab Cheat

abcheat = abcheat or {}
 
abcheat.doab = false
 
abcheat.ab = function(group, name)
        if not name then
                sendGMCP([[Char.Skills.Get {"group" : "]] .. group .. [["}]])
        else
                sendGMCP([[Char.Skills.Get {"group" : "]] .. group .. [[", "name" : "]] .. name .. [["}]])
        end
        abcheat.doab = true
        send("\n", false)
end
 
abcheat.list = function()
        if not abcheat.doab then return end
        abcheat.doab = false
        local abs = gmcp.Char.Skills.List.list
        local descs = gmcp.Char.Skills.List.descs
        local n = 21--4 + abcheat.longest(abs)
        for i, ab in ipairs(abs) do
                echo(ab .. string.rep(" ", n - #ab) .. descs[i] .. "\n")
        end
end
 
abcheat.longest = function(abs)
        local l = 0
        for _, ab in ipairs(abs) do
                if l < #ab then l = #ab end
        end
        return l
end
 
abcheat.info = function()
        if not abcheat.doab then return end
        abcheat.doab = false
        echo(gmcp.Char.Skills.Info.info)
end
 
registerAnonymousEventHandler("gmcp.Char.Skills.List", "abcheat.list")
 
registerAnonymousEventHandler("gmcp.Char.Skills.Info", "abcheat.info")