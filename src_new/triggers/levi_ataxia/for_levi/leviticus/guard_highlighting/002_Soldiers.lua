--[[mudlet
type: trigger
name: Soldiers
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
- pattern: Mounted astride a grim chaos hound, a black rider patrols the city.
  type: 1
- pattern: There are \d+ black riders here.
  type: 1
- pattern: There are \d+ oscillating lake wyrms here.
  type: 1
- pattern: Light scintillates off the perpetually wet body of an oscillating lake wyrm.
  type: 1
- pattern: Handaxes at the ready, a woodland ranger stands quietly.
  type: 1
- pattern: Suspended betwixt the realm of life and death, a spectre of the Shadow Court keeps vigil over the location.
  type: 1
- pattern: There are \d+ spectres of the Shadow Court here.
  type: 1
- pattern: Observing its surroundings with absolute loathing, a malignant baalhuezen towers here.
  type: 1
- pattern: Gripping a broadsword, a Shornwall defender crouches slightly in anticipation.
  type: 1
- pattern: There are \d+ Shornwall defenders here.
  type: 1
]]--

if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<red> (<SlateGrey>solder: <orange>heavy damage<red>)")
end

deselect()
resetFormat()
moveCursorEnd()