--[[mudlet
type: trigger
name: Centreslash
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Blademaster Limb Attacks
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^In a single motion, (\w+) draws \w+ \w+ from its scabbard and looses a vicious (?:rising|falling) slash at your
    (torso|head)\.$
  type: 1
- pattern: '1'
  type: 5
]]--

if multimatches[1][4] == "head" then 
	slc_last_limb = "head"
elseif multimatches[1][4] == "torso" then
	slc_last_limb = "torso"
end