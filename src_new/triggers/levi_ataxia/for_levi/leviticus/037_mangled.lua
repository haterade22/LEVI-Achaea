--[[mudlet
type: trigger
name: mangled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
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
- pattern: ^Your (.*) is greatly damaged from the beating.$
  type: 1
]]--

-- LEVEL-2 BREAK ("mangled"). This used to call SLC_broke() alone -- but that function
-- is defined ONLY in levi_scripts/slc/001_functions.lua, which is `isActive: no`, so at
-- runtime the global is NIL and this ACTIVE trigger errored on every mangle line while
-- feeding the tracker nothing (found v4.7.170). Route it through the live V2 path the
-- way its level-1 sibling (038_Limb_Broken_L1) does, and keep the legacy call guarded
-- in case that script is ever re-enabled.
local limb = matches[2]

if selfLimbDamage and selfLimbDamage[limb] then
	if ataxia_clearLimbDamage then ataxia_clearLimbDamage(limb) end
	selfLimbDamage[limb].threshold = "broken"
	raiseEvent("self limb threshold", limb, "broken", 0)
end

if SLC_broke then SLC_broke(limb) end