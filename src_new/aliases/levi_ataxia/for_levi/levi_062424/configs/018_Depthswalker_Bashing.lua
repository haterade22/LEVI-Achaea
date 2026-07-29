--[[mudlet
type: alias
name: Depthswalker Bashing Options
hierarchy:
- Levi_Ataxia
- Ataxia
- Basher
- Configs
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^bash dw (boinad|cull|keepers) (on|off)$
command: ''
packageName: ''
]]--

-- Depthswalker PvE toggles (v4.7.142):
--   boinad  -- spend 32 rage + the shared WORD balance to charm a second denizen (5s)
--   cull    -- swing `shadow cull` (slow/high) instead of `shadow reap` (fast/low)
--   keepers -- keep the Terminus hunting/augmentation buffs up while bashing
local key = ({ boinad = "dwBoinad", cull = "dwCull", keepers = "dwKeepers" })[matches[2]]
ataxiaBasher[key] = (matches[3] == "on")

local label = ({
	boinad = "Boinad charm (32 rage + word balance)",
	cull = "Shadow CULL as the primary swing (instead of reap)",
	keepers = "Terminus buff keepers (trusad/tsuura/mainaas/mainaad/balateth)",
})[matches[2]]
ataxiaEcho(label.." has been "..(ataxiaBasher[key] and "<green>Enabled." or "<red>Disabled."))
if matches[2] == "cull" and ataxiaBasher.dwCull then
	ataxiaEcho("<NavajoWhite>Reap vs cull is UNMEASURED -- use <green>bash probe on<NavajoWhite> to compare.")
end
