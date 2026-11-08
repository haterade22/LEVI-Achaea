--[[mudlet
type: trigger
name: Shield Down
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Serpent
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
- pattern: ^You try to flay a non-existent shield from (.+).$
  type: 1
- pattern: ^You flay away (\w+)'s shield defence\.$
  type: 1
]]--

-- Our FLAY of the target's SHIELD takes the shield, and the sileris coating with it
-- (kb/sim/rules.md attack.flay.coating; 706 reads that), but never the rebounding: FLAY <target>
-- SHIELD or REBOUNDING strips the defence named (kb/sim/rules.md attack.flay), so a rebounding stays
-- up. From the victim's seat, kb/raw/logs/2026-11-01_claes_runewarden-vs-serpent_loss_azbErKcK.txt:
-- rebounding up at 2216, "Thato flays away your shield defence." at 2235 with the coating ripped at
-- 2236, and the rebounding goes only at 2264 ("Thato flays away your aura of rebounding defence."). In
-- kb/raw/logs/2026-11-01_elmer_shikudo-vs-serpent_noresult_g-lD00-h.txt Kalys flays the shield at 37
-- and his next dstab rebounds at 62 ("The attack rebounds back onto Kalys!").
-- This used to erase rebounding as well. The next round then sent a DSTAB or an IMPULSE into the
-- rebounding, and serpent/002 armed its rebounding pre-empt for a rebounding that never dropped.
-- When neither defence is left, the game prints the second-assault line, and serpent/010 erases both.
-- Only the target's shield: these are our own lines, but the flay may be at someone else.
if isTargeted(matches[2]) then
  tAffs.shield = false
  erAff("shield")
end