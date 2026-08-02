--[[mudlet
type: trigger
name: Mnemosyne Last Word
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
- pattern: '^Last Word:\s+Denizens explode on death'
  type: 1
]]--

-- Ongoing-effects row in the Mnemosyne status screen (captured live 2026-08-02):
--   "Last Word:    Denizens explode on death!"
--
-- A PACING affix, exactly like Haemophiliac (trigger 029) -- and pacing is the whole of the
-- handling, because the explosion itself is not something we can dodge or cure. The damage
-- lands at the precise moment the room goes quiet, which is the precise moment the sweep
-- wants to walk into the next room. So the post-clear hold applies: move only at >= 90% HP
-- (user spec), or the next fight opens on a pool the last corpse already bit into.
--
-- Note the shared 90% threshold but NOT the shared wait. Haemophiliac also holds on
-- `ataxia.vitals.bleed` because its damage is a bleed SSC has to clot down; an explosion is
-- instantaneous, so there is nothing to clot and nothing to wait on but regeneration
-- (`M._lastWordHold`, explorer 008).
--
-- The trailing "!" is deliberately outside the pattern -- match the frame, not the
-- punctuation, since the exact wording of these rows has varied before. Type 1 (regex), NOT
-- type 3: the row is padded with whitespace to a column, so an exact-whole-line match would
-- silently never fire (see AGENTS.md).
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onLastWordSeen then
  ataxia.mnemosyne.onLastWordSeen()
end
