--[[mudlet
type: trigger
name: Water Emanation
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- Enamation
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
- pattern: ^The might of elemental Water surging through your body, you make the slightest flick
  type: 1
]]--

-- WATER EMANATION: "your target will be given a level of freeze (or have the insulation defence
-- stripped), and will be disrupted along with being afflicted with stuttering."
-- (Elementalism.wiki:242). Stuttering was never recorded until now.
--
-- THE LINE IS ABOUT 180 COLUMNS, and this user's server wraps at 119-124 (CLAUDE.md, v4.7.351).
-- The old pattern was the whole line, folded across two YAML lines where tools/check_wrap.py could
-- not see it (kb/CONFLICTS.md #2), so this trigger never fired. It now matches the opening words,
-- which no other emanation shares; the target's name ends the sentence, so it is read from the row
-- that finishes it (the highlighting/071 idiom). Every row of the cast is highlighted; only our
-- target's afflictions are recorded, as before.
local function record()
  magi.offense = magi.offense or {}
  magi.offense.state = magi.offense.state or {}

  if haveAff("shivering") and haveAff("nocaloric") then
    tarAffed("frozen")
    tarAffed("disrupted")
    tarAffed("stuttering")
    magi.offense.ptRelay(target .. ": Emanation Water (Frozen + Disrupted + Stuttering)")
  elseif haveAff("nocaloric") then
    tarAffed("shivering")
    tarAffed("disrupted")
    tarAffed("stuttering")
    magi.offense.ptRelay(target .. ": Emanation Water (Shivering + Disrupted + Stuttering)")
  else
    tarAffed("nocaloric")
    tarAffed("disrupted")
    tarAffed("stuttering")
    magi.offense.ptRelay(target .. ": Emanation Water (Nocaloric + Disrupted + Stuttering)")
  end
end

local function paint()
  selectCurrentLine() bg("cyan")
end

-- `text` is the sentence so far. Act once it names the target; otherwise read the next row (at
-- most two more).
local function read(text, left)
  local tgt = text:match("freezing deluge to smash (%w+)%.")
  if tgt then
    if tgt == target then record() end
    return
  end
  if left == 0 or text:match("%.%s*$") then return end
  tempLineTrigger(1, 1, function()
    paint()
    read((text:gsub("%s+$", "")) .. " " .. (line:gsub("^%s+", "")), left - 1)
  end)
end

paint()
read(line, 2)
