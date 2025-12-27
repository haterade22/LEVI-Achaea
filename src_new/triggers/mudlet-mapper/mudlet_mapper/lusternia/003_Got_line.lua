--[[mudlet
type: trigger
name: Got line
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
- pattern: ^You make out the scent of (\w+) coming from (.+)\.$
  type: 1
]]--

--deleteLine()

selectString(line, 1) replace""

-- get the name
cecho("<green>"..matches[2].."<reset>: ")

-- ids
mmp.echonums(matches[3])

-- pad spaces so we have aligned roomname
echo(string.rep(" ", 25 - #getCurrentLine()))

-- and finally, the roomname
echo(matches[3])


if mmp.tempscent[matches[3]] then
	mmp.tempscent[matches[3]][#mmp.tempscent[matches[3]]+1] = matches[2]
else
	mmp.tempscent[matches[3]] = {matches[2]}
end

-- save in our person tracking db
mmp.pdb[matches[2]] = matches[3]
mmp.pdb_lastupdate[matches[2]] = true