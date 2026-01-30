--[[mudlet
type: alias
name: Ramm
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Artefacts
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^ramm$
command: ''
packageName: ''
]]--

send("ram " ..target.. " north")
send("ram " ..target.. " northwest")
send("ram " ..target.. " northeast")
send("ram " ..target.. " south")
send("ram " ..target.. " southeast")
send("ram " ..target.. " southwest")
send("ram " ..target.. " out")
send("ram " ..target.. " in")
send("ram " ..target.. " up")
send("ram " ..target.. " out")
send("ram " ..target.. " down")