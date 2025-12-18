-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Initialize > mmp.mapdata_changed

-- aggregates map load and such events into one
function mmp.mapdata_changed()
  raiseEvent("mmapper map reloaded")
end
					