--[[mudlet
type: script
name: Imperian
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Wings and other fast travel
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

registerAnonymousEventHandler("mmp link externals", "mmp.addWingsImperian")
mmp.imperian = mmp.imperian or {}

function mmp.addWingsImperian()
  local function getcmd(word)
    return
      mmp.settings.removewings and
      [[script:if mmp.flying then sendAll("queue eqbal wear wings","queue eqbal say ]] ..
      word ..
      [[","queue eqbal remove wings",false) else sendAll("wear wings","fly",false) end]] or
      [[script:if mmp.flying then sendAll("queue eqbal say ]] ..
      word ..
      [[",false) else sendAll("fly",false) end]]
  end

  if
    (mmp.settings.shekinah or mmp.settings.suriel) and
    gmcp.Room and
    not table.contains(gmcp.Room.Info.details, "indoors") and
    not table.contains(gmcp.Room.Info.details, "considered indoors") and
    table.contains(mmp.imperian.wingAbleAreas, getRoomArea(mmp.currentroom))
  then
    if mmp.settings.shekinah then
      -- Seraphim wings - "Say shekinah"
      local weight = 15
      if mmp.flying then
        weight = 1
      end
      mmp.tempSpecialExit(4882, getcmd("shekinah"), weight)
    elseif mmp.settings.suriel then
      -- Using Orphanim wings, SURIEL works, takes you to 3885
      local weight = 15
      if mmp.flying == "1" then
        weight = 1
      end
      mmp.tempSpecialExit(3885, getcmd("suriel"), weight)
      -- clear cache so mmp.getPath accounts for the new way
    end
  end
  mmp.clearpathcache()
end

mmp.imperian.wingAbleAreas =
  {
    45,
    35,
    15,
    56,
    101,
    123,
    36,
    110,
    18,
    75,
    172,
    9,
    66,
    148,
    113,
    175,
    188,
    244,
    88,
    171,
    118,
    295,
    167,
    25,
    139,
    70,
    132,
    28,
    135,
    174,
    8,
    275,
    107,
    53,
    112,
    185,
    158,
    164,
    299,
    74,
    351,
    16,
    63,
    269,
    77,
    85,
    142,
    328,
    318,
    46,
    95,
    17,
    329,
    33,
    96,
    82,
    47,
    144,
    121,
    3,
    68,
    51,
    134,
    1,
    319,
    11,
    19,
    129,
    146,
    65,
    324,
    325,
    125,
    191,
    163,
    30,
    54,
    292,
    290,
    7,
    136,
    267,
    335,
    102,
    43,
    89,
    20,
    169,
    49,
    147,
    196,
    301,
    252,
    99,
    145,
    195,
    130,
    42,
    270,
    166,
    128,
    168,
    34,
    223,
    170,
    22,
    27,
    138,
    115,
    337,
    44,
    6,
    161,
    32,
    92,
    83,
    294,
    104,
    69,
    23,
    155,
    350,
    48,
    57,
    150,
    97,
    341,
    105,
    340,
    5,
    194,
    338,
    327,
    271,
    323,
    322,
    79,
    122,
    62,
    131,
    176,
    133,
    310,
    307,
    120,
    137,
    13,
    76,
    160,
    60,
    304,
    94,
    306,
    303,
    81,
    291,
    276,
    302,
    149,
    297,
    179,
    272,
    41,
    293,
    289,
    91,
    159,
    71,
    157,
    298,
    266,
    208,
    109,
    80,
    14,
    2,
    186,
    12,
    178,
    52,
    124,
    274,
    141,
    343,
    177,
    67,
    103,
    111,
    72,
    268,
    87,
    117,
    21,
    353,
    253,
    93,
    308,
    40,
    248,
    243,
    4,
    153,
    212,
    116,
    84,
    197,
    61,
    78,
    184,
    173,
    31,
    98,
    114,
    162,
    50,
    37,
    140,
    73,
    127,
    156,
    90,
    100,
    143,
    309,
    126,
  }