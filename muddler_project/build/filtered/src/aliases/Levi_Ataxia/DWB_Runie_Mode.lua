local cmd = matches[2]
if cmd == "status" then
  dwbRunie.status()
else
  dwbRunie.setMode(cmd)
end
