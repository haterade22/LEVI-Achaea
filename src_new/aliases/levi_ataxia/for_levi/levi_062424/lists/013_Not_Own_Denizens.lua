--[[mudlet
type: alias
name: Not Own Denizens
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash notmine ?(.*)$
command: ''
packageName: ''
]]--

-- The inverse of `bash mine`: real, killable denizens whose NAME happens to contain
-- one of your pet keywords. `bash mine` matches by case-insensitive substring, which
-- is what lets "falcon" cover "a razor-beaked falcon" -- but it also means the real
-- denizen "a slope-backed hyena" is silently shielded by the pet keyword "hyena".
-- That is not merely lost xp: in the Mnemosyne the explorer waits for the room to
-- clear while the basher refuses to ever target it, and the sweep stalls outright.
--
-- Entries here WIN over the pet keywords.
--   bash notmine                  - list exemptions (click to remove)
--   bash notmine add <name>       - exempt a real denizen
--   bash notmine rem <name>       - drop an exemption
ataxiaBasher.notOwnDenizens = ataxiaBasher.notOwnDenizens or {}

local arg = (matches[2] or ""):gsub("^%s+", ""):gsub("%s+$", "")

if arg == "" then
  if #ataxiaBasher.notOwnDenizens == 0 then
    ataxiaEcho("No exemptions set. Add one with: <white>bash notmine add <name>")
    ataxiaEcho("<grey>Use this when a REAL denizen shares a word with one of your pets.")
  else
    ataxiaEcho("Real denizens exempted from your pet keywords -- click to remove:")
    for _, nm in ipairs(ataxiaBasher.notOwnDenizens) do
      cecho("\n  <green>+ ")
      fg("white")
      echoLink(nm, [[ataxiaBasher_removeNotOwnDenizen("]] .. nm .. [[")]], "Stop exempting '" .. nm .. "'.", true)
      cecho(" <green>+")
    end
    send(" ")
  end
  return
end

local action, nm = arg:match("^(%S+)%s+(.+)$")
action = (action or arg):lower()

if action == "add" and nm then
  ataxiaBasher_addNotOwnDenizen(nm)
elseif (action == "rem" or action == "remove" or action == "del" or action == "delete") and nm then
  ataxiaBasher_removeNotOwnDenizen(nm)
else
  ataxiaEcho("Usage: <white>bash notmine<NavajoWhite> | <white>bash notmine add <name><NavajoWhite> | <white>bash notmine rem <name>")
end
