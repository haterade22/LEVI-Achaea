--[[mudlet
type: trigger
name: Clickable Links
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
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
- pattern: \b(?:(?:(?:[Hh]ttps?|ftp|telnet)://[\w\d:#@%/;$()~_?\+\-=&]+|www|ftp)(?:\.[\w\d:#@%/;$()~_?\+\-=&]+)+|[\w\d._%+\-]+@[\w\d.\-]+\.[\w]{2,4})\b
  type: 1
]]--

for i,v in ipairs(matches) do
	if selectString(matches[i], 1) ~= -1 then
		setLink([[openUrl("]]..matches[i]..[[")]], matches[i])
		setUnderline(true)
	end
end

deselect()
resetFormat()