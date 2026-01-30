--[[mudlet
type: script
name: zgui.stats()
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Logger
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: zgui.stats()
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- ZulahGUI - Saonji Edit
- zGUI Redux
- Logger
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function zgui.stats()
  if zgui.vitals and gmcp.Char and gmcp.Char.Vitals then
  zgui.vitals.h = tonumber(gmcp.Char.Vitals.hp)
  zgui.vitals.m = tonumber(gmcp.Char.Vitals.mp)
  zgui.vitals.e = tonumber(gmcp.Char.Vitals.ep)
  zgui.vitals.w = tonumber(gmcp.Char.Vitals.wp)

  zgui.vitals.maxh = tonumber(gmcp.Char.Vitals.maxhp)
  zgui.vitals.maxm = tonumber(gmcp.Char.Vitals.maxmp)
  zgui.vitals.maxe = tonumber(gmcp.Char.Vitals.maxep)
  zgui.vitals.maxw = tonumber(gmcp.Char.Vitals.maxwp)
	
	----------------------------------------------------------
	zgui.statChange() -- If you want to see health and Mana changes in Log window

  zgui.vitals.oh = zgui.vitals.h
  zgui.vitals.om = zgui.vitals.m	
  end
end

registerAnonymousEventHandler("gmcp.Char.Vitals", "zgui.stats")