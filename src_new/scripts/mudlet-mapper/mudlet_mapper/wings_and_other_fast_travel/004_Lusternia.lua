--[[mudlet
type: script
name: Lusternia
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Wings and other fast travel
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

registerAnonymousEventHandler("mmp link externals", "mmp.addWingsLusternia")

function mmp.addWingsLusternia()
  if mmp.game ~= "lusternia" then
    return
  end
  --items that use standard bix rules
  if mmp.usebix() then
    --cubix and things
    if mmp.settings.medallion then
      mmp.tempSpecialExit(13367, "touch medallion")
    end
    if mmp.settings.cubix then
      mmp.tempSpecialExit(6184, "touch cubix")
    end
    if mmp.settings.torus and mmp.usebix() then
      mmp.tempSpecialExit(28548, "touch torus")
    end
    --epic quest items
    if mmp.settings.fingerblade then
      mmp.tempSpecialExit(18777, "touch fingerblade")
    end
    if mmp.settings.blossom then
      mmp.tempSpecialExit(18730, "touch blossom")
    end
    if mmp.settings.mandala then
      mmp.tempSpecialExit(19563, "touch mandala")
    end
    if mmp.settings.belt then
      mmp.tempSpecialExit(19627, "touch enlightened")
    end
    if mmp.settings.mantle then
      mmp.tempSpecialExit(18762, "touch starlight")
    end
    if mmp.settings.key then
      mmp.tempSpecialExit(18732, "touch key")
    end
  end
  --things which use prism rules
  if mmp.useprism() then
    if mmp.settings.prism then
      mmp.tempSpecialExit(6182, "touch prism")
    end
    --curio collections
    if mmp.settings.bonecurio then
      mmp.tempSpecialExit(28613, "curio collection activate bone")
    end
    if mmp.settings.flowercurio then
      mmp.tempSpecialExit(28624, "curio collection activate flower")
    end
    if mmp.settings.utensilcurio then
      mmp.tempSpecialExit(28617, "curio collection activate utensil")
    end
    if mmp.settings.fluttercurio then
      mmp.tempSpecialExit(28622, "curio collection activate flutter")
    end
    if mmp.settings.toolcurio then
      mmp.tempSpecialExit(28586, "curio collection activate tool")
    end
    if mmp.settings.facecurio then
      mmp.tempSpecialExit(28433, "curio collection activate face")
    end
    if mmp.settings.toycurio then
      mmp.tempSpecialExit(21548, "curio collection activate toy")
    end
    if mmp.settings.feathercurio then
      mmp.tempSpecialExit(28591, "curio collection activate feather")
    end
    if mmp.settings.figurecurio then
      mmp.tempSpecialExit(28312, "curio collection activate figure")
    end
    if mmp.settings.vernalcurio then
      mmp.tempSpecialExit(29908, "curio collection activate vernal")
    end
    if mmp.settings.soullesscurio then
      mmp.tempSpecialExit(29909, "curio collection activate soulless")
    end
  end
  --all the bubblixes!
  local bubblixes =
    {
      {
        setting = "figurine",
        item = "icebix",
        room = 23187,
        areas = {"Northern Icewynd Mountains", "Southern Icewynd Mountains"},
      },
      {setting = "twist", item = "diobix", room = 18203, areas = {"Mount Dio"}},
      {setting = "snowglobe", item = "treebix", room = 10992, areas = {"the Great Spirit Tree"}},
      {setting = "periscope", item = "aquabix", room = 36073, areas = {"Aquagoria"}},
      {setting = "pebble", item = "lyraabix", room = 33825, areas = {"Lyraa Ey Rielys"}},
      {setting = "shard", item = "xionbix", room = 12652, areas = {"the Workshop of Xion"}},
      {setting = "cookie", item = "crumbix", room = 9888, areas = {"Crumkindivia"}},
      {setting = "wheel", item = "drambix", room = 10509, areas = {"the Dramube Triangle"}},
      {setting = "head", item = "bottlebix", room = 11811, areas = {"the Bubble of Bottledowns"}},
      {setting = "icicle", item = "frostbix", room = 10457, areas = {"Frosticia"}},
      {setting = "screwdriver", item = "facbix", room = 10185, areas = {"the Facility"}},
      {setting = "mud", item = "mucklebix", room = 9985, areas = {"Mucklemarsh"}},
      {
        setting = "tibia",
        item = "cankerbix",
        room = 11600,
        areas = {"the Cankermore Battlegrounds"},
      },
    }
  local shortcutCreated = false
  for _, bubblix in pairs(bubblixes) do
    if mmp.settings[bubblix.setting] then
      local command = "touch " .. bubblix.item
      if not shortcutCreated then
        --for the first bubblix in the list, let it be used as a shortcut to aetherplex.
        mmp.tempSpecialExit(bubblix.room, 6831, command)
        shortcutCreated = true
      end
      --for every bix, create an exit from outside aetherplex to the bubble.
      mmp.tempSpecialExit(148, bubblix.room, command)
      if mmp.usebubblix() then
        if table.contains(bubblix.areas, gmcp.Room.Info.area) then
          mmp.tempSpecialExit(mmp.currentroom, 6831, command)
        elseif not table.contains(gmcp.Room.Info.details, "an Aetherbubble") then
          mmp.tempSpecialExit(mmp.currentroom, bubblix.room, command)
        end
      end
    end
  end
  --one use button travel!
  if mmp.settings.buttons then
    local colors =
      {
        blue = 36073,
        brown = 11811,
        black = 11600,
        yellow = 9888,
        red = 10509,
        steel = 10185,
        white = 10457,
        purple = 47812,
        green = 9985,
        crystal = 12652,
        wooden = 10992,
      }
    local exitScript = [[script:sendAll("outr %sbutton", "touch %sbutton", false)]]
    if
      table.contains(gmcp.Room.Info.details, "the Prime Material Plane") and
      table.contains(gmcp.Room.Info.details, "outdoors")
    then
      for color, room in pairs(colors) do
        mmp.tempSpecialExit(mmp.currentroom, room, exitScript:format(color, color), 20)
      end
    else
      for color, room in pairs(colors) do
        mmp.tempSpecialExit(148, room, exitScript:format(color, color), 20)
      end
    end
  end
  --basin of life specific travel devices
  if mmp.settings.compass then
    local startingRoom = mmp.lusterniaInBasin() and mmp.currentroom or 148
    local compassPoints =
      {
        north = 21695,
        northeast = 10742,
        northwest = 6546,
        east = 9789,
        southeast = 14998,
        south = 10670,
        southwest = 19613,
        west = 20037,
      }
    for direction, destinationRoom in pairs(compassPoints) do
      mmp.tempSpecialExit(startingRoom, destinationRoom, "Touch compass " .. direction, 40)
    end
  end
  mmp.clearpathcache()
end