-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > RuneWarden > SNB

--myferocity = string.match(gmcp.Char.Vitals.charstats[4],"Ferocity\: (%w+)")
ferocity_full = false
function snbsoftlock()
envenomList = {}
if ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end


svenom1 = ""

if tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.anorexia and tAffs.weariness and tAffs.voyria then
	svenom1 = "voyria"
  table.insert(envenomList, "voyria")
  -- Voyria
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.anorexia and tAffs.weariness then
  svenom1 = "eurypteria"
  table.insert(envenomList, "eurypteria")
elseif tAffs.slickness and tAffs.asthma and tAffs.anorexia and tAffs.weariness then
  svenom1 = "eurypteria"
  table.insert(envenomList, "eurypteria")
elseif tAffs.anorexia and tAffs.stupidity then
  svenom1 = "eurypteria"
  table.insert(envenomList, "eurypteria")
elseif tAffs.anorexia then
  svenom1 = "aconite"
  table.insert(envenomList, "aconite")
elseif tAffs.slickness and tAffs.asthma and tAffs.prone then
  svenom1 = "slike"
  table.insert(envenomList, "slike")
elseif tAffs.slickness and tAffs.asthma then
  svenom1 = "slike"
  table.insert(envenomList, "slike")
elseif tAffs.asthma and tAffs.paralysis and tAffs.prone then
	svenom1 = "gecko"
  table.insert(envenomList, "gecko")
elseif tAffs.asthma and not tAffs.slickness then
	svenom1 = "gecko"
  table.insert(envenomList, "gecko")
elseif not tAffs.asthma and tAffs.weariness and tAffs.clumsiness then 
	svenom1 = "kalmia"
  table.insert(envenomList, "kalmia")
elseif tAffs.weariness and not tAffs.clumsiness then
  svenom1 = "xentio"
  table.insert(envenomList, "xentio")
elseif not tAffs.weariness then
  svenom1 = "vernalius"
  table.insert(envenomList, "vernalius")

else
	svenom1 = "darkshade"
  table.insert(envenomList, "darkshade")
  end
end

function shieldstrike()
  sstrike = ""
if tAffs.slickness and tAffs.asthma then
  sstrike = "high"
elseif tAffs.anorexia then
  sstrike = "high"
elseif not tAffs.anorexia and svenom1 == "slike" then
  sstrike = "high"
elseif tAffs.paralysis and tAffs.anorexia then
  sstrike = "high" 
elseif tAffs.prone then
  sstrike = "high"
elseif tAffs.paralysis or tAffs.slickness and tAffs.prone then
  sstrike = "high"
elseif tAffs.slickness then
  sstrike = "high"
elseif not tAffs.paralysis and svenom1 ~= "curare" then
	sstrike = "mid"
elseif not tAffs.clumsiness then
  sstrike = "low"
else
	sstrike = "high"
  end
end


function snblimblock()

if ataxia.vitals.class == 4 then
ferocity_full = true
else 
ferocity_full = false
end

envenomList = {}

svenom1 = ""

if tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.anorexia and tAffs.weariness and tAffs.voyria then
	svenom1 = "voyria"
  -- Voyria
  table.insert(envenomList, "voyria")
elseif tAffs.slickness and tAffs.asthma and tAffs.impatience and tAffs.anorexia and tAffs.weariness then
 svenom1 = "eurypteria"
 table.insert(envenomList, "eurypteria")
elseif tAffs.slickness and tAffs.asthma and tAffs.anorexia and tAffs.weariness then
  svenom1 = "eurypteria"
  table.insert(envenomList, "eurypteria")
elseif tAffs.anorexia and tAffs.stupidity then
  svenom1 = "eurypteria"
  table.insert(envenomList, "eurypteria")
elseif tAffs.slickness and tAffs.asthma and tAffs.prone then
  svenom1 = "slike"
  table.insert(envenomList, "slike")
elseif tAffs.slickness and tAffs.asthma then
  svenom1 = "slike"
  table.insert(envenomList, "slike")
elseif tAffs.asthma and tAffs.paralysis and tAffs.prone then
	svenom1 = "gecko"
  table.insert(envenomList, "gecko")
elseif tAffs.asthma and not tAffs.slickness then
	svenom1 = "gecko"
  table.insert(envenomList, "gecko")
elseif not tAffs.asthma and tAffs.weariness and tAffs.clumsiness then 
	svenom1 = "kalmia"
  table.insert(envenomList, "kalmia")
elseif not tAffs.clumsiness and tAffs.weariness then
  svenom1 = "xentio"
  table.insert(envenomList, "xentio")

elseif not tAffs.weariness then
	svenom1 = "vernalius"
  table.insert(envenomList, "vernalius")
else
	svenom1 = "darkshade"
  table.insert(envenomList, "darkshade")
  end
end