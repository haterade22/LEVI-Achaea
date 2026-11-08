--[[mudlet
type: alias
name: DISPLAY OFF
hierarchy:
- Levi_Ataxia
- General
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^aoff$
command: ''
packageName: ''
]]--

-- noDisplay and the `ak` table belonged to a tracker this repo never shipped (no revision defines
-- either). Each is guarded, because this alias only threw.
if noDisplay then noDisplay() end
if ak then ak.nodisplay = true end