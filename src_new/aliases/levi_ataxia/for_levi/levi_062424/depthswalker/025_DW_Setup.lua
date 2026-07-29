--[[mudlet
type: alias
name: DW Setup
hierarchy:
- Levi_Ataxia
- Ataxia
- Depthswalker
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^dw setup( force| stop)?$
command: ''
packageName: ''
]]--

-- `dw setup` -- intone the one-time Terminus buffs (trusad/tsuura/mainaas/mainaad/
-- balateth/tah'maal/ukhia/qamad/dalem), one per word balance. `dw setup force` re-intones
-- even defences GMCP says are already up; `dw setup stop` clears the queue.
local arg = (matches[2] or ""):gsub("%s", "")
if arg == "stop" then
	ataxia_dwSetupStop()
else
	ataxia_dwSetup(arg == "force")
end
