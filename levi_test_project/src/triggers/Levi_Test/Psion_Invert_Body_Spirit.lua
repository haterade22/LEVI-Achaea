bodyinvert = false
spiritinvert = true
inverted = true

erAff("unweavingbody")
if removeAffV3 then removeAffV3("unweavingbody") end
erAff("criticalbody")
if removeAffV3 then removeAffV3("criticalbody") end
tarAffed("unweavingspirit")
if applyAffV3 then applyAffV3("unweavingspirit") end
tarAffed("criticalspirit")
if applyAffV3 then applyAffV3("criticalspirit") end