--[[mudlet
type: trigger
name: Each person
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Achaea
- Fullsense (mudlet mapper)
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
- pattern: ^You sense (\w+) at (.+)\.$
  type: 1
]]--

echo((" "):rep(60-#line))
echo"(" mmp.echonums(matches[3]) echo")"

mmp.pdb[matches[2]] = matches[3]
mmp.pdb_lastupdate[matches[2]] = true