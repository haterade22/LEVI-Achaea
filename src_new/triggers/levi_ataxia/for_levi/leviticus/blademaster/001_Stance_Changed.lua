--[[mudlet
type: trigger
name: Stance Changed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Blademaster
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
- pattern: Clearing your mind, you sink into the Sanya stance.
  type: 3
- pattern: Resolving to move as water, you enter the Mir stance.
  type: 3
- pattern: Mind set on the dancing flame, you take up the Arash stance.
  type: 3
- pattern: Readying yourself with a flourish, you flow into the Thyr stance.
  type: 3
]]--

local elements = {
  Sanya = "purple",
  Mir = "LightSkyBlue",
  Arash = "orange",
  Thyr = "NavajoWhite",
}
for stance, colour in pairs(elements) do
  if string.find(line, stance) and ataxia.vitals.stance == stance then
    selectString(line,1)
    fg(colour)
    deselect()
    resetFormat()
    ataxia_updateBlademasterStance()
  end
end