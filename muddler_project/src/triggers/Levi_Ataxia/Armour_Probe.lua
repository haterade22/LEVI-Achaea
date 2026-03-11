-- Parses "probe armour" embrasure lines like:
-- 1: a resonate metalliferous paragon (paragon500167)     shifting damage protection (physical blunt)
-- Populates current slot state for skip-swap optimization

if ataxia and ataxia.armour and ataxia.armour.state and ataxia.armour.state.probing then
  local slotNum = tonumber(matches[2])
  local paragonId = matches[3]
  if slotNum and paragonId and slotNum >= 1 and slotNum <= 3 then
    ataxia.armour.state.currentSlots[slotNum] = paragonId
  end
end
