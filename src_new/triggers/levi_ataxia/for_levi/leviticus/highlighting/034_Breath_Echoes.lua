--[[mudlet
type: trigger
name: Breath Echoes
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Highlighting
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
- pattern: ^An echo of psionic breath assails (.+), forcing \w+ to stumble clumsily around\.$
  type: 1
- pattern: ^An echo of flaming breath strikes (.+), scorching \w+ and inhibiting \w+ natural healing\.$
  type: 1
- pattern: ^An echo of frigid breath chills (.+), slowing \w+ movements to a crawl\.$
  type: 1
- pattern: ^An echo of venomous breath rots the corpse of (.+), afflicting \w+ with a plague of weakness\.$
  type: 1
]]--

-- Dragon breath-echo procs (live capture 2026-07-28, source unconfirmed --
-- boon/affix?): the psionic echo makes the denizen CLUMSY (stumbling), the flaming
-- echo INHIBITS its natural healing, the frigid echo gives it AEON (slowed to a
-- crawl), the venomous echo rots a corpse into a plague of WEAKNESS. Distinct
-- colours so the effects read at a glance: psionic = orchid (control family),
-- flaming = tomato (burn family), frigid = cyan (ice family), venomous =
-- green_yellow (sickly green, venom family).
selectString(line,1)
setBold(true)
if line:find("psionic") then
	fg("orchid")
elseif line:find("frigid") then
	fg("cyan")
elseif line:find("venomous") then
	fg("green_yellow")
else
	fg("tomato")
end
deselect()
resetFormat()
