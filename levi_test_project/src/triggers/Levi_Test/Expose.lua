if not isTargeted(matches[2]) then return end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
else
  pariah.expose = true

  deselect()
  resetFormat()
end
