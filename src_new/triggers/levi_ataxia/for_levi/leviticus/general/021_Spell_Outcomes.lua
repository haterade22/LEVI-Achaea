--[[mudlet
type: trigger
name: Spell Outcomes
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: ''
colorTriggerBgColor: ''
patterns:
- pattern: ^You weave fire and earth and bubbling magma boils into existence to wash over (\w+) in a skin-melting tide\.$
  type: 1
- pattern: ^Weaving the elements of fire and water, you attempt to rip the excess water from the body of (\w+)\.$
  type: 1
- pattern: ^You click your fingers and lightning strikes from the air to smite (\w+)\.$
  type: 1
- pattern: ^You tap the Elemental Plane of Earth, summoning up a flurry of rocks to bombard (\w+)\.$
  type: 1
- pattern: ^You form a lash of fire, and send it to scorch the flesh of (\w+)\.$
  type: 1
- pattern: ^You weave earth and water and a torrent of thick mud thunders forth to roll over (\w+), knocking \w+ sprawling\.$
  type: 1
]]--

-- Unified spell outcome handler (merged from 011, 013, 016, 017, 018)
-- Supersedes: 011_Mudslide, 013_Fulminate, 016_Bombard, 017_Magma, 018_Firelash

local tgt = matches[2]
if not tgt or tgt ~= target then return end

local line = matches[1]
magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}

-- Magma -> scalded (from 017_Magma)
if line:find("bubbling magma") then
  tarAffed("scalded")
  if magi.offense.setScalded then magi.offense.setScalded() end
  tempTimer(20, [[erAff("scalded")]])
  magi.offense.ptRelay(target .. ": Magma (scalded)")
  magi.offense.debugEcho("Magma hit -> scalded")

-- Dehydrate cast line — outcome tracked by separate triggers (015, 021_Frozen, 022_Burning)
-- Do NOT increment burns here -- we don't know the outcome yet
elseif line:find("rip the excess water") then
  magi.offense.ptRelay(target .. ": Dehydrate")
  magi.offense.debugEcho("Dehydrate cast")

-- Fulminate — smart chain: fulminated -> epilepsy -> paralysis (from 013_Fulminate)
elseif line:find("lightning strikes from the air") then
  if haveAff("epilepsy") and haveAff("fulminated") and not haveAff("paralysis") then
    tarAffed("paralysis")
    magi.offense.ptRelay(target .. ": Fulminate (paralysis)")
  elseif not haveAff("epilepsy") and haveAff("fulminated") then
    tarAffed("epilepsy")
    magi.offense.ptRelay(target .. ": Fulminate (epilepsy)")
  else
    tarAffed("fulminated")
    magi.offense.ptRelay(target .. ": Fulminate (fulminated)")
  end
  magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
  tburns = magi.offense.state.burns
  magi.offense.debugEcho("Fulminate hit -> burns:" .. magi.offense.state.burns)

-- Bombard -> clumsiness (from 016_Bombard)
elseif line:find("flurry of rocks to bombard") then
  tarAffed("clumsiness")
  magi.offense.ptRelay(target .. ": Bombard (clumsiness)")
  magi.offense.debugEcho("Bombard hit -> clumsiness")

-- Firelash -> burning + burns increment (from 018_Firelash)
elseif line:find("lash of fire") then
  magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
  tburns = magi.offense.state.burns
  tfirelash = true
  tarAffed("burning")
  selectCurrentLine() fg("red")
  magi.offense.ptRelay(target .. ": Firelash (burning, burns:" .. magi.offense.state.burns .. ")")
  magi.offense.debugEcho("Firelash hit -> burning, burns:" .. magi.offense.state.burns)

-- Mudslide -> slickness + prone (from 011_Mudslide)
elseif line:find("torrent of thick mud") then
  tarAffed("slickness")
  tarAffed("prone")
  magi.offense.ptRelay(target .. ": Mudslide (slickness + prone)")
  magi.offense.debugEcho("Mudslide hit -> slickness + prone")
end

-- Burns counter display (only for spells that actually affect burns)
if (line:find("lightning strikes") or line:find("lash of fire")) and magi.offense.state.burns and magi.offense.state.burns > 0 then
  cecho(" <DimGrey>[<red>" .. magi.offense.state.burns .. "/5<DimGrey>]")
end
