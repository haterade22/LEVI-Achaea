--[[mudlet
type: trigger
name: Erode
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Magi Offense Tracking
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 3
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: ''
mBgColor: ''
mSoundFile: ''
colorTriggerFgColor: ''
colorTriggerBgColor: ''
patterns:
- pattern: ^You cast a spell of erosion at (\w+)\.$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

local tgt = multimatches[1][2]
if not tgt or tgt ~= target then return end

local followup = multimatches[3][2]
if not followup then return end

-- Shield strip
erAff("shield")

-- Parse which defense was eroded
local defense = followup:match("^%w+ (%w+) defence is eroded away%.$")
if defense then
  local defMap = {
    rebounding = "rebounding",
    shield = "shield",
    blindness = "blindness",
    deafness = "deafness",
    insomnia = "insomnia",
    cloak = "cloak",
    speed = "speed",
  }
  local aff = defMap[defense]
  if aff then
    erAff(aff)
  end

  -- AN ERODED INSULATION IS RECORDED BY ITS ABSENCE (v4.7.420). ERODE strips the first of
  -- "Shield, chargeshield, insulation, and temperance" the target has
  -- (kb/raw/wiki/Elementalism.wiki:74), and a stripped insulation is the target affliction
  -- `nocaloric`: 021_Freeze, 015_Dehydrate and the water emanation record it, and the offense
  -- reads it as its `caloric` flag (004_Magi_Offense). The map above used to send `caloric` to
  -- erAff, which clears a name nothing sets (a recording fight log writes it as a cure), so an
  -- eroded insulation was never recorded. Only this line's own word decides: "insulation" is the
  -- game's name for the defence (its DEF list), "caloric" the salve's; a line that names neither
  -- records nothing.
  if defense == "insulation" or defense == "caloric" then
    tarAffed("nocaloric")
  end
end

magi.offense = magi.offense or {}
if magi.offense.ptRelay then
  local msg = target .. ": Erode (shield"
  if defense then msg = msg .. " + " .. defense end
  msg = msg .. ")"
  magi.offense.ptRelay(msg)
end
if magi.offense.debugEcho then
  magi.offense.debugEcho("Erode -> shield" .. (defense and (" + " .. defense) or ""))
end
