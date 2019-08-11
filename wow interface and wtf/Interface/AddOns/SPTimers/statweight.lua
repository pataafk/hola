local addon, C = ...

local gameBuild = select(4, GetBuildInfo())
local playerClass = C.myCLASS

local classEnabled = {
	['PRIEST'] = true,
	['WARLOCK'] = true,
	['MAGE'] = true,
	['DRUID'] = true,
	['SHAMAN'] = true,
}

--if not classEnabled[playerClass] then return end

local db
local _G = _G
local format = string.format
local find = string.find
local match = string.match
local pairs = pairs
local floor = math.floor
local tonumber = tonumber
local tsort = table.sort
local type = type
local strsplit = strsplit
local select = select
local UnitClass = UnitClass
local wipe = table.wipe
local UnitLevel = UnitLevel
local GetItemInfo = GetItemInfo
local InCombatLockdown = InCombatLockdown
local GetTime = GetTime
local gsub = string.gsub
local GetItemStats = GetItemStats
local ceil = ceil
local abs = abs

local ITEM_SPELL_TRIGGER_ONEQUIP = ITEM_SPELL_TRIGGER_ONEQUIP
local ITEM_SPELL_TRIGGER_ONUSE = ITEM_SPELL_TRIGGER_ONUSE
	
	
local enabledProfiles = {}
local disableModule = true
local disableRelics = true

local ALL_FILTER = 'ALL'

local classFilter = { [ALL_FILTER] = true }

for class in pairs(RAID_CLASS_COLORS) do
	classFilter[class] = true
end

local buildFilter = { [ALL_FILTER] = 'All' }
buildFilter[60000] = '6.0.x'
buildFilter[60100] = '6.1.x'
buildFilter[60200] = '6.2.x'
buildFilter[70000] = '7.0.x'
buildFilter[70100] = '7.1.x'
buildFilter[70105] = '7.1.5'
buildFilter[70200] = '7.2.0'
buildFilter[70300] = '7.3.0'
buildFilter[70305] = '7.3.5'
buildFilter[80000] = '8.0.1'

--[[
	
		["CritRating"] = "CritRating",
		["HasteRating"] = "HasteRating",
		["MasteryRating"] = "MasteryRating",
		["Multistrike"] = "Multistrike",
		["Versatility"] = "Versatility",
		["Stamina"] = "Stamina",
			
	
		crit = 0.7597,
		haste = 0.6883,
		multistrike = 0.5809, 
		versatility =  0.4917, 
		mastery = 0.4109, 

]]

local useBlizzardAPI = false
local GemData = {}
local statCompareCache = {	
	{ 0, "CritRating"},
	{ 0, "HasteRating"},
	{ 0, "MasteryRating"},
	{ 0, "Multistrike"},
	{ 0, "Versatility"},
	{ 0, "Stamina"},
	{ 0, 'Intellect' },
	{ 0, 'Agility' },
	{ 0, 'Strength' },
}

local function statCompareSortFunc(x,y)
	if x[1] > y[1] then
		return true
	else
		return false
	end
end

local function GetMaxPresetStat(name)
	
	statCompareCache[1][1] = db.presets[name].crit or 0
	statCompareCache[2][1] = db.presets[name].haste or 0
	statCompareCache[3][1] = db.presets[name].mastery or 0
	statCompareCache[4][1] = db.presets[name].multistrike or 0
	statCompareCache[5][1] = db.presets[name].versatility or 0
	statCompareCache[6][1] = db.presets[name].stamina or 0
	statCompareCache[7][1] = db.presets[name].intellect or 0
	statCompareCache[8][1] = db.presets[name].agility or 0
	statCompareCache[9][1] = db.presets[name].strenght or 0
	
	statCompareCache[1][2] = "CritRating"
	statCompareCache[2][2] = "HasteRating"
	statCompareCache[3][2] = "MasteryRating"
	statCompareCache[4][2] = "Multistrike"
	statCompareCache[5][2] = "Versatility"
	statCompareCache[6][2] = "Stamina"
	statCompareCache[7][2] = 'Intellect'
	statCompareCache[8][2] = 'Agility'
	statCompareCache[9][2] = 'Strength'
	
--	statCompareCache[6][1] = db.presets[name].crit
	
	tsort(statCompareCache, statCompareSortFunc)
	db.presets[name].maxStat = statCompareCache[1][2]
	
--	print('T', statCompareCache[1][1], statCompareCache[1][2])
end

local function RefreshEnabledProfiles()

	gameBuild = select(4, GetBuildInfo())
	playerClass = select(2, UnitClass('player'))
	
	wipe(enabledProfiles)
	
	disableModule = true
	disableRelics = true
	
	for statname, statdata in pairs(db.presets) do	
	
		if statdata.powerBonus == nil then
			statdata.powerBonus = {}
		end
		
		if statdata.__enabled and ( statdata.__class == ALL_FILTER or statdata.__class == playerClass ) and ( statdata.__gameBuild == ALL_FILTER or statdata.__gameBuild == gameBuild ) then
			enabledProfiles[statname] = true		
			GetMaxPresetStat(statname)
			
			if statdata.selected_artifact and statdata.selected_artifact ~= 1 then
				--disableRelics = false
			end
			
			disableModule = false
		end
	end
	
--	print('disableRelics', disableRelics)
--	print('disableModule', disableModule)
end

local EquippedItem = {}
local CompareItem = {}

local statsWeight = {}

--local slot = GetInventorySlotInfo(index)
--GetInventoryItemDurability(slot)

--{'PLAYER_ENTERING_WORLD', "UPDATE_INVENTORY_DURABILITY", "MERCHANT_SHOW"}


--[[
0 = ammo
1 = head
2 = neck
3 = shoulder
4 = shirt
5 = chest
6 = waist
7 = legs
8 = feet
9 = wrist
10 = hands
11 = finger 1
12 = finger 2
13 = trinket 1
14 = trinket 2
15 = back
16 = main hand
17 = off hand
18 = ranged
19 = tabard
20 = first bag (the rightmost one)
21 = second bag
22 = third bag
23 = fourth bag (the leftmost one)
]]
--[[
local hasItem, hasCooldown, repairCost = GameTooltip:SetInventoryItem("player", 10);


for i=1, GameTooltip:NumLines() do        
   --local right = _G[GameTooltip:GetName().."TextRight"..i]:GetText()
   local left = _G[GameTooltip:GetName().."TextLeft"..i]:GetText()
   
   print("T", i, left)
   
end
]]

local ITEM_MOD_INTELLECT_SHORT = ITEM_MOD_INTELLECT_SHORT
local ITEM_MOD_INTELLECT = ITEM_MOD_INTELLECT
local ITEM_MOD_STAMINA_SHORT = ITEM_MOD_STAMINA_SHORT
local ITEM_MOD_STAMINA = ITEM_MOD_STAMINA
local ITEM_MOD_CRIT_RATING_SHORT = ITEM_MOD_CRIT_RATING_SHORT
local ITEM_MOD_CR_MULTISTRIKE_SHORT = ITEM_MOD_CR_MULTISTRIKE_SHORT
local ITEM_MOD_VERSATILITY = ITEM_MOD_VERSATILITY
local ITEM_MOD_HASTE_RATING_SHORT = ITEM_MOD_HASTE_RATING_SHORT
local ITEM_MOD_MASTERY_RATING_SHORT = ITEM_MOD_MASTERY_RATING_SHORT
local ITEM_MOD_SPELL_POWER_SHORT = ITEM_MOD_SPELL_POWER_SHORT
local ITEM_MOD_STRENGTH_SHORT = ITEM_MOD_STRENGTH_SHORT
local ITEM_MOD_AGILITY_SHORT = ITEM_MOD_AGILITY_SHORT
local ITEM_MOD_SPIRIT_SHORT = ITEM_MOD_SPIRIT_SHORT
local ITEM_MOD_EXTRA_ARMOR_SHORT = ITEM_MOD_EXTRA_ARMOR_SHORT

local NUMBER_PATTERN			= "(%d+%,?%.? ?%d*) "
local PATTERN_INTELLECT 		= NUMBER_PATTERN..ITEM_MOD_INTELLECT_SHORT..'$'
local PATTERN_STAMINA 			= NUMBER_PATTERN..ITEM_MOD_STAMINA_SHORT..'$'
local PATTERN_CRIT				= NUMBER_PATTERN..ITEM_MOD_CRIT_RATING_SHORT..'$'
local PATTERN_MULTISTRIKE 		= NUMBER_PATTERN..ITEM_MOD_CR_MULTISTRIKE_SHORT..'$'
local PATTERN_VERSATILITY 		= NUMBER_PATTERN..ITEM_MOD_VERSATILITY..'$'
local PATTERN_HASTE 			= NUMBER_PATTERN..ITEM_MOD_HASTE_RATING_SHORT..'$'
local PATTERN_MASTERY 			= NUMBER_PATTERN..ITEM_MOD_MASTERY_RATING_SHORT..'$'
local PATTERN_SPELLPOWER 		= NUMBER_PATTERN..ITEM_MOD_SPELL_POWER_SHORT..'$'
local PATTERN_STRENGTH 			= NUMBER_PATTERN..ITEM_MOD_STRENGTH_SHORT..'$'
local PATTERN_AGILITY 			= NUMBER_PATTERN..ITEM_MOD_AGILITY_SHORT..'$'
local PATTERN_SPIRIT			= NUMBER_PATTERN..ITEM_MOD_SPIRIT_SHORT..'$'
local PATTERN_EXTRAARMOR		= NUMBER_PATTERN..ITEM_MOD_EXTRA_ARMOR_SHORT..'$'

--[[
-- Feet
local INVTYPE_FEED
local FEETSLOT

-- RINGS
local FINGER0SLOT
local FINGER1SLOT
local INVTYPE_FINGER

-- TRINKET
local TRINKET0SLOT
local TRINKET1SLOT
local INVTYPE_TRINKET
]]

local Gem100 ={
	{ 115803, "CritRating", 35 }, -- Critical Strike Taladite
	{ 115804, "HasteRating", 35 }, -- Haste Taladite
	{ 115805, "MasteryRating", 35 }, -- Mastery Taladite
	{ 115806, "Multistrike", 35 }, -- Multistrike Taladite
	{ 115807, "Versatility", 35 }, -- Versatility Taladite
	{ 115808, "Stamina", 35 }, -- Stamina Taladite
	
	{ 115809, "CritRating", 50 }, -- Greater Critical Strike Taladite
	{ 115811, "HasteRating", 50 }, -- Greater Haste Taladite
	{ 115812, "MasteryRating", 50 }, -- Greater Mastery Taladite
	{ 115813, "Multistrike", 50 }, -- Greater Multistrike Taladite
	{ 115814, "Versatility", 50 }, -- Greater Versatility Taladite
	{ 115815, "Stamina", 50 }, -- Greater Stamina Taladite
	
	{ 127760, "CritRating", 75 }, -- Immaculate Critical Strike Taladite
	{ 127761, "HasteRating", 75 }, -- Immaculate Haste Taladite
	{ 127762, "MasteryRating", 75 }, -- Immaculate Mastery Taladite
	{ 127763, "Multistrike", 75 }, -- Immaculate Multistrike Taladite
	{ 127764, "Versatility", 75 }, -- Immaculate Versatility Taladite
	{ 127765, "Stamina", 75 }, -- Immaculate Stamina Taladite
}

local Gem110 = {

	{ 130215, "CritRating", 100 },
	{ 130216, "HasteRating", 100 },
	{ 130217, "Versatility", 100 },
	{ 130218, "MasteryRating", 100 },
	
	{ 130220, 'HasteRating', 150 }, -- http://www.wowhead.com/item=130220
	{ 130219, "CritRating", 150 },
	{ 130221, "Versatility", 150 },
	{ 130222, 'MasteryRating', 150 },
	
	{ 151585, 'Versatility', 200 },
	{ 151584, 'MasteryRating', 200 },
	{ 151580, 'CritRating', 200 },
	{ 151583, 'HasteRating', 200 },
	
	{ 130247, 'Agility', 200 },
	{ 130248, 'Intellect', 200 },
	{ 130246, 'Strength', 200 },
}

local function GetMaxGem(typeStat)

	local list
	
	
	if UnitLevel('player') == 110 then
		list = Gem110
	else
		list = Gem100
	end
	
	local maxVal = 0
	
	if typeStat then
		for i=1, #list do
			if maxVal < list[i][3] and typeStat == list[i][2] then
				maxVal = list[i][3]
			end
		end
	else
		for i=1, #list do
			if maxVal < list[i][3] then
				maxVal = list[i][3]
			end
		end
	end
	
	return maxVal
end

local function CreateString(data, statweight)
	local totalweght = 0
	
	if not data or not statweight then return 0 end
	
	local tempcrit, tempmultistrike, tempmastery, tempversatility, temphaste = 0, 0, 0, 0, 0
	
	if statweight.intellect and statweight.intellect > 0 and data.intellect then		
		totalweght = totalweght + (data.intellect * statweight.intellect)
	end
	
	if statweight.agility and statweight.agility > 0 and data.agility then		
		totalweght = totalweght + (data.agility * statweight.agility)
	end
	
	if statweight.strength and statweight.strength > 0 and data.strength then		
		totalweght = totalweght + (data.strength * statweight.strength)
	end
	
	if statweight.crit and statweight.crit > 0 and data.crit then		
		totalweght = totalweght + ( (data.crit+ tempcrit ) *  statweight.crit )
	end
	
	if statweight.multistrike and statweight.multistrike > 0 and data.multistrike then		
		totalweght = totalweght + ( (data.multistrike + tempmultistrike ) *  statweight.multistrike )
	end
	
	if statweight.mastery and statweight.mastery > 0 and data.mastery then		
		totalweght = totalweght + ( (data.mastery  + tempmastery ) *  statweight.mastery )
	end
	
	if statweight.versatility and statweight.versatility > 0 and data.versatility then		
		totalweght = totalweght + ( (data.versatility + tempversatility ) * statweight.versatility )
	end
	
	if statweight.haste and statweight.haste > 0 and data.haste then		
		totalweght = totalweght + ( (data.haste + temphaste ) *  statweight.haste )
	end
	
	if statweight.spellpower and statweight.spellpower > 0 and data.spellpower then		
		totalweght = totalweght +  (data.spellpower * statweight.spellpower)
	end
	
	return totalweght
end

local function CoundGem(data, data2, statweight)

	if not data or not data2 or not statweight then return 0, 0 end
	
	local totalweght, tempcrit, tempmultistrike, tempmastery, tempversatility, temphaste = 0, 0, 0, 0, 0, 0
	local totalweght2, tempcrit2, tempmultistrike2, tempmastery2, tempversatility2, temphaste2 = 0, 0, 0, 0, 0, 0
	
	if data.gem then
		local value, typeStat
		
		if type(data.gem) == 'string' then
			value, typeStat = strsplit(':', data.gem)
			value = tonumber(value)	
		else
			typeStat = statweight.gemstat or statweight.maxStat
			value = statweight.gemvalue or GetMaxGem(typeStat)
		end
		
		if typeStat == 'CritRating' then
			tempcrit = value
		elseif typeStat == 'HasteRating' then
			temphaste = value
		elseif typeStat == 'MasteryRating' then
			tempmastery = value
		elseif typeStat == 'Multistrike' then
			tempmultistrike = value
		elseif typeStat == 'Versatility' then
			tempversatility = value
		end

	end

	if statweight.crit and statweight.crit > 0 then		
		totalweght = totalweght + ( statweight.crit * tempcrit ) 
	end	
	
	if statweight.multistrike and statweight.multistrike > 0 then		
		totalweght = totalweght + ( statweight.multistrike * tempmultistrike ) 
	end
	
	if statweight.mastery and statweight.mastery > 0 then		
		totalweght = totalweght + ( statweight.mastery * tempmastery )
	end	
	
	if statweight.versatility and statweight.versatility > 0 then		
		totalweght = totalweght + ( statweight.versatility * tempversatility )
	end	

	if statweight.haste and statweight.haste > 0 then		
		totalweght = totalweght + ( statweight.haste * temphaste )
	end

	if type(data2) == 'table' then
	
		if data2.gem then
			local value, typeStat
			
			if type(data2.gem) == 'string' then
				value, typeStat = strsplit(':', data2.gem)
				value = tonumber(value)	
			else
				typeStat = statweight.gemstat or statweight.maxStat				
				value = statweight.gemvalue or GetMaxGem(typeStat)
			end
			
			if typeStat == 'CritRating' then
				tempcrit2 = value
			elseif typeStat == 'HasteRating' then
				temphaste2 = value
			elseif typeStat == 'MasteryRating' then
				tempmastery2 = value
			elseif typeStat == 'Multistrike' then
				tempmultistrike2 = value
			elseif typeStat == 'Versatility' then
				tempversatility2 = value
			end
		end
		
		if statweight.crit and statweight.crit > 0 then		
			totalweght2 = totalweght2 + ( statweight.crit * tempcrit2 )
		end	
		if statweight.multistrike and statweight.multistrike > 0 then		
			totalweght2 = totalweght2 + ( statweight.multistrike * tempmultistrike2 )
		end
		if statweight.mastery and statweight.mastery > 0 then		
			totalweght2 = totalweght2 + ( statweight.mastery * tempmastery2 )
		end	
		if statweight.versatility and statweight.versatility > 0 then		
			totalweght2 = totalweght2 + ( statweight.versatility * tempversatility2 )
		end	
		if statweight.haste and statweight.haste > 0 then
			totalweght2 = totalweght2 + ( statweight.haste * temphaste2 )
		end
		
		if data2.gem and data2.gem == true and totalweght2 == 0 then
			totalweght2 = totalweght
		end
	
	end
	
	return totalweght, totalweght2
end

local selected_preset = nil
local selected_artifact = nil

local loadGem = 0

local hidegametooltip = CreateFrame("Frame")
hidegametooltip:Hide()
local gametooltip = CreateFrame("GameTooltip", "SPTimers_StatsWeight_GameToolTip", nil, "GameTooltipTemplate");
gametooltip:SetOwner( hidegametooltip,"ANCHOR_NONE");
	gametooltip:SetScript('OnTooltipAddMoney', function()end)
	gametooltip:SetScript('OnTooltipCleared', function()end)
	gametooltip:SetScript('OnHide', function()end)
	gametooltip:SetScript('OnTooltipSetDefaultAnchor',function()end)

local attepts = 3
local function GetGemData()
	local failed = false
	wipe(GemData)
	
	local gemList = UnitLevel('player') == 110 and Gem110 or Gem100
	
	for i=1, #gemList do
		local itemID, type, value = gemList[i][1], gemList[i][2], gemList[i][3]
	
		local name, link = GetItemInfo(itemID)

		if not name then
			failed = true
		elseif link then	
			gametooltip:SetHyperlink(link)				
			local left = _G[gametooltip:GetName().."TextLeft4"]:GetText()
			if left then
				GemData[#GemData+1] = { left, value, type }
			else
				failed = true
			end
		end
	end
	
	if failed then
		if attepts ~= 0 then
			attepts = attepts - 1
			C_Timer.After(1, GetGemData)
		end
	else
--		print('GetData Loaded in ', format('%.1fs', GetTime()-loadGem))
	end
end

function C:InitStatWeight()

	if IsAddOnLoaded('PriestStatWeights') then
			AleaUI_GUI.ShowPopUp(
			   "SPTimers", 
			   'PriestStatWeights is enabled. Delete addon or disable it.', 
			   { name = "Ok", OnClick = function() DisableAddOn('PriestStatWeights'); ReloadUI(); end}, 
			   { name = "Later", OnClick = function() end}		   
			)		
		return 
	end
	
	if not PSW_SVDB then 
		PSW_SVDB = {} 
	end
	
	db = PSW_SVDB
	
	if not db.presets then
		db.presets = statsWeight
	end
	
	for k,v in pairs(statsWeight) do
		if not db.presets[k] then
			db.presets[k] = v
		end
	end
	
	RefreshEnabledProfiles()
	
	C_Timer.After(0.5, function()
		if InCombatLockdown() then
			hidegametooltip:RegisterEvent('PLAYER_REGEN_ENABLED')
			hidegametooltip:SetScript('OnEvent', function()
				hidegametooltip:UnregisterAllEvents()
				loadGem = GetTime()
				attepts = 3
				C_Timer.After(0.3, GetGemData)
			end)
		else
			loadGem = GetTime()
			attepts = 3
			C_Timer.After(0.3, GetGemData)
		end
	end)

	db.totalpresets = db.totalpresets or 0
	
	local presets = {		
		name = "Stats Weight Presets",
		order = 1.1,
		expand = false,
		type = "group",
		args = {}
	}
	
	presets.args.DisableIt = {
		name = "Disable module",
		type = "toggle",
		order = 0.5,
		set = function()
			db.disabled = not db.disabled
			RefreshEnabledProfiles()
		end,
		get = function()
			return db.disabled
		end,	
	}
	
	--[==[
	presets.args.New = {		
		name = "",
		order = 1,
		embend = true,
		type = "group",
		args = {}
	}

	presets.args.New.args.CreateNew = {
		name = "Create New",
		type = "execute",
		order = 1,
		set = function()
			db.totalpresets = db.totalpresets + 1
			
			local named = "Preset #"..db.totalpresets
			
			db.presets[named] = {
				__enabled = true,
				__spec = 3,
				__name = named,
				intellect = 0,
				strength = 0,
				agility = 0, 
				crit = 0,
				haste = 0,
				multistrike = 0, 
				versatility =  0, 
				mastery = 0, 
				spellpower = 0, 			
			}
			
			selected_preset = named
			GetMaxPresetStat(named)
			RefreshEnabledProfiles()
		end,
		get = function()
			
		end,	
	}
	]==]
	
	presets.args.Select = {
		name = "Select",
		type = "dropdown",
		order = 0.6,
		values = function()	
			local t = {}
			
			t['.a1'] = '...New'
			
			for k, v in pairs(db.presets) do
				local class = v.__class and v.__class..' - ' or ''				
				t[k] = class..(v.__name or k)
			end

			return t
		end,
		set = function(info, value)		
			if value == '.a1' then
				db.totalpresets = db.totalpresets + 1
			
				local named = "Preset #"..db.totalpresets
				
				db.presets[named] = {
					__enabled = true,
					__spec = 3,
					__name = named,
					intellect = 0,
					strength = 0,
					agility = 0, 
					crit = 0,
					haste = 0,
					multistrike = 0, 
					versatility =  0, 
					mastery = 0, 
					spellpower = 0, 			
				}
				
				selected_preset = named
				GetMaxPresetStat(named)
				RefreshEnabledProfiles()
			else
				selected_preset = value
				GetMaxPresetStat(value)
				C.UpdateTraitList()
				RefreshEnabledProfiles()
			end
		end,
		get = function()
			return selected_preset
		end,	
	}
	
	
	presets.args.Tabs = {
		name = "Tabs",
		type = "tabgroup",
		width = 'full',
		order = 2,
		args = {}
	}
	
	presets.args.Tabs.args.General = {		
		name = "General",
		order = 1,
		embend = true,
		type = "group",
		args = {}
	}
	
	presets.args.Tabs.args.Edit = {		
		name = "Stats",
		order = 2,
		embend = true,
		type = "group",
		args = {}
	}
	
	presets.args.Tabs.args.Gens = {		
		name = "Gems",
		order = 3,
		embend = true,
		type = "group",
		args = {}
	}
	--[==[
	presets.args.Tabs.args.Relics = {		
		name = "Relics",
		order = 4,
		embend = true,
		type = "group",
		args = {}
	}
	]==]
	presets.args.Tabs.args.General.args.enable = {
		name = "Enable",
		type = "toggle",
		order = 1,
		width = 'full',
		set = function()
			if selected_preset then
				db.presets[selected_preset].__enabled = not db.presets[selected_preset].__enabled
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].__enabled
			end
			
			return false
		end,	
	}
	
	presets.args.Tabs.args.General.args.Classes = {
		name = "Classes",
		type = "dropdown",
		order = 1.1,
		values = function()
			local t = {}
			for k,v in pairs(classFilter) do
				t[k] = k
			end
			
			return t
		end,
		set = function(info, value)
			if selected_preset then
				db.presets[selected_preset].__class = value
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].__class
			end
		end,	
	}
	
	presets.args.Tabs.args.General.args.Build = {
		name = "Build",
		type = "dropdown",
		order = 1.2,
		values = buildFilter,
		set = function(info, value)
			if selected_preset then
				db.presets[selected_preset].__gameBuild = value
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].__gameBuild
			end
		end,	
	}
	
	presets.args.Tabs.args.General.args.Spec = {
		name = "Spec",
		type = "dropdown",
		order = 1.3,
		values = function()
			local t = {}
			t[ALL_FILTER] = 'All'
			for i=1, GetNumSpecializations() do
				local id, name, description, icon, background, role = GetSpecializationInfo(i)				
				local role = GetSpecializationRoleByID(id)
				
				if role then
					t[id] = name
				end
			end
			
			return t
		end,
		set = function(info, value)
			if selected_preset then
				db.presets[selected_preset].__spec = value
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].__spec
			end
		end,	
	}
	
	presets.args.Tabs.args.General.args.name = {
		name = "Name",
		type = "editbox",
		width = 'full',
		order = 2,
		set = function(info, value)
			if selected_preset then
				local temp = gsub(value, '||', '|')
				
				db.presets[selected_preset].__name = temp
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
			
				local temp = db.presets[selected_preset].__name
				
				if temp then
					temp = gsub(temp, '|', '||')
				end
				
				return temp or selected_preset
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Edit.args.intellect = {
		name = "Intellect",
		type = "editbox",
		order = 3,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].intellect = num
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].intellect
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Edit.args.agility = {
		name = "Agility",
		type = "editbox",
		order = 3,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].agility = num
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].agility
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Edit.args.strength = {
		name = "Strength",
		type = "editbox",
		order = 3,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].strength = num
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].strength
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Edit.args.crit = {
		name = "Crit",
		type = "editbox",
		order = 4,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].crit = num
					GetMaxPresetStat(selected_preset)
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].crit
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Edit.args.haste = {
		name = "Haste",
		type = "editbox",
		order = 5,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].haste = num
					GetMaxPresetStat(selected_preset)
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].haste
			end
			
			return ''
		end,	
	}
	--[==[
	presets.args.Edit.args.multistrike = {
		name = "Multistrike",
		type = "editbox",
		order = 6,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].multistrike = num
					GetMaxPresetStat(selected_preset)
				end
			end
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].multistrike
			end
			
			return ''
		end,	
	}
	]==]
	presets.args.Tabs.args.Edit.args.versatility = {
		name = "Versatility",
		type = "editbox",
		order = 7,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].versatility = num
					GetMaxPresetStat(selected_preset)
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].versatility
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Edit.args.mastery = {
		name = "Mastery",
		type = "editbox",
		order = 8,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].mastery = num
					GetMaxPresetStat(selected_preset)
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].mastery
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Edit.args.spellpower = {
		name = "SpellPower",
		type = "editbox",
		order = 9,
		set = function(info, value)
			if selected_preset then
				local num = tonumber(value)
				if num then
					db.presets[selected_preset].spellpower = num
				end
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].spellpower
			end
			
			return ''
		end,	
	}
	
	presets.args.Tabs.args.Gens.args.value = {	
		name = "Value",
		type = "dropdown",
		order = 1,
		values = function()
			if UnitLevel('player') == 110 then
	
				local gemstat = ''
				
				if selected_preset then
					gemstat = db.presets[selected_preset].gemstat or db.presets[selected_preset].maxStat
				end
				
				if gemstat == 'Intellect' or gemstat == 'Agility' or gemstat == 'Strength' then
					return {
						[200] = '+200',
					}
				else
					return {
						[100] = '+100',
						[150] = '+150',
						[200] = '+200',
					}
				end
			end
			
			return {
					[35] = '+35',
					[50] = '+50',
					[75] = '+75',
				}
		end,
		set = function(info, value)
			if selected_preset then
				db.presets[selected_preset].gemvalue = tonumber(value)
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then			
				local typeStat = db.presets[selected_preset].gemstat or db.presets[selected_preset].maxStat
			
				return db.presets[selected_preset].gemvalue or GetMaxGem(typeStat)
			end
			return UnitLevel('player') == 110 and 200 or 75
		end,
	}
	
	presets.args.Tabs.args.Gens.args.stat = {	
		name = "Stat",
		type = "dropdown",
		order = 2,
		values = {
			["CritRating"] = "CritRating",
			["HasteRating"] = "HasteRating",
			["MasteryRating"] = "MasteryRating",
			["Multistrike"] = "Multistrike",
			["Versatility"] = "Versatility",
			["Stamina"] = "Stamina",
			['Intellect'] = 'Intellect',
			['Agility'] = 'Agility',
			['Strength'] = 'Strength',
		},
		set = function(info, value)
			if selected_preset then
				db.presets[selected_preset].gemstat = value
			end
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].gemstat or db.presets[selected_preset].maxStat
			end
			return ''
		end,
	}
	
	local prevListNumber = -1
	local function UpdateTraitList()
		local list
		
		if selected_preset then
			if db.presets[selected_preset].selected_artifact and db.presets[selected_preset].selected_artifact ~= 1 then
				if db.artifactTraits[C.myCLASS][db.presets[selected_preset].selected_artifact] then
					list = {}
					
					for powerID, spellID in pairs(db.artifactTraits[C.myCLASS][db.presets[selected_preset].selected_artifact]) do
					
						local name = GetSpellInfo(spellID)  or "Invalid"
			
						local fakeIcon, realIcon = GetSpellTexture(spellID)
						
						local icon = realIcon or fakeIcon or "Interface\\ICONS\\Inv_misc_questionmark"
			
						list[spellID] = "\124T"..icon..":14\124t "..name
					end
				end
			end
		end
			
		if list then
			local number = 0
		
			presets.args.Tabs.args.Relics.args['trait'..number] = {
				name = '+1 ILvL',
				order = 2,
				type = 'editbox',
				width = 'full',
				set = function(info, value)
				--	print('Set', value, '+1 ILvL', tonumber(value))
					if selected_preset then
						db.presets[selected_preset].ilvl = tonumber(value)
					end
				end,
				get = function()
					if selected_preset then
						return db.presets[selected_preset].ilvl
					end
					return ''
				end
			
			}
				
				
			for k,v in pairs(list) do
				number = number + 1
				
				
				presets.args.Tabs.args.Relics.args['trait'..number] = {
					name = v,
					order = 2+number,
					desc = GetSpellDescription(k),
					type = 'editbox',
					width = 'full',
					set = function(info, value)
					--	print('Set', value, k)
						if selected_preset then
							db.presets[selected_preset].powerBonus[k] = tonumber(value)
						end
					end,
					get = function()
						if selected_preset then
							return db.presets[selected_preset].powerBonus[k]
						end
						return ''
					end
				
				}
			end
			
			prevListNumber = number
		else
			for i=1,prevListNumber do				
				presets.args.Tabs.args.Relics.args['trait'..i] = nil
			end
		end
	end
	
	C.UpdateTraitList = UpdateTraitList
	--[==[
	presets.args.Tabs.args.Relics.args.Trait = {	
		name = "Artifact",
		type = "dropdown",
		order = 1,
		width = 'full',
		values = function()
			local t = {}
			
			if selected_preset then
				
				t[1] = 'None'
				
				if db.artifactTraits and db.artifactTraits[C.myCLASS] then
					for itemID in pairs(db.artifactTraits[C.myCLASS]) do					
						if GetItemInfo(itemID) then
							t[itemID] = GetItemInfo(itemID)
						else
							t[itemID] = 'itemID:'..itemID
						end				
					end
				end
			end
			
			return t
		end,
		set = function(info, value)
			if selected_preset then
				db.presets[selected_preset].selected_artifact = value			
			end
			
			UpdateTraitList()
			RefreshEnabledProfiles()
		end,
		get = function()
			if selected_preset then
				return db.presets[selected_preset].selected_artifact
			end
			return 1
		end,
	}
	]==]
	
	presets.args.delete = {
		name = "Delete",
		type = "execute",
		order = -1,
		set = function()
			if selected_preset then
				db.presets[selected_preset] = nil
				selected_preset = nil
				selected_artifact = nil
			end
			RefreshEnabledProfiles()
			UpdateTraitList()
		end,
		get = function()
			
		end,	
	}
	
	return presets
end

local function GetExistedLine(self, name)
	for i=self:NumLines(), 1, -1 do        
		
		local left = _G[self:GetName().."TextLeft"..i]:GetText()
		
	--	print('T', left == name, string.match(left, '^'..name))
		
		if left and match(left, '^'..name) then
			return i
		end
	end
	
	return false
end
--[[
function C:PLAYER_ENTERING_WORLD()

end

function C:UNIT_INVENTORY_CHANGED()

end

function C:UPDATE_INVENTORY_DURABILITY()

end

function C:PLAYER_EQUPMENT_CHANGED()

end

function C:MODIFIER_STATE_CHANGED()end
]]
local function SkipText(text)
	
	if not text then
		return false
	end
	
	if find(text, ITEM_SPELL_TRIGGER_ONEQUIP) then
		return false
	elseif find(text, ITEM_SPELL_TRIGGER_ONUSE) then
		return false
	end

	
	return true
end

local curItemStats = {}
local itemStatsSort = {}
local curstats = {}
itemStatsSort[1] = ITEM_MOD_INTELLECT_SHORT
itemStatsSort[2] = ITEM_MOD_STAMINA_SHORT
itemStatsSort[3] = ITEM_MOD_CRIT_RATING_SHORT
itemStatsSort[4] = ITEM_MOD_CR_MULTISTRIKE_SHORT
itemStatsSort[5] = ITEM_MOD_VERSATILITY
itemStatsSort[6] = ITEM_MOD_HASTE_RATING_SHORT
itemStatsSort[7] = ITEM_MOD_MASTERY_RATING_SHORT
itemStatsSort[8] = ITEM_MOD_SPELL_POWER_SHORT
itemStatsSort[11] = ITEM_MOD_SPIRIT_SHORT

local function GetNumberValue(str, pattern)
	local value = match(str, pattern)
	
	if value then
		value = tonumber((value:gsub(',', ''):gsub(' ', '')))
	--	value = tonumber((value:gsub(' ', '')))
	end
	
	return value
end

local linkTypeItems = {	
	['INVTYPE_HEAD']         = { skipMainStat = false, slot = { 1 }, }, -- голова
	['INVTYPE_NECK']         = { skipMainStat = true, slot = { 2 }, },  -- нека
	['INVTYPE_SHOULDER']     = { skipMainStat = false, slot = { 3 }, },  -- плечи
	['INVTYPE_CLOAK']        = { skipMainStat = false, slot = { 15 }, },  -- плащик
	['INVTYPE_ROBE']         = { skipMainStat = false, slot = { 5 }, },  -- грудак
	['INVTYPE_CHEST']		 = { skipMainStat = false, slot = { 5 }, }, -- грудак без платья
	['INVTYPE_BODY']         = { skipMainStat = false, slot = { 4 }, },  -- рубашка
	['INVTYPE_WRIST']        = { skipMainStat = false, slot = { 9 }, },  -- запястие
	['INVTYPE_HAND']         = { skipMainStat = false, slot = { 10 }, },  -- руки
	['INVTYPE_WAIST']        = { skipMainStat = false, slot = { 6 }, },  -- пояс
	['INVTYPE_LEGS']         = { skipMainStat = false, slot = { 7 }, }, -- ноги
	['INVTYPE_FEET']         = { skipMainStat = false, slot = { 8 }, },  -- тапки
	['INVTYPE_FINGER']       = { skipMainStat = true, slot = { 11, 12 }, },  -- кольцо
	['INVTYPE_TRINKET']      = { skipMainStat = true, slot = { 13, 14 }, },  -- тринка
	['INVTYPE_2HWEAPON']     = { skipMainStat = false, slot = { 16, 17 }, }, -- палка
	['INVTYPE_RANGED']       = { skipMainStat = false, slot = { 16, 17 }, }, -- лук
	['INVTYPE_WEAPON']       = { skipMainStat = false, slot = { 16, 17 }, }, -- одноручка
	['INVTYPE_RANGEDRIGHT']  = { skipMainStat = false, slot = { 16, 17 }, }, -- ванда
	['INVTYPE_SHIELD']       = { skipMainStat = false, slot = { 16, 17 }, }, -- щит
	['INVTYPE_HOLDABLE']	 = { skipMainStat = false, slot = { 16, 17 }, }, -- оффхенд
}
	
local function EnabledShowItemStats(link)
	if link then
		local _, _, _, _, _, class, subclass, _, equipSlot = GetItemInfo(link)
		
		if equipSlot and linkTypeItems[equipSlot] then
		
			return true, linkTypeItems[equipSlot].skipMainStat
		end
	
	end
	
	return false
end

local function FilterByMainStat(int, agi, str)
	return not int and not agi and not str
end

local ItemStatsCache = {}

local function GetItemStats_Custom(self)
	local intellect, stamina, crit, multistrike, versatility, haste, mastery, spellpower, strength, agility, spirit, extraarmor, gem
	
	if useBlizzardAPI then
		wipe(curItemStats)
		wipe(curstats)
		local _name, _link = self:GetItem()
		GetItemStats(_link, curstats)
		
		for stat, value in pairs(curstats) do 
			curItemStats[stat] = tonumber(value)
		end
		
		local gem = false
		if curstats['EMPTY_SOCKET_PRISMATIC'] and curstats['EMPTY_SOCKET_PRISMATIC'] == 1 then
			gem = true
		end
		
		
		intellect	= tonumber(curItemStats[ITEM_MOD_INTELLECT_SHORT] )
		stamina 	= tonumber(curItemStats[ITEM_MOD_STAMINA_SHORT] )
		crit		= tonumber(curItemStats[ITEM_MOD_CRIT_RATING_SHORT] )
		multistrike	= nil
		versatility	= tonumber(curItemStats[ITEM_MOD_VERSATILITY] )
		haste		= tonumber(curItemStats[ITEM_MOD_HASTE_RATING_SHORT] )
		mastery		= tonumber(curItemStats[ITEM_MOD_MASTERY_RATING_SHORT] )
		spellpower	= tonumber(curItemStats[ITEM_MOD_SPELL_POWER_SHORT] )
		strength	= tonumber(curItemStats[ITEM_MOD_STRENGTH_SHORT] )
		agility		= tonumber(curItemStats[ITEM_MOD_AGILITY_SHORT] )
		spirit		= tonumber(curItemStats[ITEM_MOD_SPIRIT_SHORT] )
		extraarmor	= nil
		
		for i=1, self:NumLines() do        
			local left = _G[self:GetName().."TextLeft"..i]:GetText()
			if gem == true then			
				for i=1, #GemData do
					local _text, value, sttype =  GemData[i][1],GemData[i][2],GemData[i][3]				
					if left and find(left, _text) then
						gem = format('%d:%s', value, sttype)
						break
					end
				end
			else
				break
			end
		end	

		return intellect, stamina, crit, multistrike, versatility, haste, mastery, spellpower, strength, agility, spirit, extraarmor, gem
	else
	
		wipe(curstats)
		local _name, _link = self:GetItem()
	
		GetItemStats(_link, curstats)
		local gem = false
		if curstats['EMPTY_SOCKET_PRISMATIC'] and curstats['EMPTY_SOCKET_PRISMATIC'] == 1 then
			gem = true
		end
		
		for i=1, self:NumLines() do        
			local left = _G[self:GetName().."TextLeft"..i]:GetText()
			if gem == true then			
				for i=1, #GemData do
					local _text, value, sttype =  GemData[i][1],GemData[i][2],GemData[i][3]				
					if left and find(left, _text) then
						gem = format('%d:%s', value, sttype)
						break
					end
				end
			end
			
			if left ~= '' and SkipText(left) then

				intellect	= tonumber(intellect or GetNumberValue(left, PATTERN_INTELLECT))
				stamina 	= tonumber(stamina or GetNumberValue(left,  PATTERN_STAMINA) )
				crit		= tonumber(crit or GetNumberValue(left,   PATTERN_CRIT))
				multistrike	= nil --tonumber(multistrike or match(left,  PATTERN_MULTISTRIKE) )
				versatility	= tonumber(versatility or GetNumberValue(left,  PATTERN_VERSATILITY))
				haste		= tonumber(haste or GetNumberValue(left,  PATTERN_HASTE))
				mastery		= tonumber(mastery or GetNumberValue(left,  PATTERN_MASTERY))
				spellpower	= tonumber(spellpower or GetNumberValue(left,  PATTERN_SPELLPOWER))
				strength	= tonumber(strength or GetNumberValue(left,  PATTERN_STRENGTH))
 				agility		= tonumber(agility or GetNumberValue(left,  PATTERN_AGILITY))
				spirit		= tonumber(spirit or GetNumberValue(left,  PATTERN_SPIRIT))
				extraarmor	= tonumber(extraarmor or GetNumberValue(left,  PATTERN_EXTRAARMOR))
			end
		end
		
		return intellect, stamina, crit, multistrike, versatility, haste, mastery, spellpower, strength, agility, spirit, extraarmor, gem
	end
end

local function GetPersentage(v1, v2)

	if v1 > 0 and v2 > 0 then
		local dims2 = abs(( v1*100/v2 ) - 100)
		
		if v1 < v2 then
			return format("|cFF00FF00+%d%%", ceil(dims2))
		elseif v2 < v1 then
			return format("|cFFFF0000-%d%%", ceil(dims2))	
		else
			return format("|cFFFFFFFF+%d%%", 0)	
		end	
	
	elseif v1 > 0 then
		return format("|cFFFF0000-%d%%", ceil(v1))
	elseif v2 > 0 then
		return format("|cFF00FF00+%d%%", ceil(v2))
	else
		return ''
	end
end

local function GetCurValue(value, gem)	
	local strval = (ceil(value+gem))..' |cFF808080('..ceil(value)..')|r'

	return strval
end

local function attachItemTooltip(self)
	if db.disabled or disableModule then return end
	
	local myItem = self:IsEquippedItem()
	local owner = self:GetName()
	local _name, _link = self:GetItem()
	
	
	if _link then		
		if IsArtifactRelicItem(_link) then
			C:GetRelicInfo(self)
			return
		end
	else
		return
	end
	
	local show, skipMainStat = EnabledShowItemStats(_link)
	if not show then return end
	
	local intellect, stamina, crit, multistrike, versatility, haste, mastery, spellpower, strength, agility, spirit, extraarmor, gem = GetItemStats_Custom(self)

	if not CompareItem[owner] then
		CompareItem[owner] = {}
	end
	
	CompareItem[owner].intellect = intellect
	CompareItem[owner].stamina = stamina
	CompareItem[owner].crit = crit
	CompareItem[owner].multistrike = multistrike
	CompareItem[owner].versatility = versatility
	CompareItem[owner].haste = haste
	CompareItem[owner].mastery = mastery
	CompareItem[owner].spellpower = spellpower
	CompareItem[owner].strength = strength
	CompareItem[owner].agility = agility
	CompareItem[owner].spirit = spirit
	CompareItem[owner].extraarmor = extraarmor
	CompareItem[owner].gem = gem
	
	if not skipMainStat and FilterByMainStat(intellect, agility, strength) then return end
	
	local firstLine = true
	
	for name in pairs(enabledProfiles) do
		local statname = name
		local statdata = db.presets[name]
		local current = CreateString(CompareItem[owner], statdata)
		local gem1 = CoundGem(CompareItem[owner], true, statdata)

		if firstLine then
			firstLine = false			
			self:AddLine(' ')
		end
		
		self:AddDoubleLine(( statdata.__name or statname)..":", GetCurValue(current, gem1), 1, 1, 1, 1, 1, 1, 1, 1)
	end
	
	if not firstLine then
		self:AddLine(' ')
	end
end

local function MouseoverItemTooltip(self)
	if db.disabled or disableModule then return end
	
	local myItem = self:IsEquippedItem()
	local owner = self:GetName()
	
	local _name, _link = self:GetItem()
	
	if _link then		
		if IsArtifactRelicItem(_link) then
			C:GetRelicInfo(self)
			return
		end
	else
		return
	end
	
	local show, skipMainStat = EnabledShowItemStats(_link)
	if not show then return end
	
	local intellect, stamina, crit, multistrike, versatility, haste, mastery, spellpower, strength, agility, spirit, extraarmor, gem = GetItemStats_Custom(self)

	if not CompareItem[owner] then
		CompareItem[owner] = {}
	end
	
	CompareItem[owner].intellect = intellect
	CompareItem[owner].stamina = stamina
	CompareItem[owner].crit = crit
	CompareItem[owner].multistrike = multistrike
	CompareItem[owner].versatility = versatility
	CompareItem[owner].haste = haste
	CompareItem[owner].mastery = mastery
	CompareItem[owner].spellpower = spellpower
	CompareItem[owner].strength = strength
	CompareItem[owner].agility = agility
	CompareItem[owner].spirit = spirit
	CompareItem[owner].extraarmor = extraarmor
	CompareItem[owner].gem = gem
	
	if not skipMainStat and FilterByMainStat(intellect, agility, strength) then return end
	
	if _G['ItemRefTooltip'] and _G['ItemRefTooltip']:IsShown() and CompareItem['ItemRefTooltip'] then
		local firstLine = true
		
		for name in pairs(enabledProfiles) do		
			local statname = name
			local statdata = db.presets[name]
			
			local current = CreateString(CompareItem['ItemRefTooltip'], statdata)
			local myReal = CreateString(CompareItem[owner], statdata)
			
			local gem1, gem2 = CoundGem(CompareItem['ItemRefTooltip'], CompareItem[owner], statdata)

			local dimsstr = GetPersentage((current + gem1), (myReal + gem2))

			local existedLine =  GetExistedLine(self, ( statdata.__name or statname))

			if existedLine then
				_G[owner.."TextLeft"..existedLine]:SetText((statdata.__name or statname)..":")
				_G[owner.."TextLeft"..existedLine]:SetTextColor(1,1,1,1)
				_G[owner.."TextRight"..existedLine]:SetText(format("%s%s", GetCurValue(myReal, gem2), dimsstr))
				_G[owner.."TextRight"..existedLine]:SetTextColor(1,1,1,1)		
			else
				if firstLine then
					firstLine = false					
					self:AddLine(' ')
				end
			
				self:AddDoubleLine(( statdata.__name or statname)..":", format("%s%s", GetCurValue(myReal, gem2), dimsstr), 1, 1, 1, 1, 1, 1, 1, 1)	
			end
		end
		
		if not firstLine then
			self:AddLine(' ')
		end
	
	else	
		local firstLine = true
		
		for name in pairs(enabledProfiles) do		
			local statname = name
			local statdata = db.presets[name]
			local current = CreateString(CompareItem[owner], statdata)
			local gem1 = CoundGem(CompareItem[owner], true, statdata)

			if firstLine then
				firstLine = false				
				self:AddLine(' ')
			end
			
			self:AddDoubleLine(( statdata.__name or statname)..":", GetCurValue(current, gem1), 1, 1, 1, 1, 1, 1, 1, 1)
		end
		
		if not firstLine then
			self:AddLine(' ')
		end
	end
end

local function CompareItemTooltip(self, source)
	if db.disabled or disableModule then return end
	
	local myItem = self:IsEquippedItem()
	local owner = self:GetName()

	local _name, _link = self:GetItem()
	
	if _link then		
		if IsArtifactRelicItem(_link) then
			C:GetRelicInfo(self, source)
			return
		end
	else
		return
	end
	
	local show, skipMainStat = EnabledShowItemStats(_link)
	if not show then return end
	
	local intellect, stamina, crit, multistrike, versatility, haste, mastery, spellpower, strength, agility, spirit, extraarmor, gem = GetItemStats_Custom(self)

	if not CompareItem[owner] then
		CompareItem[owner] = {}
	end
	
	CompareItem[owner].intellect = intellect
	CompareItem[owner].stamina = stamina
	CompareItem[owner].crit = crit
	CompareItem[owner].multistrike = multistrike
	CompareItem[owner].versatility = versatility
	CompareItem[owner].haste = haste
	CompareItem[owner].mastery = mastery
	CompareItem[owner].spellpower = spellpower
	CompareItem[owner].strength = strength
	CompareItem[owner].agility = agility
	CompareItem[owner].spirit = spirit
	CompareItem[owner].extraarmor = extraarmor
	CompareItem[owner].gem = gem
	
	if not skipMainStat and FilterByMainStat(intellect, agility, strength) then return end
	
	local firstLine = true
	
	for name in pairs(enabledProfiles) do		
		local statname = name
		local statdata = db.presets[name]
		
		local current = CreateString(CompareItem[source], statdata)
		local myReal = CreateString(CompareItem[owner], statdata)	
	
		local gem1, gem2 = CoundGem(CompareItem[source], CompareItem[owner], statdata)	

		local dimsstr = GetPersentage((current + gem1), (myReal + gem2))

		local existedLine =  GetExistedLine(self, ( statdata.__name or statname))

		if existedLine then
			_G[owner.."TextLeft"..existedLine]:SetText((statdata.__name or statname)..":")
			_G[owner.."TextLeft"..existedLine]:SetTextColor(1,1,1,1)
			_G[owner.."TextRight"..existedLine]:SetText(format("%s%s", GetCurValue(myReal, gem2), dimsstr))
			_G[owner.."TextRight"..existedLine]:SetTextColor(1,1,1,1)
		else
			if firstLine then
				firstLine = false
				
				self:AddLine(' ')
			end
			
			self:AddDoubleLine(( statdata.__name or statname)..":", format("%s%s", GetCurValue(myReal, gem2), dimsstr), 1, 1, 1, 1, 1, 1, 1, 1)	
		end
	end
	
	if not firstLine then
		self:AddLine(' ')
	end
end

GameTooltip:HookScript("OnTooltipSetItem", MouseoverItemTooltip)
WorldMapTooltipTooltip:HookScript("OnTooltipSetItem", MouseoverItemTooltip)

local function ShoppingTooltipHandler(self)
	if db.disabled or disableModule then return end
	
	if _G[self:GetName()]:IsShown() then
		local source = 'GameTooltip'
		
		if self == WorldMapCompareTooltip1 or
			self == WorldMapCompareTooltip2 then
			
			source = 'WorldMapTooltipTooltip'
		end
		
		CompareItemTooltip(self, source)
	end
end

ShoppingTooltip1:HookScript("OnTooltipSetItem", ShoppingTooltipHandler)
ShoppingTooltip2:HookScript("OnTooltipSetItem", ShoppingTooltipHandler)

WorldMapCompareTooltip1:HookScript("OnTooltipSetItem", ShoppingTooltipHandler)
WorldMapCompareTooltip2:HookScript("OnTooltipSetItem", ShoppingTooltipHandler)

--[==[
hooksecurefunc('GameTooltip_ShowCompareItem', function(self, anchorFrame)
	local shoppingTooltip1, shoppingTooltip2 = unpack(self.shoppingTooltips);
	
	print(self:GetName())
	print(shoppingTooltip1:GetName(), shoppingTooltip2:GetName())
	print(self:GetItem())
	print(shoppingTooltip1:GetItem())
	print(shoppingTooltip2:GetItem())

end)
]==]

ItemRefTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)



-- Artifact parses
do
	-- Artifact Parser
	local function PrepareForScan()
		local ArtifactFrame = _G.ArtifactFrame
		
		if not ArtifactFrame or not ArtifactFrame:IsShown() then
	--		print('PrepareForScan', 'Success')
			
			_G.UIParent:UnregisterEvent("ARTIFACT_UPDATE")
			if ArtifactFrame then
				ArtifactFrame:UnregisterEvent("ARTIFACT_UPDATE")
			end
		end
	end

	local function RestoreStateAfterScan()
		local ArtifactFrame = _G.ArtifactFrame
			
		if not ArtifactFrame or not ArtifactFrame:IsShown() then
			C_ArtifactUI.Clear()
			
	--		print('RestoreStateAfterScan', 'Success')
			
			if ArtifactFrame then
				ArtifactFrame:RegisterEvent("ARTIFACT_UPDATE")
			end
			_G.UIParent:RegisterEvent("ARTIFACT_UPDATE")
		end
	end

	local lastUpdate = -1
	local init = true
	local initUpdate = true

		
	function C:ResetArifactPercInfo()
		lastUpdate = -1
	end
	
	function C:GetAtrifactPercInfo()
		initUpdate = true
		
		if not HasArtifactEquipped() then		
			lastUpdate = -1			
			return false
		end
		
		if init or lastUpdate < GetTime() then
			lastUpdate = GetTime() + 2
			init = false

			PrepareForScan()
			SocketInventoryItem(INVSLOT_MAINHAND)
			
			local powers = C_ArtifactUI.GetPowers();
			local itemID = C_ArtifactUI.GetEquippedArtifactInfo();
			
		--	print('T', powers)
			
			if powers then
				
				if not db.artifactTraits then db.artifactTraits = {} end
				if not db.artifactTraits[C.myCLASS] then db.artifactTraits[C.myCLASS] = {} end
				if itemID and 
					not db.artifactTraits[C.myCLASS][itemID] then
						db.artifactTraits[C.myCLASS][itemID] = {}
				end
				
				
				for i, powerID in ipairs(powers) do
					--[==[
						self.powerID = powerID;
						self.spellID = powerInfo.spellID;
						self.currentRank = powerInfo.currentRank;
						self.bonusRanks = powerInfo.bonusRanks;
						self.maxRank = powerInfo.maxRank;
						self.isStart = powerInfo.isStart;
						self.isGoldMedal = powerInfo.isGoldMedal;
						self.isFinal = powerInfo.isFinal;
						self.tier = powerInfo.tier;
						self.textureKit = textureKit;
						self.linearIndex = powerInfo.linearIndex;
						self.numMaxRankBonusFromTier = powerInfo.numMaxRankBonusFromTier	
					]==]
					
					local powerInfo = C_ArtifactUI.GetPowerInfo(powerID);
					
					local spellID, cost, currentRank, maxRank, bonusRanks
					
					if powerInfo and type(powerInfo) == 'table' then
						spellID = powerInfo.spellID;
						maxRank = powerInfo.maxRank;
					else
						spellID, cost, currentRank, maxRank, bonusRanks = C_ArtifactUI.GetPowerInfo(powerID);	
					end
				
					if maxRank and maxRank > 1 and maxRank < 7 then
						db.artifactTraits[C.myCLASS][itemID][powerID] = spellID
					end
				end
			end
			
			RestoreStateAfterScan()
		end
	end
	
	local function CTimer_AfterUpdate()
		C:GetAtrifactPercInfo()
	end
	
	local eventframe = CreateFrame("Frame")
	eventframe:SetScript("OnEvent", function(self, event, unit)
		if event == 'ARTIFACT_UPDATE' then
			if not unit then
				if initUpdate then
					initUpdate = false
					C_Timer.After(0.5, CTimer_AfterUpdate)
				end
			end
		else
			if initUpdate then
				initUpdate = false
				C_Timer.After(0.5, CTimer_AfterUpdate)
			end
		end
	end)
	--[==[
	eventframe:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	eventframe:RegisterEvent("PLAYER_TALENT_UPDATE")
	eventframe:RegisterEvent("PLAYER_LEVEL_UP")
	eventframe:RegisterEvent("PLAYER_LOGIN")
	eventframe:RegisterEvent("ARTIFACT_CLOSE")
	eventframe:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	]==]
end

-- Relic parser

local PATTERN_RELIC_ILVL = "(%d+%,?%.?%d*) "..RELIC_ITEM_LEVEL_INCREASE..'$'
local RelicCompareOwner = {}

local function CreateRelicString(data, statweight)
	
	local totalweght = 0
	
	if not data or not statweight then return 0 end

	if statweight.ilvl and statweight.ilvl > 0 and data.ilvl then		
		totalweght = totalweght + ( data.ilvl * statweight.ilvl )
	end
	
	if data.powerBonus and statweight.powerBonus[data.powerBonus] and statweight.powerBonus[data.powerBonus] > 0 then
		totalweght = totalweght + statweight.powerBonus[data.powerBonus]
	end
	
	return totalweght
end

function C:GetRelicInfo(self, source)
	if true then return end
	
	local ilvl
	local powerBonus
	local itemID = C_ArtifactUI.GetArtifactInfo() or C_ArtifactUI.GetEquippedArtifactInfo()
	local owner = self:GetName()
	local _name, _link = self:GetItem()
	
	if not RelicCompareOwner[owner] then
		RelicCompareOwner[owner] = {}
	end
	
	local needUpdate = false
	
	if RelicCompareOwner[owner].link ~= _link then		
		RelicCompareOwner[owner].link = _link
		
		needUpdate = true
		
		for i=1, self:NumLines() do        
			local left = _G[self:GetName().."TextLeft"..i]:GetText()
			
			if left then
			
				if not ilvl then
					ilvl = string.match(left, PATTERN_RELIC_ILVL)
				end
				if not powerBonus and itemID and db.artifactTraits[C.myCLASS][itemID] then
					for powerID, spellID in pairs(db.artifactTraits[C.myCLASS][itemID]) do
						if string.match(left, (GetSpellInfo(spellID))) then
							powerBonus = spellID
							break
						end
					end
				end
			end
			
			if ilvl and powerBonus then
				break
			end
		end
		
		RelicCompareOwner[owner].ilvl = ilvl and tonumber(ilvl) or nil
		RelicCompareOwner[owner].powerBonus = powerBonus and tonumber(powerBonus) or nil
	
	end
	
--	if not needUpdate then return end
	
	local firstLine = true

	local compareData = (  source and RelicCompareOwner[source] ) or ( _G['ItemRefTooltip'] and _G['ItemRefTooltip']:IsShown() and RelicCompareOwner['ItemRefTooltip'] ) or nil
	
--	print(owner, compareData)
	
	for name in pairs(enabledProfiles) do
		local statname = name
		local statdata = db.presets[name]
		
		if statdata.selected_artifact and statdata.selected_artifact ~= 1 then
			
			local current = compareData and CreateRelicString(compareData, statdata) or 0
			local myReal = CreateRelicString(RelicCompareOwner[owner], statdata)	

			local dimsstr = GetPersentage(current, myReal)
			
			local easy = true
			
			if compareData and compareData ~= RelicCompareOwner[owner] then
				easy = false
			end
			
			local dark = true 
			
			if statdata.selected_artifact and itemID == statdata.selected_artifact then
				dark = false
			end
			
			local existedLine --=  GetExistedLine(self, ( statdata.__name or statname))

			if existedLine then
				_G[owner.."TextLeft"..existedLine]:SetText((statdata.__name or statname)..":")
				_G[owner.."TextLeft"..existedLine]:SetTextColor(1,1,1,1)
				_G[owner.."TextRight"..existedLine]:SetText(format(((dark and '|cFF808080' or '|cFFFFFFFF' )..(easy and '%s|r' or '%s|r%s')), tostring(myReal), tostring(dimsstr) ))
				_G[owner.."TextRight"..existedLine]:SetTextColor(1,1,1,1)
			else
				if firstLine then
					firstLine = false
					
					self:AddLine(' ')
				end
				
				self:AddDoubleLine(( statdata.__name or statname)..":", format(((dark and '|cFF808080' or '|cFFFFFFFF' )..(easy and '%s|r' or '%s|r%s')), tostring(myReal), tostring(dimsstr)), 1, 1, 1, 1, 1, 1, 1, 1)	
			end
			
			
			if firstLine then
				firstLine = false	
				self:AddLine(' ')
			end

		--	self:AddDoubleLine('This is relic item with '..tostring(ilvl)..', '..tostring(powerBonus)..', '..tostring(easy))
		end
	end
	
	if not firstLine then
		self:AddLine(' ')
	end
end
