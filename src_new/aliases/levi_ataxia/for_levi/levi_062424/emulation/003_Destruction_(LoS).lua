--[[mudlet
type: alias
name: Destruction (LoS)
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- LeviticusREG
- Leviticus
- Psion
- Emulation
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^los$
command: ''
packageName: ''
]]--

send(" enact destruction " ..target.. " north")
send(" enact destruction " ..target.. " northeast")
send(" enact destruction " ..target.. " northwest")
send(" enact destruction " ..target.. " south")
send(" enact destruction " ..target.. " southeast")
send(" enact destruction " ..target.. " southwest")
send(" enact destruction " ..target.. " west")
send(" enact destruction " ..target.. " east")
send(" enact destruction " ..target.. " up")
send(" enact destruction " ..target.. " down")
send(" enact destruction " ..target.. " out")
send(" enact destruction " ..target.. " in")
