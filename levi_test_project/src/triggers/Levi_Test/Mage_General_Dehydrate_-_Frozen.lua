if not tAffs.shivering and tAffs.nocaloric then
    tarAffed("weariness")
    if applyAffV3 then applyAffV3("weariness") end
    tarAffed("shivering")
    if applyAffV3 then applyAffV3("shivering") end
    haveAff("nausea")
  elseif not tAffs.nocaloric then
    tarAffed("weariness")
    if applyAffV3 then applyAffV3("weariness") end
    tarAffed("nocaloric")
    if applyAffV3 then applyAffV3("nocaloric") end
    haveAff("nausea")
  elseif tAffs.shivering and tAffs.nocaloric and not tAffs.frozen then
    tarAffed("frozen")
    if applyAffV3 then applyAffV3("frozen") end
    tarAffed("weariness")
    if applyAffV3 then applyAffV3("weariness") end
    haveAff("nausea")
  end