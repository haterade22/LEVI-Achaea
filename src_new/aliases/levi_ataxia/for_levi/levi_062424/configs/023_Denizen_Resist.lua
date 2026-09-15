--[[mudlet
type: alias
name: Denizen Resist
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash resist(?:\s+(.+))?$
command: ''
packageName: ''
]]--

-- `bash resist`                 -- every denizen CONSIDER has taught us about, with resistances.
-- `bash resist <name>`          -- one denizen (substring match).
-- `bash resist forget <name>`   -- drop a row so the next fight re-CONSIDERs it.
-- `bash resist clear`           -- drop everything.
-- The database is `ataxiaBasher.denizenResist` (basher/001), filled by trigger 771 from CONSIDER
-- output; unknown mobs are considered automatically unless Death Stare is held.
local db = ataxiaBasher.denizenResist or {}
local arg = matches[2] and matches[2]:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""

local function describe(key, row)
  local parts = {}
  for t, q in pairs(row.resist or {}) do parts[#parts + 1] = "<red>" .. q .. " resistance<reset> to " .. t end
  for t, q in pairs(row.weak or {}) do parts[#parts + 1] = "<green>" .. q .. " weakness<reset> to " .. t end
  table.sort(parts)
  local body = (#parts > 0) and table.concat(parts, ", ") or "<dim_grey>no data<reset>"
  local aura = row.aura and (" [" .. row.aura .. "]") or ""
  return "  <white>" .. key .. "<reset>" .. aura .. ": " .. body
end

if arg == "clear" then
  ataxiaBasher.denizenResist = {}
  ataxia_saveSettings(false)
  ataxiaEcho("Denizen resistance database cleared.")
elseif arg:match("^forget%s+") then
  local key = ataxiaBasher_resistKey(arg:gsub("^forget%s+", ""))
  if key and db[key] then
    db[key] = nil
    ataxia_saveSettings(false)
    ataxiaEcho("Forgot <white>" .. key .. "<reset> -- it will be CONSIDERed again next fight.")
  else
    ataxiaEcho("No row for '" .. tostring(key) .. "'.")
  end
else
  local keys = {}
  for k in pairs(db) do
    if arg == "" or k:find(arg, 1, true) then keys[#keys + 1] = k end
  end
  table.sort(keys)
  if #keys == 0 then
    ataxiaEcho(arg == "" and "Denizen resistance database is empty -- it fills from CONSIDER output as you bash."
      or ("No denizen matching '" .. arg .. "'."))
    return
  end
  ataxiaEcho("Denizen resistances (" .. #keys .. "):")
  for _, k in ipairs(keys) do cecho("\n" .. describe(k, db[k])) end
end
