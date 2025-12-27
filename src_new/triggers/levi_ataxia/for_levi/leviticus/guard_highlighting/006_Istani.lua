--[[mudlet
type: trigger
name: Istani
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
mFgColor: transparent
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: Electricity wreathes the lithe frame of a vigilant Weave Witch.
  type: 1
- pattern: Bathed in a faint blue glow, an ice mage lingers here, swinging a frozen talisman.
  type: 1
- pattern: There are \d+ earthen elementalists here.
  type: 1
- pattern: A hooded nocturni, crackling with blue streaks of electrical discharge, patrols this area.
  type: 1
- pattern: A crimson orb circling its brow, a Khaal Theurgist floats here surveying the surroundings.
  type: 1
- pattern: There are \d+ Khaal Theurgists here.
  type: 1
- pattern: There are \d+ hooded nocturni here.
  type: 1
- pattern: Lambent energy pulses around the skeletal frame of a Naxian mistweaver.
  type: 1
- pattern: There are \d+ Naxian mistweavers here.
  type: 1
]]--

if not ataxia.settings.highlighting or not ataxia.settings.highlighting.guards then return end

for i = 1, #matches, 2 do
  local line = matches[i]
  local pos = selectString(line, 1)
  moveCursor("main", pos+#line-1, getLineNumber())

  cinsertText("<LightSkyBlue> (<SlateGrey>istani: <orange>hinders<LightSkyBlue>)")
end

deselect()
resetFormat()
moveCursorEnd()

