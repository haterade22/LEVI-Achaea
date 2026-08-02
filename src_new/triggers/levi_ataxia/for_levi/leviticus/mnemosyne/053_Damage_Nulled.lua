--[[mudlet
type: trigger
name: Mnemosyne Damage Nulled
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Mnemosyne
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
- pattern: All (\w+) damage you deal is reduced by (\d+)%\.
  type: 1
]]--

--[[
    A damage-type suppression affix, from the WADE STATUS "Ongoing effects:" block:

        Null Magic:              All magic damage you deal is reduced by 33%.

    DELIBERATELY MATCHED ON THE SENTENCE, NOT THE AFFIX NAME. "Null Magic" is one member of
    a family -- there is presumably a sibling per damage type -- and the affix names are not
    all known. The effect text always names the type itself, so parsing the sentence covers
    every present and future member without us having to learn their names, and without a
    table that goes stale the moment a new one appears.

    Unanchored on purpose: the row is "<Affix Name>:<padding>All <type> damage...", so the
    match has to start mid-line. (type 1 = regex, not type 3 = exact whole line -- the
    distinction that silently killed two triggers before v4.7.170.)

    Consumers ask by damage TYPE via ataxia.mnemosyne.damageNulled("magic"). The first is
    the Blademaster infuse picker, which will not infuse an element whose damage type is
    being suppressed.
]]--

if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onDamageNulled then
	ataxia.mnemosyne.onDamageNulled(matches[2], matches[3])
end
