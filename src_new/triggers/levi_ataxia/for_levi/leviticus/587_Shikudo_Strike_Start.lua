--[[mudlet
type: trigger
name: Shikudo strike start (dedupe reset)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Monk
- Shikudo
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
- pattern: 'You whip '
  type: 2
- pattern: 'With pinpoint precision, you drive '
  type: 2
- pattern: 'Reversing your grip on '
  type: 2
- pattern: 'Stepping to the side of '
  type: 2
- pattern: 'You flow around '
  type: 2
- pattern: 'You spin a full rotation, bringing '
  type: 2
- pattern: 'You drive your foot up in a rising kick at the '
  type: 2
- pattern: 'You lash out with a straight kick at the '
  type: 2
- pattern: 'Dropping into a lower stance, you sweep '
  type: 2
- pattern: 'Falling back into a low crouch, you lash out with a swift strike at the '
  type: 2
- pattern: 'Bracing your back foot, you lunge forward with '
  type: 2
- pattern: 'Stepping forward, you drive '
  type: 2
- pattern: 'Whirling '
  type: 2
- pattern: 'Snapping back into a ready stance, you whirl '
  type: 2
- pattern: 'Lunging forward, you drive the end of '
  type: 2
- pattern: 'Turning with the motion, you channel the momentum of your previous strike into a thrust '
  type: 2
- pattern: 'Snapping your leg out to its full extent, you drive a heel into the '
  type: 2
- pattern: 'Springing off your back foot, the heel of your foot smashes into the '
  type: 2
- pattern: 'Continuing your kata, you spin '
  type: 2
- pattern: 'Spinning on one foot you bring '
  type: 2
- pattern: 'Sharply extending out your arms in front of you, you deliver '
  type: 2
- pattern: 'Taking a firm hold of '
  type: 2
- pattern: 'Bracing your feet, you drive '
  type: 2
]]--
-- v4.7.414: every Shikudo strike line starts a new hit, so it clears the dedupe flag.
--
-- The strike triggers (563-585) set ignoreThirdPerson when they record from the damage line, and
-- the effect-line triggers (the 3rd Person Shikudo group) skip once and clear it, so one
-- hit is not recorded twice. That matters for kuro, which escalates (weariness, then lethargy).
-- But strikes with no effect-line partner -- nervestrike, frontkick, risingkick, spinkick, ruku
-- to the arm, dart, thrust -- left the flag set, and the next effect line whose own strike trigger had NOT fired was skipped:
-- a blow the target's shield absorbed (no damage line is printed; log 2026-10-11, a Shield of
-- Absorption) or a line no strike trigger knows (hiru and livestrike as a later strike in the
-- combo). The affliction landed and was never recorded. Clearing the flag at every strike line
-- makes the dedupe per hit. Line starts are from the 2026-10-11 logs and the strike triggers.
ignoreThirdPerson = nil

-- v4.7.419: and the strike opens its entry in the strike ledger (shikudo/010), which gives ruku to
-- the arm's untargeted effect line (789) to the strike it belongs to. Guarded, so a switched-off
-- ledger cannot make this throw on every strike line (tools/check_orphans.py, v4.7.261).
if shikudoLedger and shikudoLedger.strike then shikudoLedger.strike(line) end
