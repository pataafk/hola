local addon, C = ...

if C.myCLASS ~= "ROGUE" then return end

local colors = C.CustomColors

local ALL = "ALL"

--[[
	1 = Assasin
	2 = Combat
	3 = Sub
	
	spec = ALL,
]]

local spells = {
	
	[1966] = { spec = ALL,duration = 5, color = colors.LBLUE },
	[2983] = { spec = ALL,duration = 8 },
	[5277] = { spec = ALL,color = colors.PINK, duration = 15 },
	[31224] = { spec = ALL,color = colors.CURSE, duration = 5 },
--	[73651] = { spec = ALL,color = colors.LGREEN ,duration = 30 },
	[5171]  = { spec = ALL,color = colors.PURPLE, duration = 30 },
--	[122233] = { spec = ALL,color = colors.RED, duration = 12, cleu = true },
	[1833] = { spec = ALL,duration = 4, color = colors.LRED, cleu = true },
	[408]  = { spec = ALL,duration = 4, color = colors.LRED, cleu = true },
	[1776] = { spec = ALL,color = colors.PINK, duration = 4, cleu = true },
	[2094] = { spec = ALL,duration = 60, pvpduration = 8, color = {0.20, 0.80, 0.2},cleu = true },
--	[51722] = { duration = 10, color = colors.LRED, cleu = true },
	[6770] = { spec = ALL,duration = 60, color = colors.LBLUE, cleu = true },
	[1943] = { spec = "1;3",pandemia = true, color = colors.RED, duration = 24, cleu = true },
	[703]  = { spec = ALL,color = colors.RED, duration = 18, cleu = true },
	[1330] = { spec = ALL,color = colors.PINK, duration = 3, cleu = true },
	[32645] = { spec = "1",color = { 0, 0.65, 0}, duration = 16 },
	[79140] = { spec = "1",color = colors.CURSE, duration = 20 },
--	[121153] = { spec = "1",color = colors.TEAL, duration = 10 },
	[108212] = { spec = ALL,duration = 4 },
--	[115197] = { color = colors.BROWN, duration = 4 },
--	[14183]  = { spec = "3",duration = 20, color = colors.CURSE },
	[74002]  = { spec = ALL,duration = 10, color = colors.CURSE },
--	[84745]  = { spec = "2",color = colors.CURSE, duration = 15 },
--	[84746]  = { spec = "2",color = colors.CURSE, duration = 15 },
--	[84747] = {  spec = "2",color = colors.CURSE, duration = 15 },
	[13750] = { spec = "2",duration = 15, color = colors.LRED },
	[13877] = { spec = "2",duration = 15, color = colors.LRED },
--	[121471] = { duration = 12, color = colors.CURSE},
--	[51713] = { spec = "3",duration = 8, color = colors.BLACK },
--	[114018] = { spec = ALL,color = colors.CURSE, duration = 15 },
--	[114842] = { color = colors.PINK, duration = 6 },
	[1725]	 = { spec = ALL,color = colors.PURPLE, duration = 10, cleu = true, whitelist_cleu = 5 },
}	

local GetSpell = C.GetSpell
local cooldown = {}	

function C:SetupClassSpells()
	return spells
end

function C:SetupClassCooldowns()
	return cooldown
end
