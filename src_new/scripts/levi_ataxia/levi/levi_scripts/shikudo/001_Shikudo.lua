--[[mudlet
type: script
name: Shikudo
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Shikudo Script - Levi
- Shikudo
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function AtaxiaGMCPParse(stat)
  --Because they sometimes pass goofy stuff
  --in the 'charstats' sub-table of vitals,
  --we need a way to parse that. Forrrrr example,
  --bleed. It gets passed as Bleed: # in charstats[1],
  --buuuut it might not ALWAYS be charstats[1], or
  --maybe it isn't there at all. Stupid. But here's
  --my solution.
  
  local stat = stat:title()..": "
  local toRet = false
  for _, v in pairs(gmcp.Char.Vitals.charstats) do
    if string.find(v, stat) then
      toRet = v:gsub(stat, "")
      toRet = toRet:gsub("%%", "")
      --sometimes we want the STRING, like morph: jaguar <-- want jaguar,
      --this will skip if there isn't a valid tonumber.
      if tonumber(toRet) then
        toRet = tonumber(toRet)
      end
    end
  end
  
  return toRet
end

