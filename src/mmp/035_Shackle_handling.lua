-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > Achaea > Shackle handling

local density = false
--Wear shackle function

function mmp.WearShackle()
  if mmp.settings.shackle and density then
    send("wear shackle")
  end
end

function mmp.UnwearShackle()
  if mmp.settings.shackle and mmp.defs.current.density then
    density = true
    send("remove shackle")
  elseif not mmp.defs.current.density then
    density = false
  end
end

--Event Handlers
registerAnonymousEventHandler("mmapper failed path", "mmp.WearShackle")
registerAnonymousEventHandler("mmapper stopped", "mmp.WearShackle")
registerAnonymousEventHandler("mmapper arrived", "mmp.WearShackle")
registerAnonymousEventHandler("started speedwalk", "mmp.UnwearShackle")