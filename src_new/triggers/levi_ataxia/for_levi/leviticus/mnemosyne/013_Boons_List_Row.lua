--[[mudlet
type: trigger
name: Mnemosyne Boons List Row
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
- pattern: ^(\S.*?)\s\s+(\d+)\s\s+(common|uncommon|rare|legendary|mythical)\s*$
  type: 1
]]--

-- A row of the BOONS list: `<name>  <echoes>  <rarity>`.
--
-- The BOONS list tells you WHAT you own but never what any of it DOES -- only the offer
-- screen carries descriptions. We learn every boon we are ever offered into
-- ataxia.mnemosyne.history.boonLibrary, so here we can join the two and print what each
-- owned boon actually does, coloured by rarity.
--
-- Also back-fills rarity into the library: the offer screen doesn't state it, this list does.
-- Anchored on the rarity word, so ordinary prose can't match.
local name, echoes, rarity = matches[2], tonumber(matches[3]), matches[4]
local mnem = ataxia and ataxia.mnemosyne
if not (mnem and mnem._learnBoon) then return end

name = name:gsub("%s+$", "")
local rec = mnem._learnBoon(name, nil, rarity) or {}

local colour = mnem.rarityColour and mnem.rarityColour(rarity) or "white"

-- Colour the row itself by rarity so the list scans at a glance.
if selectString and fg and resetFormat and type(line) == "string" and line ~= "" then
  pcall(function() selectString(line, 1); fg(colour); resetFormat() end)
end

-- Then say what it does. Unknown = we have never been offered it (so never saw a
-- description); say so rather than printing a confusing blank.
if cecho then
  local desc = rec.description
  local echoStr = (echoes and echoes > 1) and (" <grey>x" .. echoes) or ""
  if desc and desc ~= "" then
    pcall(cecho, "\n     <" .. colour .. ">|<grey> " .. desc .. echoStr)
  else
    pcall(cecho, "\n     <" .. colour .. ">|<grey> (no description learned yet -- seen on an offer screen it will be recorded)" .. echoStr)
  end
end
