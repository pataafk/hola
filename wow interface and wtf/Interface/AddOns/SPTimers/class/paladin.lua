local addon, C = ...
if C.myCLASS ~= "PALADIN" then return end

local colors = C.CustomColors
local ALL = "ALL"

--[[
	1 = Heal
	2 = Tank
	3 = DD
	
	spec = ALL,
]]

local spells = { 
	
--	[84963]  = { duration = 12, color = colors.PURPLE },
	[31842]  = { spec = "1",duration = 20, color = colors.GOLD },
	[31884]  = { spec = "3",duration = 20, color = colors.FIRE },
	[498]	 = { spec = ALL,duration = 10, color = colors.BLACK },
	[642] 	 = { spec = ALL,duration = 8, color = colors.BLACK },
	[31850]	 = { spec = "2",duration = 10, color = colors.BLACK},
	[1022]   = { spec = ALL,duration = 10, color = colors.WOO2, source = 1, cleu = true },
	[1044]   = { spec = ALL,duration = 6, source = 1, cleu = true },
--	[10326]  = { spec = ALL,duration = 20, pvpduration = 8, color = colors.LGREEN, cleu = true },
--	[105421] = { duration = 6, color = colors.DRED, cleu= true },
--	[54428]  = { duration = 15 }, 
	[20066]  = { spec = ALL,duration = 60, pvpduration = 8, color = colors.LBLUE, cleu= true  },
	[853]	 = { spec = ALL,duration = 6, color = colors.FROZEN, cleu= true },
--	[2812]	 = { spec = "1",duration = 4, color = colors.GREEN },
--	[114637] = { spec = "2",duration = 20, color = colors.DRED },
--	[59578]  = { spec = "3",color = colors.LRED, duration = 15 },
	[62124]	 = { spec = "2",color = colors.TAUNT, duration = 3 },
	[85499]  = { spec = ALL,duration = 7 },
	[114250] = { spec = ALL,duration = 15 },
	[114163] = { spec = ALL,duration = 30, color = colors.LGREEN },
--	[20925]  = { spec = ALL,color = colors.WOO2, duration = 30},
--	[90174]  = { spec = ALL,color = colors.PINK, duration = 8 },	
--	[114916] = { spec = ALL,color = colors.BLACK, duration = 10 },
--	[114917] = { spec = ALL,color = colors.BLACK, duration = 10 },

	[152262] = { spec = ALL,color = colors.FIRE, duration = 10 },
	
	[156990] = { spec = ALL, color = colors.FIRE, duration = 20 },
	[156989] = { spec = ALL, color = colors.FIRE, duration = 20 },
	[156987] = { spec = ALL, color = colors.FIRE, duration = 20 },
	[156988] = { spec = ALL, color = colors.FIRE, duration = 20 },
	
}

local GetSpell = C.GetSpell

local cooldown = {

	[GetSpell(35395)] = { spellid = 35395, color = colors.CURSE },
	[GetSpell(20271)] = { spellid = 20271, color = colors.RED },
	
	[GetSpell(24275)] = { spellid = 24275, color = colors.TEAL },
--	[GetSpell(119072)] = { spellid = 119072, color = colors.BROWN },
	[GetSpell(26573)] = { spellid = 26573, color = colors.LBLUE },
	[GetSpell(31935)] = { spellid = 31935, color = colors.BLACK },
	[GetSpell(114165)] = { spellid = 114165, color = colors.BLACK },
}



function C:SetupClassSpells() return spells end
function C:SetupClassCooldowns() return cooldown end