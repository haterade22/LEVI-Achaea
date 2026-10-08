--[[mudlet
type: trigger
name: Venom Agony Purge
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: You scream out in agony as a vicious venom tears through your body
  type: 2
]]--

-- A VENOM TEARING THROUGH US -> PURGE (v4.7.392, user: "We need to purge in this instance").
--
--   You scream out in agony as a vicious venom tears through your body.
--
-- It is the same wording as the Toxicologist relapse on a denizen ("... screams out in agony, struck
-- by the effects of a vicious venom", mnemosyne/108), turned on us. PURGE clears the venom from our
-- blood, as 014 already does for the "purge the venom ... before you may secrete another" refusal --
-- and, like 014, it is a direct send, so it does not touch a queued attack or a queued escape.
--
-- Start of line, so it matches with or without the full stop. Throttled: a burst of these lines
-- (one per tick of the venom) sends one purge, not one per line.
ataxiaTemp = ataxiaTemp or {}
local nowT = (getEpoch and getEpoch()) or os.time()
if nowT - (tonumber(ataxiaTemp.venomAgonyPurgeAt) or 0) >= 2 then
  ataxiaTemp.venomAgonyPurgeAt = nowT
  send("purge")
end
