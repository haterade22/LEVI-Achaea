--[[mudlet
type: trigger
name: Stormcleaver
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
- pattern: ^Stormcleaver\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "Your bisect attack now executes denizens with less than 20% of their maximum
-- health."
--
-- THIS IS THE BOON THAT TURNS ON A CLAUSE THE ABILITY ALREADY HAS. From AB Bisect (3107):
--
--   ** If your target is an ADVENTURER and at 20% of their health or lower when the cutting
--      damage would be applied, they will be slain outright instead.
--
-- So the execute was always in bisect and was always useless while bashing -- which is why
-- `ataxiaBasher_rwBisect` carried an explicit note saying there is no low-hp branch and the
-- Thunderclap AoE is the whole point. Stormcleaver removes the "adventurer" qualifier, and
-- that note is now wrong: there IS a single-target finisher, and it is an instant kill.
--
-- The two bisect boons pull in OPPOSITE directions and are independent:
--   * Thunderclap  -> swing bisect at 2+ denizens (room-wide electric)
--   * Stormcleaver -> swing bisect at ONE denizen under the execute threshold
-- so `rwBisect` had to stop being gated on Thunderclap alone. Either boon can now reach it.
--
-- Cleared on Mnemosyne run start / confirmed run end. Type BOONS to re-sync if needed.
mnemStormcleaver = true

if ataxiaEcho then
  ataxiaEcho("<chartreuse>Stormcleaver<reset> -- bisect now EXECUTES denizens under "
    .. tostring((ataxiaBasher and ataxiaBasher.bisectExecuteAt) or 20) .. "% health.")
end
