--[[mudlet
type: trigger
name: Warriors
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
- pattern: A sentry of the Vanguard maintains \w+ vigil, a flame-blackened bardiche planted beside \w+.
  type: 1
- pattern: There are \d+ sentries of the Vanguard here.
  type: 1
- pattern: There are \d+ imperial guardsmen here.
  type: 1
- pattern: Reserved and watchful, an imperial guardsman paces here, \w+ expression impassive.
  type: 1
- pattern: With silent vigil, a gnarled treekin roots to the treetop vantage.
  type: 1
- pattern: A knight of the Atrament guards the area, hands poised on the pommel of a broadsword.
  type: 1
- pattern: There are \d+ knights of the Atrament here.
  type: 1
- pattern: With a resolute militaristic stance, a malicious salamandrin legionnaire discerns its environs with a calculating
    scrutiny.
  type: 1
- pattern: There are \d+ salamandrins legionnaire here.
  type: 1
- pattern: 'An attentive Duskmere brawler stands ready with \w+ halberd, \w+ keen eyes missing nothing. '
  type: 1
- pattern: There are \d+ Duskmere brawlers here.
  type: 1
]]--

if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<purple> (<SlateGrey>warrior: <orange>prone/breaks<purple>)")
end

deselect()
resetFormat()
moveCursorEnd()