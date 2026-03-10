--[[mudlet
type: trigger
name: Water Emanation
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Enamation
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
- pattern: ^The might of elemental Water surging through your body, you make the slightest flick with an? \w+ staff,
    and the hand of Sllshya descends as a freezing deluge to smash (\w+)\.$
  type: 1
]]--

local tgt = matches[2]
if tgt ~= target then return end

magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}

if magi.offense.hasAff("shivering") or (tAffs and tAffs.shivering) then
  tarAffed("shivering")
  tarAffed("disrupted")
  tarAffed("frozen")
  magi.offense.ptRelay(target .. ": Emanation Water (Shivering + Disrupted + Frozen)")
elseif not magi.offense.hasAff("frostbite") or (tAffs and tAffs.nocaloric) then
  tarAffed("shivering")
  tarAffed("disrupted")
  magi.offense.ptRelay(target .. ": Emanation Water (Shivering + Disrupted)")
else
  tarAffed("nocaloric")
  tarAffed("disrupted")
  magi.offense.ptRelay(target .. ": Emanation Water (Disrupted)")
end
selectCurrentLine() bg("cyan")