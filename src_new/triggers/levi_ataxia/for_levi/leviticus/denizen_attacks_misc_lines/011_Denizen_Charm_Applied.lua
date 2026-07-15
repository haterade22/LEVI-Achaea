--[[mudlet
type: trigger
name: Denizen Charm Applied
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
- Denizen Attacks / Misc Lines
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
- pattern: Your foe's eyes glaze over as they stay their hand against you, their wrath slowly shifting toward others nearby.
  type: 3
]]--

-- A battlerage CHARM procced on our current target (the line says "your foe" -- no
-- name -- so it is always the current `target`). A charmed denizen attacks the OTHER
-- denizens for us for ~5s. Record it (auto-expires after 5s or on the charm-end line)
-- so the basher can exploit it (swap to another mob, keep this one alive). Denizen +
-- basher only -- numeric target guards it out of PvP.
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
  ataxiaBasher_dsSetAff(target, "charm")
  if bashConsoleEcho then
    bashConsoleEcho("denizen", "Charmed " .. tostring(target) .. " -- fighting the others for us.")
  end
end
