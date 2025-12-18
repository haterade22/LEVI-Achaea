-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Ashyria > mmp.ashyriaCanMove

-- Asteria's GMCP butts heads with existing GMCP 'able' checks in the speedwalking script. This works around it.

function mmp.ashyriaCanMove(_, game)
  if game ~= "ashyria" then
    return
  end

function mmp.mapperCanMove()
    return gmcp.Char and gmcp.Char.Balance and gmcp.Char.Balance.balance == 0
  end
end