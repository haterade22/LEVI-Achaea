local movedir = "down"
local command = "queue addclear free "
jumping = jumping or false
if
(gmcp.Char.Status.class == "earth Elemental Lord" or gmcp.Char.Status.class == "Silver Dragon")
and jumping
then
command = command.."leap "..movedir
end

if
(gmcp.Char.Status.class == "Infernal" or gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Apostate")
and jumping then
command = command.."mountjump "..movedir


end
if ataxiaBasher.enabled and not ataxiaBasher.manual and not autoHarvesting then
	if mmp.paused then mmp.pause("off") end
	ataxiaTemp.bashFlee = true
end


if ataxiaTemp.goldInRoom then command = command.."get gold"..ataxia.settings.separator.."put gold in tophat"..ataxia.settings.separator end
if not jumping then command = command..(gliding == true and "glide " or "").."d" end
send(command)