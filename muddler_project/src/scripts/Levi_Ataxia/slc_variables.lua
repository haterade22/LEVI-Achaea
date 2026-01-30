function slc_init()            --  use 'cres' when you finish making changes.

slc =
	{
		["display"] = "long",      -- short | long | off
		["server_curing"] = true,  -- true | false
--==change: added bm_ratio+stance+stance_modifiers==--
    ["bm_ratio"] = 0.77,                  -- ratio for leg/arm/centre slash for alternate limbs (Testing in progress!)
    ["bm_stance"] = "Sanya",              -- which stance SLC assumes BMs use.  Sayna covers all the most common stances.
    ["bm_stance_modifiers"] = 
		{
        ["Thyr"] =  1.00,
        ["Mir"] =   1.00,
        ["Sanya"] = 1.00,
        ["Arash"] = 1.30,
				--["Arash"] = 1.37,
        ["Doya"] =  1.25,
				--["Doya"] =  1.33,
        ["Unstanced"] = 1.10
    },
		["underhand_weapon"] = "blade",
		["overhand_weapon"]  = "blade",
------------------------------------------------------
--==changed: * below are what was added==--
		["attacks"] = 
		{
			["tekura"] = 5,       -- Default number of hits to break limbs *
      ["tekurakick"] = 4.5,           -- Default number of hits to break limbs *
      ["tekurapunch"] = 5,            -- Default number of hits to break limbs *
			["axekick"] = 3,
                                      -- Tekura and Weaponry skills will require adjusting *
      ["dsl"] = 14,                   -- DSL includes bard jab (they usually use low str, high speed rapiers) *
      ["hew"] = 6,
      ["pulverise"] = 4, -- *
      ["underhand_hammer"] = 4, -- *
      ["underhand_blade"] = 6, -- *
      ["overhand_hammer"] = 4, -- *
      ["overhand_blade"] = 6, -- *
      ["whirl_mstar"] = 7, -- *
      ["whirl_flail"] = 5, -- *
      ["snb_rend"] = 7, -- *
      ["snb_slice"] = 11, -- *
      ["rend"] = 4, -- dragon rend *
			["thornrend"] = 4,
			["maul"] = 4,
			["hydra"] = 4,
			["lacerate"] = 7,
			["gouge"] = 7,
			["throwingaxe"] = 7,
			["doublestrike"] = 7,
			["staffstrike"] = 11,
			["smite"] = 4,
			["crush"] = 4,
			["other"] = 4,
      ["tremolo"] = 1.8, -- *
      ["vibrato"] = 1, -- *
      ["armslash"] = 9, -- *
      ["legslash"] = 9, -- *
      ["centreslash"] = 9, -- *
      ["compassslash"] = 9, -- *
      ["drawslash"] = 10, -- *
			["acciacurato"] = 2.8, --slc.attacks.acciacurato = slc.attacks.dsl * 0.4 -- *
			
			["thrust"] = 6,
			["dart"] = 10,
			["flashheel"] = 10,
			["risingkick"] = 10,
			["frontkick"] = 10,
			["hiraku"] = 11,
			["hiru"] = 9,
			["ruku"] = 10,
			["kuro"] = 10,
			["livestrike"] = 6,
			["nervestrike"] = 6,
			["needle"] = 6,
			["spinkick_torso"] = 8,
			["spinkick_head"] = 3,
			["jinzuku"] = 10,
			
		},
		["hitcount"] = 
		{
			["head"] = 0,
			["torso"] = 0,
			["left arm"] = 0,
			["right arm"] = 0,
			["left leg"] = 0,
			["right leg"] = 0,
		},

		["percentages"] = 
		{
			["head"] = 0,
			["torso"] = 0,
			["left arm"] = 0,
			["right arm"] = 0,
			["left leg"] = 0,
			["right leg"] = 0,
		},

		
	}
end