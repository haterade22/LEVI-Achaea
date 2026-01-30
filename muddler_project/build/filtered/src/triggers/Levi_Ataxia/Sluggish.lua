if ataxiaTemp.focusVibes or ataxiaTemp.retardVibeHit then
  ataxiaTemp.focusVibes = nil
  ataxiaTemp.retardVibeHit = nil
  retardationOn()
  
elseif not affed("aeon") and not affed("blackout") and not ataxia.retardation then
  retardationOn()
  
elseif ataxiaTemp.checkingForRetardation and not ataxia.retardation then
  retardationOn()
  ataxiaTemp.checkingForRetardation = nil
  
elseif ataxiaTemp.checkingForRetardation and ataxia.retardation then
  --ignore
end

if ataxia.retardation then retardationDownCheck() end
