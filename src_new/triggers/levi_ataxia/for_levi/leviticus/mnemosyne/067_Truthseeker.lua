--[[mudlet
type: trigger
name: Truthseeker
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
- pattern: ^Truthseeker\s+\d+\s+\w+
  type: 1
]]--

-- BOONS row: "The God of Darkness allows your eyes to perceive the truth of all hidden
-- afflictions that may befall you." (uncommon; already in the boon seed DB.)
--
-- User: "When we have this boon, the ? in our prompt isnt true." There are no hidden
-- afflictions while it is held, so every `?` is a phantom -- see gotUnknownAff (004) for why
-- that matters far beyond the prompt: `ataxia.afflictions.unknown` is read as a real
-- affliction by the Mnemosyne recovery gate, and nothing ever decrements it.
--
-- Clears the banked count here as well as latching, because this row is how the flag comes
-- back after a reload or a mid-run BOON CLAIMED re-latch -- by which point phantoms have
-- already accumulated, and the flag alone would only stop NEW ones.
mnemTruthseeker = true
if ataxia and ataxia.afflictions then ataxia.afflictions.unknown = nil end

if ataxiaEcho then
	ataxiaEcho("<chartreuse>Truthseeker<reset> -- hidden afflictions are revealed; "
		.. "<white>?<reset> markers suppressed.")
end
