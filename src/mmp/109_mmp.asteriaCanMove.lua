-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Asteria > mmp.asteriaCanMove

-- Asteria's GMCP butts heads with existing GMCP 'able' checks in the speedwalking script. This works around it.

function mmp.asteriaCanMove(_, game)
  if game ~= "Asteria" then
    return
  end

function mmp.mapperCanMove()
    return gmcp.Char and gmcp.Char.Balance and gmcp.Char.Balance.balance == 0
  end
end