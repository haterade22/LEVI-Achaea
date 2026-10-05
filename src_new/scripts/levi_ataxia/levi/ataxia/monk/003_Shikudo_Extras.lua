--[[mudlet
type: script
name: Shikudo Extras
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- Combat
- Offensive Things
- Monk
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function shikudo_checkForms()
  -- v4.7.382: the vitals update calls this while it is still reading the Form charstat, before
  -- Kata has been parsed, so on the first prompt kata is nil and `k > 5` threw.
  if not ataxia.vitals.form then return end
  local k = ataxia.vitals.kata or 0
  local f = ataxia.vitals.form:lower()
  local nextForm = {
    tykonos = {"Willow"},
    willow = {"Rain"},
    rain = {"Tykonos", "Oak"},
    oak = {"Willow", "Gaital"},
    gaital = {"Rain", "Maelstrom"},
    maelstrom = {"Oak"},
  }
  if k > 5 or k == 0 then
    if not nextForm[f] then return end
    cecho("\n<orange>[<green>"..ataxia.vitals.form.."<orange>]: <NavajoWhite>"..table.concat(nextForm[f], " -- ").."")
  end
end