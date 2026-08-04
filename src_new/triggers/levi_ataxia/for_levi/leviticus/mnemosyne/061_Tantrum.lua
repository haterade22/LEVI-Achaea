--[[mudlet
type: trigger
name: Mnemosyne Tantrum
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
- pattern: ^Tantrum\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "Your first battlerage ability per ripple costs no rage."
--
-- Mechanically this is RAGE-FUELLED with a different trigger. That boon banks a free
-- battlerage per KILL (trigger 340_Slain); this one banks it per RIPPLE. Both describe the
-- same STATE -- "one battlerage is free right now" -- so both arm the same
-- `ataxiaTemp.brFreeCharge`, and the whole payoff comes for free: `ataxiaBasher_brFree()`
-- already short-circuits all 37 `rageAfford` call sites AND the eight culling-reap gates
-- (including the shared one that v4.7.198 found the v4.7.179 sweep had missed), and
-- `brCommit`/`brSent` already spend it.
--
-- Holding BOTH boons needs no special case: one boolean correctly means "a free battlerage is
-- banked", whichever granted it. The charge does not stack, and modelling it as a counter
-- would be inventing a mechanic the boon text does not describe.
--
-- Armed by `M.tantrumArm()` (mnemosyne/004), guarded on the RIPPLE NUMBER rather than simply
-- fired from onRipple -- because this flag can be latched mid-ripple by `_relatchBoons`, a
-- BOONS-list row, or the claim alias, and re-arming on any of those would hand out a second
-- free battlerage in a ripple whose first was already spent. The guard makes every path
-- idempotent, which is why this trigger can call it unconditionally.
--
-- Cleared on run start and on the confirmed run end, along with the ripple guard.
mnemTantrum = true
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.tantrumArm then
  ataxia.mnemosyne.tantrumArm()
end
