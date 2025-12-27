--[[mudlet
type: script
name: Outrifting Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Gmcp Related
- Rift
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--Set the Outrifted table.
ataxiaTemp.outrifted = {
	antimony = 0,
	argentum = 0,
	arsenic = 0,
	ash = 0,
	aurum = 0,
	azurite = 0,
	bayberry = 0,
	bellwort = 0,
	bisemutum = 0,
	bloodroot = 0,
	calamine = 0,
	calcite = 0,
	cinnabar = 0,
	cohosh = 0,
	cuprum = 0,
	dolomite = 0,
	echinacea = 0,
	elm = 0,
	ferrum = 0,
	ginger = 0,
	ginseng = 0,
	goldenseal = 0,
	gypsum = 0,
	hawthorn = 0,
	irid = 0,
	kelp = 0,
	kola = 0,
	lobelia = 0,
	magnesium = 0,
	malachite = 0,
	myrrh = 0,
	pear = 0,
	plumbum = 0,
	potash = 0,
	quartz = 0,
	quicksilver = 0,
	realgar = 0,
	sileris = 0,
	skullcap = 0,
	stannum = 0,
	valerian = 0,
}

--parsing function for extracting herb names
function returnHerbName(s)
	local found = false
	if s:find("potash") then
		found = "potash"
	else
  	for herb, num in pairs(ataxiaTemp.outrifted) do
			if s:find(herb) then
				found = herb
				break
			end
		end
	end
  return found
end

--get a number from a string
function extractNumberFromString(s)
	return tonumber(string.match(s, "(%d+)"))
end

function ataxia_precacheQueue()		
	if canOutrift() and not ataxiaTemp.outriftTimer then
		if ataxiaTemp.outriftTimer then killTimer(ataxiaTemp.outriftTimer) end
		ataxiaTemp.outriftTimer = tempTimer(2, [[ataxiaTemp.outriftTimer = nil]])
		for h, n in pairs(ataxiaTemp.outrifted) do
			if ataxiaTemp.keepout[h] and n < ataxiaTemp.keepout[h] then
				sendToOutrift(h, ataxiaTemp.keepout[h] - n)
			end
		end
	end
end

function sendToOutrift(herb, num)
	if not ataxia.afflictions.aeon then
		send("outr "..num.." "..herb)
	end
end

--Outrift failsafe.
function outrifted(herb, num)
	local what = returnHerbName(herb)
  local amount = tonumber(num)

  if what then
    ataxiaTemp.outrifted[what] = ataxiaTemp.outrifted[what] + amount
  end
end


function inrifted()
  ataxia_resetOutrifted()
	if ataxiaTemp.inraTimer then killTimer(ataxiaTemp.inraTimer) end
	ataxiaTemp.inraTimer = tempTimer(3, [[ataxiaTemp.inraTimer = nil; ataxia_precacheQueue()]])
end

function ataxia_resetOutrifted()
	ataxiaTemp.outrifted = {
		antimony = 0,
		argentum = 0,
		arsenic = 0,
		ash = 0,
		aurum = 0,
		azurite = 0,
		bayberry = 0,
		bellwort = 0,
		bisemutum = 0,
		bloodroot = 0,
		calamine = 0,
		calcite = 0,
		cinnabar = 0,
		cohosh = 0,
		cuprum = 0,
		dolomite = 0,
		echinacea = 0,
		elm = 0,
		ferrum = 0,
		ginger = 0,
		ginseng = 0,
		goldenseal = 0,
		gypsum = 0,
		hawthorn = 0,
		irid = 0,
		kelp = 0,
		kola = 0,
		lobelia = 0,
		magnesium = 0,
		malachite = 0,
		myrrh = 0,
		pear = 0,
		plumbum = 0,
		potash = 0,
		quartz = 0,
		quicksilver = 0,
		realgar = 0,
		sileris = 0,
		skullcap = 0,
		stannum = 0,
		valerian = 0,
	}
end
