--[[mudlet
type: trigger
name: Dragon Scorch Inhibit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Denizen Attacks Misc Lines
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
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
packageName: ''
patterns:
- pattern: ^You blacken (.+)'s flesh with a quick blast of flame, slowing \w+ healing
    process\.$
  type: 1
]]--

-- RED DRAGON SCORCH (AB 2299, Attainment): `SCORCH <target>`, 18 rage, 25.00s cooldown,
-- denizens only, and the AB names its own effect -- "Gives denizen affliction: Inhibit".
--
-- TWO JOBS, and the second is the one the user asked for.
--
-- 1. RECORD THE AFFLICTION. `inhibit` is already modelled by basher/008_Denizen_State
--    (BR_AFFS.inhibit; Monk's Ripplestrike and the Infernal Necrotic Aura proc are the other
--    two sources, and trigger 024 does exactly this). Recording it stops a second inhibit being
--    spent on a mob that already carries one, and it is the direct counter to the self-healing
--    denizens that otherwise out-heal a slow kill ("...ceases tending to his wounds").
--
--    The line NAMES its target, but we still record against `target`: scorch is something we
--    aimed, so the named denizen is the one we are fighting, and the denizen model is keyed by
--    the numeric id rather than the name. Same assumption trigger 024 makes.
--
-- 2. ANNOUNCE ON PT. Gated on `ataxia.settings.raid.enabled`, the party-relay toggle every other
--    PT announce in this tree uses (188_Impatience is the model), so it has an off switch and
--    behaves consistently. `send(..., false)` keeps it out of the local echo.
--
-- `\w+` in the pattern is the possessive pronoun -- the game prints "his"/"her"/"its" by denizen
-- gender, so matching the word rather than enumerating them is what makes this work for every mob
-- rather than the one that was in the room when it was captured.
--
-- NOT wired into a battlerage rotation: there is no red-dragon rotation (GDRAGON_BR is Golden --
-- deaden/psidaze/psiblast/overwhelm), so scorch is currently a manual cast. At 18 rage for a 25s
-- heal-block that is worth automating, but building a colour-specific rotation is a bigger change
-- than this line needs.
if type(target) == "number" and ataxiaBasher and ataxiaBasher.enabled and ataxiaBasher_dsSetAff then
	ataxiaBasher_dsSetAff(target, "inhibit")
end

if ataxia and ataxia.settings and ataxia.settings.raid and ataxia.settings.raid.enabled then
	send("pt " .. matches[2] .. ": inhibit", false)
end

-- medium_sea_green, matching trigger 024: the same effect on the same denizen state should read
-- the same colour whichever ability applied it.
selectString(line, 1)
fg("medium_sea_green")
deselect()
resetFormat()
