--[[mudlet
type: trigger
name: each lift floor
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Starmourn
- Lifts
- KEY LIFT table
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
- pattern: \((\d)\).+"(.+)"(?:\s\[)?(HERE)?(?:]\s)?
  type: 1
]]--

if mmp.autowalking then
  if matches[4] == "HERE" then
  	mmp.liftFloor(matches[3],matches[2],true)
		mmp.correctLiftFloor = true
  else
		if not mmp.correctLiftFloor then
  		mmp.liftFloor(matches[3],matches[2],false)
		end
  end
	mmp.deleteLineP()
end