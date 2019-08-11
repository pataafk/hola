local addon, C = ...
if C.myCLASS ~= "DEMONHUNTER" then return end

local colors = C.CustomColors

local ALL = "ALL"

--[[
	1 = DD Havoc
	2 = TANK Vengeance
	
	spec = ALL,
]]

local spells = {

	[207744]= { spec = ALL, duration = 8, color = colors.RED },
    [203819]= { spec = ALL, color = colors.PINK3, duration = 6 },
    [218256]= { spec = ALL, duration = 6, color = colors.TEAL2 },
	[187827]= { spec = '2', duration = 20,  color = colors.CURSE }, -- vengeance
    [162264]= { spec = '1', duration = 30,  color = colors.CURSE }, -- havoc
    [212800]= { spec = ALL, duration = 10,  color = colors.PINK },
    [196555]= { spec = ALL, duration = 5,  color = colors.WOO2, },
	
	[179057]= { spec = ALL, duration = 5, color = colors.RED, },
	[211881]= { spec = ALL, duration = 2, color = colors.RED, },
    [217832]= { spec = ALL, duration = 60, color = colors.GOLD },
    [224509]= { spec = ALL, duration = 15, color = colors.DPURPLE },
    [208628]= { spec = ALL, duration = 4, color = colors.PINK3, },
    [211048]= { spec = ALL, duration = 12, color = colors.TEAL3, },

    [227225]= { spec = ALL, duration = 8, color = colors.WOO2},
    [207811]= { spec = ALL, duration = 15, color = colors.WOO2},
	
	[196718]= { spec = '1', duration = 8, color = colors.DPURPLE, whitelist_cleu = 5, cleu = true, },
}

local GetSpell = C.GetSpell

local cooldown = {
	[GetSpell(178740)] = { spellid = 178740, color = colors.PINKIERED },

	[GetSpell(213241)] = { spellid = 213241, color = colors.CURSE},
	[GetSpell(185123)] = { spellid = 185123, color = colors.PURPLE},
	[GetSpell(188499)] = { spellid = 188499, color = colors.PINKIERED},	

	[GetSpell(195072)] = { spellid = 195072},
	[GetSpell(198013)] = { spellid = 198013},
	[GetSpell(212084)] = { spellid = 212084},

	[GetSpell(211881)] = { spellid = 211881, color = colors.DBROWN},

	[GetSpell(207407)] = { spellid = 207407, },
	[GetSpell(201467)] = { spellid = 201467, },
}	

function C:SetupClassSpells()
	return spells
end

function C:SetupClassCooldowns()
	return cooldown
end