--[[mudlet
type: trigger
name: Priest Mana Prio
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+)'s guardian angel casts a piercing glance at you\.$
  type: 1
]]--

-- Only switch to mana priority if we have Inquisition
-- Kill condition requires INQ + <50% mana, so no INQ = no kill threat
if ataxia.afflictions.inquisition then
    send("curing priority mana", false)
    ataxiaTemp.priestManaPrio = true
    Algedonic.Echo("<cyan>ANGEL SAP + INQ - MANA PRIORITY<white>")

    -- Reset to health when INQ clears (20 sec is INQ duration)
    tempTimer(20, [[
        if not ataxia.afflictions.inquisition then
            send("curing priority health", false)
            ataxiaTemp.priestManaPrio = nil
        end
    ]])
end