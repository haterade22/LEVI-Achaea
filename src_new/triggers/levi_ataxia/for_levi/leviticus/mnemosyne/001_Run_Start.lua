--[[mudlet
type: trigger
name: Mnemosyne Run Start
hierarchy:
- Levi_Ataxia
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
- pattern: ^You begin to wade out into the depths of the Mnemosyne
  type: 1
]]--

ataxia.mnemosyne.onRunStart()
bardWarmarch = false  -- boons reset each run
bmShatteredStar = false  -- boons reset each run
magiKkractle = false  -- boons reset each run
magiHotSprings = false  -- boons reset each run

-- The wade lifecycle is the AUTHORITY on being in the tower -- this line and the confirmed
-- run-end bracket it exactly. Do not infer it from gmcp: the boon "Creville's Legacy" (attack
-- 20% faster, INCURABLE dementia, echoes 3x) fakes gmcp.Room.Info wholesale, so the area/num/
-- exits can all name a real place while we are still inside. Set unconditionally (independent
-- of telemetry), mirroring the boon flags above. SURVEY (351/352) re-syncs on demand.
if ataxiaBasher_mnemHere then ataxiaBasher_mnemHere("wade started") end
