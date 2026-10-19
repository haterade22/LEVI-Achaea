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

-- THE BURN IS NOT COUNTED HERE (v4.7.429). A dehydrate that gives a stack of burning (a weary
-- target, Elementalism.wiki:328) prints "You fan the heat of <T>'s body into consuming flame." on
-- the next line, and 022_Increase_Burning counts that line. This trigger counted the same stack as
-- well, so one dehydrate added two burns (kb/CONFLICTS.md, Resolved 2026-10-19). Evidence: Tabethys's log
-- (kb/raw/logs/2026-10-19_tabethys_magi-group_kalys_o6UKnyyy.txt): a dehydrate on a weary,
-- nauseous target printed exactly one fan line. Burns gate conflagrate (P12) and destroy (P1).
if target == matches[2] then

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

  -- Weary, not nauseous: a stack of burning, and the spell's own nausea. NOT frozen: "If they
  -- already have weariness, they will be given a stack of burning. If they already have nausea,
  -- gives a stack of freeze." (Elementalism.wiki:328). The frozen recorded here made P7 cast a
  -- 2.6 s hypothermia at a target that was not frozen. The burning is the fan line's (above).
  if not haveAff("nausea") and haveAff("weariness") then
    tarAffed("nausea")
  end
  if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": weariness nausea") end
end



   
   
