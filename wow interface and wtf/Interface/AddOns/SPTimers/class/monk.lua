local addon, C = ...
if C.myCLASS ~= "MONK" then return end

local colors = C.CustomColors

local ALL = "ALL"

--[[
	1 = Tank
	2 = DD
	3 = Heal
	
	spec = ALL,
]]

local spells = {


	[120954] =  { spec = ALL,color = colors.WOO2, duration = 20 },
--	[117368] =  { color = colors.BROWN, duration = 10, cleu = true },
	[115078] =  { spec = ALL,color = colors.PURPLE, duration = 30, pvpduration = 8, cleu = true },
	[115546] =  { spec = "1",color = colors.TAUNT, duration = 3, cleu = true },
--	[118864] =  { spec = "2",color = colors.WOO, duration = 15 },
	[116768] =  { spec = "2",color = colors.PINK, duration = 15 },
--	[125195] =  { spec = "1",color = colors.BLACK, duration = 120 },
	[116740] =  { spec = "2",color = colors.BLACK, duration = 15 },
--	[125359] =  { spec = "1;2", pandemia = true, color = colors.PURPLE2, duration = 20 },
--	[127722] =  { spec = "2",color = colors.PINK, duration = 30 },
	[119611] =  { spec = "3",color = colors.LGREEN, target = "player", duration = 18 },
--	[115867] =  { spec = "3",duration = 120, color = colors.BLACK },
	[116849] =  { spec = "3",color = colors.PURPLE, duration = 12, cleu = true },
--	[118674] =  { spec = "3",color = colors.BLACK, duration = 30 },
--	[115213] =  { duration = 15 },
--	[115307] =  { spec = "1",color = colors.RED, duration = 6 },
--	[116330] =  { spec = "1",color = colors.PURPLE, duration = 15, cleu = true },
--	[123727] =  { color = colors.PURPLE, duration = 15, cleu = true },
	[128939] =  { spec = "1",duration = 30, color = colors.BLACK },
	[115308] =  { spec = "1",duration = 15, color = colors.BLACK },
	[124081] =  { spec = ALL,duration = 16, color = { 1, 0.2, 1} },
	[119381] =  { spec = ALL,duration = 5, color = colors.RED, cleu = true },
	[122783] =  { spec = ALL,duration = 6, color = colors.CURSE },

}

local GetSpell = C.GetSpell

local cooldown = {
	[GetSpell(107428)] = { spellid = 107428, color = colors.PURPLE },
--	[GetSpell(123761)] = { spellid = 123761, color = colors.CURSE },
	[GetSpell(116680)] = { spellid = 116680, color = colors.CURSE },
--	[GetSpell(115295)] = { spellid = 115295, color = colors.GOLD },
	[GetSpell(121253)] = { spellid = 121253, color = colors.CURSE },
}	

function C:SetupClassSpells()
	return spells
end

function C:SetupClassCooldowns()
	return cooldown
end
