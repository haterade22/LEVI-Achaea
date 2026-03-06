if totemChecker and totemChecker.state and totemChecker.state.active
   and totemChecker.state.phase == "probing" then
  totemChecker.onProbeEmpowered()
end
