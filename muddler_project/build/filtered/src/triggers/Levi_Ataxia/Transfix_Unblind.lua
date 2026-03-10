send("pt " ..target..": Unblind")

erAff("unblind")

if gmcp.Char.Status.class == "Magi" then
  send("queue addclearfull freestand cast transfix " .. target)
end