send("pt " ..target..": Transfixed")
tarAffed("transfix")

if gmcp.Char.Status.class == "Magi" then
  send("queue addclearfull freestand staffcast horripilation at " .. target)
end