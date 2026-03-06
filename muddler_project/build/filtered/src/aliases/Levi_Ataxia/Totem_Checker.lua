local args = (matches[2] or ""):match("^%s*(.-)%s*$")

if args == "" then
  totemChecker.start()
elseif args == "stop" then
  totemChecker.stop()
elseif args == "status" then
  totemChecker.status()
else
  totemChecker.echo("Usage: totcheck [stop|status]")
end
