--[[mudlet
type: alias
name: Own Denizens
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Lists
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash mine ?(.*)$
command: ''
packageName: ''
]]--

-- Manage the "our denizens" list: pet/ally/summon name keywords (case-insensitive
-- substrings) the basher must never auto-learn or target (falcons, Baalzadeen, ...).
--   bash mine                 - list current keywords (click to remove)
--   bash mine add <keyword>   - add a keyword and purge existing matches from targets
--   bash mine rem <keyword>   - remove a keyword
ataxiaBasher.ownDenizens = ataxiaBasher.ownDenizens or {}

local arg = (matches[2] or ""):gsub("^%s+", ""):gsub("%s+$", "")

if arg == "" then
  if #ataxiaBasher.ownDenizens == 0 then
    ataxiaEcho("No own-denizen keywords set. Add one with: <white>bash mine add <keyword>")
  else
    ataxiaEcho("Your denizens (never auto-added or targeted) — click to remove:")
    for _, kw in ipairs(ataxiaBasher.ownDenizens) do
      cecho("\n  <red>- ")
      fg("white")
      echoLink(kw, [[ataxiaBasher_removeOwnDenizen("]] .. kw .. [[")]], "Remove '" .. kw .. "' from own-denizen list.", true)
      cecho(" <red>-")
    end
    send(" ")
  end
  return
end

local action, kw = arg:match("^(%S+)%s+(.+)$")
action = (action or arg):lower()

if action == "add" and kw then
  ataxiaBasher_addOwnDenizen(kw)
elseif (action == "rem" or action == "remove" or action == "del" or action == "delete") and kw then
  ataxiaBasher_removeOwnDenizen(kw)
else
  ataxiaEcho("Usage: <white>bash mine<NavajoWhite> | <white>bash mine add <keyword><NavajoWhite> | <white>bash mine rem <keyword>")
end
