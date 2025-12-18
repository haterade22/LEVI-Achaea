-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SHIKUDO > TELEPATHY > DISRUPT

function disruptmind()

local atk = combatQueue()


if not tAffs.blackout then 
  atk = atk.."mind blackout"
elseif tAffs.blackout and not tAffs.confusion then
  atk = atk.."mind confuse"
  elseif tAffs.confusion and not tAffs.disrupted then
  atk = atk.."mind disrupt"
elseif tAffs.confusion and tAffs.disrupted and not tAffs.impatience then
  atk = atk.."mind impatience"
  end
  




if not ataxia.settings.paused and not ataxia_needLockBreak() and not ataxia.afflictions.stupidity then


send("queue addclear free "..atk)

end
end