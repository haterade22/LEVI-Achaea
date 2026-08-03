--[[mudlet
type: trigger
name: Gag Combat Refusals
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
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
- pattern: The sundering note of the Nomos already keens forth
  type: 2
- pattern: The paean already refrains from your
  type: 2
]]--

-- MID-COMBAT refusal spam -- gagged with a plain `deleteLine()`, NOT `deleteFull()`.
--
-- That distinction is the whole reason this trigger exists separately from 006_GAG (user,
-- 2026-08-03: "this should be deleteLine()"). `deleteFull` (misc_scripts/006) does not just
-- gag the line: it also sets `noPromptEcho` and arms a one-shot line trigger that deletes the
-- NEXT line if it is a prompt.
--
-- That is exactly right for the ~50 lines in 006_GAG, which are RESPONSES TO COMMANDS -- they
-- arrive with a prompt of their own, and gagging the line while leaving its prompt behind
-- would litter the screen with bare prompts.
--
-- It is exactly wrong here. These two fire in the MIDDLE of a combat round, several times a
-- round, and the prompt that follows belongs to the round -- our vitals, balance and
-- affliction tags. `deleteFull` would eat it, hiding the readout precisely when it matters
-- most, and re-arming a tempLineTrigger on every swing while it did so.
--
-- Both lines are Bard refusals meaning "that refrain is ALREADY on the blade", printed
-- because the attack names the song every swing (`blade flick <t> nomos|paean`, basher/002).
-- type 2 (begin-of-line): the tail names the weapon, so an exact type 3 would silently never
-- fire, and anchoring at the head stops it gagging someone quoting the line over a channel.
--
-- STILL OPEN (see memory/bard.md): whether the attack LANDS when these print. If it does, the
-- gag is the whole fix. If the refusal eats the swing, the rotation should stop naming the
-- song once it is up -- and gagging the evidence would then be hiding a real problem, which
-- is why the question is written down rather than closed.
deleteLine()
