--[[mudlet
type: trigger
name: Stop capturing
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Lusternia
- mmp Lusternia Scent
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
- pattern: ''
  type: 7
]]--

setTriggerStayOpen("mmp Lusternia Scent", 0)

--[[for area, names in pairs(mmp.tempscent) do
	for _, name in ipairs(names) do

-- get the name
cecho("\n<green>"..name.."<reset>: ")

-- ids
mmp.echonums(area)

-- pad spaces so we have aligned roomname
echo(string.rep(" ", 25))

-- and finally, the roomname
echo(area)
end
end]]


raiseEvent("mmapper updated pdb")