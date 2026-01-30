local profile = ataxia.settings.defences.current

if profile == "none" or profile == nil then
	ataxiaEcho("Not currently in a defup profile. Please switch to one first.")
	return
end

local dl = ataxia.settings.defences.keepup[profile]

if matches[2] == "sl" then
  if not dl.selfishness then
    addToKeepup("selfishness")
  else
    ataxiaEcho("No longer keeping up selfishness.")
    ataxia.settings.defences.defup[profile].selfishness = nil
    ataxia.settings.defences.keepup[profile].selfishness = nil
    sendAll("curing priority defence selfishness reset", "queue addclear free generosity",false)
  end
elseif matches[2] == "mass" then
  if not dl.mass then
    addToKeepup("mass")
  else
    ataxiaEcho("No longer keeping up mass.")
    ataxia.settings.defences.defup[profile].mass = nil
    ataxia.settings.defences.keepup[profile].mass = nil
    send("curing priority defence mass reset", false)
  end
elseif matches[2] == "br" then
  if not dl.heldbreath then
    addToKeepup("heldbreath")
  else
    ataxiaEcho("No longer holding breath.")
    ataxia.settings.defences.defup[profile].heldbreath = nil
    ataxia.settings.defences.keepup[profile].heldbreath = nil
    send("curing priority defence heldbreath reset", false)  
  end
else
  if not dl.rebounding then
    addToKeepup("rebounding")
  else
    ataxiaEcho("No longer keeping up rebounding.")
    ataxia.settings.defences.defup[profile].rebounding = nil
    ataxia.settings.defences.keepup[profile].rebounding = nil
    send("curing priority defence rebounding reset", false)
  end
end