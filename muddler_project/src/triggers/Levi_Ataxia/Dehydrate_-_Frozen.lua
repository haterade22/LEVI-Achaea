if not tAffs.shivering and tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("shivering")
    haveAff("nausea")
  elseif not tAffs.nocaloric then
    tarAffed("weariness")
    tarAffed("nocaloric")
    haveAff("nausea")
  elseif tAffs.shivering and tAffs.nocaloric and not tAffs.frozen then
    tarAffed("frozen")
    tarAffed("weariness")
    haveAff("nausea")
  end