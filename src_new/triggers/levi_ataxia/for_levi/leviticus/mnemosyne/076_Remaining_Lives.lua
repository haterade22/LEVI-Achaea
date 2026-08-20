--[[mudlet
type: trigger
name: Remaining Lives
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
- pattern: Remaining lives:\s*(\d+)
  type: 1
]]--
-- WADE STATUS: `Remaining lives:  <n>` -- how many deaths this RUN can still absorb.
--
-- THE ONE RUN-SCOPED STAKE THIS PACKAGE HAS NEVER KNOWN. Every risk decision we make is
-- priced in HP -- the escape ladder at 35%, the panic tumble, the boss-chase HP guard, the
-- forced disengage -- and HP measures how close THIS FIGHT is to going wrong. Lives measure
-- what dying COSTS. At three lives a death is a setback; at one it ends the run and every
-- boon claimed in it. The same 20% reading deserves different answers at 3 and at 1.
--
-- Captured and surfaced (`mnem status`), deliberately NOT yet wired into any threshold:
-- turning it into policy means picking numbers, and a wrong guess gets us killed in a
-- no-flee instance. See the notes on M.onLivesLeft.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onLivesLeft then
	ataxia.mnemosyne.onLivesLeft(matches[2])
end
