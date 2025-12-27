--[[mudlet
type: trigger
name: Identify Uses
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- LegendDeck Cards
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
- pattern: ^A card depicting (.+) may be used (\d+) more times before its potential will need to be restored\.$
  type: 1
]]--

if matches[2] == "Seasone, the Industrious" then
  ataxiaTables.ldeckcardscount.SeasoneE = matches[3]
elseif matches[2] == "Matic Ridley, The Salvation" then
  ataxiaTables.ldeckcardscount.Matic = matches[2]
elseif matches[2] == "Maran La'Saen, Seraph of Creation" then
  ataxiaTables.ldeckcardscount.Maran = matches[2]
elseif matches[2] == "Xylthus, the Outcast" then
  ataxiaTables.ldeckcardscount.Xylthus = matches[2]
elseif matches[2] == "Bakios, the Winemaster" then
  ataxiaTables.ldeckcardscount.Bakios = matches[2]
elseif matches[2] == "Covenant Stormcrow" then
  ataxiaTables.ldeckcardscount.Bakios = matches[2]

                                                                                    
end




