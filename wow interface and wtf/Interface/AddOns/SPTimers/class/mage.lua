local addon, C = ...
if C.myCLASS ~= "MAGE" then return end

local colors = C.CustomColors

local ALL = "ALL"

--[[
	1 = Arcane
	2 = Fire
	3 = Frost
	
	spec = ALL,
]]

local spells = {
	
	[184073]= { spec = ALL, color = { 0.631372549019608, 0.192156862745098, 0.227450980392157, }, duration = 10, color_on = true, cleu = true, },	
	
	[118]   = { spec = ALL,duration = 50, color = colors.LGREEN, pvpduration = 8, cleu = true },
	[61305] = { spec = ALL,duration = 50, color = colors.LGREEN, pvpduration = 8, cleu = true },
	[28271] = { spec = ALL,duration = 50, color = colors.LGREEN, pvpduration = 8, cleu = true },
	[28272] = { spec = ALL,duration = 50, color = colors.LGREEN, pvpduration = 8, cleu = true },
	[61721] = { spec = ALL,duration = 50, color = colors.LGREEN, pvpduration = 8, cleu = true },
	[61780] = { spec = ALL,duration = 50, color = colors.LGREEN, pvpduration = 8, cleu = true },
	
	[12042] = { spec = "1",duration = 15, color = colors.PINK }, 
	[36032] = { spec = "1",duration = 10, color = colors.CURSE },
	[79683] = { spec = "1",duration = 20, color = colors.WOO },
	[31589] = { spec = "1",cleu = true, duration = 15, pvpduration = 8 },
--	[55021] = { cleu = true, duration = 4, color = colors.PINK },
	
	[48108] = { spec = "2",duration = 10, color = colors.CURSE, group = "procs" },
--	[11113] = { color = colors.CHILL, duration = 3, cleu = true }, -- ?????
	[31661] = { spec = "2",duration = 5, color = colors.ORANGE, cleu = true },
	
	[2120]  = { spec = "2",duration = 8, haste = true, showTicks = true, tick = 2, color = colors.ORANGE, cleu = true, group = "player", whitelist_cleu = 5, blacklist_cleu = 3, blacklist = 3 },
	
	[12472] = { spec = "3",duration = 20 },
	[82691] = { spec = ALL,color = colors.FROZEN, cleu = true, duration = 12, pvpduration = 8 },
	[122]   = { spec = ALL,duration = 8, color = colors.FROZEN, cleu = true },
	[33395] = { spec = "3",duration = 8, color = colors.FROZEN, cleu = true },
	[44544] = { spec = "3",duration = 15, color = colors.FROZEN },
--	[57761] = { spec = "3",duration = 15, color = colors.LRED },
	[45438] = { spec = ALL,duration = 10 },
--	[44572] = { spec = "3",cleu = true, duration = 5 },
	[120]   = { spec = "3", duration = 8, color = colors.CHILL, cleu = true },
--	[12043] = { spec = "1",duration = 1, color = colors.CURSE },
	[11426] = { spec = ALL,duration = 60, color = colors.LGREEN },
	[115610] = { spec = ALL,duration = 4, color = colors.LGREEN },
--	[102051] = { spec = ALL,duration = 8, pvpduration = 4,  color = colors.PINK, cleu = true },
	[32612] =  { spec = ALL,duration = 20 },
	[110960] = { spec = ALL,duration = 20, color = colors.CURSE },
--	[116257] = { duration = 60, color = colors.DPURPLE },
	[116014] = { spec = ALL,duration = 1, color = colors.DPURPLE },
	[112948] = { spec = '3',duration = 4,  haste = true, showTicks = true, tick = 4, color = colors.CURSE, cleu = true },
	[114923] = { spec = '1',custom_text = "%tN", duration = 12, haste = true, showTicks = true, tick = 1, color = colors.PURPLE, cleu = true },
	[44457]  = { spec = '2',custom_text = "%tN", duration = 12, haste = true, showTicks = true, tick = 3, color = colors.RED, cleu = true, pandemia = true },
	[11366]  = { spec = "2",duration = 18, haste = true, showTicks = true, tick = 3, color = colors.RED, cleu = true, pandemia = true },
	[12654]  = { spec = "2",duration = 4,  showTicks = true, tick = 2, color = colors.RED },
--	[83853]  = { spec = "2",duration = 10, haste = true, tick = 1, color = colors.RED },

}


local GetSpell = C.GetSpell

local cooldown = {

--	[GetSpell(159916)]  = { spellid = 159916, color = colors.CURSE },
}	

function C:SetupClassSpells()
	return spells
end

function C:SetupClassCooldowns()
	return cooldown
end


------------- Fire Mage Bombs stuff
--[==[
local SpreadSpellCast = nil

local spellToSpread = {
	[44457] = true,
	[12654] = true,
	[11366] = true,
	[83853] = true,
}

local currentSpec = nil
local FireMageSpecID = 2

local events = CreateFrame("Frame")
events:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player")
events:RegisterEvent("PLAYER_TALENT_UPDATE")
events:RegisterEvent("PLAYER_LEVEL_UP")
events:RegisterEvent("PLAYER_LOGIN")

function C.GetFireMageDotSource(destGUID, spellID)
	if C.SpreadSpellCast and C.SpreadSpellDestGUID ~= destGUID and spellToSpread[spellID] then
		return true, C.SpreadSpellDestGUID
	else
		return false
	end
end

events:SetScript('OnEvent', function(self, event, ...)
	currentSpec = GetSpecialization()	
--	print('T', FireMageSpecID, currentSpec)
	if currentSpec and currentSpec == FireMageSpecID then
		C.IsFireMage = true
	else
		C.IsFireMage = false
	end
end)
]==]