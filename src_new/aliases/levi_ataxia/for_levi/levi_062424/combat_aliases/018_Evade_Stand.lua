--[[mudlet
type: alias
name: Evade Stand
hierarchy:
- Levi_Ataxia
- Combat
- Combat Aliases
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^evade (\w+)$
command: ''
packageName: ''
]]--

-- STAND BEFORE EVADE (2026-11-11). EVADE refuses while prone ("You must be standing first."). In the
-- 2026-11-11 Serpent group log a typed `evade s` drew that line 36 times. Typed EVADE now stands
-- first when we are prone: both raw, the stand first. Paralysis blocks the stand too, so a
-- paralysed press still fails; it still goes out, and the game says why. A send() from code does
-- not pass through aliases, so the Blademaster `ee`/`en`... aliases are not changed by this one.
local dir = matches[2]
if ataxia and ataxia.afflictions and ataxia.afflictions.prone then
  send("stand", false)
end
send("evade " .. dir)
