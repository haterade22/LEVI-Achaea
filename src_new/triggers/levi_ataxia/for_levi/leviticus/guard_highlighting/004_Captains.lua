--[[mudlet
type: trigger
name: Captains
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
- pattern: There are \d+ thralls of the wheel here.
  type: 1
- pattern: There are \d+ dashing troubadours here.
  type: 1
- pattern: Rapier glinting in the light, a dashing young troubadour fences with an imagined foe.
  type: 1
- pattern: Suffused with the power of Nature, a veiled dryad lingers in the shadows.
  type: 1
- pattern: There are \d+ mounted tsalmaveths here.
  type: 1
- pattern: A mounted tsalmaveth watches this area carefully.
  type: 1
- pattern: There are \d+ flail-wielding knights here.
  type: 1
- pattern: There are \d+ flail-wielding knights here.
  type: 1
- pattern: Ready for action, a Blackstone swordsman monitors the surrounds.
  type: 1
- pattern: There are \d+ Blackstone swordsmen here.
  type: 1
]]--

if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<firebrick> (<SlateGrey>captain: <orange>blackout/aoe<firebrick>)")
end

deselect()
resetFormat()
moveCursorEnd()

