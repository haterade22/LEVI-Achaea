--[[mudlet
type: trigger
name: Freeze
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
- pattern: ^You rip the heat from (\w+)\.$
  type: 1
]]--

if matches[2] ~= target then return end

-- One stage of the freeze ladder per line: "you will first strip the insulation defence if the
-- target has it, then cause the target to shiver, and finally freeze him" (Elementalism.wiki:304).
-- A stripped insulation is tracked as the target affliction `nocaloric`.
--
-- NO WEARINESS OR NAUSEA. Every branch used to add both, although FREEZE gives neither; they
-- switched off the offense's dehydrateWillFreeze and steered it to "dehydrate if weariness"
-- (004_Magi_Offense). This file was "Dehydrate - Frozen" until b48b6603 and no capture says which
-- spell prints this line; if it is DEHYDRATE's freeze stack, 015 records that cast's own nausea
-- and weariness from its landing line.
--
-- FROSTBITE: "While suffering from frostbite, the next time you are frozen if you possess the
-- insulation defence it will be stripped and you will be struck with the freezing attack
-- directly. Your frostbite will fade when this occurs." (kb/raw/live/affliction_show/frostbite.txt)
-- So with frostbite and insulation, one line strips the insulation AND lands the next stage.
local function nextStage()
  if not haveAff("shivering") then
    tarAffed("shivering")
  elseif not haveAff("frozen") then
    tarAffed("frozen")
  end
end

if not haveAff("nocaloric") then
  tarAffed("nocaloric")
  if haveAff("frostbite") then
    nextStage()
    erAff("frostbite")
  end
else
  nextStage()
end
