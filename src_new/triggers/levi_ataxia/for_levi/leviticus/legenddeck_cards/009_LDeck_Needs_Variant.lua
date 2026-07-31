--[[mudlet
type: trigger
name: LDeck Needs Variant
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
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
- pattern: ^You must draw that card for either ELIXIR or POISON\.$
  type: 1
]]--

--[[
    A MALFORMED DRAW (live 2026-07-31). Seasone is the only two-variant card, and it was
    being drawn as "ldeck draw seasone FOR elixir" -- taken literally from the card's own
    help text, "DRAW FOR ELIXIR or FOR POISON". That text is English, not syntax: the
    variant is a bare argument, exactly as ldm.draw/drawQueued build it
    (003_Legend_Deck_Functions:112-115, 129-132). Fixed to "ldeck draw seasone elixir".

    This trigger is the backstop for getting it wrong again. A rejected draw spends NO
    charge, so nothing about the deck changes -- but the auto-draw layer holds its pick in
    a ~4s in-flight replay (it has to, because the basher's queue addclearfull wipes the
    queued line every prompt), and a syntax error would therefore be re-sent every rebuild
    for the whole window. Lapse the pending pick instead: that releases the replay and
    holds the card's interval, so a bad command costs one round rather than a burst.

    Lapse rather than Rejected: Rejected ZEROES the charge count, which is right for
    "lacks the power to invoke its stored potential" and wrong here -- the card is fine,
    the command was not.
]]--

local p = ataxiaTemp and ataxiaTemp.mnemLdeckPending

if p and p.key and ataxiaBasher_mnemLdeckLapse then
	ataxiaBasher_mnemLdeckLapse(p.key)
	if ataxiaEcho then
		ataxiaEcho("<red>" .. p.key .. " draw REFUSED<reset> -- needs a variant. Check the command shape "
			.. "in basher/010 (it is a bare argument, not \"for <variant>\").")
	end
end
