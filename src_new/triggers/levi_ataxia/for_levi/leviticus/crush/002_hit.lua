--[[mudlet
type: trigger
name: hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Knight Limb Attacks
- DualB
- Crush
- Crush 1
attributes:
  isActive: 'no'
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
- pattern: ^.*$
  type: 1
]]--
-- ORPHANED, DISABLED v4.7.261. Every statement in this trigger called into the legacy `slc`
-- system, whose script was switched off when `lb` superseded it -- so it did nothing but throw
-- "attempt to call global (a nil value)", once per matching line, forever. Kept rather than
-- deleted so the attack->limb mapping it records is not lost. See tools/check_orphans.py.

if SLC_blocked(matches[1]) == false then
	SLC_connects(slc_last_limb,"crush")
end