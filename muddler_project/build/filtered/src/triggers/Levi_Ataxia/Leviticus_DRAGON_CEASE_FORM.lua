ataxia.settings.paused = false
ataxiaEcho("System has been "..(ataxia.settings.paused and "<red>paused." or "<green>unpaused."))
send("curing priority defence list reset")
if gmcp.Char.Status.class == "Infernal" then
expandAlias("defup isnb")
send("mastery on;hyena recall;order hyena follow me")
elseif gmcp.Char.Status.class == "Apostate" then
expandAlias("defup apoo")
send("summon baalzadeen;summon daegger")
elseif gmcp.Char.Status.class == "Runewarden" then
expandAlias("defup rdwb")
elseif gmcp.Char.Status.class == "Earth Lord" then
expandAlias("defup earth")
end