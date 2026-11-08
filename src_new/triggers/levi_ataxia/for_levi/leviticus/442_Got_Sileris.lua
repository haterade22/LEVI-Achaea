--[[mudlet
type: trigger
name: Got Sileris
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^A supple metallic shell of quicksilver has formed around (\w+).$
  type: 1
- pattern: ^(\w+) applies a quicksilver droplet to \w+\.$
  type: 1
- pattern: ^A supple purple shell of sileris berry juice has formed around (\w+)\.$
  type: 1
]]--

-- v4.7.416: the shell forms about 10 s AFTER the application (Mystor's logs, 2026-10-11: 1117 -> 1465,
-- 2399 -> 2724, 3495 -> 3888), and until it forms a venom or a ruku to the torso still lands. Only the
-- "has formed" line records the barrier; the application line just notes when it was applied.
-- A sileris BERRY forms a purple shell, not the quicksilver one
-- (kb/raw/logs/ours/2026-11-03_080944_Lauryyn.log:955, "... has formed around Grulk."). That
-- line matched nothing, so a berry user's coating was never recorded, and the Serpent offence
-- bit or impulsed into it after every strip and re-apply. herbs/013 leaves the barrier to this line.
if isTargeted(matches[2]) then
  local formed = matches[1] or ""
  if formed:find("^A supple metallic shell") or formed:find("^A supple purple shell") then
    tarAffed("fangbarrier")
    tarAffed("sileris")
    if confirmAffV2 then
      confirmAffV2("fangbarrier")
      confirmAffV2("sileris")
    end
    if serpent and serpent.state then serpent.state.geckoStripAttempted = false end
  elseif ataxiaTemp then
    ataxiaTemp.silerisAppliedAt = getEpoch and getEpoch() or os.time()
  end
end
