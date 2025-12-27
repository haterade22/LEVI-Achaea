--[[mudlet
type: trigger
name: Shield Blocked!
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
- pattern: Your shield completely absorbs the damage.
  type: 3
- pattern: The defenses of the Anthem absorb the damage completely.
  type: 3
- pattern: The defences of the Anthem absorb the damage completely.
  type: 3
- pattern: Your paragon completely absorbs the damage.
  type: 3
]]--

bashConsoleEcho("denizen", "Denizen attack blocked!")
bashStats.mobhits = bashStats.mobhits + 1
bashStats.blockedhits = bashStats.blockedhits + 1
if ataxiaBasher.enabled and not ataxiaBasher.manual then
	--deleteFull()
	moveCursor(0, getLineNumber()-1)
	--deleteLine()

	moveCursor(0, getLineNumber()-1)
	if not isPrompt() then
		--deleteLine()
	end
end
