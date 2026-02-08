local atk = combatQueue()
local curses = {}
local venoms = {}




  
if not tAffs.paralysis then
    table.insert(curses,"paralysis")
end
if not tAffs.impatience then
    table.insert(curses,"impatience")
end
if not tAffs.asthma then
    table.insert(curses,"asthma")
end

if not tAffs.stupidity then
    table.insert(curses,"stupidity")
end

if not tAffs.weariness then
    table.insert(curses,"weariness")
end

if not tAffs.recklessness then
    table.insert(curses,"recklessness")
end

if not tAffs.sensitivity then
    table.insert(curses,"sensitivity")
end

if not tAffs.paralysis and curses[1] ~= "paralysis" then
    table.insert(venoms,"curare")
end

if not tAffs.asthma and curses[1] ~= "asthma" then
    table.insert(venoms,"kalmia")
end

if not tAffs.stupidity and curses[1] ~= "stupidity" then
    table.insert(venoms,"aconite")
end

if not tAffs.slickness then
    table.insert(venoms,"gecko")
end

if not tAffs.anorexia then
    table.insert(venoms,"slike")
end

if not tAffs.shield then
	atk = atk.."wield shield;dragoncurse "..target.." "..curses[1].." 1;rend "..target.." torso "..venoms[1]..";breathgust "..target
  end
  
  if tAffs.shield then
	atk = atk.."tailsmash "..target
  end

if not ataxia.settings.paused then
	send("queue addclear free "..atk)
end
