--[[mudlet
type: trigger
name: Limb Broken L1
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
- pattern: ^Your (left arm|right arm|left leg|right leg) breaks with a loud crack\.$
  type: 1
]]--

--[[
    THE MISSING MIDDLE OF THE SELF-LIMB TRIO (v4.7.167).

    SLC already captures the two ends:
      036_Limb_healed  "^Your (.*) feels stronger and healthier.$"       -> ataxia_clearLimbDamage
      037_mangled      "^Your (.*) is greatly damaged from the beating.$" -> SLC_broke
    but the LEVEL-1 break -- by far the most common of the three -- had no handler at
    all. Verified by grepping four phrasings ("loud crack", "breaks with", "Your right
    arm", ...): the only "loud crack" hit in the package is the TARGET's limb
    (general/022_Resonance_Afflictions).

    Why that mattered, beyond the missing signal: `ataxia_brokenLimbFound` only branches
    on the `damaged*`/`mangled*` affliction families, so a level-1 break never reset the
    accumulator. `selfLimbDamage[limb].damage` therefore kept climbing past the real
    break, `ataxia_selfHitsToBreak` pinned at 0, the threshold latched "critical"
    forever, and every one-shot reaction latch (SSC priority, party callout, auto-shield
    cooldown) stayed set and never re-armed.

    This line is the game's own words, names the limb AND the side, and needs no GMCP
    key, no SSC affliction name and no telemetry -- the project's canonical
    fire-text-confirm pattern. It sidesteps the whole `crippled*` vs `broken*` vs
    `damaged*` naming question that makes every other approach here ambiguous.

    Live 2026-07-30: iron malagmae emitted ~25 of these in 90 seconds.
]]--

local limb = matches[2]

if selfLimbDamage and selfLimbDamage[limb] then
	-- Reset the accumulator: the limb HAS broken, so damage-toward-break restarts.
	-- (clearLimbDamage also raises the "safe" threshold event, which re-arms the
	-- one-shot reaction latches -- exactly what was stuck.)
	if ataxia_clearLimbDamage then ataxia_clearLimbDamage(limb) end
	-- Then announce the break itself, so handleBothArmsBrokenFlee and friends see a
	-- real "broken" edge instead of a threshold that can never reach it.
	selfLimbDamage[limb].threshold = "broken"
	raiseEvent("self limb threshold", limb, "broken", 0)
end
