-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Achaea > Shackle handling

local density = false
--Wear shackle function

function mmp.wearShackle()
  if mmp.settings.shackle and density then
    send("wear shackle")
  end
end

function mmp.unwearShackle()
  if mmp.settings.shackle and mmp.defs.current.density then
    density = true
    send("remove shackle")
  elseif not mmp.defs.current.density then
    density = false
  end
end

--Event Handlers
registerAnonymousEventHandler("mmapper failed path", "mmp.wearShackle")
registerAnonymousEventHandler("mmapper stopped", "mmp.wearShackle")
registerAnonymousEventHandler("mmapper arrived", "mmp.wearShackle")
registerAnonymousEventHandler("started speedwalk", "mmp.unwearShackle")