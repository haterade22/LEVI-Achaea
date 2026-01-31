if ataxiaBasher.paused then
  ataxia_Echo("Unpausing to resume bashing.")
  ataxiaBasher.paused = false
  ataxiaBasher_patterns()
 else
  ataxia_Echo("Pausing all basher actions.")
  ataxiaBasher.paused = true
  send("cq all",false)
end