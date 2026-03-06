curseCharge = 14
swiftcursing = false

if ataxiaBasher.enabled and found_target then
  -- Attack dispatch now handled by unified tryAttack() gate in prompt handler
  if not ataxiaBasher.manual then
    deleteFull()
  end
end

