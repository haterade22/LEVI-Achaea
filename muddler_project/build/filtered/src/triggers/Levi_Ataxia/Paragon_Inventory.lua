-- Parses "ii paragon" output lines like:
--     paragon514466           a crucious paragon
-- Registers each paragon in the armour management system

if ataxia and ataxia.armour and ataxia.armour.state and ataxia.armour.state.scanning then
  local id = matches[2]
  local name = matches[3]:match("^%s*(.-)%s*$") -- trim
  if id and name then
    ataxia.armour.registerParagon(id, name)
  end
end
