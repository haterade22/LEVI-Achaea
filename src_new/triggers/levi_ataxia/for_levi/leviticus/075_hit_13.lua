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
- Shikudo Limb Attacks
- Dart 1
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
-- ORPHANED BY DESIGN, DISABLED 2026-08-12 (v4.7.261).
--
-- This is legacy old-SLC attack-connect tracking (namespace `slc`, SLC_blocked/SLC_connects),
-- superseded by `lb` for target limb tracking. Its script,
-- scripts/levi_ataxia/levi/levi_scripts/slc/001_functions.lua, was DELIBERATELY switched off
-- (isActive: 'no') when that happened -- but these 23 sibling triggers were left ACTIVE, so
-- every one of them called a function that no longer exists.
--
-- The cost was not just noise. Each carries the pattern `^.*$`, so they were evaluated against
-- EVERY line of game output and threw on each one:
--     [ERROR:] object:<hit> function:<Trigger2153>
--       <[string "Trigger: hit"]:2: attempt to call global 'SLC_blocked' (a nil value)>
--
-- Disabled rather than deleted: the parent group scripts above them are LIVE (they set
-- ataxiaTemp.lastLimbHit and call isTargeted), and these files are the record of which attack
-- each child belonged to. Re-enabling the old script instead would resurrect a superseded
-- system alongside `lb`.
--
-- THE RULE: a script switched off must take its callers with it. Nothing checked that, so
-- tools/check_orphans.py now does, in CI.

if SLC_blocked(matches[1]) == false then
	SLC_connects(slc_last_limb,"dart")
end