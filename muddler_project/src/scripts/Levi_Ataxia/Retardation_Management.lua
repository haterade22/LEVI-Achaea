--Borrowed and improved/made neater from Wundersys

function retardationOn()
  if not ataxia.retardation then
    ataxia.afflictions.aeon = true
    ataxia.retardation = true
    setRetardationSip()
    send("curing batch off",false)
    ataxia_boxEcho("Uh oh, slowcuring toggles adjusted!", "red")
    retardationDownCheck()
  end
end

function retardationOff()
  ataxia.afflictions.aeon = nil
  ataxia.retardation = false
  setNormalSip()
  send("curing batch on", false)
  ataxiaTemp.vibeSpinner = nil
  ataxia_boxEcho("Looks like we're no longer slowed", "green")
end

function setRetardationSip()
  send("curing siphealth 45", false)
  send("curing sipmana 45", false)
  send("curing mosshealth 0", false)
  send("curing mossmana 0", false)
end

function setNormalSip()
  send("curing siphealth 80", false)
  send("curing sipmana 75", false)
  send("curing mosshealth 70",false)
  send("curing mossmana 70",false)
end

function retardationDownCheck()
  if retardDropDetectionTimer then killTimer(retardDropDetectionTimer) end
  retardDropDetectionTimer = tempTimer(5, [[retardDropDetectionTimer = nil; if ataxia.retardation then retardationOff() end]])
end

function serversideRetardation(cure)
  if not affed("aeon") and not affed("blackout") then
    retardationOn()
  end
end