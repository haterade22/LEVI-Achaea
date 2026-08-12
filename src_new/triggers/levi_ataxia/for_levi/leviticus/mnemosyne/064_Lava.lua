--[[mudlet
type: trigger
name: Lava
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
- pattern: ^You splash into boiling lava!$
  type: 1
- pattern: ^You continue to struggle in the boiling grasp of the lava as it eats away
    at your body\.$
  type: 1
]]--

-- BOILING LAVA (captured live 2026-08-11). 5,890 UNBLOCKABLE per tick against the 10,939 HP
-- in that prompt -- 54% of the pool, twice over is a death, and "unblockable" means no shield,
-- no barrier and no resistance changes it.
--
-- TWO LINES, BOTH USED, deliberately. The splash is the entry and the struggle is the tick, and
-- either alone is insufficient:
--   * entering without the tick still puts us in the room, and
--   * the tick fires without an entry line when we were already standing in it (walked in
--     before this shipped, or dragged in).
-- Re-firing on every tick is the point rather than a flaw: M.onLava re-sends the move, because
-- a move that was eaten must be retried and there is no budget worth preserving against a
-- hazard that kills in two ticks.
--
-- Distinct from the ABLAZE affix (mnemosyne/049), which is ~1,200 a tick and merely gates the
-- recovery hover. That one can be fought through; this one cannot be traded with at all.
--
-- Highlighted in the "this is hurting us badly" colour rather than the attack-landing family:
-- it is incoming, and it is the largest single number in the log.
-- PASS THE LINE (v4.7.262). The two patterns mean different things and the script must be able
-- to tell them apart: the splash is the ENTRY and always speaks for the room we are standing in
-- now, while the struggle is the TICK -- and a buffered tick can be processed AFTER the escape's
-- gmcp.Room has already moved MAP.current. Sharing one script with no way to distinguish them
-- meant a trailing tick marked the SAFE room we had just escaped into and condemned the escape
-- edge, i.e. the one door the code above calls provably not lava. `line` is the Mudlet global
-- holding the matched line, already used below by selectString.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onLava then
	ataxia.mnemosyne.onLava(line)
end

selectString(line, 1)
setBold(true)
fg("indian_red")
deselect()
resetFormat()
