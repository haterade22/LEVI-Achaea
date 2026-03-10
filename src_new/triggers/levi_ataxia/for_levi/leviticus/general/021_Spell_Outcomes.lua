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

-- This trigger handles multiple spell patterns
-- Each pattern fires this script; check which matched

local tgt = matches[2]
if not tgt or tgt ~= target then return end

local line = matches[1]

-- Magma
if line:find("bubbling magma") then
  magi.offense.setScalded()
  tarAffed("scalded")
  magi.offense.ptRelay(target .. ": Magma (scalded)")
  magi.offense.debugEcho("Magma hit → scalded")

-- Dehydrate
elseif line:find("rip the excess water") then
  magi.offense.state.burns = (magi.offense.state.burns or 0) + 1
  magi.offense.ptRelay(target .. ": Dehydrate (burns:" .. magi.offense.state.burns .. ")")
  magi.offense.debugEcho("Dehydrate hit → burns:" .. magi.offense.state.burns)

-- Fulminate
elseif line:find("lightning strikes from the air") then
  tarAffed("fulminated")
  magi.offense.state.burns = (magi.offense.state.burns or 0) + 1
  magi.offense.ptRelay(target .. ": Fulminate (burns:" .. magi.offense.state.burns .. ")")
  magi.offense.debugEcho("Fulminate hit → burns:" .. magi.offense.state.burns)

-- Bombard
elseif line:find("flurry of rocks to bombard") then
  magi.offense.ptRelay(target .. ": Bombard")
  magi.offense.debugEcho("Bombard hit")

-- Firelash
elseif line:find("lash of fire") then
  magi.offense.state.burns = (magi.offense.state.burns or 0) + 1
  tfirelash = true
  magi.offense.ptRelay(target .. ": Firelash (burns:" .. magi.offense.state.burns .. ")")
  magi.offense.debugEcho("Firelash hit → burns:" .. magi.offense.state.burns)

-- Mudslide
elseif line:find("torrent of thick mud") then
  tarAffed("prone")
  magi.offense.ptRelay(target .. ": Mudslide (prone)")
  magi.offense.debugEcho("Mudslide hit → prone")
end

-- Burns counter display
if magi.offense.state.burns > 0 then
  cecho(" <DimGrey>[<red>" .. magi.offense.state.burns .. "/5<DimGrey>]")
end
