--[[mudlet
type: trigger
name: Shikudo strike outcome (ledger)
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
- pattern: ^(\w+) parries the attack with a deft manoeuvre\.
  type: 1
- pattern: ^The staff connects to the (left|right) arm with a resounding crack
  type: 1
- pattern: '^\w+ staggers as the staff cracks across '
  type: 1
- pattern: 'You fumble your strike, the attack going wide.'
  type: 2
- pattern: 'As your blow lands with a crunch, you perceive that you have dealt '
  type: 2
- pattern: 'A dizzying beam of energy strikes you as your attack rebounds off of '
  type: 2
- pattern: 'The staff cracks across the '
  type: 2
- pattern: 'The breath of '
  type: 2
- pattern: 'The staff smashes into the face of '
  type: 2
- pattern: 'The staff connects to the side of '
  type: 2
- pattern: 'The end of the staff '
  type: 2
- pattern: 'The end of your staff smashes the magical shield'
  type: 2
- pattern: 'Horror overcomes the face of '
  type: 2
- pattern: 'The instep of your foot smashes into the '
  type: 2
- pattern: 'Your foot catches '
  type: 2
- pattern: 'Your foot drives into the solar plexus of '
  type: 2
- pattern: 'You feel the satisfying crunch of bone'
  type: 2
- pattern: 'The staff sweeps the legs out from under '
  type: 2
]]--
-- v4.7.419: every line that can end a Shikudo strike, handed to the strike ledger (shikudo/010).
-- A one-line adapter, so the deciding stays in the script, where the tests can see it.
--
-- The lines, from kb/raw/logs/2026-10-11_shikudo-vs-runewarden-snb_attacker.txt and Mystor's logs:
-- a parry, a fumble and a shield's rebound mean the strike did not land; the damage line and the
-- effect lines mean it did. Only ruku to the arm's effect line ("The staff connects to the right arm
-- with a resounding crack, the limb flopping uselessly.") is recorded here, because it alone names no
-- target; the others have their own recorders, and here they only mark the strike resolved.
-- Line starts, never end-anchored: a wrapped line or a client suffix would defeat a $. The group
-- runs by number, so the strike triggers (563-585) and 587 come first on the same line.
if shikudoLedger and shikudoLedger.outcome then shikudoLedger.outcome(line) end
