--[[mudlet
type: alias
name: Inline Infuse
hierarchy:
- Levi_Ataxia
- For Levi
- levi_062424
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
regex: ^bash inlineinfuse(?:\s+(on|off|status))?$
]]--

-- `bash inlineinfuse on|off|status` -- weave the infuse INTO the attack rather than sending it as
-- its own command (game announcement #174, 2026-08-17):
--
--   drawslash <t> infuselightning sternum        (on, the default)
--   infuse lightning ; drawslash <t> sternum     (off, the pre-v4.7.273 form)
--
-- WHY IT DEFAULTS ON: `infuse` as a separate command sits in a chain that `queue addclearfull`
-- rebuilds every prompt, and a command that does not wait on balance executes on EVERY rebuild
-- rather than once per swing -- the same mechanic that had `shin augment` refused five times in
-- 0.45 seconds (v4.7.270). Inline, it can only happen when the attack happens.
--
-- WHY THE TOGGLE EXISTS: the failure modes are not symmetric. A malformed `infuse X` costs the
-- infuse and the swing still lands. A malformed inline attack is rejected WHOLE -- no swing at all.
-- The token order is inferred from the announcement's single example, so if the game starts
-- refusing the attack, turn this off and the two-command form returns immediately.
local arg = matches[2]

if arg == "on" or arg == "off" then
	ataxiaBasher.bmInlineInfuse = (arg == "on")
end

local on = ataxiaBasher.bmInlineInfuse ~= false
ataxia.echo("<gold>inline infuse<reset> " .. (on and "<green>ON" or "<indian_red>OFF")
	.. "<reset> -- " .. (on and "<white>drawslash <t> infuse<element> sternum"
	                        or "<white>infuse <element><reset> as a separate command"))
if on then
	cecho("\n  <DimGrey>one infuse per SWING rather than one per queue rebuild. If the game starts"
		.. "\n  refusing the attack outright, <white>bash inlineinfuse off<reset> restores the old form.\n")
end
