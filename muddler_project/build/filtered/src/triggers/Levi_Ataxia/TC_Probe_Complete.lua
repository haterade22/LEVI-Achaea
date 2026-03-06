-- Set flag instead of calling onProbeComplete() directly.
-- The prompt handler will process results AFTER all probe output lines
-- (including the empowered line that comes after this) have been received.
if totemChecker and totemChecker.state and totemChecker.state.active
   and totemChecker.state.phase == "probing" then
  totemChecker.state.probeDataReceived = true
end
