--[[mudlet
type: trigger
name: Constables
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
- Item Highlighting
- Guard Highlighting
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'yes'
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
- pattern: There are \d+ Ashtani corsairs here.
  type: 1
- pattern: There are \d+ runic knights here.
  type: 1
- pattern: There are \d+ Briar Knights here.
  type: 1
- pattern: A Briar Knight casts a cool gaze over the village.
  type: 1
- pattern: ^There are \d+ court constables here.$
  type: 1
- pattern: There are \d+ Blackrock clerics here.
  type: 1
- pattern: There are \d+ Brighthold watchmen here.
  type: 1
]]--

if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<blue> (<green>constable: <orange>aoe + cfh<green>)")
end

deselect()
resetFormat()
moveCursorEnd()

