-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Wings and other fast travel > Lusternia

registerAnonymousEventHandler("mmp link externals", "mmp.addWingsLusternia")

local function linkBubblix(area, entranceRoom, command)
  -- always add this link to allow pathfinding to the bubble regardless of indoor/outdoor
  mmp.tempSpecialExit(148, entranceRoom, command)
  -- always add this link to allow pathfinding from the bubbe regardless of indoor/outdoor
  mmp.tempSpecialExit(entranceRoom, 6831, command)
  if mmp.usebubblix() then
    if not table.contains(gmcp.Room.Info.details, "an Aetherbubble") then
      -- we are not in an Aetherbubble and could use a bubblix, so allow its use from here
      mmp.tempSpecialExit(entranceRoom, command)
    elseif gmcp.Room.Info.area == area then
      -- we are in an Aetherbubble and it's the one the bubblix belongs to and we could use a bubblix, so allow its use from here
      mmp.tempSpecialExit(6831, command)
    end
  end
end

function mmp.addWingsLusternia()
  if mmp.game ~= "lusternia" then
    return
  end
  --that dorky prism
  if mmp.useprism() then
    if mmp.settings.prism then
      mmp.tempSpecialExit(6182, "touch prism")
    end
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
    --curio collections!
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
  if mmp.settings.screwdriver then
    linkBubblix("the Facility", 10185, "touch screwdriver")
  end
  if mmp.settings.wheel then
    linkBubblix("the Dramube Triangle", 10509, "touch wheel")
  end
  if mmp.settings.mud then
    linkBubblix("Mucklemarsh", 9985, "touch mud")
  end
  if mmp.settings.snowglobe then
    linkBubblix("the Great Spirit Tree", 10992, "shake snowglobe")
  end
  if mmp.settings.cookie then
    linkBubblix("Crumkindivia", 9888, "touch cookie")
  end
  if mmp.settings.head then
    linkBubblix("the Bubble of Bottledowns", 11811, "touch doll")
  end
  if mmp.settings.icicle then
    linkBubblix("Frosticia", 10457, "touch icicle")
  end
  if mmp.settings.tibia then
    linkBubblix("the Cankermore Battlegrounds", 11600, "touch tibia")
  end
  mmp.clearpathcache()
end