--[[mudlet
type: trigger
name: Gold Dropped
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Clean-up
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
- pattern: Golden sovereigns spill onto the ground from
  type: 2
- pattern: drops some golden sovereigns onto the ground.
  type: 0
- pattern: ^[A-z ]+ sovereigns? spills? from the corpse\.$
  type: 1
]]--

if not ataxia_paused() then
	if not found_target then
    if ataxia.settings.goldcommand then
      send("queue addclear free "..ataxia.settings.goldcommand)
    else
		  send("queue addclear free get gold"..ataxia.settings.separator.."open pack436363;put gold in pack436363;close pack436363")
    end
	end
end

if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("denizen", "Nicely dropped gold for us!")
    if not ataxiaBasher.manual then
			deleteFull()
		end
end
