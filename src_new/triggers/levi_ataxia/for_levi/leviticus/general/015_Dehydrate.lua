--[[mudlet
type: trigger
name: Dehydrate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^The skin of (\w+) begins to dry and crack as (.+) grows pale\.$
  type: 1
]]--

if target == matches[2] then

  if haveAff("weariness") and haveAff("nausea") then
      magi.offense = magi.offense or {}
      magi.offense.state = magi.offense.state or {}
      magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
      tburns = magi.offense.state.burns -- backward compat
      tarAffed("burning")
      cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  end

  if not haveAff("weariness") and not haveAff("nausea") then
   tarAffed("weariness")
   tarAffed("nausea")
  end

  if not haveAff("weariness") and haveAff("nausea") and not haveAff("shivering") and haveAff("nocaloric") then
    tarAffed("weariness")
    tarAffed("shivering")
  elseif not haveAff("weariness") and haveAff("nausea") and not haveAff("nocaloric") then
    tarAffed("weariness")
    tarAffed("nocaloric")
  elseif not haveAff("weariness") and haveAff("nausea") and haveAff("shivering") and haveAff("nocaloric") and not haveAff("frozen") then
    tarAffed("frozen")
    tarAffed("weariness")
  end

  if not haveAff("nausea") and haveAff("weariness") then
    magi.offense = magi.offense or {}
    magi.offense.state = magi.offense.state or {}
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
    tburns = magi.offense.state.burns -- backward compat
    tarAffed("burning")
    tarAffed("frozen")
    tarAffed("nausea")
    cecho(" <DimGrey>[<red>"..tburns.."/5<DimGrey>]")
  end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": weariness and nausea") end
end



   
   
