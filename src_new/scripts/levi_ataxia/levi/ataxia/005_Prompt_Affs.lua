--[[mudlet
type: script
name: Prompt Affs
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Curing Stuff
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Dispatch table for numeric (stacking) afflictions.
-- Format: { abbreviation, open_color [, close_color] }
-- close_color defaults to open_color when omitted.
local numericAffDisplay = {
  temperedsanguine    = {"TS",    "a_red"},
  temperedphlegmatic  = {"TP",    "NavajoWhite"},
  temperedcholeric    = {"TC",    "DarkGreen"},
  temperedmelancholic = {"TM",    "DodgerBlue"},
  skullfractures      = {"Sf",    "a_darkred"},
  torntendons         = {"Tt",    "a_darkred"},
  crackedribs         = {"Cr",    "a_red",     "a_darkred"},
  crescendo           = {"Cres",  "a_red",     "a_darkred"},
  wristfractures      = {"Wf",    "a_red",     "a_darkred"},
  pressure            = {"Pr",    "purple"},
  burning             = {"burns", "orange"},
  unweavingmind       = {"UWM",   "a_yellow"},
  unweavingbody       = {"UWB",   "sienna"},
  unweavingspirit     = {"UWS",   "NavajoWhite"},
  horror              = {"HORROR","magenta"},
  pyre                = {"PYRE",  "magenta"},
}

function ataxia_promptAffs()
	if not affs_to_colour then populate_aff_colours() end
	local aff_str = ""

	if (rTabSize(ataxia.afflictions) == 0 or ataxia.afflictions == {}) and not ataxia.afflictions.unknown and ataxia.vitals.bleed < 100 then
		return ""
	else
		aff_str = "<tomato> ["
		if ataxia.vitals.bleed >= 100 then
			aff_str = aff_str.." <a_red>bld(<NavajoWhite>"..ataxia.vitals.bleed.."<a_red>)"
		end
		if ataxia.afflictions.unknown then
			aff_str = aff_str.." "
			for i=1, ataxia.afflictions.unknown do
				aff_str = aff_str.."<brown>?"
			end
		end
		for aff,boo in pairs(ataxia.afflictions) do
			if type(boo) ~= "number" then
				local foundAff = false
				for conv, tab in pairs(affs_to_colour) do
					if aff == conv then
						aff_str = aff_str.." <"..tab[1]..">"..tab[2]
						foundAff = true
						break
					end
				end
				if not foundAff then aff_str = aff_str.." <NavajoWhite>"..aff end
			elseif tonumber(boo) ~= 0 then
				local fmt = numericAffDisplay[aff]
				if fmt then
					local close_c = fmt[3] or fmt[2]
					aff_str = aff_str.." <"..fmt[2]..">"..fmt[1].."(<white>"..boo.."<"..close_c..">)"
				end
			end
		end
		aff_str = aff_str .. ataxia_promptLocks()
		-- Add Damnation warning when fighting Paladin with head broken + pyre/burning
		if getDamnationPromptWarning then
			aff_str = aff_str .. getDamnationPromptWarning()
		end
		aff_str = aff_str .. " <tomato>]"
	end
	return aff_str
end
