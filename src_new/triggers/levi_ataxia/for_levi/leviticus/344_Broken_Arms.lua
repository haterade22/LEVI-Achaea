--[[mudlet
type: trigger
name: Broken Arms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
- Basher Lines
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
- pattern: You cannot do that because both of your arms must be whole and unbound.
  type: 3
]]--

--[[
    OUR OFFENCE IS DEAD AND THE GAME JUST SAID SO.

    This used to fire an UNTHROTTLED `diag` -- and nothing in the package parses our
    own DIAGNOSE output (greps: "afflicted by" -> 0, "You are:" -> 0; onDiagnoseV3 is
    defined but has zero call sites). So the only effect was six lines of console spam
    at the exact moment the screen mattered most; it fired 3x in 0.8s in the live log
    of 2026-07-30 while two malagmae shattered both arms. The other two diagnose
    senders are both throttled (basher/001:108-110, 004_Aff_gains_losses:36-38); this
    one never was.

    What the line is actually worth: it is an authoritative "the attack we just queued
    did NOT execute" signal. The owned battlerage rotations stamp their cooldown at
    SEND time and hold the pick in an in-flight replay, so a rejected round would
    otherwise (a) burn the client-side cooldown on an ability that never fired and
    (b) keep replaying a command the game will refuse again. Roll both back -- the same
    treatment 329_Battlerage_Global_Cooldown gives the "must wait" rejection.

    NOTE the battlerage itself is a SEPARATE command in the same queued chain, so it is
    not necessarily lost -- collide/onslaught need no arms. Only the weapon swing dies.
]]--

-- Drop the in-flight replay on every owned rotation: the queued round was refused.
for _, k in ipairs({"rwBrPending", "dwBrPending", "psionBrPending", "gdragonBrPending"}) do
	ataxiaTemp[k] = nil
end

if ataxiaEcho and ataxiaBasher and ataxiaBasher.enabled then
	ataxiaEcho("<red>Both arms broken<reset> -- weapon attack refused; battlerage and pet still ride.")
end