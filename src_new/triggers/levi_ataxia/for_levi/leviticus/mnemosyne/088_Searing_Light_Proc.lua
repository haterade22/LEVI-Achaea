--[[mudlet
type: trigger
name: Mnemosyne Searing Light Proc
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You form a ball of light in your palm and hurl it \w+\.$
  type: 1
- pattern: searing the location with solar force
  type: 0
]]--

-- LIGHTWALL conjured, and the Searing Light detonation. Captured live 2026-09-16:
--
--   "You form a ball of light in your palm and hurl it northwards."
--   "A bright, fiery detonation flares outwards as the lightwall takes shape, searing the
--    location with solar force."
--
-- Pattern 1 is the conjure itself (base Subterfuge; the direction word varies, hence `\w+`), a
-- short fixed-length line safe to anchor. Pattern 2 is the boon's proc -- matched as an END
-- fragment because the full line is ~110 characters and wraps at the player's width (the 057/058
-- rule) -- and prints ONLY with the boon, so it is self-proving. Both feed
-- `ataxiaBasher_searingLightConfirm` (basher/002): restamp the room from the LANDED moment and
-- release the in-flight replay; only the proc re-latches the flag. `chartreuse` bold on the proc
-- is the attack-landed colour (Arc, Thunderclap, Spirit Rend, Flourish, Death Stare).
local proc = line:find("searing the location with solar force", 1, true) ~= nil
if proc then
  selectString(line, 1)
  fg("chartreuse")
  setBold(true)
  deselect()
  resetFormat()
end

if ataxiaBasher_searingLightConfirm then
  ataxiaBasher_searingLightConfirm(proc)
end
