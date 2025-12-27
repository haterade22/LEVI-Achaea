--[[mudlet
type: trigger
name: Archers
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
- pattern: A whistling tumult of whirling air surrounds a gangly, robe-clad figure.
  type: 1
- pattern: Mounted atop a sleek snow panther, a mountain archer coolly scans the distant peaks.
  type: 1
- pattern: Mounted atop a woodland bear, a forest archer keenly scans the sprawling canopy.
  type: 1
- pattern: There are \d+ forest archers here.
  type: 1
- pattern: A fierce virago carefully scans the area for signs of trouble.
  type: 1
- pattern: There are \d+ fierce viragos here.
  type: 1
- pattern: A baleful apostate looms here, \w+ daemonic companion at one side, and unholy daegger hovering at the other.
  type: 1
- pattern: Eyes keenly raised to the skies, a cowled bow-maiden plucks idly at \w+ bowstring.
  type: 1
- pattern: There are \d+ \w+ bow-maidens here.
  type: 1
]]--

if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<yellow> (<SlateGrey>archer: <orange>anti-flyer<yellow>)")
end

deselect()
resetFormat()
moveCursorEnd()