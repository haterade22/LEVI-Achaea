if not tAffs.shivering and tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("shivering")
    if applyAffV3 then applyAffV3("weariness"); applyAffV3("shivering") end
    haveAff("nausea")
  elseif not tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("nocaloric")
    if applyAffV3 then applyAffV3("weariness"); applyAffV3("nocaloric") end
    haveAff("nausea")
  elseif tAffs.shivering and tAffs.nocaloric and not tAffs.frozen then
    tarAffed("frozen")
    tarAffed("weariness")
    if applyAffV3 then applyAffV3("frozen"); applyAffV3("weariness") end
    haveAff("nausea")
  end