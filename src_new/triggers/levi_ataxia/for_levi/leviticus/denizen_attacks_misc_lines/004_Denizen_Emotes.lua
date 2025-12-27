--[[mudlet
type: trigger
name: Denizen Emotes
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
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'yes'
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
colorTriggerFgColor: '#0000ff'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(.+).$
  type: 1
- pattern: FG9BG2
  type: 6
]]--

local x = multimatches[1][1]:lower()

for _, npc in pairs(ataxiaBasher.targetList[gmcp.Room.Info.area]) do
	if string.find(x, npc:lower()) then
		if not ataxiaBasher.manual then
			deleteFull()
		end
	end
end
