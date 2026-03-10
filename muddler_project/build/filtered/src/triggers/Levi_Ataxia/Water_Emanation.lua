local tgt = matches[2]
if tgt ~= target then return end

magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}

if magi.offense.hasAff("shivering") or (tAffs and tAffs.shivering) then
  tarAffed("shivering")
  tarAffed("disrupted")
  tarAffed("frozen")
  magi.offense.ptRelay(target .. ": Emanation Water (Shivering + Disrupted + Frozen)")
elseif not magi.offense.hasAff("frostbite") or (tAffs and tAffs.nocaloric) then
  tarAffed("shivering")
  tarAffed("disrupted")
  magi.offense.ptRelay(target .. ": Emanation Water (Shivering + Disrupted)")
else
  tarAffed("nocaloric")
  tarAffed("disrupted")
  magi.offense.ptRelay(target .. ": Emanation Water (Disrupted)")
end
selectCurrentLine() bg("cyan")