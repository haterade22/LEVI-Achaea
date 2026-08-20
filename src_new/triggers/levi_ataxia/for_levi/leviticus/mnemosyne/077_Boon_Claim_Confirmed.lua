--[[mudlet
type: trigger
name: Boon Claim Confirmed
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
- pattern: A fulgent eddy falls still
  type: 1
]]--
-- `A fulgent eddy falls still.` -- THE GAME CONFIRMING A BOON CLAIM LANDED.
--
-- Adopted from MediaRes' standalone tracker (2026-08-20), and it closes a real hole rather
-- than adding a nicety. Our boon flags latch at SEND time: the claim alias passes the command
-- through and immediately calls onBoonClaim, which records the history, latches the flag and
-- posts the telemetry. NOTHING in that chain knows whether the game accepted it -- so a claim
-- the game refuses (wrong name, eddy already spent, screen gone) still arms that boon's
-- automation for the rest of the run. A Bard swaps to paean for a Warmarch it never got.
--
-- Same rule this codebase keeps re-learning: where the game speaks about its own state, our
-- bookkeeping is the fallback (v4.7.266, v4.7.270, v4.7.271).
--
-- It WARNS rather than un-latching -- see M.onBoonClaimConfirmed for why that asymmetry is
-- deliberate while this wording is still second-hand.
if ataxia and ataxia.mnemosyne and ataxia.mnemosyne.onBoonClaimConfirmed then
	ataxia.mnemosyne.onBoonClaimConfirmed()
end

selectString(line, 1)
setBold(true)
fg("spring_green")
deselect()
resetFormat()
