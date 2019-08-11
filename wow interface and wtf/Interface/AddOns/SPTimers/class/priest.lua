local addon, C = ...
if C.myCLASS ~= "PRIEST" then return end

local colors = C.CustomColors

local ALL = "ALL"

--[[

	groups = {
		"target",
		"player",
		"procs",
		"offtargets",
	}
	
	cleu filters 
	
	 filters_cleu = {
	1 L["None"],
	2 L["Only buff"],
	3 L["Only debuff"],
	4 L["All"],
	5 L["SpellCast"],
	6 L["Summon"],
}
	
	ALL = ALL
	1 = Dc
	2 = Holy
	3 = Shadow
	
	spec = "1;2;3",

	
]]
-- blacklist_cleu = 7 SPELL_ENERGIZE

local spells = {
	
	[204213] = { spec = '1', duration = 20, pandemia = true, haste = true, cleu = true, },
	[198069] = { spec = '1', duration = 20, },
	
	[197937] = { spec = '3', duration = 60, group = "player", }, -- Lingering Insanity
	[194249] = { spec = '3', group = "player", }, -- Void Form
	
	[184073] = { spec = "3", color = { 0.631372549019608, 0.192156862745098, 0.227450980392157, }, duration = 10, color_on = true, cleu = true, },		
	
	[34914]	 = { spec = "3", pandemia = true, duration = 24, custom_text = "%tN", showTicks = true, tick = 3, showOverlay = true, showOverlay = true, cast = 1.5, haste = true, cleu = true, color = colors.BLUE, }, -- vt
	[589]	 = { spec = ALL, pandemia = true, duration = 18, custom_text = "%tN", showTicks = true, tick = 2, haste = true, cleu = true, color = colors.PURPLE, },	   -- swp
--	[158831] = { spec = "3", pandemia = true, duration = 6,  custom_text = "%tN", tick = 1, haste = true, cleu = true, color = colors.WOO },	   -- dp
	
	[34433]  = { spec = ALL, duration = 12, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 6, }, --color = colors.BLACK }
	[132603] = { spec = ALL, duration = 12, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 6, },
	[123040] = { spec = ALL, duration = 20, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 6, },
	[132604] = { spec = ALL, duration = 20, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 6, },
	
	[47585]	 = { spec = "3", duration = 6,  color = colors.PURPLE, group = "player" },
	[123254] = { spec = ALL, duration = 10, color = colors.CURSE, group = "player", priority = -10, color = colors.CURSE},
	
--	[15407]	 = { spec = "3", duration = 3, tick = 1, group = "target", spellType = 2, haste = true, },
--	[129197] = { spec = "3", duration = 3, tick = 1, group = "target", spellType = 2, haste = true, },
	
--	[87160] = { spec = "3", duration = 10,  color = colors.LRED }, -- FDCL SHADOW

--	[114255] = { spec = "1;2", duration = 20, color = colors.LRED }, -- FDCL HEAL
	
--	[112833] = { spec = ALL, duration = 6,  color = colors.CURSE }, --Spectral Guise
	
--	[145180] = { spec = "3", duration = 12,  custom_text = "%spell (%val1)", color = colors.CURSE }, --Spectral Guise
	
--	[123266] = { duration = 10, color = colors.BLACK }, -- Divine Insight discipline
--	[123267] = { spec = "2", duration = 10, color = colors.BLACK }, -- Divine Insight holy	
	[124430] = { spec = "3", duration = 12, color = colors.BLACK }, -- Divine Insight shadow
	
--	[132573] = { spec = "3", duration = 6, color = colors.INSANITY },
	
	[10060]   = { spec = ALL, duration = 20, color = colors.ELV_FOCUS },
	
	[9484]   = { spec = ALL, duration = 50 },
	[15487]  = { spec = "1;3", duration = 5,  color = colors.PINK },
	
	[8122]   = { spec = ALL, duration = 8,  cleu = true },
	
	[139]	 = { spec = "1;2", color = colors.LGREEN, duration = 12 },
	[17]	 = { spec = ALL, duration = 15, color = colors.LRED },
	[41635]  = { spec = ALL, duration = 30, color = colors.RED, cleu = true },
	[47788]  = { spec = "2", duration = 10, color = colors.LBLUE},
	[33206]  = { spec = "1", duration = 8, color = colors.LBLUE },
	[586]	 = { spec = ALL, duration = 10 },
--	[89485]  = { color = colors.LBLUE, duration = 1 },
	[15286]  = { spec = "3", duration = 15, color = colors.LBLUE },
--	[81700]	 = { spec = "1", duration = 18, color = colors.PINKIERED },
--	[59889]	 = { spec = "1", duration = 6 },
--	[109964] = { spec = "1", duration = 15, color = colors.PURPLE2 },
--	[113792] = { cleu = true, duration = 30, pvpduration = 8 },
	[62618]	 = { spec = "1", cleu = true, duration = 10, group = "player", whitelist_cleu = 5, blacklist_cleu = 2, blacklist = 2 },
--	[81661]  = { spec = "1", duration = 15, color = colors.ORANGE },
--	[81208]	 = { spec = "2", color = colors.WOO, duration = 1 },
--	[81206]	 = { spec = "2", color = colors.WOO2, duration = 1 },
--	[81209]	 = { spec = "2", color = colors.RED, duration = 1 },	
--	[47755]  = { cleu = true, color = colors.DPURPLE, duration = 12, whitelist_cleu = 7, },
	
--	[155361] = { spec = "3", pandemia = true, duration = 60,  custom_text = "%tN", tick = 3, haste = true, cleu = true, color = colors.WOO },	   -- dp
	
--	[167254] = { spec = "3", duration = 4,  }, -- dp
	
	[188779] = { spec = "3", duration = 15, }, -- t18p4
	
--	[87194] = { spec = '3', color = colors.RED, duration = 4, }, -- mb root glyph
}

local GetSpell = C.GetSpell
local cooldown = {

	[GetSpell(8092)]  = { spellid = 8092, color = colors.CURSE },
	[GetSpell(32379)] = { spellid = 32379, color = colors.PURPLE },
	[GetSpell(88625)] = { spellid = 88625, color = colors.CURSE },
	[GetSpell(47540)] = { spellid = 47540, color = colors.CURSE },
	[GetSpell(14914)] = { spellid = 14914, color = colors.PINK },
	
}


function C:SetupClassSpells()
	return spells
end

function C:SetupClassCooldowns()
	return cooldown
end

--[==[
do

	local function OnEvent(self)

		if IsSpellKnown(157223) then
		
			C.db.profile.classSpells[C.myCLASS][15407].tick = 3/4
			C.db.profile.classSpells[C.myCLASS][129197].tick = 3/4

		else
			C.db.profile.classSpells[C.myCLASS][15407].tick = 1
			C.db.profile.classSpells[C.myCLASS][129197].tick = 1
		end
	end

	local eventframe = CreateFrame("Frame")
	eventframe:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
	eventframe:RegisterEvent("PLAYER_TALENT_UPDATE")
	eventframe:RegisterEvent("PLAYER_LEVEL_UP")
	eventframe:RegisterEvent("SPELL_CHANGED")
	eventframe:RegisterEvent("PLAYER_LOGIN")
	eventframe:SetScript("OnEvent", OnEvent)

end
]==]