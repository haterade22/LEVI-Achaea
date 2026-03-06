if targetIshere then
  if haveAff("nocaloric") then
    tarAffed("shivering", "frozen")
    if applyAffV3 then applyAffV3("shivering"); applyAffV3("frozen") end
  else
    tarAffed("nocaloric", "shivering")
    if applyAffV3 then applyAffV3("nocaloric"); applyAffV3("shivering") end
  end
end

ataxia_boxEcho("~ baby it's cold outside ~", "black:a_blue")