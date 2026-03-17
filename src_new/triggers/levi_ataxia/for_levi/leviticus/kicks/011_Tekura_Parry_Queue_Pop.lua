--[[mudlet
type: trigger
name: Tekura Parry Queue Pop
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Monk
- Tekura Limbs
- Kicks
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
- pattern: ^You (hurl yourself towards .+ with a lightning-fast moon kick|let fly at .+ with a snap kick|pump out at .+ with a powerful side kick|ball up one fist and hammerfist .+|unleash a powerful hook towards .+|lash out at .+ with a vicious sweep|twist your torso and send a roundhouse towards .+|wrench .+'s .+ viciously|jab at .+'s arms|raise your leg high and bring it down on .+|throw your force behind a forward palmstrike at .+'s face|form a spear hand and stab out towards .+|launch a powerful uppercut at .+|spin into the air and throw a whirlwind kick towards .+|whip your hand in a vicious bladehand at the neck of .+|grab .+ and haul them over your knee)\.$
  type: 1
]]--

-- Pop the next limb from the parry tracking attack queue
-- This replaces the temp trigger system that was prone to orphaning on script reload
if tekura and tekura.parry and tekura.parry.onAttack then
  tekura.parry.onAttack()
end
