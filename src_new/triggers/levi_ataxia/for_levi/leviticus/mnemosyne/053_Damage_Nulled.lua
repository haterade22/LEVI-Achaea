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
- pattern: All (\w+) damage(?: [a-z ]+?)? is reduced by (\d+)%\.
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

    THE MIDDLE IS DELIBERATELY LOOSE (v4.7.191). The first two members seen both read "...
    damage YOU DEAL is reduced by...", and the pattern was written to that. Steel Skin then
    turned up reading "All physical damage DEALT is reduced by 33%." -- and was missed
    SILENTLY, which is the whole failure mode this family of triggers has to avoid. The
    `(?: [a-z ]+?)?` tolerates any lowercase filler between "damage" and "is reduced by", so
    a third phrasing does not need a third patch. The surrounding frame ("All <type> damage
    ... is reduced by N%.") is still strict enough that no unrelated affix row matches --
    verified against Tundral and Mysterious, which do not.

    Known members:
      Null Magic:   All magic damage you deal is reduced by 33%.
      Blank Mind:   All psychic damage you deal is reduced by 33%.
      Steel Skin:   All physical damage dealt is reduced by 33%.

    RESIDUAL RISK worth stating: a wording that drops the type entirely ("All damage you
    deal...") would still be missed, because the frame requires a word before "damage". If a
    global damage-suppression affix exists, it needs its own handling.

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
