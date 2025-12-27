--[[mudlet
type: trigger
name: Embedded a vibration
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Magi
- Vibes
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
- pattern: With a forceful gesture, you command the crystals to embed themselves into the ground.
  type: 3
]]--

if ataxiaTemp.embeddingVibes then
  cecho(" embedded: <NavajoWhite>"..ataxiaTemp.vibes[1])
	table.remove(ataxiaTemp.vibes, 1)
	magiVibes_nextEmbed()
end
