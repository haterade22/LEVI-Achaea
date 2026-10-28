--[[mudlet
type: alias
name: RW2H Mode
hierarchy:
- Levi_Ataxia
- Classes
- Knight
- RUNIE
- 2H
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^rw2h(?: (impale|overwhelm|tendons|break))?$
command: ''
packageName: ''
]]--

-- rw2h            show the mode
-- rw2h impale     main kill: 6 tendons -> devastate + upset -> impale -> disembowel (default)
-- rw2h overwhelm  warhammer: prone, break the head, overwhelm at 5 skull fractures, brain
-- rw2h tendons    overwhelm gets prone by tendons + devastate + upset (default)
-- rw2h break      overwhelm gets prone by breaking a leg + upset
local arg = matches[2]
if arg == "tendons" or arg == "break" then
  rw2h.config.overwhelmProne = arg
  rw2h.echo("Overwhelm gets prone by: <white>" .. arg)
elseif arg then
  rw2h.setMode(arg)
else
  rw2h.echo("Mode: <white>" .. rw2h.state.mode .. "<lavender>, overwhelm prone by <white>" .. rw2h.config.overwhelmProne)
end
