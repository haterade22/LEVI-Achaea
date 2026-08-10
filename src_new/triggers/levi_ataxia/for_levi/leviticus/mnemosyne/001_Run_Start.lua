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

-- BEFORE onRunStart(): it reads run.paused, which onRunStart consumes on a resume.
-- A resume-after-pause wade is the SAME run, so the Reaper tally survives it;
-- only a genuinely fresh wade resets it (the count is unrecoverable otherwise).
ataxia.mnemosyne.reaperOnWade()
ataxia.mnemosyne.onRunStart()
bardWarmarch = false  -- boons reset each run
bmShatteredStar = false  -- boons reset each run
magiKkractle = false  -- boons reset each run
magiHotSprings = false  -- boons reset each run
mnemHammerAnvil = false  -- boons reset each run
mnemReaper = false  -- boons reset each run (re-latches from the next tithe/BOONS row on a resume)
bmBladedReflexes = false  -- boons reset each run
mnemSleuth = false  -- boons reset each run
mnemRollHide = false  -- boons reset each run
mnemBloodscent = false  -- boons reset each run
mnemKaiUnleashed = false  -- boons reset each run
mnemSenselessFlurry = false  -- boons reset each run
psionPanoply = false  -- boons reset each run
dragonMightSycaerunax = false  -- boons reset each run
dragonRampage = false  -- boons reset each run
dwFlashforward = false  -- boons reset each run
infArmyOfDead = false  -- boons reset each run
infDaemonJaws = false  -- boons reset each run
infIndiscriminate = false  -- boons reset each run
infNecroticAura = false  -- boons reset each run
infFuryOfAges = false  -- boons reset each run
mnemWintersHeart = false  -- boons reset each run
mnemResourceful = false  -- boons reset each run
mnemFalconersTactics = false  -- boons reset each run
mnemHomebound = false  -- boons reset each run
mnemHammerAndNail = false  -- boons reset each run
mnemHaemophiliac = false  -- affixes reset each run (re-latches from the next WADE STATUS row)
mnemLastWord = false  -- affixes reset each run (re-latches from the next WADE STATUS row)
mnemBravado = false  -- affixes reset each run (re-latches from the next WADE STATUS row)
mnemDeluge = false  -- affixes reset each run (re-latches from the next WADE STATUS row)
mnemRageFuelled = false -- boons reset each run (re-latches from the BOONS row / claim)
mnemThunderclap = false -- boons reset each run (re-latches from the BOONS row / claim)
mnemStormcleaver = false
mnemDivineThunder = false -- boons reset each run (re-latches from the BOONS row / claim)
mnemIcyHeart = false -- boons reset each run (re-latches from the BOONS row / claim)
mnemSongstep = false -- boons reset each run (re-latches from the BOONS row / claim)
mnemTantrum = false -- boons reset each run (re-latches from the BOONS row / claim)
mnemBorrowedPower = false -- boons reset each run (re-latches from the BOONS row / claim)
if ataxiaTemp then ataxiaTemp.mnemNulled = nil end -- damage-suppression affixes re-latch per ripple
if ataxiaTemp then ataxiaTemp.mnemBoonsRelatched = nil end -- re-latch boons this run
if ataxiaTemp then ataxiaTemp.brFreeCharge = nil end
if ataxiaTemp then ataxiaTemp.tantrumRipple = nil end -- Tantrum re-banks on the first ripple

-- The wade lifecycle is the AUTHORITY on being in the tower -- this line and the confirmed
-- run-end bracket it exactly. Do not infer it from gmcp: the boon "Creville's Legacy" (attack
-- 20% faster, INCURABLE dementia, echoes 3x) fakes gmcp.Room.Info wholesale, so the area/num/
-- exits can all name a real place while we are still inside. Set unconditionally (independent
-- of telemetry), mirroring the boon flags above. SURVEY (351/352) re-syncs on demand.
if ataxiaBasher_mnemHere then ataxiaBasher_mnemHere("wade started") end
