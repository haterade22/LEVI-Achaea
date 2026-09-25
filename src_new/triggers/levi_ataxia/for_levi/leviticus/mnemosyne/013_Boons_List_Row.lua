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

-- Remember what we OWN (the library is everything we've ever been offered, which is a
-- different set). `mnem boonfill` reads this to CONTEMPLATE the ones with no description --
-- the only way to learn a boon claimed before the catalogue existed. ataxiaTemp: not
-- serialized, rebuilt every time BOONS scrolls past.
ataxiaTemp.boonsOwned = ataxiaTemp.boonsOwned or {}
ataxiaTemp.boonsOwned[name] = rarity

-- ...and ARM IT (v4.7.350). `M.BOON_FLAGS` has always said it latches from "the BOON CLAIM (as it
-- happens) and the BOONS list (on demand, and after a reload)" -- and only the first half was
-- ever true. This row is the BOONS list: `M._relatchBoons` sends `boon claimed` once per run
-- precisely so a reload mid-run can put every owned boon back, and the rows arrived here, were
-- recorded as owned, coloured, annotated... and never latched. The boons with a hand-written
-- row trigger of their own (Panoply, Army of the Dead, ...) came back; the fifteen that live
-- ONLY in the table did not. Dead Breath and Deathtempest are two of them, so a reimport
-- mid-run silently stopped the belch and the soulstorm -- and a belch cannot re-latch its own
-- flag from its boon line, because the rider never fires without the flag.
--
-- Safe to latch from: this pattern demands the echo count AND a rarity word, which is the shape
-- of what we OWN. The offer screen prints `Name:   description` with neither, so an offered-
-- but-declined boon cannot arrive here. pcall'd: arming a flag must never break the listing.
--
-- ONLY INSIDE THE TOWER (v4.7.351, deep review). Neither this trigger nor latchBoonFlag checked,
-- and of the table's twenty consumers exactly one (Sharp Mind) checks for itself -- so a list
-- printed outside a run would have armed the belch, the soulstorm, the Psion keepers and
-- Timequake for ordinary bashing. `inMnemosyne` is owned by the wade lifecycle and is already TRUE
-- when the reload re-latch runs: the wade-status trigger asserts it before onRipple sends
-- `boon claimed`. The library learning above stays ungated on purpose.
if mnem.latchBoonFlag and ataxiaBasher and ataxiaBasher.inMnemosyne then
  pcall(mnem.latchBoonFlag, name)
end
-- _learnBoon only mutates the in-memory table; every other _historySave caller sits behind a
-- telemetry gate, so without this the back-filled rarity would die with the session. Debounced,
-- because this trigger fires once per row of the list.
if mnem._historySaveSoon then mnem._historySaveSoon() end

local colour = mnem.rarityColour and mnem.rarityColour(rarity) or "white"

-- Colour the row itself by rarity so the list scans at a glance.
if selectString and fg and resetFormat and type(line) == "string" and line ~= "" then
  pcall(function() selectString(line, 1); fg(colour); resetFormat() end)
end

-- Then say what it does -- but ONLY if we actually know. A boon is only learned when its offer
-- screen goes by, so early on most rows are unknown; printing a placeholder under every one of
-- them would double the list's length and bury the table it is annotating. Silence is the
-- honest default: the row is still rarity-coloured, and the description appears once learned.
local desc = rec.description
if cecho and desc and desc ~= "" then
  local echoStr = (echoes and echoes > 1) and (" <grey>x" .. echoes) or ""
  pcall(cecho, "\n     <" .. colour .. ">|<grey> " .. desc .. echoStr)
end
