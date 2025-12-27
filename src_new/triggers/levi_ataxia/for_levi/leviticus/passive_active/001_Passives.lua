--[[mudlet
type: trigger
name: Passives
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Passive/Active
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
- pattern: ^(\w+) surrounds \w+ with a translucent achromatic aura.$
  type: 1
- pattern: ^The globe of light illuminates (\w+) with its brilliance.$
  type: 1
- pattern: ^A song can be heard on the edge of hearing as the air distorts about (\w+)\.$.
  type: 1
- pattern: ^A rune like a rising sun upon the ground flares, bathing (\w+) with healing magic.$
  type: 1
- pattern: ^A demonic crimson glow emanates from (\w+).$
  type: 1
- pattern: ^A soft chiming emanates from (\w+).$
  type: 1
- pattern: ^A gentle glow surrounds (\w+).$
  type: 1
- pattern: ^The tempestuous form of (\w+) is cleansed by a purifying breeze.$
  type: 1
- pattern: ^The guardian angel of (\w+) shimmers and \w+ gives a sigh of relief.$
  type: 1
- pattern: ^(\w+) is surrounded in a cool, refreshing mist.$
  type: 1
- pattern: ^Something pulses from within the chest of (.+)\, and \w+ seems more vital\.$
  type: 1
- pattern: ^The air shudders about (\w+), a keening whine on the edge of hearing.$
  type: 1
]]--

local name = matches[2]
local voyriaBlock = ((pariah and pariah.latency) and true or false)

if isTargeted(matches[2]) then
  if haveAff("voyria") and not voyriaBlock then
    erAff("voyria")
  else
    ataxiaTemp.randomCure = 1
  end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
 
 tBals.passive = false
 tempTimer(14.9,[[tBals.passive = true]])
  
end
