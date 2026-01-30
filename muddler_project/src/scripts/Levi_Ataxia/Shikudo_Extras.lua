function shikudo_checkForms()
  local k = ataxia.vitals.kata
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
    cecho("\n<orange>[<green>"..ataxia.vitals.form.."<orange>]: <NavajoWhite>"..table.concat(nextForm[f], " -- ").."")
  end
end