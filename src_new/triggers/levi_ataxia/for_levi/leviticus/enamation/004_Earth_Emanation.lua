--[[mudlet
type: trigger
name: Earth Emanation
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
- pattern: ^The might of elemental Earth thrumming within your bones, you point
  type: 1
]]--

-- EARTH EMANATION: "your target's torso will become calcified. Additionally, if cast against
-- someone with serious internal trauma, your foe shall be slain outright." (Elementalism.wiki:242)
-- What this trigger records is unchanged: the magi.calcifying_head flag and the party relay. A
-- calcified torso is recorded by general/026_Calcify.lua, from "You sense calcification setting in
-- across the torso of <target>." (no capture shows whether this emanation prints that line). The
-- flag says HEAD where the wiki says TORSO, and nothing reads it.
--
-- THE LINE IS ABOUT 157 COLUMNS, and this user's server wraps at 119-124 (CLAUDE.md, v4.7.351).
-- The old pattern was the whole line, folded across two YAML lines where tools/check_wrap.py could
-- not see it (kb/CONFLICTS.md #2), so this trigger never fired. Since v4.7.420 it matches the
-- opening words, as the water emanation (002) does; the target's name falls on row 1 or 2
-- depending on the width and the name, so the rows are joined until the sentence closes and the
-- name is read from that. Every row of the cast is highlighted; only our target is recorded.
local function record()
  -- Emanation earth STARTS calcification process, not completes it
  -- Actual calcify success tracked in 026_Calcify.lua
  magi.calcifying_head = true
  magi.offense.ptRelay(target .. ": Emanation Earth (calcifying)")
end

local function paint()
  selectCurrentLine() bg("cyan")
end

-- `text` is the sentence so far. Act once it has closed with the name in it; otherwise read the
-- next row (at most two more).
local function read(text, left)
  local tgt = text:match("staff at (%w+) and an intangible wave of power strikes forth to smite %w+%.")
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
