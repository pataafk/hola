local addon, C = ...
if C.myCLASS ~= "WARLOCK" then return end

local L = AleaUI_GUI.GetLocale("SPTimers")

local colors = C.CustomColors

local ALL = "ALL"
--[[
	ALL = ALL
	1 = Affli
	2 = Demo
	3 = Destro
	
	spec = "1;2;3",
	
]]


local spells = {
	[184073] 	 = { spec = ALL, color = { 0.631372549019608, 0.192156862745098, 0.227450980392157, }, duration = 10, color_on = true, cleu = true, },	
	
--	[108686]	 = { spec = "3", duration = 15, tick = 3, haste = true, pandemia = true, cleu = true }, -- aoe immolate
	[348]		 = { spec = "3", duration = 15, custom_text = "%tN", showTicks = true, tick = 3, haste = true, pandemia = true, cleu = true },	   -- solo immolate
	[157736]	 = { spec = "3", duration = 15, custom_text = "%tN", showTicks = true, tick = 3, haste = true, pandemia = true, cleu = true },	   -- aoe immolate
	
--	[47960]		 = { spec = "2",duration = 6, tick = 1, pandemia = true,  haste = true, color = colors.CURSE },
	[146739]	 = { spec = "1",duration = 14, custom_text = "%tN", showTicks = true, tick = 2, haste = true, pandemia = true, cleu = true },-- corruption
	[980]		 = { spec = "1",duration = 18, custom_text = "%tN", showTicks = true, tick = 2, haste = true, pandemia = true, cleu = true },-- agony
	
	[30108] 	 = { spec = "1",duration = 8, custom_text = "%tN", showTicks = true, tick = 2, showOverlay = true, cast = 1.5, haste = true, pandemia = false, cleu = true },-- ua
	[233490]	 = { spec = "1",duration = 8, custom_text = "%tN", showTicks = true, tick = 2, showOverlay = true, cast = 1.5, haste = true, pandemia = false, cleu = true },-- ua
	[233496]	 = { spec = "1",duration = 8, custom_text = "%tN", showTicks = true, tick = 2, showOverlay = true, cast = 1.5, haste = true, pandemia = false, cleu = true },-- ua
	[233497]	 = { spec = "1",duration = 8, custom_text = "%tN", showTicks = true, tick = 2, showOverlay = true, cast = 1.5, haste = true, pandemia = false, cleu = true },-- ua
	[233498]	 = { spec = "1",duration = 8, custom_text = "%tN", showTicks = true, tick = 2, showOverlay = true, cast = 1.5, haste = true, pandemia = false, cleu = true },-- ua
	[233499]	 = { spec = "1",duration = 8, custom_text = "%tN", showTicks = true, tick = 2, showOverlay = true, cast = 1.5, haste = true, pandemia = false, cleu = true },-- ua

	[48181] 	 = { spec = "1",duration = 8,  showOverlay = true, cast = 3, haste = false, cleu = true },-- блуждающий дух
	
--	[74434]		 = { spec = "1",duration = 20, color = colors.CURSE },
	[111400]	 = { spec = ALL,group = "player", color = colors.PURPLE2 },
--	[34936]		 = { group = "procs", duration = 8,  color = colors.CURSE },
	
	[104773]	 = { spec = ALL,group = "player", duration = 12, color = colors.WOO2 },
	
--	[122355]	 = { spec = "2",duration = 30, color = colors.PURPLE },
	
	[27243]		 = { spec = "1",duration = 15, showOverlay = true, cast = 1.5, showTicks = true, tick = 2, haste = true, cleu = true }, -- soc
--	[114790]	 = { spec = "1",duration = 15, cast = 1.5, tick = 2, haste = true, cleu = true }, -- soc + ss

	[105174] 	 = { spec = "2",duration = 6,  showTicks = true, tick = 2,  haste = true},	-- hand of Gul'Dan
	[603] 	 	 = { spec = "2", duration = 20, custom_text = "%tN", haste = true, pandemia = true, cleu = true },	-- doom,

	[689]		 = { spec = "1;2",duration = 12, showTicks = true, tick = 2, haste = true, spellType = 2, group = "target" }, -- drain life
--	[103103]	 = { spec = "1",duration = 4,  tick = 1, haste = true, spellType = 2, group = "target" }, -- malf grasp
	
--	[113861]	 = { spec = "2",duration = 20 }, -- demon souls
--	[113860]	 = { spec = "1",duration = 20 },
--	[113858]	 = { spec = "3",duration = 20 },
	
	[117828]	 = { spec = "3",duration = 15, group = "procs", color = colors.FIRE },
--	[140074]	 = { spec = "2",duration = 30, group = "procs", color = colors.FIRE },
	
	[1122]   	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	[18540]  	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	[112921] 	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	[112927] 	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	
	[111895] 	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	[111859] 	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	[111897] 	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	[111898] 	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },
	[111896] 	 = { spec = ALL,duration = 25, cleu = true, group = "player", color = colors.BLACK, whitelist_cleu = 5, },

--	[1949]		 = { spec = "2",duration = 14, haste = true }, -- hellfire
	
--	[104232]	 = { spec = "3",cleu = false, whitelist = 2, blacklist = 3 },
	
	[86211] 	 = { spec = "1",group = "procs", duration = 20, color = colors.BLACK },
	
	[6789]		 = { spec = ALL,duration = 3 },
	[5484]		 = { spec = ALL,duration = 20, pvpduration = 8, cleu = true },
--	[110913]	 = { spec = ALL,group = "procs", duration = 10 },
	[108416] 	 = { spec = ALL,group = "procs", duration = 10 },
	[30283]		 = { spec = ALL,duration = 3, cleu = true },
	[5782]		 = { spec = ALL,duration = 20, pvpduration = 8, cleu = true },
	[118699]	 = { spec = ALL,duration = 20, pvpduration = 8, cleu = true },
--	[104045]	 = { duration = 20, pvpduration = 8, cleu = true },
	[710]		 = { spec = ALL,duration = 30 },
	
--	[157698]	 = { spec = "1", duration = 30, group = "procs", pandemia = true, },
--	[137587]	 = { spec = ALL, duration = 8, group = "procs", },
--	[108508]	 = { spec = ALL, duration = 8, group = "procs", },
	
	[171982]	 = { spec = "2", duration = 15, group = "player", source = 5, target_affil = 2 },
	[145085]	 = { spec = "2", duration = 10, group = "player" },
	
	[196098]	 = { spec = '2', duration = 10, group = "player", source = 5, target_affil = 2 }, -- soul harvest
	[205146]	 = { spec = "2", duration = 20, group = "player",},	-- demonic calling ,
	
	[196104]	 = { spec = '1;3', duration = 12, group = "player",}, -- Mana Tap
	
	[63106] 	 = { spec = '1', duration = 15, cleu = true, pandemia = true }, -- Siphon Life
	
	[205179]	 = { spec = '1', duration = 15 }, -- phantom
	[205178]	 = { spec = '1', duration = 600, cleu = true }, -- Soul effigy
	
	[196414]	 = { spec = '3', duration = 6, }, -- Eraducation
	
	[80240]		 = { spec = '3', duration = 20,  group = "player", }, -- Havoc
	
	-- [80240]		 = { spec = "3",duration = 15, color = colors.LRED, group = "player", whitelist = 2 },
}

local GetSpell = C.GetSpell
local cooldown = {
	[GetSpell(17962)] = { spellid = 17962, color = colors.PINK },
	[GetSpell(105174)] = { spellid = 105174, color = colors.CURSE },
}	

function C:SetupClassSpells()
	return spells
end

function C:SetupClassCooldowns()
	return cooldown
end


do	
	--[==[
		02:14:01 T SPELL_CAST_SUCCESS Тэваро Мятежный бес Жертвенный огонь 348
		02:14:01 T SPELL_AURA_APPLIED Тэваро Мятежный бес Жертвенный огонь 157736
		02:14:04 T SPELL_CAST_SUCCESS Тэваро Мятежный бес Поджигание 17962
		02:14:04 T SPELL_AURA_APPLIED Тэваро Тэваро Хаотичное воспламенение 196546
		02:14:05 T SPELL_CAST_SUCCESS Тэваро Мятежный бес Поджигание 17962
	]==]
	local data = {}
	local enableImmolate = false
	
	local event = CreateFrame('Frame')
--	event:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	event:SetScript('OnEvent', function(self, event, ...)
		local timestamp, eventType, hideCaster,
			srcGUID, srcName, srcFlags, srcFlags2,
			dstGUID, dstName, dstFlags, dstFlags2,
			spellID, spellName, spellSchool = ...
		
		if srcGUID ~= C.myGUID then return end

		if spellID == 157736 and ( eventType == 'SPELL_AURA_APPLIED' or eventType == 'SPELL_AURA_REFRESH' ) then
		--	print('T', eventType, srcName, dstName, spellName, spellID)
			
			if C.IsTalentKnown(205184) then
				data[dstGUID] = 0
			else
				data[dstGUID] = nil
			end
		elseif spellID == 17962 and eventType == 'SPELL_DAMAGE' then
		--	print('T', eventType, srcName, dstName, spellName, spellID)
			
			if data[dstGUID] and C.IsTalentKnown(205184) then
				data[dstGUID] = data[dstGUID] + 1
			end
		elseif spellID == 157736 and eventType == 'SPELL_AURA_REMOVED' then
		--	print('T', eventType, srcName, dstName, spellName, spellID)
	
			data[dstGUID] = nil
		end
	end)
	
	function C:GetImmolateBuffsStacks(guid)
		
		if enableImmolate and data[guid] then			
			return data[guid]
		end
		
		return '0'
	end
	
	local function OnEvent()

		if C.IsTalentKnown(205184) then
			event:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
			enableImmolate = true
		else
			event:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
			enableImmolate = false
		end
		
		
	--	local prevPandemic = nil
	--	local showTicks = nil
		C.ignorePandemicForCorruption = false
		
		if C.IsTalentKnown(196103) then
			C.ignorePandemicForCorruption = true
		end
	end
	--[==[
	local function ClassGUIChange(dir, spellID)
		if (spellID == 146739 ) and C.IsTalentKnown(196103) then
			if dir.args.classGrop and
				dir.args.classGrop.args.Pandemia then
				
				dir.args.classGrop.args.Pandemia.disabled = true
				dir.args.classGrop.args.Pandemia.desc = L["30% dutation indicator desc"]..'\n\n|cFFFF0000Disabled cuz of talent '..GetSpellInfo(196103)
			end
			if dir.args.classGrop and
				dir.args.classGrop.args.ShowTicks.args.show then
				
				dir.args.classGrop.args.ShowTicks.args.show.disabled = true
				dir.args.classGrop.args.ShowTicks.args.show.desc = '\n|cFFFF0000Disabled cuz of talent '..GetSpellInfo(196103)
			end
		else
			if dir.args.classGrop and
				dir.args.classGrop.args.Pandemia then
				
				dir.args.classGrop.args.Pandemia.disabled = false				
				dir.args.classGrop.args.Pandemia.desc = L["30% dutation indicator desc"]
			end
			if dir.args.classGrop and
				dir.args.classGrop.args.ShowTicks.args.show then
				
				dir.args.classGrop.args.ShowTicks.args.show.disabled = false
				dir.args.classGrop.args.ShowTicks.args.show.desc = nil
			end
		end
	end
	]==]
--	C:AddOnClassGUIChangeHandler(ClassGUIChange)	
	C:AddToTalentCheck(OnEvent)
end
