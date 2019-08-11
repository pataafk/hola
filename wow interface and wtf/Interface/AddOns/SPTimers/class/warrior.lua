local addon, C = ...
local _,class = UnitClass("player")

if class ~= "WARRIOR" then return end

local colors = C.CustomColors

local ALL = "ALL"

--[[
	1 = Arms
	2 = Fury
	3 = Protection
	
	spec = ALL,
]]

local spells = {

	[132404] = { spec = "3", color = colors.WOO2, duration = 6, },
--	[112048] = { spec = ALL,color = colors.WOO, duration = 6 },
--	[12328] = {  spec = "1",color = colors.BLACK, duration = 10 },
--	[20511] = {  duration = 8, cleu = true },	
--	[86346] = {spec = ALL,color = colors.PURPLE2, duration = 6 }, --debuff	
--	[676]  = { color = colors.BROWN, duration = 10, cleu = true },
	[1715]  = { spec = ALL,color = colors.PURPLE, duration = 15, pvpduration = 8, cleu = true },
	[355]  = {  spec = "3",duration = 3, color = colors.TAUNT },
	[1160]  = { spec = "3",color = colors.BLACK, duration = 30, cleu = true },	
	[122510]  = { spec = "3",color = colors.TEAL, duration = 10 },		
--	[55694] =  {  spec = ALL,color = colors.LGREEN, duration = 5 },	
	[132168]  = { spec = ALL,color = colors.CURSE, duration = 4, cleu = true, },
--	[12880] = { spec = ALL, color = colors.DPURPLE, group = "procs", duration =6 },
	[12323]  = { spec = "2", cleu = true, duration = 15 },	
	[107566]  = { spec = "3", cleu = true, duration = 5 },	
	[107574] =  { spec = ALL,group = "player",  color = colors.TEAL, duration = 30 },	
	[132169] =  { spec = ALL,cleu = true, color = colors.TEAL2, duration = 3},
--[[
	[114203] =   duration = 15, color = colors.BLACK 
	]]	
	
--	[114207] =  { group = "player", source = 1, duration = 10, color = colors.RED },	
	[1719] =  { spec = ALL,color = colors.LRED, group = "player", duration = 20},
	[12292] =  { spec = ALL,group = "player", color = colors.PINKIERED, duration = 12, },	
--	[60503]  = { color = colors.PINKIERED, duration = 12 },
	[131116]  = { spec = "2",duration = 12 },
	[12975] =  { spec = "3",color = colors.BLACK, duration = 20, group = "player" },
	[97463]  = { spec = ALL,color = colors.BLACK, duration = 10, group = "player" },	
	[118038] =  {spec = ALL, color = colors.BLACK, duration = 8, group = "player" },
	[871] =  {spec = "3", color = colors.WOO2, duration = 12, group = "player" },	
	[32216] =  {spec = ALL, group = "player", color = colors.PURPLE, duration = 20},
	
--	[94009] = { spec = "1",duration = 18, tick = 3, pandemia = true },
	[772] 	= { spec = "1",duration = 18, showTicks = true, tick = 3, pandemia = true },
	
	
	[152277] = { spec = ALL,duration = 10, color = colors.PURPLE },
--	[169667] = { spec = "3", duration = 7, color = colors.DBROWN },

	[215570] = { spec = '2', duration = 10, },
	[208086] = { spec = '1', duration = 24, color = colors.DBROWN, },
}



local GetSpell = C.GetSpell

local cooldown = {
--	[GetSpell(86346)] = { spellid = 167105, color = colors.WOO },	
	[GetSpell(6572)] = { spellid = 6572, color = colors.PURPLE },	
	[GetSpell(46968)] = { spellid = 46968, color = colors.WOO2 },	
	[GetSpell(12294)] = { spellid = 12294, color = colors.CURSE },
	[GetSpell(23881)] = { spellid = 23881, color = colors.CURSE },
	[GetSpell(23922)] = { spellid = 23922, color = colors.CURSE },
	[GetSpell(6343)] = { spellid = 6343, color = colors.PINKIERED },
	[GetSpell(152277)] = { spellid = 152277, color = colors.PURPLE },
}


function C:SetupClassSpells() self.myCLASS = class; return spells end
function C:SetupClassCooldowns() self.myCLASS = class; return cooldown end