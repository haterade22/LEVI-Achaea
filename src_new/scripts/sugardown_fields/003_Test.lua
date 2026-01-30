--[[mudlet
type: script
name: Test
hierarchy:
- Sugardown Fields
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function sugardown.testList()
  -- make sure tiles will actually build
  racetrackList = true

  -- create fake data in the same shape tiles expect
  humgiiList = {
    { name="Cinderhoof", points=87, jockey="Mara",   jockeyPts=42, winCr=120, placeCr=80,  showCr=55 },
    { name="Blue Comet", points=91, jockey="Rook",   jockeyPts=39, winCr=150, placeCr=90,  showCr=60 },
    { name="Dirt Rocket",points=73, jockey="Sable",  jockeyPts=28, winCr=95,  placeCr=70,  showCr=45 },
    { name="Glimmerfax", points=88, jockey="Nix",    jockeyPts=41, winCr=130, placeCr=85,  showCr=58 },
    { name="Night Warden",points=79,jockey="Vonn",   jockeyPts=33, winCr=110, placeCr=75,  showCr=50 },
    { name="Sunspike",   points=84, jockey="Kara",   jockeyPts=36, winCr=125, placeCr=82,  showCr=57 },
  }

  cecho("\n<orange>== sugardown test: rendering tiles ==<reset>\n")
  if sugardown.renderHumgiiTiles then
    sugardown.renderHumgiiTiles()
  else
    cecho("<red>ERROR:<reset> sugardown.renderHumgiiTiles() not found. Paste the main script first.\n")
  end

  cecho("<orange>Click any <black:yellow> Bet <reset><orange> button above to verify it fills your command line.<reset>\n\n")
end

function sugardown.testView()
  sugardown.betsByRacer = {
    ["Big Gob"] = {
      track = "Sugardown Fields",
      win = true, place = false, show = false,
      winAmt = 3, placeAmt = 0, showAmt = 0,
    },
    ["Snacks It All"] = {
      track = "Sugardown Fields",
      win = false, place = true, show = false,
      winAmt = 0, placeAmt = 2, showAmt = 0,
    },
    ["The Flying Lunchman"] = {
      track = "Sugardown Fields",
      win = false, place = false, show = true,
      winAmt = 0, placeAmt = 0, showAmt = 1,
    },
    ["Kiss My Sass"] = {
      track = "Sugardown Fields",
      win = true, place = true, show = true,
      winAmt = 1, placeAmt = 1, showAmt = 1,
    },
  }

  humgiiList = {
    { name = "Big Gob",             winCr = 100, placeCr = 60, showCr = 40 },
    { name = "Snacks It All",       winCr = 120, placeCr = 75, showCr = 50 },
    { name = "The Flying Lunchman", winCr = 90,  placeCr = 55, showCr = 35 },
    { name = "Kiss My Sass",        winCr = 200, placeCr = 120, showCr = 80 },
  }

  local lines = {
    "1st: Big Gob (rider: Telma Jasun)",
    "2nd: Snacks It All (rider: Ogmund Oneeye)",
    "3rd: Legacy of Skipicus (rider: Yapa Sangkik)",
    "4th: Belly 'o Beans (rider: Annabelle Tizzle)",
    "5th: Double Time (rider: Arbela Shamash)",
    "6th: The Flying Lunchman (rider: Sarma Anta)",
    "7th: Kiss My Sass (rider: Jairn Tarsh)",
    "8th: Touch of Shallam (rider: Msasu Saulo)",
  }

  cecho("\n<white>--- trigger test start ---<reset>\n")

  for _, l in ipairs(lines) do
    feedTriggers(l .. "\n")
  end

  cecho("<white>--- trigger test end ---<reset>\n\n")
end
