--[[mudlet
type: trigger
name: Kai Surge
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Monk
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
- pattern: ^As the power of your kai builds within you, you lift a hand towards (\w+)\. A searing bolt of power leaps forth, blasting \w+ backwards and leaving \w+ lying, twitching, upon the ground\.$
  type: 1
]]--

if isTargeted(matches[2]) then
  tAffs.prone = true
  erAff("shield")
  selectString(line, 1)
  setBold(true)
  fg("violet")
  resetFormat()
  tarAffed("prone")
  confirmAffV2("prone")
  tarAffed("prone")

  -- 15s mount lockout window: target cannot remount, use sweep + parried limb
  ataxiaTemp = ataxiaTemp or {}
  ataxiaTemp.kaiSurgeWindow = true
  tempTimer(15, function()
    ataxiaTemp = ataxiaTemp or {}
    ataxiaTemp.kaiSurgeWindow = false
    cecho("\n<yellow>[Monk] Kai Surge mount window expired")
  end)
end

if partyrelay and not ataxia.afflictions.aeon then
  send("pt: " .. matches[2] .. ": Kai Surged (prone)")
end
