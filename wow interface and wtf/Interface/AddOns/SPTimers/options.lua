local addon, C = ...
local L = AleaUI_GUI.GetLocale("SPTimers")

--GLOBALS: AleaUI_GUI, NO, STANDARD_TEXT_FONT, APPLY, ALEAUI_NewDB, ALEAUI_GetProfileOptions

local ipairs = ipairs
local pairs = pairs
local GetSpellInfo = GetSpellInfo
local GetItemInfo = GetItemInfo
local tonumber = tonumber
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local tostring = tostring
local wipe = table.wipe
local GetTime = GetTime
local type = type
local strsplit = strsplit
local GetSpellTexture = GetSpellTexture
local format = string.format
local UnitClass = UnitClass
local find = string.find
local match = string.match
local setmetatable = setmetatable
local getmetatable = getmetatable
local tsort = table.sort

local LSM = C.LSM
local o
local anchor_value = nil
local class_select = nil
local proc_select = nil
local others_select = nil
local cooldown_select = nil
local ICD_select = nil
local blocklist_select = nil
local unit_filter_set = nil
local unit_per_achor_choose = nil
local bar_cooldown_select = nil
local AuraCD_select = nil

local old_print = print
local print = function(...)
	if C.dodebugging then	
		old_print(GetTime(), "SPTimers_Options, ", ...)
	end
end

local message = C.message

local justifu = {
	["RIGHT"] = "RIGHT",
	["CENTER"] = "CENTER",
	["LEFT"] = "LEFT",
}

local text_flaggs = {
	[""] = NO,
	["OUTLINE"] = "OUTLINE",
	["THICKOUTLINE"] = "THICKOUTLINE",
	["MONOCHROMEOUTLINE"] = "MONOCHROMEOUTLINE",
--	["Shadow"] = 'Shadow',
}

local filters = {
	L["None"],
	L["Only buff"],
	L["Only debuff"],
	L["All"],
}

local filters_cleu = {
	L["None"],
	L["Only buff"],
	L["Only debuff"],
	L["All"],
	L["SpellCast"],
	L["Summon"],
	L["Energize"],
}

local affiliation = {
	L["Any"],
	L["player"],
	L["raid"],
	L["party"],
	L["pet"],
}

local targetType = {
	L["single"],
	L["multi"],
	L["auto"],
}

local groupSorting = {
	["player"] = "player",
	["procs"]  = "procs",
	["auto"]   = "auto",
	["target"] = "target",
}

local AuraCooldownType = {
	L["Any"],
	L["Buff"],
	L["Debuff"],	
}
					
local bar_timer_format = {
	"1h,2m,119s,29.9",
	"1h,2m,119s/300,29.99/300",
	"1:11m,59s,10s,1s",
	"1:11m,59.1s,10.2s,1.1s",
	"1,2,119,29.9",
	"1,2,119/300,29.99/300",
	"1:11,59,10,1",
	"1:11,59.1,10.2,1.1",
}

local cooldown_timer_format = {
	"1h,2m,119s,29.9",
	"1:11m,59s,10s,1s",
	"1:11m,59.1s,10.2s,1.1s",
	"1 ,2 ,119,29.9",
	"1:11,59,10,1",
	"1:11,59.1,10.2,1.1",
}

local sorting_timer_table = {
	L["priority from lower to upper"],
	L["endtime from upper to lower"],
	L["endtime from lower to upper"],
}

local function GetSpellOrItemID(val, tip)
	local id, ctip = nil, nil
	if type(val) == "string" and not tonumber(val) then
		

		local found, _, spellString = find(val, "^|c%x+|H(.+)|h%[.*%]")
		
		if found then
		
			local ctip, id = match(spellString, "(%a+):(%d+)")
			
		--	print(spellString,ctip,id)
			
			if ctip == tip and tonumber(id) then
				return tonumber(id), tip
			elseif ctip == "talent" then
			--[[
				for tier=1, MAX_TALENT_TIERS do
					for column=1, NUM_TALENT_COLUMNS do
						
						print(GetTalentLink(tier, column))
					
					end
				end
				]]
			end
		end
	elseif val and tonumber(val) and tip then
	
		return tonumber(val), tip
	end

end

-- PROC filter 

local CHOSEN_ROLE = nil

local CHOSEN_CLASS_SPEC = nil

local CASTER = "CASTER"
local CASTER_HEAL = "CASTER_HEAL"
local CASTER_DPS = "CASTER_DPS"
local MELEE = "MELEE"
local MELEE_STR = "MELEE_STR"
local MELEE_AGI = "MELEE_AGI"
local TANK = "TANK"
local ALL = "ALL"
local CUSTOM_DATA = "CUSTOM_DATA"
--
local PATCH_BC  = 'PATCH_BC'
local PATCH_WLK = 'PATCH_WLK'
local PATCH_CAT = 'PATCH_CATA'
local PATCH_MOP = 'PATCH_MOP'
local PATCH_WOD = 'PATCH_WOD'
local PATCH_LEG = 'PATCH_LEG'

local CHOSEN_PATCH = PATCH_LEG

local Role_Values_List = {}
Role_Values_List[1] = { name = L['ALL'],    value = ALL }
Role_Values_List[2] = { name = L['CUSTOM'], value = CUSTOM_DATA }

Role_Values_List[3] = { name = L['Role'],   values = {} }
Role_Values_List[3].values[1] = { name = L["CASTER"], value = CASTER }
Role_Values_List[3].values[2] = { name = L["CASTER_HEAL"], value = CASTER_HEAL }
Role_Values_List[3].values[3] = { name = L["CASTER_DPS"], value = CASTER_DPS }
Role_Values_List[3].values[4] = { name = L["MELEE"], value = MELEE }
Role_Values_List[3].values[5] = { name = L["MELEE_STR"], value = MELEE_STR }
Role_Values_List[3].values[6] = { name = L["MELEE_AGI"], value = MELEE_AGI }
Role_Values_List[3].values[7] = { name = L["TANK"], value = TANK }

Role_Values_List[4] = { name = L['PATCH_MOP'], values = {} }
Role_Values_List[4].values[1] = { name = L["ALL"], value = ALL..'\n'..PATCH_MOP }		
Role_Values_List[4].values[2] = { name = L["CASTER"], value = CASTER..'\n'..PATCH_MOP }
Role_Values_List[4].values[3] = { name = L["CASTER_HEAL"], value = CASTER_HEAL..'\n'..PATCH_MOP }
Role_Values_List[4].values[4] = { name = L["CASTER_DPS"], value = CASTER_DPS..'\n'..PATCH_MOP }
Role_Values_List[4].values[5] = { name = L["MELEE"], value = MELEE..'\n'..PATCH_MOP }
Role_Values_List[4].values[6] = { name = L["MELEE_STR"], value = MELEE_STR..'\n'..PATCH_MOP }
Role_Values_List[4].values[7] = { name = L["MELEE_AGI"], value = MELEE_AGI..'\n'..PATCH_MOP }
Role_Values_List[4].values[8] = { name = L["TANK"], value = TANK..'\n'..PATCH_MOP }

Role_Values_List[5] = { name = L['PATCH_WOD'], values = {} }
Role_Values_List[5].values[1] = { name = L["ALL"], value = ALL..'\n'..PATCH_WOD }				
Role_Values_List[5].values[2] = { name = L["CASTER"], value = CASTER..'\n'..PATCH_WOD }
Role_Values_List[5].values[3] = { name = L["CASTER_HEAL"], value = CASTER_HEAL..'\n'..PATCH_WOD }
Role_Values_List[5].values[4] = { name = L["CASTER_DPS"], value = CASTER_DPS..'\n'..PATCH_WOD }
Role_Values_List[5].values[5] = { name = L["MELEE"], value = MELEE..'\n'..PATCH_WOD }
Role_Values_List[5].values[6] = { name = L["MELEE_STR"], value = MELEE_STR..'\n'..PATCH_WOD }
Role_Values_List[5].values[7] = { name = L["MELEE_AGI"], value = MELEE_AGI..'\n'..PATCH_WOD }
Role_Values_List[5].values[8] = { name = L["TANK"], value = TANK..'\n'..PATCH_WOD }

Role_Values_List[6] = { name = L['PATCH_LEG'], values = {} }
Role_Values_List[6].values[1] = { name = L["ALL"], value = ALL..'\n'..PATCH_LEG }	
Role_Values_List[6].values[2] = { name = L["CASTER"], value = CASTER..'\n'..PATCH_LEG }
Role_Values_List[6].values[3] = { name = L["CASTER_HEAL"], value = CASTER_HEAL..'\n'..PATCH_LEG }
Role_Values_List[6].values[4] = { name = L["CASTER_DPS"], value = CASTER_DPS..'\n'..PATCH_LEG }
Role_Values_List[6].values[5] = { name = L["MELEE"], value = MELEE..'\n'..PATCH_LEG }
Role_Values_List[6].values[6] = { name = L["MELEE_STR"], value = MELEE_STR..'\n'..PATCH_LEG }
Role_Values_List[6].values[7] = { name = L["MELEE_AGI"], value = MELEE_AGI..'\n'..PATCH_LEG }
Role_Values_List[6].values[8] = { name = L["TANK"], value = TANK..'\n'..PATCH_LEG }
		
local ClassRole = {
	PALADIN 		= { CASTER_HEAL, 	TANK, 			MELEE_STR},
	PRIEST 			= { CASTER_HEAL, 	CASTER_HEAL, 	CASTER_DPS },
	WARLOCK 		= { CASTER_DPS, 	CASTER_DPS, 	CASTER_DPS },
	WARRIOR 		= { MELEE_STR, 		MELEE_STR, 		TANK },		
	HUNTER 			= { MELEE_AGI, 		MELEE_AGI, 		MELEE_AGI },
	SHAMAN 			= { CASTER_DPS, 	MELEE_AGI, 		CASTER_HEAL },		
	ROGUE 			= { MELEE_AGI, 		MELEE_AGI, 		MELEE_AGI },
	MAGE 			= { CASTER_DPS, 	CASTER_DPS, 	CASTER_DPS },
	DEATHKNIGHT 	= { TANK, 			MELEE_STR, 		MELEE_STR },		
	DRUID 			= { CASTER_DPS, 	MELEE_AGI, 		TANK, 			CASTER_HEAL },	
	MONK 			= { TANK, 			CASTER_HEAL, 	MELEE_AGI },
	DEMONHUNTER		= { MELEE_AGI,		TANK },
}

local RoleSelect = {
	[ALL] = ALL,
	[CASTER] = CASTER,
	[CASTER_HEAL] = CASTER_HEAL,
	[CASTER_DPS] = CASTER_DPS,
	[MELEE] = MELEE,
	[MELEE_STR] = MELEE_STR,
	[MELEE_AGI] = MELEE_AGI,
	[TANK] = TANK,
	[CUSTOM_DATA] = "Player",
}

local function GetRole()
	local talent = GetSpecialization()
	local role
	local _, classFileName = UnitClass("player")
	
	if talent then
		role = ClassRole[classFileName][talent]
	else
		role = ALL
	end
	
	return role
end

local function GetClassSpec(spec)

	if not CHOSEN_CLASS_SPEC then CHOSEN_CLASS_SPEC = GetSpecialization() and ""..GetSpecialization().."" or ALL end
	
	if not spec or spec == ALL or CHOSEN_CLASS_SPEC == ALL then return true end	

	if match(spec, CHOSEN_CLASS_SPEC) then return true end	
end

local function SpecSelect()
	local max_specs = 3
	if C.myCLASS == "DRUID" then max_specs = 4 end
	if C.myCLASS == 'DEMONHUNTER' then max_specs = 2 end
	
	local t = { [ALL] = L['ALL'] }
	
	for i=1, max_specs do
		local gID, name,_, icon = GetSpecializationInfo(i)
	
		t[""..i..""] = "\124T"..icon..":0\124t "..name
	end
	
	return t
end

local function SetSelectProcFilter(value)
	local role, patch = strsplit('\n', value)
	
	
	CHOSEN_ROLE = role or ALL
	CHOSEN_PATCH = patch or false
end

local function GetSelectProcFilter()
	if not CHOSEN_ROLE then CHOSEN_ROLE = GetRole() end
	
	if CHOSEN_PATCH then
		return CHOSEN_ROLE..'\n'..CHOSEN_PATCH
	else
		return CHOSEN_ROLE
	end
end

local function ProcFilter_Patch(patch)

	if patch then
		if CHOSEN_PATCH then
			return patch == CHOSEN_PATCH
		end
	end
	
	return true	
end

local function ProcFilter(role)
	
	if not CHOSEN_ROLE then CHOSEN_ROLE = GetRole() end

	if not role or role == ALL or CHOSEN_ROLE == ALL then return true end
	
	if role == CHOSEN_ROLE then 
		return true 
	end
	
	if CHOSEN_ROLE == CASTER then
		if ( role == CASTER_HEAL or role == CASTER_DPS ) then
			return true
		end
	end
	
	if ( CHOSEN_ROLE == CASTER_HEAL or CHOSEN_ROLE == CASTER_DPS )then
		if ( role == CASTER ) then
			return true
		end
	end
	
	if CHOSEN_ROLE == MELEE then
		if ( role == MELEE_STR or role == MELEE_AGI ) then
			return true
		end
	end
	
	if ( CHOSEN_ROLE == MELEE_STR or CHOSEN_ROLE == MELEE_AGI )then
		if ( role == MELEE ) then
			return true
		end
	end
	
	return false
end

local SpellString
do
	local cache = {}
	local lastid = nil
	
	local spaces = "  "
	local name, _, icon, spacess
	
	function C.ShortSpellSting(spellID, size, hideid, cooldown)
		
		if not size then size = 12 end
		
		if spellID then
		
			name = GetSpellInfo(spellID)
			
			local fakeIcon, realIcon = GetSpellTexture(spellID)
			
			icon = realIcon or fakeIcon
			
			name = name or "Invalid"
			
			icon = ( cooldown and C:GetCustomCooldownTexture(name) ) or C:GetCustomTextureBars(spellID) or icon or "Interface\\ICONS\\Inv_misc_questionmark"
		end

		local color = C:GetColor(spellID, cooldown and "COOLDOWN_SPELL" or nil)
		local color2 = ""
		
		if color then
			color2 = format("|cff%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)
		end
		
		return "|T"..icon..":0:0|t #"..spellID..' '..name.." "..color2.." #COLOR|r"

	end
	
	function C.SpellString(spellID,size, hideid, cooldown)
		if not size then size = 12 end
		
		if spellID then
		
			name = GetSpellInfo(spellID)
			
			local fakeIcon, realIcon = GetSpellTexture(spellID)
			
			icon = realIcon or fakeIcon
			
			name = name or "Invalid"
			
			icon = ( cooldown and C:GetCustomCooldownTexture(name) ) or C:GetCustomTextureBars(spellID) or icon or "Interface\\ICONS\\Inv_misc_questionmark"
			
			spacess = ""
			
			if spellID > 9 then
				spacess = spaces..spaces..spaces..spaces..spaces..spaces
			end
			
			if spellID > 99 then
				spacess = spaces..spaces..spaces..spaces..spaces
			end
			
			if spellID > 999 then
				spacess = spaces..spaces..spaces..spaces
			end
			
			if spellID > 9999 then
				spacess = spaces..spaces..spaces
			end
			
			if spellID > 99999 then
				spacess = spaces..spaces
			end
			
			if spellID > 999999 then
				spacess = spaces
			end

		end

		local color = C:GetColor(spellID, cooldown and "COOLDOWN_SPELL" or nil)
		local color2 = ""
		
		if color then
			color2 = format("|cff%02x%02x%02x", color[1]*255, color[2]*255, color[3]*255)
		end
		
		return "|T"..icon..":"..size.."|t #"..spellID..spacess..name.." "..color2.." #COLOR|r"

	end

end

local placeholder = { 
	
	[172] = 146739,
	[2944] = 158831,
	
	[157707] = 53351,
	[157708] = 53351,
}

function C:SearchDBSpell(spellid, dbtype)
	
	local spellid = placeholder[spellid] or spellid
	
--	print("Do searth")
	
	if C.myCLASS == "HUNTER" and C:GetTrapType(spellid) then
		message(C.ShortSpellSting(spellid)..L[" already exists in "]..L["Traps"]..L[". Redirect..."])
		
		AleaUI_GUI:SelectGroup(addon, "bars", "Traps")
		
		return
	end
	
	if dbtype == "bar_cooldowns" then
		if not self.db.profile.bars_cooldowns[C.myCLASS] then self.db.profile.bars_cooldowns[C.myCLASS] = {} end
		if self.db.profile.bars_cooldowns[C.myCLASS][spellid] and not self.db.profile.bars_cooldowns[C.myCLASS][spellid].fulldel then
			self.db.profile.bars_cooldowns[C.myCLASS][spellid].deleted = nil
			
			AleaUI_GUI:SelectGroup(addon, "bars", "spellList4")
			self:BarCooldownSpell(spellid)
			
			C:UpdateBars_CooldownPart()
			return
		else
			self.db.profile.bars_cooldowns[C.myCLASS][spellid] = {}
			self:BarCooldownSpell(spellid)
			
			C:UpdateBars_CooldownPart()
			return
		end
	else
		if self.db.profile.classSpells[self.myCLASS][spellid] and not self.db.profile.classSpells[self.myCLASS][spellid].fulldel then
			
			self.db.profile.classSpells[self.myCLASS][spellid].deleted = nil
			
			message(C.ShortSpellSting(spellid)..L[" already exists in "]..L["Class Spells"]..L[". Redirect..."])
			
			CHOSEN_CLASS_SPEC = self.db.profile.classSpells[self.myCLASS][spellid].spec or ALL
			
			AleaUI_GUI:SelectGroup(addon, "bars", "ClassSpells")
			self:ClassSpell(spellid)
			return
		end
		
		if self.db.profile.procSpells[spellid] and not self.db.profile.procSpells[spellid].fulldel then
			self.db.profile.procSpells[spellid].deleted = nil
			
			message(C.ShortSpellSting(spellid)..L[" already exists in "]..L["Procs"]..L[". Redirect..."])
			
			CHOSEN_ROLE = self.db.profile.procSpells[spellid].role or ALL
			
			AleaUI_GUI:SelectGroup(addon, "bars", "spellList2")
			self:ProcsSpell(spellid)
			return
		end
		
		if self.db.profile.othersSpells[spellid] and not self.db.profile.othersSpells[spellid].fulldel then
			self.db.profile.othersSpells[spellid].deleted = nil
			
			message(C.ShortSpellSting(spellid)..L[" already exists in "]..L["Other"]..L[". Redirect..."])
			
			AleaUI_GUI:SelectGroup(addon, "bars", "spellList3")
			self:OthersSpell(spellid)
			return
		end
		
		if dbtype == "class" then
			self.db.profile.classSpells[self.myCLASS][spellid] = {}
			self:ClassSpell(spellid)
			return
		elseif dbtype == "procs" then
			self.db.profile.procSpells[spellid] = {}
			self:ProcsSpell(spellid)
			return
		elseif dbtype == "others" then
			self.db.profile.othersSpells[spellid] = {}
			self:OthersSpell(spellid)
			return
		end
		
		self:OnCustomUpdateAuras()
	end
end

function C:SearchSpell(spellid, showmore)
	
	local spellid = placeholder[spellid] or spellid
	
--	print("Do searth")
	if showmore then

		if self.db.profile.classSpells[self.myCLASS][spellid] then
			return true, "Class"
		end
		
		if self.db.profile.procSpells[spellid] then
			return true, "Procs"
		end
		
		if self.db.profile.othersSpells[spellid] then
			return true, "Others"
		end
		
		if self.db.profile.bars_cooldowns[C.myCLASS][spellid] then
			return true, "Cooldown"
		end
		
		return false, false
	else
	
	
		if self.db.profile.classSpells[self.myCLASS][spellid] then
			return true
		end
		
		if self.db.profile.procSpells[spellid] then
			return true
		end
		
		if self.db.profile.othersSpells[spellid] then
			return true
		end
		
		if self.db.profile.bars_cooldowns[C.myCLASS][spellid] then
			return true
		end
	
	end
	
	return false
end
local IsGroupUpSpell = C.IsGroupUpSpell

local function deepcopy(t)
	if type(t) ~= 'table' then return t end
		local mt = getmetatable(t)
		local res = {}
		for k,v in pairs(t) do
			if type(v) == 'table' then
				v = deepcopy(v)
			end
		res[k] = v
		end
		setmetatable(res,mt)
	return res
end
	
function C:GlobalStyleUpdate()
	
	--statusbar
	local global_statusbar			= self.db.profile.global_statusbar
	local global_statusbrcolor		= self.db.profile.global_statusbrcolor
	local global_statusbar_bg		= self.db.profile.global_statusbar_bg
	local global_statusbrcolor_bg	= self.db.profile.global_statusbrcolor_bg
	--font
	local global_font 				= self.db.profile.global_font	
	local global_textcolor 			= self.db.profile.global_textcolor	
	local global_size 				= self.db.profile.global_size	
	local global_alpha 				= self.db.profile.global_alpha
	local global_flags 				= self.db.profile.global_flags
	-- border
	local global_border 			= self.db.profile.global_border
	local global_bordercolor 		= self.db.profile.global_bordercolor
	local global_bordersize 		= self.db.profile.global_bordersize
	local global_borderinset 		= self.db.profile.global_borderinset
	
	local global_font_shadow 		= self.db.profile.global_font_shadow
	local global_font_shadow_offset = self.db.profile.global_font_shadow_offset
	for i, opts in ipairs(self.db.profile.bars_anchors) do
	
		self.db.profile.bars_anchors[i].border 		= global_border or opts.border
		self.db.profile.bars_anchors[i].bordersize		= global_bordersize or opts.bordersize
		self.db.profile.bars_anchors[i].borderinset	= global_borderinset or opts.borderinset
		self.db.profile.bars_anchors[i].bordercolor	= deepcopy(global_bordercolor or opts.bordercolor)
		
		self.db.profile.bars_anchors[i].bar.color		= deepcopy(global_statusbrcolor or opts.bar.color)
		self.db.profile.bars_anchors[i].bar.texture 	= global_statusbar or opts.bar.texture
		self.db.profile.bars_anchors[i].bar.bgcolor		= deepcopy(global_statusbrcolor_bg or opts.bar.bgcolor)
		self.db.profile.bars_anchors[i].bar.bgtexture	= global_statusbar_bg or opts.bar.bgtexture
	
		self.db.profile.bars_anchors[i].stack.textcolor 	= deepcopy(global_textcolor or opts.stack.textcolor)
		self.db.profile.bars_anchors[i].stack.font			= global_font or opts.stack.font
		self.db.profile.bars_anchors[i].stack.size			= global_size or opts.stack.size
		self.db.profile.bars_anchors[i].stack.flags		= global_flags or opts.stack.flags
		self.db.profile.bars_anchors[i].stack.shadow		= global_font_shadow or opts.stack.shadow
		self.db.profile.bars_anchors[i].stack.offset		= global_font_shadow_offset or opts.stack.offset
	
		self.db.profile.bars_anchors[i].stack.alpha		= global_alpha or opts.stack.alpha
		
		self.db.profile.bars_anchors[i].timer.textcolor	= deepcopy(global_textcolor or opts.timer.textcolor)
		self.db.profile.bars_anchors[i].timer.font			= global_font or opts.timer.font
		self.db.profile.bars_anchors[i].timer.size			= global_size or opts.timer.size
		self.db.profile.bars_anchors[i].timer.flags		= global_flags or opts.timer.flags
		self.db.profile.bars_anchors[i].timer.alpha		= global_alpha or opts.timer.alpha
		self.db.profile.bars_anchors[i].timer.shadow		= global_font_shadow or opts.timer.shadow
		self.db.profile.bars_anchors[i].timer.offset		= global_font_shadow_offset or opts.timer.offset
		
		
		self.db.profile.bars_anchors[i].spell.textcolor	= deepcopy(global_textcolor or opts.spell.textcolor)
		self.db.profile.bars_anchors[i].spell.font			= global_font or opts.spell.font
		self.db.profile.bars_anchors[i].spell.size			= global_size or opts.spell.size
		self.db.profile.bars_anchors[i].spell.flags		= global_flags or opts.spell.flags
		self.db.profile.bars_anchors[i].spell.alpha		= global_alpha or opts.spell.alpha
		self.db.profile.bars_anchors[i].spell.shadow		= global_font_shadow or opts.spell.shadow
		self.db.profile.bars_anchors[i].spell.offset		= global_font_shadow_offset or opts.spell.offset
	
	end
	
	self:Visibility()
	
	-- 1-r 2-g 3-b 4-a
	
	self.db.profile.cooldownline.statusbar 				= global_statusbar or self.db.profile.cooldownline.statusbar 
	self.db.profile.cooldownline.bgcolor				= global_statusbrcolor and { r = global_statusbrcolor[1], g = global_statusbrcolor[2], b = global_statusbrcolor[3], a = global_statusbrcolor[4], } or self.db.profile.cooldownline.bgcolor
	self.db.profile.cooldownline.border					= global_border or self.db.profile.cooldownline.border
	self.db.profile.cooldownline.bordersize				= global_bordersize or self.db.profile.cooldownline.bordersize
	self.db.profile.cooldownline.borderinset			= global_borderinset or self.db.profile.cooldownline.borderinset
	self.db.profile.cooldownline.bordercolor			= global_bordercolor and { r = global_bordercolor[1], g = global_bordercolor[2], b = global_bordercolor[3], a = global_bordercolor[4], } or self.db.profile.cooldownline.bordercolor

	self.db.profile.cooldownline.icon_border			= global_border or self.db.profile.cooldownline.icon_border
	self.db.profile.cooldownline.icon_bordersize		= global_bordersize or self.db.profile.cooldownline.icon_bordersize
	self.db.profile.cooldownline.icon_borderinset		= global_borderinset or self.db.profile.cooldownline.icon_borderinset
	self.db.profile.cooldownline.icon_background_inset	= 0 or self.db.profile.cooldownline.icon_background_inset
	self.db.profile.cooldownline.icon_bordercolor		= global_bordercolor and { r = global_bordercolor[1], g = global_bordercolor[2], b = global_bordercolor[3], a = global_bordercolor[4], } or self.db.profile.cooldownline.icon_bordercolor
	
	self.db.profile.cooldownline.font					= global_font and self.db.profile.cooldownline.font	
	self.db.profile.cooldownline.fontflags				= global_flags and self.db.profile.cooldownline.fontflags
	self.db.profile.cooldownline.fontsize				= global_size and self.db.profile.cooldownline.fontsize
	self.db.profile.cooldownline.fontshadowcolor		= global_textcolor and { r = global_textcolor[1], g = global_textcolor[2], b = global_textcolor[3], a = global_textcolor[4], } or self.db.profile.cooldownline.fontshadowcolor	
	self.db.profile.cooldownline.fontshadowoffset		= global_font_shadow_offset or self.db.profile.cooldownline.fontshadowoffset

	self.db.profile.cooldownline.fontcolor				= global_textcolor and { r = global_textcolor[1], g = global_textcolor[2], b = global_textcolor[3], a = global_textcolor[4], } or self.db.profile.cooldownline.fontcolor
	
	self.db.profile.cooldownline.icon_font				= global_font and self.db.profile.cooldownline.icon_font
	self.db.profile.cooldownline.icon_fontflaggs		= global_flags and self.db.profile.cooldownline.icon_fontflaggs
	self.db.profile.cooldownline.icon_fontsize			= global_size and self.db.profile.cooldownline.icon_fontsize
	self.db.profile.cooldownline.icon_fontcolor			= global_textcolor and { r = global_textcolor[1], g = global_textcolor[2], b = global_textcolor[3], a = global_textcolor[4], } or self.db.profile.cooldownline.icon_fontcolor
	self.db.profile.cooldownline.icon_fontshadowcolor	= global_textcolor and { r = global_textcolor[1], g = global_textcolor[2], b = global_textcolor[3], a = global_textcolor[4], } or self.db.profile.cooldownline.icon_fontshadowcolor
	self.db.profile.cooldownline.icon_fontshadowoffset	= global_font_shadow_offset or self.db.profile.cooldownline.icon_fontshadowoffset
		
	self.UpdateSettings()
	
	
	for unit, opts in ipairs(self.db.profile.castBars) do
		--[==[
			point = {0,0}, 
			w = 410, 
			h = 20,
			font = "Friz Quadrata TT",
			font_size = 12,
			font_alpha = 1,
			font_flag = "OUTLINE",
			font_color = { 1, 1, 1, 1 },
			font_shadow_color = { 0, 0, 0, 1},
			font_shadow_offset = { 0, 0 },
			justify = "LEFT",
			startusbar = "Flat",
			
			ping = true,
			target_name = false,
			
			icon_gap = 1,
			
			border = "Flat",
			border_size = 1,
			border_inset = 1,
			border_color = { 0, 0, 0, 1 },
			
			tick_color = { 150/255, 225/255, 239/255, 1 },
			ping_color = { 1, 1, 1, 0.5 },
			
			color_inter = { 0.2,0.2,0.2,1 },
			color_notinter = {  .6, .2, .2, 1 },
			color_bg = { 0, 0, 0, 1 },
		]==]
		
		self.db.profile.castBars[unit].font 				= global_font and self.db.profile.castBars[unit].font
		self.db.profile.castBars[unit].icon_fontflaggs		= global_flags and self.db.profile.castBars[unit].icon_fontflaggs
		self.db.profile.castBars[unit].font_size			= global_size and self.db.profile.castBars[unit].font_size
		self.db.profile.castBars[unit].font_color			= global_textcolor and { global_textcolor[1], global_textcolor[2], global_textcolor[3], global_textcolor[4], } or self.db.profile.castBars[unit].font_color
	--	self.db.profile.castBars[unit].font_shadow_color	
		self.db.profile.castBars[unit].font_shadow_offset	= global_font_shadow_offset or self.db.profile.castBars[unit].font_shadow_offset
		
		self.db.profile.castBars[unit].startusbar 			= global_statusbar or self.db.profile.castBars[unit].startusbar
	
		self.db.profile.castBars[unit].border 				= global_border or self.db.profile.castBars[unit].border
		self.db.profile.castBars[unit].border_size			= global_bordersize or self.db.profile.castBars[unit].border_size
		self.db.profile.castBars[unit].border_inset			= global_borderinset or self.db.profile.castBars[unit].border_inset
		self.db.profile.castBars[unit].border_color			= deepcopy(global_bordercolor or self.db.profile.castBars[unit].border_color)
		
		self.db.profile.castBars[unit].color_bg				= deepcopy(global_statusbrcolor_bg or self.db.profile.castBars[unit].color_bg)		
	end
end

SpellString = C.SpellString

function C:DefaultOptions()

	local default = {
		locked = false,
		totalanchor = 1,
		engageThrottle = 30,
		unitThrottleValue = 0.3,
		throttleOutCombat = 30,
		playerThrottleValue = 0,
		show_mark = true,
		bar_module_enabled = true,
		bar_smooth_value = 100,
		bar_smooth_value_v2 = 5,
		doswap = true,
		onlyMineDebuff = true,
		othersFiltersoff = false,
		procsFiltersoff = false,
		classlistFiltersoff = false,
		maximumtime_value = 30,
		hide_during_petbattle = true,
		hide_dot_ticks = false,
		shine_on_apply = false,
		delayfading_outanim = 0.3,
		delayfading_wait = 0.5,
		
		pandemia_bp_style = 2,
		
		show_item_spellid = true,
		show_spellid_tooltip = true,
		
		sound_channel = "Master",
		
		spell_list_grouping = false,
		
		minimap = {
			hide = true,
		},			
		global_statusbar = "Flat",
		global_statusbrcolor = {80/255,80/255,80/255,1},
		global_statusbar_bg = "Flat",
		global_statusbrcolor_bg = {80/255,80/255,80/255,0.5},
		global_font = "Friz Quadrata TT",
		global_textcolor = { 1, 1, 1, 1},
		global_size = 12,
		global_alpha = 1,
		global_flags = "OUTLINE",
		global_border = "Flat",
		global_bordercolor = {0,0,0,1},
		global_bordersize = 1,
		global_borderinset = 1,

		global_font_shadow = { 0, 0, 0, 1},
		global_font_shadow_offset = { 0, 0},
		
		castBars = {
			["pet"] = { 
				point = {0,0}, 
				w = 410, 
				h = 20,
				font = "Friz Quadrata TT",
				font_size = 12,
				font_alpha = 1,
				font_flag = "OUTLINE",
				font_color = { 1, 1, 1, 1 },
				font_shadow_color = { 0, 0, 0, 1},
				font_shadow_offset = { 0, 0 },
				justify = "LEFT",
				startusbar = "Flat",
				
				ping = true,
				target_name = false,
				
				icon_gap = 1,
				
				border = "Flat",
				border_size = 1,
				border_inset = 1,
				border_color = { 0, 0, 0, 1 },
				
				tick_color = { 150/255, 225/255, 239/255, 1 },
				ping_color = { 1, 1, 1, 0.5 },
				
				color_inter = { 0.2,0.2,0.2,1 },
				color_notinter = {  .6, .2, .2, 1 },
				color_bg = { 0, 0, 0, 1 },
				
			},
			["player"] = { 
				showGCD = true,
				point = {0,0}, 
				w = 410, 
				h = 20,
				font = "Friz Quadrata TT",
				font_size = 12,
				font_alpha = 1,
				font_flag = "OUTLINE",
				font_color = { 1, 1, 1, 1 },
				font_shadow_color = { 0, 0, 0, 1},
				font_shadow_offset = { 0, 0 },
				justify = "LEFT",
				startusbar = "Flat",
				
				ping = true,
				target_name = false,
				
				icon_gap = 1,
				
				border = "Flat",
				border_size = 1,
				border_inset = 1,
				border_color = { 0, 0, 0, 1 },
				
				tick_color = { 150/255, 225/255, 239/255, 1 },
				ping_color = { 1, 1, 1, 0.5 },
				
				color_inter = { 0.2,0.2,0.2,1 },
				color_notinter = {  .6, .2, .2, 1 },
				color_bg = { 0, 0, 0, 1 },
				
			},
			["target"] = { 
				point = {0,50}, 
				w = 410, 
				h = 20,
				font = "Friz Quadrata TT",
				font_size = 12,
				font_alpha = 1,
				font_flag = "OUTLINE",
				font_color = { 1, 1, 1, 1 },
				font_shadow_color = { 0, 0, 0, 1},
				font_shadow_offset = { 0, 0 },
				justify = "LEFT",
				startusbar = "Flat",
				icon_gap = 1,
				border = "Flat",
				border_size = 1,
				border_inset = 1,
				border_color = { 0, 0, 0, 1 },
				
				ping = false,
				
				tick_color = { 150/255, 225/255, 239/255, 1 },
				ping_color = { 1, 1, 1, 0.5 },
				
				color_inter = { 0.2,0.2,0.2,1 },
				color_notinter = {  .6, .2, .2, 1 },
				color_bg = { 0, 0, 0, 1 },
				},
			["targettarget"] = { 
				point = {0,100}, 
				w = 410, 
				h = 20,
				font = "Friz Quadrata TT",
				font_size = 12,
				font_alpha = 1,
				font_flag = "OUTLINE",
				font_color = { 1, 1, 1, 1 },
				font_shadow_color = { 0, 0, 0, 1},
				font_shadow_offset = { 0, 0 },
				justify = "LEFT",
				startusbar = "Flat",
				icon_gap = 1,
				border = "Flat",
				border_size = 1,
				border_inset = 1,
				border_color = { 0, 0, 0, 1 },
				
				ping = false,
				
				tick_color = { 150/255, 225/255, 239/255, 1 },
				ping_color = { 1, 1, 1, 0.5 },
				
				color_inter = { 0.2,0.2,0.2,1 },
				color_notinter = {  .6, .2, .2, 1 },
				color_bg = { 0, 0, 0, 1 },},
			["focus"] = { point = {0,150},
				w = 410, 
				h = 20,
				font = "Friz Quadrata TT",
				font_size = 12,
				font_alpha = 1,
				font_flag = "OUTLINE",
				font_color = { 1, 1, 1, 1 },
				font_shadow_color = { 0, 0, 0, 1},
				font_shadow_offset = { 0, 0 },
				justify = "LEFT",
				startusbar = "Flat",
				icon_gap = 1,
				border = "Flat",
				border_size = 1,
				border_inset = 1,
				border_color = { 0, 0, 0, 1 },
				
				ping = false,
				
				tick_color = { 150/255, 225/255, 239/255, 1 },
				ping_color = { 1, 1, 1, 0.5 },
				
				color_inter = { 0.2,0.2,0.2,1 },
				color_notinter = {  .6, .2, .2, 1 },
				color_bg = { 0, 0, 0, 1 },},
		},
		
		disableBlizzard = false,
		playerCastBar = false,
		targetCastBar = false,
		targettargetCastBar = false,
		focusCastBar = false,
		
		unit_filters = {
			target = true,
			focus  = true,
			boss1  = true,
			boss2  = true,
			boss3  = true,
			boss4  = true,
			boss5  = true,
			arena1  = true,
			arena2  = true,
			arena3  = true,
			arena4  = true,
			arena5  = true,
			unknown = true,
			player = true,
		},
		totems = {
			["totem1"] = {
				show = true,
				color = {1,80/255,0},
				priority = -19,
				group = "procs",
			},
			["totem2"] = {
				show = true,
				color = {74/255, 142/255, 42/255},
				priority = -20,
				group = "procs",
			},
			["totem3"] = {
				show = true,
				color = { 65/255, 110/255, 1},
				priority = -18,
				group = "procs",
			},
			["totem4"] = {
				show = true,
				color = {0.6, 0, 1},
				priority = -17,
				group = "procs",
			},
		},
		
		hunterTraps = {
			frost = {
				active = true,
				nonactive = true,
				color = { 0, 1, 1, 1},
				priority = 0,
				anchor = 1,
				anchor_off = 1,
				group = "auto",
			},
			slow = {
				active = true,
				nonactive = true,
				color = { 0, 0, 1, 1},
				priority = 0,
				anchor = 1,
				anchor_off = 1,
				group = "auto",
			},
			fire = {
				active = true,
				nonactive = true,
				color = { 0.6, 0, 0, 1},
				priority = 0,
				anchor = 1,
				anchor_off = 1,
				group = "auto",
			},
		},
		enchants = {},
		cacheSpells = {},
		classSpells = {
			["PRIEST"] = {},
			["WARLOCK"] = {},
			["WARRIOR"] = {},
			["PALADIN"] = {},
			["MAGE"] = {},
			["DEATHKNIGHT"] = {},
			["DRUID"] = {},
			["SHAMAN"] = {},
			["MONK"] = {},
			["HUNTER"] = {},
			["ROGUE"] = {},
			['DEMONHUNTER'] = {},
		},
		classCooldowns = {
			["PRIEST"] = {},
			["WARLOCK"] = {},
			["WARRIOR"] = {},
			["PALADIN"] = {},
			["MAGE"] = {},
			["DEATHKNIGHT"] = {},
			["DRUID"] = {},
			["SHAMAN"] = {},
			["MONK"] = {},
			["HUNTER"] = {},
			["ROGUE"] = {},
			['DEMONHUNTER'] = {},
		},
		procSpells = {},
		othersSpells = {},
		bars_cooldowns = {
			["PRIEST"] = {},
			["WARLOCK"] = {},
			["WARRIOR"] = {},
			["PALADIN"] = {},
			["MAGE"] = {},
			["DEATHKNIGHT"] = {},
			["DRUID"] = {},
			["SHAMAN"] = {},
			["MONK"] = {},
			["HUNTER"] = {},
			["ROGUE"] = {},
			['DEMONHUNTER'] = {},
		},
		
		internal_cooldowns = {},
		
		auras_cooldowns = {
			["PRIEST"] = {},
			["WARLOCK"] = {},
			["WARRIOR"] = {},
			["PALADIN"] = {},
			["MAGE"] = {},
			["DEATHKNIGHT"] = {},
			["DRUID"] = {},
			["SHAMAN"] = {},
			["MONK"] = {},
			["HUNTER"] = {},
			["ROGUE"] = {},
			['DEMONHUNTER'] = {},			
		},
		cooldownline = {
			w = 360, 
			h = 18, 
			x = 0, 
			y = -240,
			hide_cooldown_line = false,
			tooltip_anchor_gap = 0,
			tooltip_anchor_to_frame = 2,
			tooltip_anchor_to = 1,
			slash_x = 0,
			slash_y = 0,
			slash_size = 200,
			slash_alpha = 0.5,
			slash_show = true,
			slash_show_small = true,
			slash_small_alpha = 0.7,
			
			minimal_time_to_fade = 10,
			
			custom_text_timer = "0 1 10 30 60 120 300",
			
			splash_big = {
				time_in = 0.5,
				time_out = 0.6,
				step_in = 0.6,
				step_out = -1.5,
				alpha_in = 1,
				alpha_out = -1.5,
			},
			
			splash_small = {
				time_in = 0.5,
				time_out = 0,
				step_in = 3,
				step_out = -2,
				alpha_in = 0,
				alpha_out = 0,
			},
			
			fortam_s = 1,
			
			enabled = true,
			
			hidepet = false,
			hidebag = false,
			hideinv = false,
			hidefail = false,
			hideplay = false,
			hidevehi = false,
			hideinternal = false,
			hidaurabuffs = false,
			hidauradebuffs = false,
			
			pla_color = {1,0.5,0,1},
			veh_color = {1,0.5,0,1},
			pet_color = {1,0,.95,1},
			bag_color = {1,1,0,1},
			inv_color = {1,1,0,1},
			inter_color = {0, 0.6, 0.85, 1},
			
			aura_cd_buff_color = { 0.2, 0.8, 0.2, 1 },
			aura_cd_debuff_color = { 0.8, 0.2, .2, 1 },
			
			blood_runes = true,
			frost_runes = true,
			unholy_runes = true,
			
			blood_runes_color = {1, 0, 0, 1},
			frost_runes_color = {0, 0.43, 1, 1},
			unholy_runes_color = {0.2, 0.8, 0, 1},
			
			showenchants = false,
			
			iconplus = 4,
			inactivealpha = 0.5,
			activealpha = 1.0,
			statusbar = "Flat",
			bgcolor = { 
				r = 0, 
				g = 0, 
				b = 0, 
				a = 0.5, 
			},
			border = "Flat",
			bordersize = 1, -- Added defaults
			borderinset = 1, -- Added defaults
			bordercolor = { 
				r = 80/255, 
				g = 80/255, 
				b = 80/255, 
				a = 1, 
			},
			icon_backgroundcolor = {
				r = 0, 
				g = 0, 
				b = 0, 
				a = 0.8, 				
			},
			icon_border = "Flat",
			icon_bordersize = 1, -- Added defaults
			icon_borderinset = 0, -- Added defaults
			icon_background_inset = 0,
			icon_bordercolor = { 
				r = 80/255, 
				g = 80/255, 
				b = 80/255, 
				a = 1, 
			},
			splash_background_color	= {
				r = 0, 
				g = 0, 
				b = 0, 
				a = 0.3, 
			},
			splashsmall_background_color = {
				r = 0, 
				g = 0, 
				b = 0, 
				a = 0.3, 
			},
			font = "Friz Quadrata TT",
			fontflags = "OUTLINE",
			fontsize = 10,
			fontcolor = { 
				r = 1,
				g = 1,
				b = 1, 
				a = 1, 
			},
			fontshadowcolor = {
				r = 0,
				g = 0,
				b = 0,
				a = 1,					
			},
			
			fontshadowoffset = { 0, 0},
			icon_font = "Friz Quadrata TT",
			icon_fontflaggs = "OUTLINE",
			icon_fontsize = 10,
			icon_fontcolor = { 
				r = 1,
				g = 1,
				b = 1, 
				a = 1, 
			},
			icon_fontshadowcolor = {
				r = 0,
				g = 0,
				b = 0,
				a = 1,					
			},
			
			icon_fontshadowoffset = { 0, 0},
			spellcolor = { 
				r = 204/255, 
				g = 0, 
				b = 0, 
				a = 1,
				},
			nospellcolor = { 
				r = 0, 
				g = 0, 
				b = 0, 
				a = 1, 
			},
			block = {  -- [spell or item name] = true,
				[ GetItemInfo(6948) or L["Hearthstone"] ] = { itemid = 6948, hide = true },  -- Hearthstone
				[ GetItemInfo(110560) or L["Garrison Hearthstone"] ] = { itemid = 110560, hide = true },  -- Hearthstone
				[ GetSpellInfo(125439) or L["Revive Battle Pets"] ] = { spellid = 125439, hide = true },
			},	
			
			blockList = {
				['item:6948'] = { itemid = 6948, hide = true },
				['item:110560'] = { itemid = 110560, hide = true },
				['item:140192'] = { itemid = 140192, hide = true },
				['spell:125439'] = { spellid = 125439, hide = true },
			},
			transferList = true,
		},
		bars_anchors = {
			{
				name = 1,
				bar_number = 20,
				left_icon = true,
				right_icon = false,
				icon_gap = 5,
				reverse = false,
				vertical = false,
				add_up = true,
				point = { 0, 0},
				w = 250,
				h = 14,
				target_name =true,
				fortam_s = 1,
				gap = 5,
				border = "Flat",
				bordersize = 1, -- Added defaults
				borderinset = 1, -- Added defaults
				bordercolor = {80/255,80/255,80/255,1},
				bar = { 
					color = {118/255, 0, 0, 1},
					texture = "Flat",
					bgcolor = {0, 0, 0, 0.5},
					bgtexture = "Flat",
				},
				stack = {
					textcolor = {1, 1, 1,1},
					font = STANDARD_TEXT_FONT,
					size = 14,
					flags = "OUTLINE",
					justify = "RIGHT",
					shadow =  { 0, 0, 0, 1},
					offset = { 0, 0 },
				},
				timer ={
					textcolor = {1, 1, 1,1},
					font = STANDARD_TEXT_FONT,
					size = 14,
					flags = "OUTLINE",
					justify = "RIGHT",
					shadow =  { 0, 0, 0, 1},
					offset = { 0, 0 },
				},
				spell ={
					textcolor = {1, 1, 1, 1},
					font = STANDARD_TEXT_FONT,
					size = 14,
					flags = "OUTLINE",
					justify = "LEFT",
					offsetx = 0,
					shadow =  { 0, 0, 0, 1},
					offset = { 0, 0 },
				},
				
				raidicon_xOffset = 0,
				raidicon_y = 5, 
				raidiconsize = 10,
				raidicon_alpha = 1,

				castspark = {
					color = {1, 1, 1, 1},	
					alpha = 1,
				},
				dotticks = {
					color = {1, 1, 1, 1},	
					alpha = 1,
				},
				sorting = {
					{name = "target", 		gap = 10, alpha = 1,  sort = 1 },
					{name = "player", 		gap = 10, alpha = 1,  sort = 2 },
					{name = "procs",		gap = 15, alpha = .7, sort = 3 },
					{name = "cooldowns",	gap = 15, alpha = 1,  sort = 4 },
					{name = "offtargets",	gap = 6,  alpha = .7, sort = 5 },
				},	
			},
		},
	}
		
	self:SetupAuras(default)
	self.db = {}
	self.db.profile = ALEAUI_NewDB("SPTimersDB", default, true)
end

function C:OptionsTable()
	o = {
		title = L["SPTimers (drag here to move options frame)"],
		args = {
			about ={
				order = 99998,name = L["About"],type = "group",
				args={					
				},
			},
			changelog ={
				order = 99999,name = "Change Log",type = "group",
				args={
					changes  = {
						order = 1,
						type = "string",
						width = "full",
						name = self.changeLog,
					}
			
				},
			},
			general={
				order = 1,name = L["General"],type = "group",
				args={
					
					lock = {
						order = 0.1,name = L["Lock frames"],type = "toggle",
						set = function(info,val) self.db.profile.locked = not self.db.profile.locked; self:UpdateMovers(); self:UnlockCooldownLine(); self:UnlockCastBars(); end,
						get = function() return self.db.profile.locked end
					},
					test_bars = {
						type = 'execute',
						order = 0.2,
						name = L['Test bars'],
						func = function(info, value)
							self:TestBars();
							self:TestCastBars();
						end,
					},
					show_more_buttons = {
						order = 0.3,name = L["Move Buttons"],type = "toggle",
						set = function(info,val) self.db.profile.show_more_buttons = not self.db.profile.show_more_buttons; self:UpdateMoverPosition() end,
						get = function() return self.db.profile.show_more_buttons end
					},
			
					minimap = {
						order = 1,name = L["Show minimap"],type = "toggle", width = 'full',
						set = function(info,val) self.db.profile.minimap.hide = not self.db.profile.minimap.hide; AleaUI_GUI.GetMinimapButton(addon):Update(self.db.profile.minimap) end,
						get = function(info) return self.db.profile.minimap.hide end
					},
					show_item_id_tooltip = {
						order = 1.01, name = L["Show ItemID"], desc = L["Tooltips now show ItemID"], type = "toggle",
						set = function(info,val) self.db.profile.show_item_spellid = not self.db.profile.show_item_spellid; end,
						get = function(info) return self.db.profile.show_item_spellid end
					},
					show_spell_id_tooltip = {
						order = 1.01, name = L["Show SpellID"], desc = L["Tooltips now show SpellID"], type = "toggle",
						set = function(info,val) self.db.profile.show_spellid_tooltip = not self.db.profile.show_spellid_tooltip; end,
						get = function(info) return self.db.profile.show_spellid_tooltip end					
					},
					spell_list_grouping = {
						order = 1.02, name = L["Grouping spell"], desc = L["Grouping similar spells settings"], type = "toggle",
						set = function(info,val) self.db.profile.spell_list_grouping = not self.db.profile.spell_list_grouping; end,
						get = function(info) return self.db.profile.spell_list_grouping end
					},

					hide_during_petbattle = {
						order = 1,name = L["Hide during PetBattle"],type = "toggle", width = "full",
						set = function(info,val) self.db.profile.hide_during_petbattle = not self.db.profile.hide_during_petbattle; end,
						get = function(info) return self.db.profile.hide_during_petbattle end
					},
					sound_channel = {
						order = 7,type = "dropdown",name = L["Sound Channel"],
						values = {
							["Master"] = "Master",
							["SFX"] = "SFX",
							["Ambience"] = "Ambience",
							["Music"] = "Music",
						},
						set = function(info,value) self.db.profile.sound_channel = value; end,
						get = function(info) return self.db.profile.sound_channel end,
					},
					
					global_style_settings = {
					
						type = "group",	order	= 10,
						embend = true,
						name	= L["Global Style Settings"],
						args = {
							statusbr = {
								order = 1,type = 'statusbar',name = L["Texture"],
							--	dialogControl = 'LSM30_Statusbar',
								values = LSM:HashTable("statusbar"),
								set = function(info,value) self.db.profile.global_statusbar = value; end,
								get = function(info) return self.db.profile.global_statusbar end,
							},
							statusbrcolor = {
								order = 2,name = L["Texture Color"],type = "color", hasAlpha = true,
								set = function(info,r,g,b,a) self.db.profile.global_statusbrcolor={r,g,b,a}; end,
								get = function(info)
									if self.db.profile.global_statusbrcolor then
										return self.db.profile.global_statusbrcolor[1],self.db.profile.global_statusbrcolor[2],self.db.profile.global_statusbrcolor[3],self.db.profile.global_statusbrcolor[4] 
									end
								end
							},
							statusbar_bg = {
								order = 2.1,type = 'statusbar',name = L["Background Texture"],
							--	dialogControl = 'LSM30_Statusbar',
								values = LSM:HashTable("statusbar"),
								set = function(info,value) self.db.profile.global_statusbar_bg = value; end,
								get = function(info) return self.db.profile.global_statusbar_bg end,
							},
							statusbrcolor_bg = {
								order = 2.2,name = L["Background Color"],type = "color", hasAlpha = true,
								set = function(info,r,g,b,a) self.db.profile.global_statusbrcolor_bg={r,g,b,a}; end,
								get = function(info)
									if self.db.profile.global_statusbrcolor_bg then
										return self.db.profile.global_statusbrcolor_bg[1],self.db.profile.global_statusbrcolor_bg[2],self.db.profile.global_statusbrcolor_bg[3],self.db.profile.global_statusbrcolor_bg[4] 
									end
								end
							},
							font = {
								order = 3,name = L["Font"],type = 'font',
							--	dialogControl = 'LSM30_Font',
								values = LSM:HashTable("font"),
								set = function(info,key) self.db.profile.global_font = key; end,
								get = function(info) return self.db.profile.global_font end,
							},
							font_color = {
								order = 4,name = L["Text color"],type = "color",
								set = function(info,r,g,b) self.db.profile.global_textcolor={r,g,b}; end,
								get = function(info)
									if self.db.profile.global_textcolor then
										return self.db.profile.global_textcolor[1],self.db.profile.global_textcolor[2],self.db.profile.global_textcolor[3],1 
									end
								end
							},
							font_size = {
								name = L["Size"],
								type = "slider",
								order	= 5,
								min		= 1,
								max		= 32,
								step	= 1,
								set = function(info,val) 
									self.db.profile.global_size = val
								end,
								get = function(info)
									return	self.db.profile.global_size
								end,
							},
							font_alpha = {
								name = L["Transparent"],
								type = "slider",
								order	= 6,
								min		= 0,
								max		= 1,
								step	= 0.1,
								set = function(info,val) 
									self.db.profile.global_alpha = val
								end,
								get = function(info)
									return	self.db.profile.global_alpha
								end,
							},
							fontflaggs = {
								type = "dropdown",	order = 6.1,
								name = L["Flags"],
								values = text_flaggs,
								set = function(info,val) 
									self.db.profile.global_flags = val
								end,
								get = function(info) return self.db.profile.global_flags end
							},
							
							shadowsettings = {
								type = "group",
								name = L["Font shadow"],
								order = 6.2, embend = true, args = {							
									font_shadow_color = {
										order = 1,name = L["Shadow color"] ,type = "color", hasAlpha = true,
										set = function(info,r,g,b,a) self.db.profile.global_font_shadow={r,g,b,a} end,
										get = function(info) 
											local color = self.db.profile.global_font_shadow or { 0, 0, 0, 1}
											
										return color[1],color[2],color[3],color[4] end
									},
									font_shadow_offset_x = {
										name = L["Shadow offset X"],
										type = "slider",
										order	= 2,
										min		= -10,
										max		= 10,
										step	= 0.1,
										set = function(info,val)
											if not self.db.profile.global_font_shadow_offset then self.db.profile.global_font_shadow_offset = {} end

											self.db.profile.global_font_shadow_offset[1] = val
										end,
										get = function(info)
											return self.db.profile.global_font_shadow_offset and self.db.profile.global_font_shadow_offset[1] or 0
										end,
									},

									font_shadow_offset_y = {
										name = L["Shadow offset Y"],
										type = "slider",
										order	= 3,
										min		= -10,
										max		= 10,
										step	= 0.1,
										set = function(info,val) 
											self.db.profile.global_font_shadow_offset[2] = val
										end,
										get = function(info)
											return self.db.profile.global_font_shadow_offset[2]
										end,
									},
								},
							},

							border = {
								order = 7,type = 'border',name = L["Border Texture"],
							--	dialogControl = 'LSM30_Border',
								values = LSM:HashTable("border"),
								set = function(info,value) self.db.profile.global_border = value; end,
								get = function(info) return self.db.profile.global_border end,
							},
							bordercolor = {
								order = 8,name = L["Border Color"],type = "color", hasAlpha = true,
								set = function(info,r,g,b,a) self.db.profile.global_bordercolor={r,g,b,a}; end,
								get = function(info)
									if self.db.profile.global_bordercolor then
										return self.db.profile.global_bordercolor[1],self.db.profile.global_bordercolor[2],self.db.profile.global_bordercolor[3],self.db.profile.global_bordercolor[4] 
									end
								end
							},
							bordersize = {
								name = L["Border Size"],
								desc = L["Set Border Size"],
								type = "slider",
								order	= 9,
								min		= 0,
								max		= 32,
								step	= 1,
								set = function(info,val) 
									self.db.profile.global_bordersize = val
								end,
								get =function(info)
									return self.db.profile.global_bordersize
								end,
							},							
							borderinset = {
								name = L["Border Inset"],
								desc = L["Set Border Inset"],
								type = "slider",
								order	= 10,
								min		= 0,
								max		= 32,
								step	= 1,
								set = function(info,val) 
									self.db.profile.global_borderinset = val
								end,
								get =function(info)
									return self.db.profile.global_borderinset
								end,
							},
							apply = {
								type = 'execute',
								order = -1,
								name = APPLY,
								func = function(info, value)
									self:GlobalStyleUpdate()
								end,
							},
						},
					},
					
				}
			},
			bars={
				order = 2,name = L["Bars"],type = "group", expand = true,
				args={
							bar_module_enabled = {
								order = 1,name = L["Enabled"],type = "toggle", width = "full",
								set = function(info,val) self.db.profile.bar_module_enabled = not self.db.profile.bar_module_enabled; self:UpdateStatusBars(); self:CoreBarsStatusUpdate() end,
								get = function(info) return self.db.profile.bar_module_enabled end
							},
							show_marks = {
								order = 1.1,name = L["Show raid marks"],type = "toggle",
								set = function(info,val) self.db.profile.show_mark = not self.db.profile.show_mark; end,
								get = function(info) return self.db.profile.show_mark end
							},
							doswap = {
								order = 1.2,name = L["Swap bars when change target"],type = "toggle", width = "full",
								set = function(info,val) 
									self.db.profile.doswap = not self.db.profile.doswap; 
									
									if self.options.args.bars.args.ClassSpells.args.offtargetanchor then
								--		self.options.args.bars.args.ClassSpells.args.offtargetanchor.disabled = not self.db.profile.doswap
									end
								end,
								get = function(info) return self.db.profile.doswap end
							},
							procsFilters = {
								order = 1.3,name = L["Hide auras from"].." '"..L["Procs"].."'",type = "toggle", width = "full",
								set = function(info,val) self.db.profile.procsFiltersoff = not self.db.profile.procsFiltersoff; end,
								get = function(info) return self.db.profile.procsFiltersoff end
							},
							othersFilters = {
								order = 1.4,name = L["Hide auras from"].." '"..L["Other List"].."'",type = "toggle", width = "full",
								set = function(info,val) self.db.profile.othersFiltersoff = not self.db.profile.othersFiltersoff; end,
								get = function(info) return self.db.profile.othersFiltersoff end
							},
							classlistFiltersoff = {
								order = 1.5,name = L["Hide auras from"].." '"..L["Class Spells"].."'",type = "toggle", width = "full",
								set = function(info,val) self.db.profile.classlistFiltersoff = not self.db.profile.classlistFiltersoff; end,
								get = function(info) return self.db.profile.classlistFiltersoff end
							},
							
							background_fading = {
								order = 1.6,name = L["Background fading"],type = "toggle",
								set = function(info,val) self.db.profile.background_fading = not self.db.profile.background_fading; end,
								get = function(info) return self.db.profile.background_fading end
							},
							back_bar_color = {
								order = 1.7,name = L["Bar color for background"],type = "toggle",
								set = function(info,val) self.db.profile.back_bar_color = not self.db.profile.back_bar_color; self:UpdateBackgroundBarColor(); end,
								get = function(info) return self.db.profile.back_bar_color end
							},
							
							ignore_custom_colors = {
								order = 1.8,type = 'toggle',name = L["Ignore custom colors"],
								set = function(info,val) self.db.profile.ignore_custom_color = not self.db.profile.ignore_custom_color; self:UpdateBackgroundBarColor(); end,
								get = function(info) return self.db.profile.ignore_custom_color end
							},
							
							shine_on_apply = {
								order = 1.8,type = 'toggle',name = L["Shine on apply"],
								set = function(info,val) self.db.profile.shine_on_apply = not self.db.profile.shine_on_apply; end,
								get = function(info) return self.db.profile.shine_on_apply end
							},
							
							bar_smooth = {
								order = 2,
								type = "group",
								embend = true,
								name	= L["Smooth bar"],
								args = {
									
									bar_smooth = {
										order = 2,name = L["Enabled"],type = "toggle", disabled = false,
										set = function(info,val) self.db.profile.bar_smooth = not self.db.profile.bar_smooth; end,
										get = function(info) return self.db.profile.bar_smooth end
									},
									bar_smooth_value = {
										name = L["Smooth bar speed"], disabled = false,
										type = "slider",
										width = "halp",
										order	= 3,
										min		= 1,
										max		= 20,
										step	= 1,
										set = function(info,val) 
											self.db.profile.bar_smooth_value_v2 = val
										end,
										get =function(info)
											return self.db.profile.bar_smooth_value_v2
										end,
									},
								},
							},

							
							pandemias = {
								order = 3.2 ,name = L["Pandemia"],type = "group", embend = true,
								args={
							
									show_pandemia_bp = {
										order = 1,name = L["Show pandemia breakpoint"],type = "toggle",
										set = function(info,val) self.db.profile.show_pandemia_bp = not self.db.profile.show_pandemia_bp; end,
										get = function(info) return self.db.profile.show_pandemia_bp end
									},

									pandemia_bp_style = {
										order = 2,type = "dropdown",name = L["Pandemia breakpoint style"],
										values = {
											L["Tick"],
											L["Overlay"],
										},
										set = function(info,value) self.db.profile.pandemia_bp_style = value; end,
										get = function(info) 
											return self.db.profile.pandemia_bp_style or 2						
										end,
									},
								},
							},
							
							ticks_opts = {
								order = 3.3,
								type = "group",
								embend = true,
								name	= L["Ticks1"],
								args = {
									
									showonlynext = {
										order = 3.4,name = L["Show only next tick"],type = "toggle", width = "full",
										set = function(info,val) self.db.profile.showonlynext = not self.db.profile.showonlynext; end,
										get = function(info) return self.db.profile.showonlynext end
									},
									hide_dot_ticks = {
										order = 3.5,name = L["Hide dot ticks"],type = "toggle",
										set = function(info,val) self.db.profile.hide_dot_ticks = not self.db.profile.hide_dot_ticks; end,
										get = function(info) return self.db.profile.hide_dot_ticks end						
									},
									ticksfade = {
										order = 3.6,name = L["Hide passed tick"],type = "toggle",
										set = function(info,val) self.db.profile.ticksfade = not self.db.profile.ticksfade; end,
										get = function(info) return self.db.profile.ticksfade end
									},
									tick_count_on_stacks = {
										order = 3.7,name = L["Tick count as stack text"],type = "toggle", width = "full",
										set = function(info,val) self.db.profile.tick_count_on_stacks = not self.db.profile.tick_count_on_stacks; end,
										get = function(info) return self.db.profile.tick_count_on_stacks end
									},
								},
							},
							engageThrottle = {
								name = L["Engage Throttle"],
								desc = L["Engage Throttle Desc"],
								type = "slider",
								order	= 3.7,
								min		= 1,
								max		= 60,
								step	= 1,
								set = function(info,val) 
									self.db.profile.engageThrottle = val
								end,
								get =function(info)
									return self.db.profile.engageThrottle
								end,
							},
				
							throttleOutCombat = {
								name = L["Out Of Combat Throttle"],
								desc = L["Out Of Combat Throttle Desc"],
								type = "slider",
								order	= 3.8,
								min		= 5,
								max		= 30,
								step	= 1,
								set = function(info,val) 
									self.db.profile.throttleOutCombat = val
								end,
								get =function(info)
									return self.db.profile.throttleOutCombat
								end,
							},
							
							adapttoonemax = {
								type = "group",	order	= 10,
								embend = true,
								name	= L["Adapt to one maximum"],
								args = {
	
									adapttoonemax = {
										order = 10,name = L["Enabled"],type = "toggle", width = "full",
										set = function(info,val) self.db.profile.adapttoonemax = not self.db.profile.adapttoonemax; end,
										get = function(info) return self.db.profile.adapttoonemax end
									},
									maximumtime = {
										order = 11,name = L["Maximum time"],type = "toggle",
										set = function(info,val) self.db.profile.maximumtime = not self.db.profile.maximumtime; end,
										get = function(info) return self.db.profile.maximumtime end
									},
									maximumtime_value = {
										type = "editbox",	order	= 12,
										name = L["Maximum time"],
										set = function(info,val)
											local num = tonumber(val)
											if num then
												self.db.profile.maximumtime_value = num
											end	
										end,
										get = function(info) return self.db.profile.maximumtime_value and tostring(self.db.profile.maximumtime_value) or "30" end
									},
								},
							},
	
							delayfading = {
							
								type = "group",	order	= 16,
								embend = true,
								name	= L["Delay timer fading"],
								args = {
									delayfading = {
										order = 1,name = L["Enabled"],type = "toggle", width = "full",
										set = function(info,val) self.db.profile.delayfading = not self.db.profile.delayfading; end,
										get = function(info) return self.db.profile.delayfading end
									},

									delayfading_wait = {
										name = L["Delay start fading"],
										type = "slider",
										order	= 16.1,
										min		= 0.2,
										max		= 1.5,
										step	= 0.1,
										set = function(info,val) 
											self.db.profile.delayfading_wait = val
											self:updateSortings()
										end,
										get =function(info)
											return self.db.profile.delayfading_wait or 0.5
										end,
									},
								
									delayfading_outanim = {
										name = L["Timer fading duration"],
										type = "slider",
										order	= 16.2,
										min		= 0.1,
										max		= 1,
										step	= 0.1,
										set = function(info,val) 
											self.db.profile.delayfading_outanim = val
											self:updateSortings()
										end,
										get =function(info)
											return self.db.profile.delayfading_outanim or 0.3
										end,
									},
								},
							},
							UnitFilter = {		
								type = "group",	order	= 1.9,
								embend = true,
								name	= L["Unit Filter"],
								args = {
									enabled = {
										order = 1,name = L["Enabled"],type = "toggle", width = "full", desc = L["Target Type"].." "..L["should be "]..L["multi"].." "..L["or"].." "..L["auto"],
										set = function(info,val) self.db.profile.unit_filter_enabled = not self.db.profile.unit_filter_enabled; end,
										get = function(info) return self.db.profile.unit_filter_enabled end
									},
									unit = {
										name = L["Unit"],
										order = 2,
									--	desc = L["Select Anchor offtarget Desc"].." ->'"..L["General"].."'->'"..L["Swap bars when change target"].."'",
										type = "dropdown",
										values = function()
											local t = {}
											for k,v in pairs(self.db.profile.unit_filters) do						
												if v then
													t[k] = "|cFF0eed28"..k.."|r"
												else
													t[k] = "|cFFff5c5c"..k.."|r"
												end									
											end				
											return t
										end,
										set = function(info,val)
											unit_filter_set = val
										end,
										get = function(info, val)
											return unit_filter_set
										end
									},					
									enabled_unit = { -- unit_filter_set
										order = 3,name = L["Show"],type = "toggle",
										set = function(info,val) 
											if unit_filter_set then 
												self.db.profile.unit_filters[unit_filter_set] = not self.db.profile.unit_filters[unit_filter_set]; 
											end
										end,
										get = function(info)
											return self.db.profile.unit_filters[unit_filter_set]
										end
									},
								}
							},
					style = {
						type = "group",	order	= 1,
						name	= L["Style"],						
						args={
							CreateNew = {
								type = 'execute',
								--width = "half",
								order = 1,
								name = L['Add New Anchor'],
								func = function(info, value) 
									C:CreateNewAnhors()					
								end,
								},
							Anchor = {
								name = L["Select Anchor"],
								order = 1,
								desc = L["Select Anchor Desc"],
								type = "dropdown",						
								values = function()
									local t = {}
									
									for k,v in ipairs(self.db.profile.bars_anchors) do						
										t[k] = v.name or k
									end
									
									return t
								end,
								set = function(info,val)
									self:SetAnchorTable(val)
								end,
								get = function(info, val) 
									return anchor_value
								end
							},
						},
					},
					ClassSpells = {
						type = "group",	order	= 2,
						name	= L["Class Spells"],						
						args={
							Anchor = {
								name = L["Select Spell"],
								order = 2,
								desc = L["Select Spell"],
							--	width = "half",
								width = "full",
								showSpellTooltip = true,
								type = "dropdown",
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.classSpells[self.myCLASS]) do
										if not v.deleted and not v.fulldel and GetClassSpec(v.spec) then
											local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
											t[g_spellID or k] = g_spellName or SpellString(k, 10)
										end
									end								
									return t
								end,
								set = function(info,val)
									C:ClassSpell(val)
								end,
								get = function(info, val)
									return class_select
								end
							},
							AddNew = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Change spellID"],
								filterType = "Player_EditBox_SPTimer",
								
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "spell")
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then										
											C:SearchDBSpell(num, "class")
										end
									end	
								end,
								get = function(info) end
							},
							selectSpec = {
								name = L["Spec"],
								order = 1.1,
								desc = L["Spec"],
								type = "dropdown",
								values = SpecSelect,
								set = function(info,val)
									CHOSEN_CLASS_SPEC = val
								end,
								get = function(info, val)
									if not CHOSEN_CLASS_SPEC then CHOSEN_CLASS_SPEC = GetSpecialization() and ""..GetSpecialization().."" or ALL end							
									return CHOSEN_CLASS_SPEC
								end
							},							
						}, --done later
					},
					spellList2 = {
						type = "group",	order	= 3,
						name	= L["Procs"],						
						args={
							
							Anchor = {
								name = L["Select Spell"],
								order = 2,
								desc = L["Select Spell"],
							--	width = "half",
								width = "full",
								showSpellTooltip = true,
								type = "dropdown",
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.procSpells) do
										
										if not v.deleted and not v.fulldel and ProcFilter(v.role) and ProcFilter_Patch(v.patch) then
											local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
											t[g_spellID or k] = g_spellName or SpellString(k, 10)
										end
									end									
									return t
								end,
								set = function(info,val)
									C:ProcsSpell(val)
								end,
								get = function(info, val)
									return proc_select
								end
							},						
							selectProcFilter = {
								name = L["Filter"],
								order = 1.1,
								type = "multiselect",
								values = Role_Values_List,
								set = function(info, value)
									SetSelectProcFilter(value)
								end,
								get = function(info)
									return GetSelectProcFilter()
								end,
							},
							--[==[
							selectRole = {
								name = L["Role"],
								order = 1.1,
								type = "dropdown",
								values = RoleSelect,
								set = function(info,val)
									CHOSEN_ROLE = val
								end,
								get = function(info, val)
									if not CHOSEN_ROLE then CHOSEN_ROLE = GetRole() end								
									return CHOSEN_ROLE
								end
							},
							]==]
							AddNew = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Change spellID"],
								filterType = "Aura_EditBox_SPTimer",
								set = function(info,val)

									local num, tip = GetSpellOrItemID(val, "spell")
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then
											
											C:SearchDBSpell(num, "procs")
										end
									end	
								end,
								get = function(info)end
							},
						}, --done later
					  },
					spellList3 = {
						type = "group",	order	= 4,
						name	= L["Other List"],					
						args={
							Anchor = {
								name = L["Select Spell"],
								order = 2,
								desc = L["Select Spell"],
							--	width = "half",
								width = "full",
								showSpellTooltip = true,
								type = "dropdown",
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.othersSpells) do
										if not v.deleted and not v.fulldel then
											local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
											t[g_spellID or k] = g_spellName or SpellString(k, 10)
										end
									end								
									return t
								end,
								set = function(info,val)
									C:OthersSpell(val)
								end,
								get = function(info, val)
									return others_select
								end
							},
							AddNew = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Change spellID"],
								
								filterType = "Spell_EditBox_SPTimer",
								
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "spell")
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then										
											C:SearchDBSpell(num, "others")
										end
									end	
								end,
								get = function(info) end
							},
						}, --done later
					  },
					  spellList4 = {
						type = "group",	order	= 5,
						name	= L["Cooldowns"],					
						args={							
							Anchor = {
								name = L["Select Spell"],
								order = 2,
								desc = L["Select Spell"],
							--	width = "half",
								width = "full",
								showSpellTooltip = true,
								type = "dropdown",
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.bars_cooldowns[C.myCLASS] or {}) do
										if not v.deleted and not v.fulldel then
											t[k] = SpellString(k, 10, nil, true)
										end
									end								
									return t
								end,
								set = function(info,val)
									C:BarCooldownSpell(val)
								end,
								get = function(info, val)
									return bar_cooldown_select
								end
							},
							AddNew = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Change spellID"],
								filterType = "Player_EditBox_SPTimer",
								
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "spell")									
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then										
											C:SearchDBSpell(num, "bar_cooldowns")
										end
									end	
								end,
								get = function(info) end
							},
						},
					},
				}
			},
			coolline = {
				order = 3,name = L["Coolline"],type = "group", expand = true,
				args={
					ICD = {
						type = "group",	order	= 2,
						name	= L["ICD"],						
						args={						
							Anchor = {
								name = L["Select Spell"],
								order = 2,
								desc = L["Select Spell"],
								width = "full",
							--	width = "half",
								showSpellTooltip = true,
								type = "dropdown",
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.internal_cooldowns) do						
										t[k] = SpellString(v.spellid, 10)
									end								
									return t
								end,
								set = function(info,val)
									C:ICooldown(val)
								end,
								get = function(info, val)
									return ICD_select
								end
							},
							AddNew = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Change spellID"],
								filterType = "Aura_EditBox_SPTimer",
								
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "spell")
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then
											if not self.db.profile.internal_cooldowns then self.db.profile.internal_cooldowns = {} end											
											if not self.db.profile.internal_cooldowns[spellname] then self.db.profile.internal_cooldowns[spellname] = {} end
											
											self.db.profile.internal_cooldowns[spellname].spellid = num
											C:ICooldown(spellname)
										end
									end	
								end,
								get = function(info) end
							},	
						
						},
					},
					Debuffs = {
						type = "group",	order	= 2,
						name	= L["Auras"],						
						args={						
							Anchor = {
								name = L["Select Spell"],
								order = 2,
								desc = L["Select Spell"],
								width = "full",
							--	width = "half",
								showSpellTooltip = true,
								type = "dropdown",
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.auras_cooldowns[self.myCLASS]) do						
										t[k] = SpellString(v.spellid, 10)
									end								
									return t
								end,
								set = function(info,val)
									C:AuraCooldown(val)
								end,
								get = function(info, val)
									return AuraCD_select
								end
							},
							AddNew = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Change spellID"],
								filterType = "Aura_EditBox_SPTimer",
								
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "spell")
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then
											if not self.db.profile.auras_cooldowns[self.myCLASS] then self.db.profile.auras_cooldowns[self.myCLASS] = {} end											
											if not self.db.profile.auras_cooldowns[self.myCLASS][spellname] then self.db.profile.auras_cooldowns[self.myCLASS][spellname] = {} end
											
											self.db.profile.auras_cooldowns[self.myCLASS][spellname].spellid = num
											C:AuraCooldown(spellname)
										end
									end	
								end,
								get = function(info) end
							},	
						
						},
					},
					ClassSpells = {
						type = "group",	order	= 3,
						name	= L["Class CD"],						
						args={						
							Anchor = {
								name = L["Select Spell"],
								order = 2,
								desc = L["Select Spell"],
								type = "dropdown",
								width = "full",
								showSpellTooltip = true,
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.classCooldowns[self.myCLASS]) do
										if v.spellid then
											t[k] = SpellString(v.spellid, 10)
										end
									end								
									return t
								end,
								set = function(info,val)
									C:Cooldown(val)
								end,
								get = function(info, val)
									return cooldown_select
								end
							},
							AddNew = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Change spellID"],
								filterType = "Player_EditBox_SPTimer",
							
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "spell")
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then
											if not self.db.profile.classCooldowns[C.myCLASS] then self.db.profile.classCooldowns[C.myCLASS] = {} end											
											if not self.db.profile.classCooldowns[C.myCLASS][spellname] then self.db.profile.classCooldowns[C.myCLASS][spellname] = {} end
											
											self.db.profile.classCooldowns[self.myCLASS][spellname].spellid = num
											
											C:Cooldown(spellname)
										end
									end	
								end,
								get = function(info) end
							},						
						},
					},
					BanCooldown = {
						type = "group",	order	= 4,
						name	= L["Other List"],
						args = {
							Anchor = {
								name = L["Select CD"],
								order = 3,
								type = "dropdown",
								width = "full",
								values = function()
									local t = {}												
									for k,v in pairs(self.db.profile.cooldownline.blockList) do
										if not v.deleted and not v.fulldel then
											local lineName = ''
											if v.spellid and GetSpellInfo(v.spellid) then
												lineName = GetSpellInfo(v.spellid)
											elseif v.itemid and GetItemInfo(v.itemid) then
												lineName = GetItemInfo(v.itemid)
											end
											
											if v.hide then
												t[k] = "|cFFff5c5c"..lineName.."|r"
											else
												t[k] = "|cFF0eed28"..lineName.."|r"
											end
										end
									end								
									return t
								end,
								set = function(info,val)
									blocklist_select = val
								end,
								get = function(info, val)
									return blocklist_select
								end
							},
							AddNewSpellID = {
								type = "spellloader",	order	= 1,
								name = L["Spell ID"],
								desc = L["Add new spellID"],
								filterType = "Spell_EditBox_SPTimer",
								
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "spell")
									if num then
										local spellname = GetSpellInfo(num)										
										if spellname then											
											self.db.profile.cooldownline.blockList['spell:'..num] = { spellid = num, hide = true }
											
											C:BuildCooldownBlockList()
											blocklist_select = 'spell:'..num
										end
									end	
								end,
								get = function(info) end
							},
							AddNewItem = {
								type = "spellloader",	order	= 2,
								name = L["Item ID"],
								desc = L["Add new ItemID"],
								filterType = 'Disabled',
								set = function(info,val)
									local num, tip = GetSpellOrItemID(val, "item")
									
								--	print(num, tip, val)
									
									if num then
										local itemname = GetItemInfo(num)										
										if itemname then											
											self.db.profile.cooldownline.blockList['item:'..num] = { itemid = num, hide = true }
											
											C:BuildCooldownBlockList()
											blocklist_select = 'item:'..num
										end
									end	
								end,
								get = function(info) end
							},
							enabled = {
								order = 4,name = L["Hide"],type = "toggle" ,
								set = function(info,val) 
									if blocklist_select then
										self.db.profile.cooldownline.blockList[blocklist_select].hide = not self.db.profile.cooldownline.blockList[blocklist_select].hide
									end
								end,
								get = function(info)
									if not blocklist_select then return nil end
									
							--		print(blocklist_select)
									
									return self.db.profile.cooldownline.blockList[blocklist_select] and self.db.profile.cooldownline.blockList[blocklist_select].hide or false
								
								end
							},
							annonce = {
								order = 5,name = L["Reporting"], type = "toggle",
								desc = L["Turn on/off spell cooldown report"],
								set = function(info,val) 
									if blocklist_select then 
										self.db.profile.cooldownline.blockList[blocklist_select].reporting  = not self.db.profile.cooldownline.blockList[blocklist_select].reporting 
									end
								end,
								get = function(info) 
									if not blocklist_select then return nil end
									return self.db.profile.cooldownline.blockList[blocklist_select] and self.db.profile.cooldownline.blockList[blocklist_select].reporting or false 
									
								end
							},
							hide_splash = {
								order = 5.1,name = L["Forced big splash"], type = "toggle", desc = L["Force big splash Desc"],
								set = function(info,val)
									if blocklist_select then 
										self.db.profile.cooldownline.blockList[blocklist_select].hide_splash = not self.db.profile.cooldownline.blockList[blocklist_select].hide_splash 
									end
								end,
								get = function(info)
									if not blocklist_select then return nil end
									return self.db.profile.cooldownline.blockList[blocklist_select] and self.db.profile.cooldownline.blockList[blocklist_select].hide_splash or false
								end
							},
							SoundFile = {					
								type = "group",	order	= 6,
								embend = true,
								name	= L["Sound"],
								args = {						
									OnShow = {
										order = 1,type = 'sound',name = L["On Show"],
									--	dialogControl = 'LSM30_Sound',
										values = LSM:HashTable("sound"),
										set = function(info,value) 
											if blocklist_select then 
												self.db.profile.cooldownline.blockList[blocklist_select].sound_onshow = value
											end
										end,
										get = function(info) 
											if not blocklist_select then return "None" end
											return self.db.profile.cooldownline.blockList[blocklist_select] and self.db.profile.cooldownline.blockList[blocklist_select].sound_onshow or "None"; 
										end,
									},
									OnHide = {
										order = 1,type = 'sound',name = L["On Hide"],
									--	dialogControl = 'LSM30_Sound',
										values = LSM:HashTable("sound"),
										set = function(info,value) 
											if blocklist_select then
												self.db.profile.cooldownline.blockList[blocklist_select].sound_onhide = value 
											end
										end,
										get = function(info) 
											if not blocklist_select then return "None" end
											return self.db.profile.cooldownline.blockList[blocklist_select] and self.db.profile.cooldownline.blockList[blocklist_select].sound_onhide or "None";
										end,
									},
								}
							},
							delete = {
								type = 'execute',
								order = -1,
								name = L['SemiDelete'],
								desc = L['SemiDelDesc'],
								func = function(info, value)
									if self.db.profile.cooldownline.blockList[blocklist_select] then
										self.db.profile.cooldownline.blockList[blocklist_select].deleted = true
									end
									blocklist_select = nil								
								end,
							},
							fulldelete = {
								type = 'execute',
								order = -1,
								name = L['Full delete'],
								desc = L['FullDelDesc'],
								func = function(info, value)
									if self.db.profile.cooldownline.blockList[blocklist_select] then
										self.db.profile.cooldownline.blockList[blocklist_select].fulldel = true
									end
									blocklist_select = nil								
								end,
							},
						},
					},
					--[[
					desc1 = {
						type = "header",
						name = "",
						order = 1,
					},
					]]
					enabled = {
						order = 2,name = L["Enabled"],type = "toggle",
						set = function(info,val) self.db.profile.cooldownline.enabled = not self.db.profile.cooldownline.enabled; self.UpdateSettings() end,
						get = function(info) return self.db.profile.cooldownline.enabled end
					},
					hide_cooldown_line = {
						order = 2.1,name = L["Hide"],desc = L["Only Hide cooldown line, so big cooldown spash will continue to work"], type = "toggle",
						set = function(info,val) self.db.profile.cooldownline.hide_cooldown_line = not self.db.profile.cooldownline.hide_cooldown_line; self.UpdateSettings()end,
						get	= function(info) return self.db.profile.cooldownline.hide_cooldown_line end
					},
					enabled_mouse_events = {
						order = 2.11,name = L["Enable mouse events"],type = "toggle" ,
						set = function(info,val) self.db.profile.cooldownline.mouse_events = not self.db.profile.cooldownline.mouse_events; self.UpdateSettings() end,
						get = function(info) return self.db.profile.cooldownline.mouse_events end
					},
					
					hide_fail = {
						order = 2.2,name = L["Hide fail glow"],type = "toggle",
						set = function(info,val) self.db.profile.cooldownline.hidefail = not self.db.profile.cooldownline.hidefail; self.UpdateSettings() end,
						get = function(info) return self.db.profile.cooldownline.hidefail end
						},
					minimal_time_to_fade = {	
						name = L["Minimum time to fading"],
						type = "slider",
						order	= 2.22,
						min		= 0,
						max		= 10,
						step	= 1,
						set = function(info,val) 
							self.db.profile.cooldownline.minimal_time_to_fade = val
						end,
						get =function(info)
							return self.db.profile.cooldownline.minimal_time_to_fade
						end,
					
					},
					tooltip = {
					
						type = "group",	order	= 2.21,
						embend = true,
						name	= L["Tooltip"],
						args = {
							show_tooltip = {
								order = 1,name = L["Show"],type = "toggle",
								set = function(info,val) self.db.profile.cooldownline.show_tooltip = not self.db.profile.cooldownline.show_tooltip end,
								get	= function(info) return self.db.profile.cooldownline.show_tooltip end
							},
							tooltip_anchor_to = {
										name = L["Position"],
										order = 2.21,
										type = "dropdown",
										values = {
											L["TOP"],
											L["BOTTOM"],
											L["LEFT"],
											L["RIGHT"],
										},
										set = function(info,val)
											self.db.profile.cooldownline.tooltip_anchor_to = val
											self:UpdateTooltip()
										end,
										get = function(info, val)
											return self.db.profile.cooldownline.tooltip_anchor_to
										end
									},
							tooltip_anchor_to_frame = {
										name = L["Select Anchor"],
										order = 2.22,
										type = "dropdown",
										values = {
											L["ICON"],
											L["LINE"],
										},
										set = function(info,val)
											self.db.profile.cooldownline.tooltip_anchor_to_frame = val
											self:UpdateTooltip()
										end,
										get = function(info, val)
											return self.db.profile.cooldownline.tooltip_anchor_to_frame
										end
									},

							tooltip_anchor_gap = {
								name = L["Gap"],
								type = "slider",
								order	= 3,
								min		= -400,
								max		= 400,
								step	= 1,
								set = function(info,val) 
									self.db.profile.cooldownline.tooltip_anchor_gap = val
									self:UpdateTooltip()
								end,
								get =function(info)
									return self.db.profile.cooldownline.tooltip_anchor_gap
								end,
							
							
							}
						}
					},
					player_color_group = {
					
						type = "group",	order	= 2.3,
						embend = true,
						name	= L["Player"],
						args = {
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 1, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.pla_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.pla_color[1],self.db.profile.cooldownline.pla_color[2],self.db.profile.cooldownline.pla_color[3],1 end
								},
								toggleOpts1 = {
									order = 2,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hideplay = not self.db.profile.cooldownline.hideplay; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hideplay end
								},
								toggleOpts2 = {
									order = 3,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.player_reporting = not self.db.profile.cooldownline.player_reporting end,
									get = function(info) return self.db.profile.cooldownline.player_reporting end
								},
							},
						},
					},
					
					pet_color_group = {
					
						type = "group",	order	= 2.4,
						embend = true,
						name	= L["Pet"],
						args = {
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 5, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.pet_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.pet_color[1],self.db.profile.cooldownline.pet_color[2],self.db.profile.cooldownline.pet_color[3],1 end
								},
								toggleOpts1 = {
									order = 6,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hidepet = not self.db.profile.cooldownline.hidepet; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hidepet end
								},
								toggleOpts2 = {
									order = 7,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.pet_reporting = not self.db.profile.cooldownline.pet_reporting end,
									get = function(info) return self.db.profile.cooldownline.pet_reporting end
								},
							},
						},
					},
					
					bag_color_group = {
					
						type = "group",	order	= 2.5,
						embend = true,
						name	= L["Bags"],
						args = {
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 7, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.bag_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.bag_color[1],self.db.profile.cooldownline.bag_color[2],self.db.profile.cooldownline.bag_color[3],1 end
									},
								toggleOpts1 = {
									order = 8,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hidebag = not self.db.profile.cooldownline.hidebag; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hidebag end
									},
								toggleOpts2 = {
									order = 9,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.bag_reporting = not self.db.profile.cooldownline.bag_reporting end,
									get = function(info) return self.db.profile.cooldownline.bag_reporting end
								},
							},
						},
					},
					
					inv_color_group = {
					
						type = "group",	order	= 2.6,
						embend = true,
						name	= L["Equipped Items"],
						args = {							
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 9, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.inv_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.inv_color[1],self.db.profile.cooldownline.inv_color[2],self.db.profile.cooldownline.inv_color[3],1 end
									},
								toggleOpts1 = {
									order = 10,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hideinv = not self.db.profile.cooldownline.hideinv; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hideinv end
									},
								toggleOpts2 = {
									order = 11,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.inv_reporting = not self.db.profile.cooldownline.inv_reporting end,
									get = function(info) return self.db.profile.cooldownline.inv_reporting end
								},
							},
						},
					},
					
					veh_color_group = {
					
						type = "group",	order	= 2.7,
						embend = true,
						name	= L["Vehicle"],
						args = {
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 11, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.veh_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.veh_color[1],self.db.profile.cooldownline.veh_color[2],self.db.profile.cooldownline.veh_color[3],1 end
									},
								toggleOpts1 = {
									order = 12,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hidevehi = not self.db.profile.cooldownline.hidevehi; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hidevehi end
									},
								toggleOpts2 = {
									order = 13,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.veh_reporting = not self.db.profile.cooldownline.veh_reporting end,
									get = function(info) return self.db.profile.cooldownline.veh_reporting end
								},
							},
						},
					},
					
					icd_color_group = {
					
						type = "group",	order	= 2.8,
						embend = true,
						name	= L["Internal cd"],
						args = {
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 13, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.inter_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.inter_color[1],self.db.profile.cooldownline.inter_color[2],self.db.profile.cooldownline.inter_color[3],1 end
									},
								toggleOpts1 = {
									order = 14,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hideinternal = not self.db.profile.cooldownline.hideinternal; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hideinternal end
									},
								toggleOpts2 = {
									order = 15,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.icd_reporting = not self.db.profile.cooldownline.icd_reporting end,
									get = function(info) return self.db.profile.cooldownline.icd_reporting end
								},
							},
						},
					},
					
					aura_buff_color_group = {
					
						type = "group",	order	= 2.8,
						embend = true,
						name	= L["Buff"],
						args = {						
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 13, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.aura_cd_buff_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.aura_cd_buff_color[1],self.db.profile.cooldownline.aura_cd_buff_color[2],self.db.profile.cooldownline.aura_cd_buff_color[3],1 end
									},
								toggleOpts1 = {
									order = 14,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hidaurabuffs = not self.db.profile.cooldownline.hidaurabuffs; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hidaurabuffs end
									},
								toggleOpts2 = {
									order = 15,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.aura_cd_buff_reporting = not self.db.profile.cooldownline.aura_cd_buff_reporting end,
									get = function(info) return self.db.profile.cooldownline.aura_cd_buff_reporting end
								},
							},
						},
					},
					
					aura_debuff_color_group = {
					
						type = "group",	order	= 2.8,
						embend = true,
						name	= L["Debuff"],
						args = {
							prototype1 = {
								order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
								width = 'full',
								set = function() end, 
								get = function() end,
								
								colorOpts = {
									order = 13, name = L["Color"],type = "color", hasAlpha = false, width = "half",
									set = function(info,r,g,b) self.db.profile.cooldownline.aura_cd_debuff_color={r,g,b}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.aura_cd_debuff_color[1],self.db.profile.cooldownline.aura_cd_debuff_color[2],self.db.profile.cooldownline.aura_cd_debuff_color[3],1 end
									},
								toggleOpts1 = {
									order = 14,name = L["Hide"],type = "toggle", width = "half",
									set = function(info,val) self.db.profile.cooldownline.hidauradebuffs = not self.db.profile.cooldownline.hidauradebuffs; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hidauradebuffs end
									},
								toggleOpts2 = {
									order = 15,name = L["Reporting"], type = "toggle", width = "half",
									desc = L["Turn on/off spell cooldown report"],
									set = function(info,val) self.db.profile.cooldownline.aura_cd_debuff_reporting = not self.db.profile.cooldownline.aura_cd_debuff_reporting end,
									get = function(info) return self.db.profile.cooldownline.aura_cd_debuff_reporting end
								},
							},
						},
					},
					
					cooldownline_style = {
						type = "group",	order	= 1,
						name	= L["Style"],
						args = {
							
						desc4 = {
							type = "group",
							name = L["Line config"],
							order = 15,
							embend = true,
							args = {							
								reversed = {
									order = 16,name = L["Reverse"],type = "toggle",
									set = function(info,val) self.db.profile.cooldownline.reverse = not self.db.profile.cooldownline.reverse; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.reverse end
								},

								custom_text_timer = {
									type = "editbox",	order	= 17,
									name = L["Custom Text"],
									desc = L["Coolline Custom Text Desc"],
									set = function(info,val) 
										local num = tostring(val)				
										if num then
											self.db.profile.cooldownline.custom_text_timer = num
											self.UpdateSettings()
										end
									end,
									get = function(info) return tostring(self.db.profile.cooldownline.custom_text_timer) end
								},
								vertical = {
									order = 16,name = L["Vertical"],type = "toggle",
									set = function(info,val) self.db.profile.cooldownline.vertical = not self.db.profile.cooldownline.vertical; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.vertical end
								},
								
								hidelinetext = {
									order = 17.1,name = L["Hide line text"],type = "toggle",
									set = function(info,val) self.db.profile.cooldownline.hidelinetext = not self.db.profile.cooldownline.hidelinetext; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hidelinetext end
								},
								
								format_s = {
									name = L["Time format"],
									order = 18,
									desc = L["Select timer format Desc"],
									type = "dropdown",						
									values = cooldown_timer_format,
									set = function(info,val)
										 self.db.profile.cooldownline.fortam_s = val
									end,
									get = function(info, val) 
										return  self.db.profile.cooldownline.fortam_s
									end
								},			
								bg = {
									order = 19,type = 'statusbar',name = L["Main Texture"],
								--	dialogControl = 'LSM30_Statusbar',
									values = LSM:HashTable("statusbar"),
									set = function(info,value) self.db.profile.cooldownline.statusbar = value; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.statusbar end,
								},
								bg_color = {
									order = 20,name = L["Texture Color"],type = "color", hasAlpha = true,
									set = function(info,r,g,b,a) self.db.profile.cooldownline.bgcolor={r = r,g = g,b = b, a = a}; self.UpdateSettings()  end,
									get = function(info) return self.db.profile.cooldownline.bgcolor.r,self.db.profile.cooldownline.bgcolor.g,self.db.profile.cooldownline.bgcolor.b,self.db.profile.cooldownline.bgcolor.a end
								},
								hidestatusbar = {
									order = 20.1,name = L["Hide cd texture"],type = "toggle",
									set = function(info,val) self.db.profile.cooldownline.hidestatusbar = not self.db.profile.cooldownline.hidestatusbar; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.hidestatusbar end
								},
								w = {
									name = L["Width"],
									desc = L["Set bar Width"],
									type = "slider",
									order	= 21,
									min		= 1,
									max		= 1920,
									step	= 1,
									set = function(info,val) 
										self.db.profile.cooldownline.w = val
										self.UpdateSettings()
									end,
									get =function(info)
										return self.db.profile.cooldownline.w
									end,
								},
								h = {
									name = L["Height"],
									desc = L["Set bar Height"],
									type = "slider",
									order	= 22,
									min		= 1,
									max		= 32,
									step	= 1,
									set = function(info,val) 
										self.db.profile.cooldownline.h = val
										self.UpdateSettings()
									end,
									get =function(info)
										return self.db.profile.cooldownline.h
									end,
								},
								activealpha = {
									name = L["Active Alpha"],
									desc = L["Set alpha when cooldown line is active"],
									type = "slider",
									order	= 23,
									min		= 0,
									max		= 1,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.activealpha = val
										self.UpdateSettings()
									end,
									get =function(info)
										return self.db.profile.cooldownline.activealpha
									end,
								},
								inactivealpha = {
									name = L["Inactiv Alpha"],
									desc = L["Set alpha when cooldown line is inactive"],
									type = "slider",
									order	= 24,
									min		= 0,
									max		= 1,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.inactivealpha = val
										self.UpdateSettings()
									end,
									get =function(info)
										return self.db.profile.cooldownline.inactivealpha
									end,
								},
							
							},
							
						},
						borderDsk = {
							type = "group",
							name = L["Borders"],
							order = 25, embend = true,
							
							args = {
							
								border = {
									order = 26,type = 'border',name = L["Border Texture"],
								--	dialogControl = 'LSM30_Border',
									values = LSM:HashTable("border"),
									set = function(info,value) self.db.profile.cooldownline.border = value; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.border end,
								},
								bordersize = {
									name = L["Border Size"],
									desc = L["Set Border Size"],
									type = "slider",
									order	= 27,
									min		= 1,
									max		= 32,
									step	= 1,
									set = function(info,val) 
										self.db.profile.cooldownline.bordersize = val
										self.UpdateSettings()
									end,
									get =function(info)
										return self.db.profile.cooldownline.bordersize
									end,
								},
								bordercolor = {
									order = 28,name = L["Border Color"],type = "color", hasAlpha = true,
									set = function(info,r,g,b,a) self.db.profile.cooldownline.bordercolor={r = r,g = g,b = b, a = a}; self.UpdateSettings()  end,
									get = function(info) return self.db.profile.cooldownline.bordercolor.r,self.db.profile.cooldownline.bordercolor.g,self.db.profile.cooldownline.bordercolor.b,self.db.profile.cooldownline.bordercolor.a end
								},
								borderinset = {
									name = L["Border Inset"],
									desc = L["Set Border Inset"],
									type = "slider",
									order	= 29,
									min		= -32,
									max		= 32,
									step	= 1,
									set = function(info,val) 
										self.db.profile.cooldownline.borderinset = val
										self.UpdateSettings()
									end,
									get =function(info)
										return self.db.profile.cooldownline.borderinset
									end,
								},

							},
							},
							icon_backdrop = {
									type = "group",
									name = L["Icon"],
									order = 29.1, embend = true,
									args = {
										icon_border = {
											order = 29.2,type = 'border',name = L["Border Texture"],
										--	dialogControl = 'LSM30_Border',
											values = LSM:HashTable("border"),
											set = function(info,value) self.db.profile.cooldownline.icon_border = value; self.UpdateSettings() end,
											get = function(info) return self.db.profile.cooldownline.icon_border end,
										},
										icon_bordersize = {
											name = L["Border Size"],
											desc = L["Set Border Size"],
											type = "slider",
											order	= 29.3,
											min		= 1,
											max		= 32,
											step	= 1,
											set = function(info,val) 
												self.db.profile.cooldownline.icon_bordersize = val
												self.UpdateSettings()
											end,
											get =function(info)
												return self.db.profile.cooldownline.icon_bordersize
											end,
										},
										icon_bordercolor = {
											order = 29.4,name = L["Border Color"],type = "color", hasAlpha = true,
											set = function(info,r,g,b,a) self.db.profile.cooldownline.icon_bordercolor={r = r,g = g,b = b, a = a}; self.UpdateSettings()  end,
											get = function(info) return self.db.profile.cooldownline.icon_bordercolor.r,self.db.profile.cooldownline.icon_bordercolor.g,self.db.profile.cooldownline.icon_bordercolor.b,self.db.profile.cooldownline.icon_bordercolor.a end
										},
										icon_borderinset = {
											name = L["Border Inset"],
											desc = L["Set Border Inset"],
											type = "slider",
											order	= 29.5,
											min		= -32,
											max		= 32,
											step	= 1,
											set = function(info,val) 
												self.db.profile.cooldownline.icon_borderinset = val
												self.UpdateSettings()
											end,
											get =function(info)
												return self.db.profile.cooldownline.icon_borderinset
											end,
										},
										
										icon_background_inset = {
											name = L["Background Inset"],
											desc = L["Set Background Inset"],
											type = "slider",
											order	= 29.6,
											min		= -32,
											max		= 32,
											step	= 1,
											set = function(info,val) 
												self.db.profile.cooldownline.icon_background_inset = val
												self.UpdateSettings()
											end,
											get =function(info)
												return self.db.profile.cooldownline.icon_background_inset
											end,
										},
										icon_background_color = {
											order = 29.4,name = L["Background Color"],type = "color", hasAlpha = true,
											set = function(info,r,g,b,a) self.db.profile.cooldownline.icon_backgroundcolor={r = r,g = g,b = b, a = a}; self.UpdateSettings()  end,
											get = function(info) return self.db.profile.cooldownline.icon_backgroundcolor.r,self.db.profile.cooldownline.icon_backgroundcolor.g,self.db.profile.cooldownline.icon_backgroundcolor.b,self.db.profile.cooldownline.icon_backgroundcolor.a end
										},
										iconplus = {
											name = L["Icon plus"],
											type = "slider",
											order	= 29.7,
											min		= 1,
											max		= 32,
											step	= 1,
											set = function(info,val) 
												self.db.profile.cooldownline.iconplus = val
												self.UpdateSettings()
											end,
											get = function(info)
												return	self.db.profile.cooldownline.iconplus
											end,
										},
									},
								}, 
						desc2 = {
							type = "group",
							name = L["Line fonts"],
							order = 30,embend = true,
							args = {							
								textcolor = {
									order = 31,name = L["Text color"],type = "color", hasAlpha = true,
									set = function(info,r,g,b,a) self.db.profile.cooldownline.fontcolor={r=r, g=g,b=b, a=a}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.fontcolor.r,self.db.profile.cooldownline.fontcolor.g,self.db.profile.cooldownline.fontcolor.b,self.db.profile.cooldownline.fontcolor.a end
								},
								font = {
									order = 32,name = L["Font"],type = 'font',
								--	dialogControl = 'LSM30_Font',
									values = LSM:HashTable("font"),
									set = function(info,key) self.db.profile.cooldownline.font = key; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.font end,
								},
								fontsize = {
									name = L["Size"],
									type = "slider",
									order	= 33,
									min		= 1,
									max		= 32,
									step	= 1,
									set = function(info,val) 
										self.db.profile.cooldownline.fontsize = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.fontsize
									end,
								},
								fontflaggs = {
									type = "dropdown",	order = 34,
									name = L["Flags"],
									values = text_flaggs,
									set = function(info,val) 
										self.db.profile.cooldownline.fontflags = val
										self.UpdateSettings()
									end,
									get = function(info) return self.db.profile.cooldownline.fontflags end
								},							
								shadowsettings = {
									type = "group",
									name = L["Font shadow"],
									order = 34.1, embend = true, args = {							
										textshadowcolor = {
											order = 34.1,name = L["Text Shadow color"],type = "color", hasAlpha = true,
											set = function(info,r,g,b,a) self.db.profile.cooldownline.fontshadowcolor={r=r, g=g,b=b, a=a}; self.UpdateSettings() end,
											get = function(info) 
												local color = self.db.profile.cooldownline.fontshadowcolor or { r=0,g=0,b=0,a=1}
												
												return color.r,color.g,color.b,color.a 
											end
										},
										fontshadowoffset_x = {
											name = L["Shadow offset X"],
											type = "slider",
											order	= 34.2,
											min		= -10,
											max		= 10,
											step	= 0.1,
											set = function(info,val)
												if not self.db.profile.cooldownline.fontshadowoffset then self.db.profile.cooldownline.fontshadowoffset = {} end

												self.db.profile.cooldownline.fontshadowoffset[1] = val
												self.UpdateSettings()
											end,
											get = function(info)
												return self.db.profile.cooldownline.fontshadowoffset and self.db.profile.cooldownline.fontshadowoffset[1] or 0
											end,
										},
										fontshadowoffset_y = {
											name = L["Shadow offset Y"],
											type = "slider",
											order	= 34.3,
											min		= -10,
											max		= 10,
											step	= 0.1,
											set = function(info,val)
												if not self.db.profile.cooldownline.fontshadowoffset then self.db.profile.cooldownline.fontshadowoffset = {} end

												self.db.profile.cooldownline.fontshadowoffset[2] = val
												self.UpdateSettings()
											end,
											get = function(info)
												return self.db.profile.cooldownline.fontshadowoffset and self.db.profile.cooldownline.fontshadowoffset[2] or 0
											end,
										},
									},
								},
							},
						},
						
						desc3 = {
							type = "group",
							name = L["Icon fonts"],
							order = 35, embend = true,							
							args = {							
								icon_fontcolor = {
									order = 36,name = L["Text color"],type = "color", hasAlpha = true,
									set = function(info,r,g,b,a) self.db.profile.cooldownline.icon_fontcolor={r=r, g=g,b=b, a=a}; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.icon_fontcolor.r,self.db.profile.cooldownline.icon_fontcolor.g,self.db.profile.cooldownline.icon_fontcolor.b,self.db.profile.cooldownline.icon_fontcolor.a end
								},
								icon_font= {
									order = 37,name = L["Font"],type = 'font',
								--	dialogControl = 'LSM30_Font',
									values = LSM:HashTable("font"),
									set = function(info,key) self.db.profile.cooldownline.icon_font = key; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.icon_font end,
								},
								icon_fontsize = {
									name = L["Size"],
									type = "slider",
									order	= 38,
									min		= 1,
									max		= 32,
									step	= 1,
									set = function(info,val) 
										self.db.profile.cooldownline.icon_fontsize = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.icon_fontsize
									end,
								},
								icon_fontflaggs = {
									type = "dropdown",	order = 39,
									name = L["Flags"],
									values = text_flaggs,
									set = function(info,val) 
										self.db.profile.cooldownline.icon_fontflaggs = val
										self.UpdateSettings()
									end,
									get = function(info) return self.db.profile.cooldownline.icon_fontflaggs end
								},
								shadowsettings = {
									type = "group",
									name = L["Font shadow"],
									order = 39.1, embend = true, args = {	
										icon_textshadowcolor = {
											order = 39.1,name = L["Text Shadow color"],type = "color", hasAlpha = true,
											set = function(info,r,g,b,a) self.db.profile.cooldownline.icon_fontshadowcolor={r=r, g=g,b=b, a=a}; self.UpdateSettings() end,
											get = function(info) 
												local color = self.db.profile.cooldownline.icon_fontshadowcolor or {r=0, g=0, b=0,a=1}
												return color.r,color.g,color.b,color.a 
											end
										},
										icon_fontshadowoffset_x = {
											name = L["Shadow offset X"],
											type = "slider",
											order	= 39.2,
											min		= -10,
											max		= 10,
											step	= 0.1,
											set = function(info,val)
												if not self.db.profile.cooldownline.icon_fontshadowoffset then self.db.profile.cooldownline.icon_fontshadowoffset = {} end

												self.db.profile.cooldownline.icon_fontshadowoffset[1] = val
												self.UpdateSettings()
											end,
											get = function(info)
												return self.db.profile.cooldownline.icon_fontshadowoffset and self.db.profile.cooldownline.icon_fontshadowoffset[1] or 0
											end,
										},
										icon_fontshadowoffset_y = {
											name = L["Shadow offset Y"],
											type = "slider",
											order	= 39.2,
											min		= -10,
											max		= 10,
											step	= 0.1,
											set = function(info,val)
												if not self.db.profile.cooldownline.icon_fontshadowoffset then self.db.profile.cooldownline.icon_fontshadowoffset = {} end

												self.db.profile.cooldownline.icon_fontshadowoffset[2] = val
												self.UpdateSettings()
											end,
											get = function(info)
												return self.db.profile.cooldownline.icon_fontshadowoffset and self.db.profile.cooldownline.icon_fontshadowoffset[2] or 0
											end,
										},
									},
								},
							},
						},
						
						
						descSplashSmall = {
							type = "group",
							name = L["Small splash"],
							order = 51, embend = true,						
							args = {
								slash_show1 = {
									order = 52,name = L["Show"],type = "toggle",
									set = function(info,val) self.db.profile.cooldownline.slash_show_small = not self.db.profile.cooldownline.slash_show_small; self.UpdateSettings() end,
									get = function(info) return self.db.profile.cooldownline.slash_show_small end
								},
								splashsmall_background_color = {
									order = 52.1,name = L["Background Color"],type = "color", hasAlpha = true,
									set = function(info,r,g,b,a) self.db.profile.cooldownline.splashsmall_background_color={r = r,g = g,b = b, a = a}; self.UpdateSettings()  end,
									get = function(info) return self.db.profile.cooldownline.splashsmall_background_color.r,self.db.profile.cooldownline.splashsmall_background_color.g,self.db.profile.cooldownline.splashsmall_background_color.b,self.db.profile.cooldownline.splashsmall_background_color.a end
								},
								slash_small_alpha = {
									name = L["Transparent"],
									type = "slider",
									order	= 53,
									min		= 0,
									max		= 1,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.slash_small_alpha = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.slash_small_alpha
									end,
								},
								time_in1 = {
									name = L["Splash In"],
									desc = L["Small Splash In Desc"],
									type = "slider",
									order	= 54,
									min		= 0,
									max		= 1,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.splash_small.time_in = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.splash_small.time_in
									end,
								},
								time_out1 = {
									name = L["Splash Out"],
									desc = L["Small Splash Out Desc"],
									type = "slider",
									order	= 55,
									min		= 0,
									max		= 1,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.splash_small.time_out = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.splash_small.time_out
									end,
								},
								step_in1 = {
									name = L["Step In"],
									desc = L["Small Step In Desc"],
									type = "slider",
									order	= 56,
									min		= -5,
									max		= 5,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.splash_small.step_in = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.splash_small.step_in
									end,
								},
								step_out1 = {
									name = L["Step Out"],
									desc = L["Small Step Out Desc"],
									type = "slider",
									order	= 57,
									min		= -5,
									max		= 5,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.splash_small.step_out = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.splash_small.step_out
									end,
								},
								alpha_in1 = {
									name = L["Alpha In"],
									desc = L["Small Alpha In Desc"],
									type = "slider",
									order	= 58,
									min		= -5,
									max		= 5,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.splash_small.alpha_in = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.splash_small.alpha_in
									end,
								},
								alpha_out1 = {
									name = L["Alpha Out"],
									desc = L["Small Alpha Out Desc"],
									type = "slider",
									order	= 59,
									min		= -5,
									max		= 5,
									step	= 0.1,
									set = function(info,val) 
										self.db.profile.cooldownline.splash_small.alpha_out = val
										self.UpdateSettings()
									end,
									get = function(info)
										return	self.db.profile.cooldownline.splash_small.alpha_out
									end,
								},
							},
						},
						},
					},
				},
			},
			cooldown_splash = {
				order = 3.1,name = L["Big splash"],type = "group",
				args={
					slash_size = {
							name = L["Size"],
							type = "slider",
							order	= 43,
							min		= 1,
							max		= 400,
							step	= 1,
							set = function(info,val) 
								self.db.profile.cooldownline.slash_size = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.slash_size
							end,
						},
						slash_alpha = {
							name = L["Transparent"],
							type = "slider",
							order	= 44,
							min		= 0,
							max		= 1,
							step	= 0.1,
							set = function(info,val) 
								self.db.profile.cooldownline.slash_alpha = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.slash_alpha
							end,
						},
						slash_show = {
							order = 42,name = L["Show"],type = "toggle",
							set = function(info,val) self.db.profile.cooldownline.slash_show = not self.db.profile.cooldownline.slash_show; self.UpdateSettings() end,
							get = function(info) return self.db.profile.cooldownline.slash_show end
						},
						splash_background_color = {
							order = 42.1,name = L["Background Color"],type = "color", hasAlpha = true,
							set = function(info,r,g,b,a) self.db.profile.cooldownline.splash_background_color={r = r,g = g,b = b, a = a}; self.UpdateSettings()  end,
							get = function(info) return self.db.profile.cooldownline.splash_background_color.r,self.db.profile.cooldownline.splash_background_color.g,self.db.profile.cooldownline.splash_background_color.b,self.db.profile.cooldownline.splash_background_color.a end
						},
						show_only_force = {
							order = 42.2,width = "full",name = L["Show forced"],type = "toggle", desc = L["If checked then show only forced spells. Otherwise do not show splash for forced spells."],
							set = function(info,val) self.db.profile.cooldownline.show_only_force = not self.db.profile.cooldownline.show_only_force; end,
							get = function(info) return self.db.profile.cooldownline.show_only_force end
						},
						time_in = {
							name = L["Splash In"],
							desc = L["Big Splash In Desc"],
							type = "slider",
							order	= 45,
							min		= 0,
							max		= 1,
							step	= 0.1,
							set = function(info,val) 
								self.db.profile.cooldownline.splash_big.time_in = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.splash_big.time_in
							end,
						},
						time_out = {
							name = L["Splash Out"],
							desc = L["Big Splash Out Desc"],
							type = "slider",
							order	= 46,
							min		= 0,
							max		= 1,
							step	= 0.1,
							set = function(info,val) 
								self.db.profile.cooldownline.splash_big.time_out = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.splash_big.time_out
							end,
						},
						step_in = {
							name = L["Step In"],
							desc = L["Big Step In Desc"],
							type = "slider",
							order	= 47,
							min		= -5,
							max		= 5,
							step	= 0.1,
							set = function(info,val) 
								self.db.profile.cooldownline.splash_big.step_in = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.splash_big.step_in
							end,
						},
						step_out = {
							name = L["Step Out"],
							desc = L["Big Step Out Desc"],
							type = "slider",
							order	= 48,
							min		= -5,
							max		= 5,
							step	= 0.1,
							set = function(info,val) 
								self.db.profile.cooldownline.splash_big.step_out = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.splash_big.step_out
							end,
						},
						alpha_in = {
							name = L["Alpha In"],
							desc = L["Big Alpha In Desc"],
							type = "slider",
							order	= 49,
							min		= -5,
							max		= 5,
							step	= 0.1,
							set = function(info,val) 
								self.db.profile.cooldownline.splash_big.alpha_in = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.splash_big.alpha_in
							end,
						},
						alpha_out = {
							name = L["Alpha Out"],
							desc = L["Big Alpha Out Desc"],
							type = "slider",
							order	= 50,
							min		= -5,
							max		= 5,
							step	= 0.1,
							set = function(info,val) 
								self.db.profile.cooldownline.splash_big.alpha_out = val
								self.UpdateSettings()
							end,
							get = function(info)
								return	self.db.profile.cooldownline.splash_big.alpha_out
							end,
						},
					
				},
			},
			
			castbars = C:GetCastBarGUI(),
			--copui = C:GetCoPGUI(),
			
		--	profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db),
			
			profiles = ALEAUI_GetProfileOptions("SPTimersDB"),
			
			import_exposrt ={
				order = 99997,name = L["Export & Import Profile"],type = "group",
				args={
					Export = {
						type = 'execute',
						order = -99,
						name = L['Export'],
						func = function(info, value)
							self:ExportProfile()			
						end,
					},
					Import = {
						type = 'execute',
						order = -98,
						name = L['Import'],
						func = function(info, value)
							self:ImportProfile()	
						end,
					},
				},
			},
			
		}
	}

		
	return o
end

do
	
	local sites = {
		["curse_com"] = { "curseforge.com", "https://wow.curseforge.com/projects/sp-timers", false, "full" },
		--["h2p"]		  = { "HowToPriest.com", "http://howtopriest.com/viewtopic.php?f=26&t=5480", false, "full" },
	}
		
	function C:InitSupports()
		local order_1 = 1
		for k,v in pairs(sites) do
		
			o.args.about.args[k] =  {
				type = "editbox",	order	= order_1,multiline = v[3],
				name = v[1],
				width = v[4],
				set = function(info,val) end,						
				get = function(info) return v[2] end
			}
			order_1 = order_1 + 1
		
		end
	end
end
	
	local classGUIChangeHandlers = {}
	
	function C:AddOnClassGUIChangeHandler(handler)	
		classGUIChangeHandlers[#classGUIChangeHandlers+1] = handler
	end
	
	local function ClassSpellSettings_Update(opts)
	
		if opts.spellType == 2 then
			o.args.bars.args.ClassSpells.args.classGrop.args.pvpduration = nil
			o.args.bars.args.ClassSpells.args.classGrop.args.cleu = nil
			o.args.bars.args.ClassSpells.args.classGrop.args.targetType = nil
			o.args.bars.args.ClassSpells.args.classGrop.args.Pandemia = nil
		else
			o.args.bars.args.ClassSpells.args.classGrop.args.pvpduration = {
				type = "editbox",	width = "half", order	= 6.1,
				name = L["PVP duration"],
				set = function(info,val) 
					local num = tonumber(val)				
					if num then opts.pvpduration = num end
				end,
				get = function(info) return opts.pvpduration and tostring(opts.pvpduration) or NO end
			}
			
			o.args.bars.args.ClassSpells.args.classGrop.args.cleu = {
				order = 3.6,name = L["cleu"], desc = L["cleu_desc"], type = "toggle",
				set = function(info,val) 
					opts.cleu = not opts.cleu; 
					ClassSpellSettings_Update(opts)
				end,
				get = function(info) return opts.cleu end
			}
			o.args.bars.args.ClassSpells.args.classGrop.args.targetType = {
				name = L["Target Type"],
				order = 3.7,
				type = "dropdown",
				values = targetType,
				set = function(info,val)
					opts.target = val
				end,
				get = function(info, val) 
					return opts.target or 3
				end
			}
			
			o.args.bars.args.ClassSpells.args.classGrop.args.Pandemia = {
				order = 6.2,name = L["30% dutation indicator"], type = "toggle", width = 'full',
				set = function(info,val) 
					opts.pandemia = not opts.pandemia; 
					ClassSpellSettings_Update(opts)
				end,
				get = function(info) return opts.pandemia end
			}
			
		end
		
		if opts.showTicks then
			if opts.showOverlay then	
				o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.tickoverlap = {
					order = 8.2,name = L["Include Tick Overlap"],type = "toggle",
					set = function(info,val) opts.tickoverlap = not opts.tickoverlap; end,
					get = function(info) return opts.tickoverlap end
				}
			else
				o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.tickoverlap = nil
			end
		else
			o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.tickoverlap = nil
		end
		
		if opts.showOverlay then		
			o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.cast = {
				type = "editbox",width = "half", order	= 8,
				name = L["Cast time"],
				set = function(info,val) 
					local num = tonumber(val)				
					if num then opts.cast = num end
				end,
				get = function(info) return opts.cast and tostring(opts.cast) or "0" end
			}
			
			o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.withgcd = {
				order = 8.1,name = L["Include Global Cooldown"],type = "toggle",
				set = function(info,val) opts.withgcd = not opts.withgcd; end,
				get = function(info) return opts.withgcd end
			}
			
			if opts.showTicks then
				o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.tickoverlap = {
					order = 8.2,name = L["Include Tick Overlap"],type = "toggle",
					set = function(info,val) opts.tickoverlap = not opts.tickoverlap; end,
					get = function(info) return opts.tickoverlap end
				}
			else
				o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.tickoverlap = nil
			end		
		else
			o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.cast = nil
			o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.withgcd = nil
			o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.tickoverlap = nil
		end
				
		if opts.showTicks then 		
			o.args.bars.args.ClassSpells.args.classGrop.args.ShowTicks.args.tick = {
				type = "editbox",width = "half", order	= 1,
				name = L["Ticks"],
				desc = L["TicksComm"],
				set = function(info,val) 
					local num = tonumber(val)				
					if num then opts.tick = num end
				end,
				get = function(info) return opts.tick and tostring(opts.tick) or "0" end
			}
			
			o.args.bars.args.ClassSpells.args.classGrop.args.ShowTicks.args.Haste = {
				type = 'toggle', order = 2,
				name = L["Change by haste"],
				set = function(info, val)
					opts.haste = not opts.haste
				end,
				get = function(info)				
					return opts.haste
				end,
			}
			
		else
			o.args.bars.args.ClassSpells.args.classGrop.args.ShowTicks.args.tick = nil
			o.args.bars.args.ClassSpells.args.classGrop.args.ShowTicks.args.Haste = nil
		end
		
		if opts.spellType == 2 then
			o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader = nil
		else
		
			o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader = {
				name	= L["Filters"],
				order	= 16,
				type = "group",args = {},embend = true,
			}
			o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.whitelist = {
				name = L["White List"],
				order = 17,
				desc = L["White List Desc"],
				type = "dropdown",
				values = filters,
				set = function(info,val)
					opts.whitelist = val
				end,
				get = function(info, val) 
					return opts.whitelist or 1
				end
			}
			o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.blacklist = {
				name = L["Black List"],
				order = 17.1,
				desc = L["Black List Desc"],
				type = "dropdown",
				values = filters,
				set = function(info,val)
					opts.blacklist = val
				end,
				get = function(info, val) 
					return opts.blacklist or 1
				end
			}
			
			if opts.cleu then
				o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.whitelist_cleu = {
					name = L["White List Combat Log"],
					order = 18,
					desc = L["White List Combat Log Desc"],
					type = "dropdown",
					values = filters_cleu,
					set = function(info,val)
						opts.whitelist_cleu = val
					end,
					get = function(info, val) 
						return opts.whitelist_cleu or 1
					end
				}
				o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.blacklist_cleu = {
					name = L["Black List Combat Log"],
					order = 18.1,
					desc = L["Black List Combat Log Desc"],
					type = "dropdown",
					values = filters_cleu,
					set = function(info,val)
						opts.blacklist_cleu = val
					end,
					get = function(info, val) 
						return opts.blacklist_cleu or 1
					end
				}			
			else
				o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.whitelist_cleu = nil
				o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.blacklist_cleu = nil
			end
			
			o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.affilation = {
				name = L["Source affiliation"],
				desc = L["Source affiliation desc"],
				
				order = 20,
				type = "dropdown",
				values = affiliation,
				set = function(info,val)
					opts.source = val
				end,
				get = function(info, val) 
					return opts.source or 2
				end
			}
			o.args.bars.args.ClassSpells.args.classGrop.args.filterHeader.args.affilation_targ = {
				name = L["Target affiliation"],
				desc = L["Target affiliation desc"],
				
				order = 20.1,
				type = "dropdown",
				values = affiliation,
				set = function(info,val)
					opts.target_affil = val
				end,
				get = function(info, val) 
					return opts.target_affil or 1
				end
			}		
		end
		
		
		if opts.spellType == 2 then
			o.args.bars.args.ClassSpells.args.anchor_per_unit = nil
		else
		
			o.args.bars.args.ClassSpells.args.anchor_per_unit = {		
				type = "group",	order	= 22,
				embend = true,
				name	= L["Anchor per Unit"],
				args = {}
			}

			o.args.bars.args.ClassSpells.args.anchor_per_unit.args.enabled = {
				order = 1,name = L["Enabled"],type = "toggle", desc = L["Anchor per Unit Desc"],
				set = function(info,val) 
					opts.anchor_per_unit_enabled = not opts.anchor_per_unit_enabled; 
					ClassSpellSettings_Update(opts)
				end,
				get = function(info) return opts.anchor_per_unit_enabled end
			}
			
			if opts.anchor_per_unit_enabled then
				
				o.args.bars.args.ClassSpells.args.anchor_per_unit.args.unit = {
					name = L["Unit"],
					order = 3,
				--	desc = L["Select Anchor offtarget Desc"].." ->'"..L["General"].."'->'"..L["Swap bars when change target"].."'",
					type = "dropdown",
					values = {
					--	target = "target",
						focus  = "focus",					
						boss1  = "boss1",
						boss2  = "boss2",
						boss3  = "boss3",
						boss4  = "boss4",
						boss5  = "boss5",
						arena1  = "arena1",
						arena2  = "arena2",
						arena3  = "arena3",
						arena4  = "arena4",
						arena5  = "arena5",
					--	offtargets = "offtargets",
					},
					set = function(info,val)
						if not opts.anchor_per_unit then 
							opts.anchor_per_unit = {} 
							opts.anchor_per_unit[val] = 1
						end
						unit_per_achor_choose = val
					end,
					get = function(info, val)
						return unit_per_achor_choose
					end
				}
				
				o.args.bars.args.ClassSpells.args.anchor_per_unit.args.anchor = {
					name = L["Select Anchor"],
					order = 4,
				--	desc = L["Select Anchor offtarget Desc"].." ->'"..L["General"].."'->'"..L["Swap bars when change target"].."'",
					type = "dropdown",
					values = function()
						local t = {}
						t[0] = NO
						for k,v in ipairs(C.db.profile.bars_anchors) do						
							t[k] = v.name or k
						end				
						return t
					end,
					set = function(info,val)
						if unit_per_achor_choose then 
							opts.anchor_per_unit[unit_per_achor_choose] = val
						end
					end,
					get = function(info)
						if unit_per_achor_choose then						
							return opts.anchor_per_unit[unit_per_achor_choose]
						end
						return nil
					end					
				}
							
				o.args.bars.args.ClassSpells.args.anchor_per_unit.args.always_show_enabled = {
					order = 2,name = L["Always show"],type = "toggle", desc = L["If Enabled always show timers for this unit. Working only if Swap timers is enabled"],
					set = function(info,val) 						
						if not opts.unit_force_show then opts.unit_force_show = {} end					
						if unit_per_achor_choose then
							opts.unit_force_show[unit_per_achor_choose] = not opts.unit_force_show[unit_per_achor_choose]
						end
					end,
					get = function(info) 										
						if unit_per_achor_choose then
							return opts.unit_force_show and opts.unit_force_show[unit_per_achor_choose] or false
						end
						return false
					end
				}
			else
				o.args.bars.args.ClassSpells.args.anchor_per_unit.args.unit = nil
				o.args.bars.args.ClassSpells.args.anchor_per_unit.args.anchor = nil
				o.args.bars.args.ClassSpells.args.anchor_per_unit.args.always_show_enabled = nil
			end
		end
		
		for i=1, #classGUIChangeHandlers do
			classGUIChangeHandlers[i](o.args.bars.args.ClassSpells, class_select)
		end
	end
	
	function C:ClassSpell(spellID)
		local opts = self.db.profile.classSpells[self.myCLASS][spellID]	
		class_select = spellID
		unit_per_achor_choose = nil
		
		
		o.args.bars.args.ClassSpells.args.classGrop = {
				name	= "",
				order	= 3.2,
				type = "group",
				embend = true,
				args = {},
			}
			
			
		o.args.bars.args.ClassSpells.args.classGrop.args.hide = {
				order = 3.3,name = L["Hide"],type = "toggle",
				set = function(info,val) opts.hide = not opts.hide; C:OnCustomUpdateAuras(); end,
				get = function(info) return opts.hide end
			}
		--[==[
		o.args.bars.args.ClassSpells.args.classGrop.args.haste = {
				order = 3.4,name = L["Hasted"],type = "toggle",
				set = function(info,val) opts.haste = not opts.haste; end,
				get = function(info) return opts.haste end
			}
		]==]
		
		o.args.bars.args.ClassSpells.args.classGrop.args.spellType = {
			order = 3.4, name = L['Spell Type'], type = 'dropdown',
			values = {
				L['Timer'],
				L['Channeling'],
			},
			set = function(info, value) 
				opts.spellType = value
				self:ScanForChannelingSpell()
				
				ClassSpellSettings_Update(opts)
		
			end,
			get = function(info)
				return opts.spellType or 1
			end,		
		}
			
			
		--[==[
		o.args.bars.args.ClassSpells.args.classGrop.args.channel = {
			order = 5,name = L["Channeling"],type = "toggle",
			set = function(info,val) opts.channel = not opts.channel; self:ScanForChannelingSpell() end,
			get = function(info) return opts.channel end
		}
		]==]
		
		local spellType = opts.spellType or 1
	
		o.args.bars.args.ClassSpells.args.classGrop.args.duration = {
				type = "editbox",	width = "half", order	= 6,
				name = L["Duration"],
				set = function(info,val) 
					local num = tonumber(val)				
					if num then opts.duration = num end
				end,
				get = function(info) return opts.duration and tostring(opts.duration) or NO end
			}
		
		o.args.bars.args.ClassSpells.args.classGrop.args.ShowTicks = {
			name	= L["Tick's settings"],
			order	= 6.9,
			type = "group",
			embend = true,args = {},
		}
		
		o.args.bars.args.ClassSpells.args.classGrop.args.ShowTicks.args.show = {
			order = 0.1,name = L["Show"],type = "toggle", width = 'full',
			set = function(info,val) 
				opts.showTicks = not opts.showTicks;

				ClassSpellSettings_Update(opts)
			end,
			get = function(info)
				return opts.showTicks
			end,
		}

		o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay = {
			name	= L["Cast overlay"],
			order	= 7,
			type = "group",
			embend = true,args = {},
		}
		
		o.args.bars.args.ClassSpells.args.classGrop.args.CastOverlay.args.show = {
			order = 3.3,name = L["Show"],type = "toggle", width = 'full',
			set = function(info,val) 
				opts.showOverlay = not opts.showOverlay; 
				
				ClassSpellSettings_Update(opts)
			end,
			get = function(info) return opts.showOverlay end
		}
		
		o.args.bars.args.ClassSpells.args.classGrop.args.BarColors = {
				name	= L["Bar color"],
				order	= 9,
				type = "group",
				embend = true,args = {},
			}
		o.args.bars.args.ClassSpells.args.classGrop.args.BarColors.args.color = {
				order = 10,name = L["Color"],type = "color",
				set = function(info,r,g,b) opts.color={r,g,b}; C:OnCustomUpdateAuras(); end,
				get = function(info) return ( opts.color and opts.color[1] or 0 ),( opts.color and opts.color[2] or 0 ),( opts.color and opts.color[3] or 0 ),1 end
			}
		
		o.args.bars.args.ClassSpells.args.classGrop.args.BarColors.args.color_on = {
				order = 10,name = L["Own color"],type = "toggle",
				set = function(info,val) opts.color_on = not opts.color_on; C:OnCustomUpdateAuras(); end,
				get = function(info) return opts.color_on end
			}
		o.args.bars.args.ClassSpells.args.classGrop.args.CustomText = {
				name	= L["Custom Text"],
				order	= 11,
				type = "group",args = {},embend = true,
			}
		o.args.bars.args.ClassSpells.args.classGrop.args.CustomText.args.custom_text = {
				type = "editbox",	order	= 12.1, width = "full",
				name = L["Custom Text"],
				desc = L["Custom Text Desc"],
				set = function(info,val) 
					local num = tostring(val)				
					if num then opts.custom_text = num end
					self:PreCacheCustomTextCheck();
					C:OnCustomUpdateAuras(); 
				end,
				get = function(info) return opts.custom_text and tostring(opts.custom_text) or "" end
			}
		o.args.bars.args.ClassSpells.args.classGrop.args.CustomText.args.custom_text_on= {
				order = 12,name = L["Custom Text On"],type = "toggle", width = "full",
				set = function(info,val) opts.custom_text_on = not opts.custom_text_on; self:PreCacheCustomTextCheck(); C:OnCustomUpdateAuras(); end,
				get = function(info) return opts.custom_text_on end
			}
			
		o.args.bars.args.ClassSpells.args.classGrop.args.sortHeader = {
				name	= L["Sorting"],
				order	= 13.1,
				type = "group",args = {},
				embend = true,
			}
			
		o.args.bars.args.ClassSpells.args.classGrop.args.sortHeader.args.priority = {
				name = L["Priority"],
				type = "slider",
				order	= 14,
				min		= -20,
				max		= 20,
				step	= 1,
				set = function(info,val) 
					opts.priority = val
				end,
				get = function(info)
					return opts.priority
				end,
			}
		o.args.bars.args.ClassSpells.args.classGrop.args.sortHeader.args.anchor = {
				name = L["Select Anchor"],
				order = 15,
				desc = L["Select Anchor Desc"],
				type = "dropdown",
				values = function()
					local t = {}							
					for k,v in ipairs(self.db.profile.bars_anchors) do						
						t[k] = v.name or k
					end							
					return t
				end,
				set = function(info,val)
					opts.set_anchor = val
				end,
				get = function(info, val) 
					return opts.set_anchor or 1
				end
			}
		o.args.bars.args.ClassSpells.args.classGrop.args.sortHeader.args.offtargetanchor = {
				name = L["Select offtarget Anchor"],
				order = 15,
				desc = L["Select Anchor offtarget Desc"], --.." ->'"..L["Bars"].."'->'"..L["Swap bars when change target"].."'",
				type = "dropdown",
			--	disabled = not self.db.profile.doswap,
				values = function()
					local t = {}							
					for k,v in ipairs(self.db.profile.bars_anchors) do						
						t[k] = v.name or k
					end							
					return t
				end,
				set = function(info,val)
					opts.offtarge = val
				end,
				get = function(info, val) 
					return opts.offtarge or 1
				end
			}
		o.args.bars.args.ClassSpells.args.classGrop.args.sortHeader.args.group = {
				name = L["Select group"],
				order = 15,
				desc = L["Select group Desc"],
				type = "dropdown",
				values = groupSorting,
				set = function(info,val)
					opts.group = val
				end,
				get = function(info, val) 
					return opts.group or "auto"
				end
			}
			
		--[[
		o.args.bars.args.ClassSpells.args.anchor_per_unit_desc = {
				name	= L["Anchor per Unit"],
				order	= 21,
				type = "header",
			}
		]]
		
		o.args.bars.args.ClassSpells.args.SoundFile = {					
			type = "group",	order	= 22.1,
			embend = true,
			name	= L["Sound"],
			args = {						
				OnShow = {
					order = 1,type = 'sound',name = L["On Show"],
				--	dialogControl = 'LSM30_Sound',
					values = LSM:HashTable("sound"),
					set = function(info,value) opts.sound_onshow = value end,
					get = function(info) return opts.sound_onshow or "None"; end,
				},
				OnHide = {
					order = 1,type = 'sound',name = L["On Hide"],
				--	dialogControl = 'LSM30_Sound',
					values = LSM:HashTable("sound"),
					set = function(info,value) opts.sound_onhide = value end,
					get = function(info) return opts.sound_onhide or "None"; end,
				},
			}
		}
		
		o.args.bars.args.ClassSpells.args.delete = {
			type = 'execute',
			order = 999999,
			name = L['SemiDelete'],
			desc = L['SemiDelDesc'],
			func = function(info, value)
				opts.deleted = true
				class_select = nil
				wipe(o.args.bars.args.ClassSpells.args)
						
				o.args.bars.args.ClassSpells.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.classSpells[self.myCLASS]) do	
								
								if not v.deleted and not v.fulldel and GetClassSpec(v.spec) then							
									local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
									t[g_spellID or k] = g_spellName or SpellString(k, 10)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:ClassSpell(val)
						end,
						get = function(info, val)
							return class_select
						end
					}
				o.args.bars.args.ClassSpells.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Player_EditBox_SPTimer",
						
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "class")
								end	
							end
						end,
						get = function(info)end
					}
					
				o.args.bars.args.ClassSpells.args.selectSpec = {
					name = L["Spec"],
					order = 1.1,
					desc = L["Spec"],
					type = "dropdown",
					values = SpecSelect,
					set = function(info,val)
						CHOSEN_CLASS_SPEC = val
					end,
					get = function(info, val)
						if not CHOSEN_CLASS_SPEC then CHOSEN_CLASS_SPEC = GetSpecialization() and ""..GetSpecialization().."" or ALL end							
						return CHOSEN_CLASS_SPEC
					end
				}
				
			end,
		}
		o.args.bars.args.ClassSpells.args.fulldelete = {
			type = 'execute',
			order = 999999,
			name = L['Full delete'],
			desc = L['FullDelDesc'],
			func = function(info, value)
				opts.fulldel = true
				class_select = nil
				wipe(o.args.bars.args.ClassSpells.args)
						
				o.args.bars.args.ClassSpells.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.classSpells[self.myCLASS]) do	
								
								if not v.deleted and not v.fulldel and GetClassSpec(v.spec) then							
									local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
									t[g_spellID or k] = g_spellName or SpellString(k, 10)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:ClassSpell(val)
						end,
						get = function(info, val)
							return class_select
						end
					}
				o.args.bars.args.ClassSpells.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Player_EditBox_SPTimer",
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "class")
								end	
							end
						end,
						get = function(info)end
					}
					
				o.args.bars.args.ClassSpells.args.selectSpec = {
					name = L["Spec"],
					order = 1.1,
					desc = L["Spec"],
					type = "dropdown",
					values = SpecSelect,
					set = function(info,val)
						CHOSEN_CLASS_SPEC = val
					end,
					get = function(info, val)
						if not CHOSEN_CLASS_SPEC then CHOSEN_CLASS_SPEC = GetSpecialization() and ""..GetSpecialization().."" or ALL end							
						return CHOSEN_CLASS_SPEC
					end
				}
				
			end,
		}
		
		ClassSpellSettings_Update(opts)
	end


	function C:ProcsSpell(spellID)
		
		local opts = self.db.profile.procSpells[spellID]

		proc_select = spellID

		o.args.bars.args.spellList2.args.hide = {
				order = 3,name = L["Hide"],type = "toggle",
				set = function(info,val) opts.hide = not opts.hide; end,
				get = function(info) return opts.hide end
			}
			
		o.args.bars.args.spellList2.args.targetType = {
			name = L["Target Type"],
			order = 3.1,
			type = "dropdown",
			values = targetType,
			set = function(info,val)
				opts.target = val
			end,
			get = function(info, val) 
				return opts.target or 3
			end
		}
	
		
		o.args.bars.args.spellList2.args.typeHeader1 = {
				name	= L["Color"],
				order	= 4,
				type = "group",embend = true,
				
				args = {}
			}
		
		o.args.bars.args.spellList2.args.customTextureGroup = {
				name	= L["Custom Texture"],
				order	= 5,
				type = "group",embend = true,				
				args = {}
			}
		o.args.bars.args.spellList2.args.customTextureGroup.args.custom_texture = {
				type = "editbox",	order	= 8,
				name = L["Custom Texture"],
				desc = L["Custom Texture Desc"],
				set = function(info,val) 		
					opts.custom_texture = val
				end,
				get = function(info) return opts.custom_texture or "" end
			}
		o.args.bars.args.spellList2.args.customTextureGroup.args.custom_texture_on= {
				order = 9,name = L["Custom Texture On"],type = "toggle",
				set = function(info,val) opts.custom_texture_on = not opts.custom_texture_on; end,
				get = function(info) return opts.custom_texture_on end
			}
			
			
		o.args.bars.args.spellList2.args.typeHeader1.args.color = {
				order = 5,name = L["Color"],type = "color",
				set = function(info,r,g,b) opts.color={r,g,b}; end,
				get = function(info) return ( opts.color and opts.color[1] or 0 ),( opts.color and opts.color[2] or 0 ),( opts.color and opts.color[3] or 0 ),1 end
			}
		
		o.args.bars.args.spellList2.args.typeHeader1.args.color_on = {
				order = 6,name = L["Own color"],type = "toggle",
				set = function(info,val) opts.color_on = not opts.color_on; end,
				get = function(info) return opts.color_on end
			}
		o.args.bars.args.spellList2.args.typeHeader2 = {
				name	= L["Bar Text"],
				order	= 7,
				type = "group",
				embend = true,
				args = {}
			}
		o.args.bars.args.spellList2.args.typeHeader2.args.custom_text = {
				type = "editbox",	order	= 8,
				name = L["Custom Text"],
				desc = L["Custom Text Desc"],
				set = function(info,val) 
					local num = tostring(val)				
					if num then opts.custom_text = num end
					self:PreCacheCustomTextCheck();
				end,
				get = function(info) return opts.custom_text and tostring(opts.custom_text) or "" end
			}
		o.args.bars.args.spellList2.args.typeHeader2.args.custom_text_on= {
				order = 9,name = L["Custom Text On"],type = "toggle",
				set = function(info,val) opts.custom_text_on = not opts.custom_text_on; self:PreCacheCustomTextCheck();end,
				get = function(info) return opts.custom_text_on end
			}
		
		o.args.bars.args.spellList2.args.typeHeader2.args.check_stacks = {
				type = "editbox",	order	= 10,
				name = L["Check Stacks"],
				desc = L["Check Stacks Desc"],
				set = function(info,val) 
					local num = tonumber(val)				
					if num then opts.checkstaucks = num end
				end,
				get = function(info) return opts.checkstaucks and tostring(opts.checkstaucks) or "" end
			}
		o.args.bars.args.spellList2.args.typeHeader2.args.check_stacks_on= {
				order = 11,name = L["Check Stacks On"],type = "toggle",
				set = function(info,val) opts.checkstaucks_on = not opts.checkstaucks_on; end,
				get = function(info) return opts.checkstaucks_on end
			}
		o.args.bars.args.spellList2.args.sortHeader = {
				name	= L["Sorting"],
				order	= 12,
				type = "group",
				embend = true,
				args = {
				
				
				}
			}
			
		o.args.bars.args.spellList2.args.sortHeader.args.priority = {
				name = L["Priority"],
				type = "slider",
				order	= 13,
				min		= -20,
				max		= 20,
				step	= 1,
				set = function(info,val) 
					opts.priority = val
				end,
				get = function(info)
					return opts.priority
				end,
			}
		o.args.bars.args.spellList2.args.sortHeader.args.anchor = {
				name = L["Select Anchor"],
				order = 14,
				desc = L["Select Anchor Desc"],
				type = "dropdown",
				values = function()
					local t = {}							
					for k,v in ipairs(self.db.profile.bars_anchors) do						
						t[k] = v.name or k
					end							
					return t
				end,
				set = function(info,val)
					opts.set_anchor = val
				end,
				get = function(info, val)
					return opts.set_anchor or 1
				end
			}
		o.args.bars.args.spellList2.args.sortHeader.args.group = {
				name = L["Select group"],
				order = 15,
				desc = L["Select group Desc"],
				type = "dropdown",
				values = groupSorting,
				set = function(info,val)
					opts.group = val
				end,
				get = function(info, val) 
					return opts.group or "auto"
				end
			}
		o.args.bars.args.spellList2.args.filterHeader = {
				name	= L["Filters"],
				order	= 16,
				type = "group", embend = true, args = {}
			}
		o.args.bars.args.spellList2.args.filterHeader.args.whitelist = {
				name = L["White List"],
				order = 17,
				type = "dropdown",
				values = filters,
				set = function(info,val)
					opts.whitelist = val
				end,
				get = function(info, val) 
					return opts.whitelist or 1
				end
			}
		o.args.bars.args.spellList2.args.filterHeader.args.blacklist = {
				name = L["Black List"],
				order = 18,
				type = "dropdown",
				values = filters,
				set = function(info,val)
					opts.blacklist = val
				end,
				get = function(info, val) 
					return opts.blacklist or 1
				end
			}
		o.args.bars.args.spellList2.args.filterHeader.args.affilation = {
				name = L["Source affiliation"],
				desc = L["Source affiliation desc"],				
				order = 19,
				type = "dropdown",
				values = affiliation,
				set = function(info,val)
					opts.source = val
				end,
				get = function(info, val) 
					return opts.source or 2
				end
			}
		o.args.bars.args.spellList2.args.filterHeader.args.affilation_targ = {
				name = L["Target affiliation"],
				desc = L["Target affiliation desc"],				
				order = 19.1,
				type = "dropdown",
				values = affiliation,
				set = function(info,val)
					opts.target_affil = val
				end,
				get = function(info, val) 
					return opts.target_affil or 1
				end
			}
		o.args.bars.args.spellList2.args.SoundFile = {					
			type = "group",	order	= 20.1,
			embend = true,
			name	= L["Sound"],
			args = {						
				OnShow = {
					order = 1,type = 'sound',name = L["On Show"],
				--	dialogControl = 'LSM30_Sound',
					values = LSM:HashTable("sound"),
					set = function(info,value) opts.sound_onshow = value end,
					get = function(info) return opts.sound_onshow or "None" end,
				},
				OnHide = {
					order = 1,type = 'sound',name = L["On Hide"],
				--	dialogControl = 'LSM30_Sound',
					values = LSM:HashTable("sound"),
					set = function(info,value) opts.sound_onhide = value end,
					get = function(info) return opts.sound_onhide or "None" end,
				},
			}
		}
	
		o.args.bars.args.spellList2.args.delete = {
			type = 'execute',
			order = 99999,
			name = L['SemiDelete'],
			desc = L['SemiDelDesc'],
			func = function(info, value)
				opts.deleted = true
				class_select = nil
				wipe(o.args.bars.args.spellList2.args)
						
				o.args.bars.args.spellList2.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.procSpells) do	
								if not v.deleted and not v.fulldel and ProcFilter(v.role) and ProcFilter_Patch(v.patch) then
									local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
									t[g_spellID or k] = g_spellName or SpellString(k, 10)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:ProcsSpell(val)
						end,
						get = function(info, val)
							return class_select
						end
					}
				o.args.bars.args.spellList2.args.selectProcFilter = {
					name = L["Filter"],
					order = 1.1,
					type = "multiselect",
					values = Role_Values_List,
					set = function(info, value)
						SetSelectProcFilter(value)
					end,
					get = function(info)
						return GetSelectProcFilter()
					end,
				}
				--[==[
				selectRole = {
					name = L["Role"],
					order = 1.1,
					type = "dropdown",
					values = RoleSelect,
					set = function(info,val)
						CHOSEN_ROLE = val
					end,
					get = function(info, val)
						if not CHOSEN_ROLE then CHOSEN_ROLE = GetRole() end								
						return CHOSEN_ROLE
					end
				}
				]==]	
				o.args.bars.args.spellList2.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Aura_EditBox_SPTimer",
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "procs")
								end	
							end
						end,
						get = function(info)end
					}
			end,
		}
		
		o.args.bars.args.spellList2.args.fulldelete = {
			type = 'execute',
			order = 99999,
			name = L['Full delete'],
			desc = L['FullDelDesc'],
			func = function(info, value)
				opts.fulldel = true
				class_select = nil
				wipe(o.args.bars.args.spellList2.args)
						
				o.args.bars.args.spellList2.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.procSpells) do	
								if not v.deleted and not v.fulldel and ProcFilter(v.role) and ProcFilter_Patch(v.patch) then
									local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
									t[g_spellID or k] = g_spellName or SpellString(k, 10)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:ProcsSpell(val)
						end,
						get = function(info, val)
							return class_select
						end
					}
				o.args.bars.args.spellList2.args.selectProcFilter = {
					name = L["Filter"],
					order = 1.1,
					type = "multiselect",
					values = Role_Values_List,
					set = function(info, value)
						SetSelectProcFilter(value)
					end,
					get = function(info)
						return GetSelectProcFilter()
					end,
				}
				
				--[==[
				selectRole = {
					name = L["Role"],
					order = 1.1,
					type = "dropdown",
					values = RoleSelect,
					set = function(info,val)
						CHOSEN_ROLE = val
					end,
					get = function(info, val)
						if not CHOSEN_ROLE then CHOSEN_ROLE = GetRole() end								
						return CHOSEN_ROLE
					end
				}
				]==]		
				o.args.bars.args.spellList2.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Aura_EditBox_SPTimer",
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "procs")
								end	
							end
						end,
						get = function(info)end
					}
			end,
		}
	end



	function C:OthersSpell(spellID)
		
		local opts = self.db.profile.othersSpells[spellID]
		
		others_select = spellID
		
		o.args.bars.args.spellList3.args.hide = {
			order = 9.1,name = L["Hide"],type = "toggle",
			set = function(info,val) opts.hide = not opts.hide; end,
			get = function(info) return opts.hide end
		}
		
		o.args.bars.args.spellList3.args.targetType = {
			name = L["Target Type"],
			order = 9.2,
			type = "dropdown",
			values = targetType,
			set = function(info,val)
				opts.target = val
			end,
			get = function(info, val) 
				return opts.target or 3
			end
		}
		
		
		o.args.bars.args.spellList3.args.desc2 = {
			name	= L["Color"],
			order	= 9.3,
			type = "group", embend = true,
			args = {},
		}

		o.args.bars.args.spellList3.args.desc2.args.color = {
				order = 10,width = "half",name = L["Color"],type = "color",
				set = function(info,r,g,b) opts.color={r,g,b}; end,
				get = function(info) return ( opts.color and opts.color[1] or 0 ),( opts.color and opts.color[2] or 0 ),( opts.color and opts.color[3] or 0 ),1 end
			}
		
		o.args.bars.args.spellList3.args.desc2.args.color_on = {
				order = 11,width = "half",name = L["Own color"],type = "toggle",
				set = function(info,val) opts.color_on = not opts.color_on; end,
				get = function(info) return opts.color_on end
			}
		o.args.bars.args.spellList3.args.desc3 = {
				name	= L["StatusBar configurations"],
				order	= 12,
				type = "group", embend = true,
				args = {},
			}
		o.args.bars.args.spellList3.args.desc3.args.custom_text = {
				type = "editbox",	order	= 13,
				name = L["Custom Text"],
				desc = L["Custom Text Desc"],
				set = function(info,val) 
					local num = tostring(val)				
					if num then opts.custom_text = num end
					self:PreCacheCustomTextCheck();
				end,
				get = function(info) return opts.custom_text and tostring(opts.custom_text) or "" end
			}
		o.args.bars.args.spellList3.args.desc3.args.custom_text_on= {
				order = 14,name = L["Custom Text On"],type = "toggle",
				set = function(info,val) opts.custom_text_on = not opts.custom_text_on; self:PreCacheCustomTextCheck(); end,
				get = function(info) return opts.custom_text_on end
			}
		o.args.bars.args.spellList3.args.desc4 = {
				name	= L["Sorting"],
				order	= 15,
				type = "group", embend = true,
				args = {},
			}
			
		o.args.bars.args.spellList3.args.desc4.args.priority = {
				name = L["Priority"],
				type = "slider",
				order	= 16,
				min		= -20,
				max		= 20,
				step	= 1,
				set = function(info,val) 
					opts.priority = val
				end,
				get = function(info)
					return opts.priority
				end,
			}
		o.args.bars.args.spellList3.args.desc4.args.anchor = {
				name = L["Select Anchor"],
				order = 17,
				desc = L["Select Anchor Desc"],
				type = "dropdown",
				values = function()
					local t = {}							
					for k,v in ipairs(self.db.profile.bars_anchors) do						
						t[k] = v.name or k
					end							
					return t
				end,
				set = function(info,val)
					opts.set_anchor = val
				end,
				get = function(info, val) 
					return opts.set_anchor or 1
				end
			}
		o.args.bars.args.spellList3.args.desc4.args.group = {
				name = L["Select group"],
				order = 18,
				desc = L["Select group Desc"],
				type = "dropdown",
				values = groupSorting,
				set = function(info,val)
					opts.group = val
				end,
				get = function(info, val) 
					return opts.group or "auto"
				end
			}
		o.args.bars.args.spellList3.args.filterHeader = {
				name	= L["Filters"],
				order	= 19,
				type = "group", embend = true, args = {}
			}
		o.args.bars.args.spellList3.args.filterHeader.args.whitelist = {
				name = L["White List"],
				order = 20,
				desc = L["White List Desc"],
				type = "dropdown",
				values = filters,
				set = function(info,val)
					opts.whitelist = val
				end,
				get = function(info, val) 
					return opts.whitelist or 1
				end
			}
		o.args.bars.args.spellList3.args.filterHeader.args.blacklist = {
				name = L["Black List"],
				order = 21,
				desc = L["Black List Desc"],
				type = "dropdown",
				values = filters,
				set = function(info,val)
					opts.blacklist = val
				end,
				get = function(info, val) 
					return opts.blacklist or 1
				end
			}
		o.args.bars.args.spellList3.args.filterHeader.args.affilation = {
				name = L["Source affiliation"],
				desc = L["Source affiliation desc"],				
				order = 22,
				type = "dropdown",
				values = affiliation,
				set = function(info,val)
					opts.source = val
				end,
				get = function(info, val) 
					return opts.source or 2
				end
			}
		o.args.bars.args.spellList3.args.filterHeader.args.affilation_targ = {
				name = L["Target affiliation"],
				desc = L["Target affiliation desc"],				
				order = 22.1,
				type = "dropdown",
				values = affiliation,
				set = function(info,val)
					opts.target_affil = val
				end,
				get = function(info, val) 
					return opts.target_affil or 1
				end
			}
			
		o.args.bars.args.spellList3.args.SoundFile = {					
			type = "group",	order	= 23.1,
			embend = true,
			name	= L["Sound"],
			args = {						
				OnShow = {
					order = 1,type = 'sound',name = L["On Show"],
				--	dialogControl = 'LSM30_Sound',
					values = LSM:HashTable("sound"),
					set = function(info,value) opts.sound_onshow = value end,
					get = function(info) return opts.sound_onshow or "None" ; end,
				},
				OnHide = {
					order = 1,type = 'sound',name = L["On Hide"],
				--	dialogControl = 'LSM30_Sound',
					values = LSM:HashTable("sound"),
					set = function(info,value) opts.sound_onhide = value end,
					get = function(info) return opts.sound_onhide or "None"; end,
				},
			}
		}
		
		o.args.bars.args.spellList3.args.delete = {
			type = 'execute',
			order = 24,
			name = L['SemiDelete'],
			desc = L['SemiDelDesc'],
			func = function(info, value)
				opts.deleted = true
				class_select = nil
				wipe(o.args.bars.args.spellList3.args)
						
				o.args.bars.args.spellList3.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.othersSpells) do	
								if not v.deleted and not v.fulldel then
									local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
									t[g_spellID or k] = g_spellName or SpellString(k, 10)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:OthersSpell(val)
						end,
						get = function(info, val)
							return class_select
						end
					}
				o.args.bars.args.spellList3.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Spell_EditBox_SPTimer",
						
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "others")
								end	
							end
						end,
						get = function(info)end
					}
			end,
		}
		
		o.args.bars.args.spellList3.args.fulldelete = {
			type = 'execute',
			order = 24,
			name = L['Full delete'],
			desc = L['FullDelDesc'],
			func = function(info, value)
				opts.fulldel = true
				class_select = nil
				wipe(o.args.bars.args.spellList3.args)
						
				o.args.bars.args.spellList3.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.othersSpells) do	
								if not v.deleted and not v.fulldel then
									local g_spellID, g_spellName  = IsGroupUpSpell(k)
											
									t[g_spellID or k] = g_spellName or SpellString(k, 10)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:OthersSpell(val)
						end,
						get = function(info, val)
							return class_select
						end
					}
				o.args.bars.args.spellList3.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Spell_EditBox_SPTimer",
						
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "others")
								end	
							end
						end,
						get = function(info)end
					}
			end,
		}
	end


local function get_sort_value(name, value)
	local t = C.db.profile.bars_anchors[anchor_value].sorting
	
	for k,v in ipairs(t) do	
		if v.name == name then 
			return v[value]
		end
	end
	
end

local function set_sort_value(name, value, arg)
	local t = C.db.profile.bars_anchors[anchor_value].sorting
	
	for k,v in ipairs(t) do	
		if v.name == name then 
			v[value] = arg
		end
	end
end

local function get_sort_order(val)
	local t = C.db.profile.bars_anchors[anchor_value].sorting
	
	for k,v in ipairs(t) do	
		if v.name == val then 
			return k
		end
	end
end

local function update_sort_order(name, val)
	local t = C.db.profile.bars_anchors[anchor_value].sorting	
	local old_val
	local old_tbl
	
	local from, to
	
	
	for i, tb in ipairs(t) do
		if name == tb.name then
			old_val = tb.sort			
			from = tb
		end
		
		if val == tb.sort then
			to = tb
		end
	end
	
	from.sort = val
	to.sort = old_val
	
	tsort(t, function(x,y)
		return x.sort < y.sort 
	end)
end

function C:SetAnchorTable(value)
	anchor_value = value

	o.args.bars.args.style.args.StatusBarGroup = {
		type = "group",
		name = L["StatusBar configurations"],
		order = 2,
		embend = true,args = {},	
	}
	
	
	o.args.bars.args.style.args.StatusBarGroup.args.Anchor_copy = {
			name = L["Copy settings from"],
			order = 2.1,
			desc = L["Select Anchor"],
			type = "dropdown",
			values = function()
				local t = {}
									
				for k,v in ipairs(self.db.profile.bars_anchors) do
					if k ~= anchor_value then 
						t[k] = v.name or k
					end
				end
									
				return t
			end,
			set = function(info,val)
				if anchor_value and anchor_value ~= val then
					C:CopySettings(val, anchor_value)
				end
			end,
			get = function(info, val) end
		}
		
	o.args.bars.args.style.args.StatusBarGroup.args.Anchor_name = {
			type = "editbox", order	= 2.11,
			name = L["Name"],
			set = function(info,val) 
				
				if val and val ~= "" then self.db.profile.bars_anchors[anchor_value].name = val end
			end,
			get = function(info)
				return self.db.profile.bars_anchors[anchor_value].name 
			end
		}
		
	o.args.bars.args.style.args.StatusBarGroup.args.left_icon = {
			order = 3,name = L["Show left icon"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].left_icon = not self.db.profile.bars_anchors[anchor_value].left_icon; self:Visibility()	end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].left_icon end
		}
	o.args.bars.args.style.args.StatusBarGroup.args.right_icon = {
			order = 4,name = L["Show right icon"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].right_icon = not self.db.profile.bars_anchors[anchor_value].right_icon; self:Visibility() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].right_icon end
		}	
	o.args.bars.args.style.args.StatusBarGroup.args.add_up = {
			order = 5,name = L["Grow up"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].add_up = not self.db.profile.bars_anchors[anchor_value].add_up; self:UpdateBarsSize(); end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].add_up end
		}
	o.args.bars.args.style.args.StatusBarGroup.args.target_name = {
			order = 6,name = L["Show target name"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].target_name = not self.db.profile.bars_anchors[anchor_value].target_name; self:UpdateFormatTexts(anchor_value) end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].target_name end
		}
	o.args.bars.args.style.args.StatusBarGroup.args.short_name = {
			order = 7,name = L["Short bar text"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].short = not self.db.profile.bars_anchors[anchor_value].short; self:UpdateFormatTexts(anchor_value); self:ResetColoredNameCache() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].short end
		}
	o.args.bars.args.style.args.StatusBarGroup.args.debug_info = {
			order = 8,name = L["Show debug info"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].debug_info = not self.db.profile.bars_anchors[anchor_value].debug_info; self:UpdateFormatTexts(anchor_value) end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].debug_info end
		}
	o.args.bars.args.style.args.StatusBarGroup.args.timer_left = {
			order = 9,name = L["Timer text on left"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].lefttext = not self.db.profile.bars_anchors[anchor_value].lefttext; self:Update_TimeText(); self:Update_SpellText()end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].lefttext end
		}
	
	o.args.bars.args.style.args.StatusBarGroup.args.reverse_fill = {
			order = 9.1,name = L["Revers bar filling"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].reverse_fill = not self.db.profile.bars_anchors[anchor_value].reverse_fill; self:Visibility() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].reverse_fill end
		}	
		
	o.args.bars.args.style.args.StatusBarGroup.args.show_header = {
			order = 9.2,name = L["Group Header"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].show_header = not self.db.profile.bars_anchors[anchor_value].show_header; self:updateSortings() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].show_header end
		}
		
	o.args.bars.args.style.args.StatusBarGroup.args.show_header_setup = {
		order = 9.3,name = L["Group Settings"], type = "execute", -- o.args.bars.args.style.args.group_header_settings
		set = function(info,val) AleaUI_GUI:SelectGroup(addon, 'bars', "style", "group_header_settings"); end,
		get = function(info) return  end
	}	
		
	o.args.bars.args.style.args.StatusBarGroup.args.bar_number = {
			name = L["Bar Number"],
			desc = L["Set Max bars number"],
			type = "slider",
			order	= 10,
			min		= 1,
			max		= 20,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].bar_number = val
				self:InitFrames()
			end,
			get =function(info)
				return self.db.profile.bars_anchors[anchor_value].bar_number
			end,
		}
		
	o.args.bars.args.style.args.StatusBarGroup.args.format_s = {
		name = L["Time format"],
		order = 11,
		desc = L["Select timer format Desc"],
		type = "dropdown",						
		values = bar_timer_format,
		set = function(info,val)
			self.db.profile.bars_anchors[anchor_value].fortam_s = val
		end,
		get = function(info, val) 
			return self.db.profile.bars_anchors[anchor_value].fortam_s
		end
			}
	o.args.bars.args.style.args.StatusBarGroup.args.bg = {
			order = 12,type = 'statusbar',name = L["Main Texture"],
		--	dialogControl = 'LSM30_Statusbar',
			values = LSM:HashTable("statusbar"),
			set = function(info,value) self.db.profile.bars_anchors[anchor_value].bar.texture = value; self:Visibility() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].bar.texture end,
		}
	o.args.bars.args.style.args.StatusBarGroup.args.bg_bg = {
			order = 13,type = 'statusbar',name = L["Background Texture"], 
		--	dialogControl = 'LSM30_Statusbar',
			values = LSM:HashTable("statusbar"),
			set = function(info,value) self.db.profile.bars_anchors[anchor_value].bar.bgtexture = value; self:Visibility() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].bar.bgtexture end,
		}
	o.args.bars.args.style.args.StatusBarGroup.args.bg_color = {
			order = 14,name = L["Texture Color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].bar.color={r,g,b,a}; self:Visibility()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].bar.color[1],self.db.profile.bars_anchors[anchor_value].bar.color[2],self.db.profile.bars_anchors[anchor_value].bar.color[3],self.db.profile.bars_anchors[anchor_value].bar.color[4] end
		}
	o.args.bars.args.style.args.StatusBarGroup.args.bg_color2 = {
			order = 15,name = L["Background Color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].bar.bgcolor={r,g,b,a}; self:Visibility()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].bar.bgcolor[1],self.db.profile.bars_anchors[anchor_value].bar.bgcolor[2],self.db.profile.bars_anchors[anchor_value].bar.bgcolor[3],self.db.profile.bars_anchors[anchor_value].bar.bgcolor[4]  end
		}
		
	o.args.bars.args.style.args.StatusBarGroup.args.pandemia_color = {
			order = 15.1,name = L["Pandemia breakpoint color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].pandemia_color={r,g,b,a}; self:Visibility()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].pandemia_color[1],self.db.profile.bars_anchors[anchor_value].pandemia_color[2],self.db.profile.bars_anchors[anchor_value].pandemia_color[3],self.db.profile.bars_anchors[anchor_value].pandemia_color[4]  end
		}
	o.args.bars.args.style.args.StatusBarGroup.args.shine_on_apply = {
			order = 15.2,name = "Shine on apply",type = "toggle",
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].shine_on_apply = not self.db.profile.bars_anchors[anchor_value].shine_on_apply; end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].shine_on_apply end						
		}
	o.args.bars.args.style.args.StatusBarGroup.args.w = {
			name = L["Width"],
			type = "slider",
			order	= 16,
			min		= 1,
			max		= 1920, --400,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].w = val
				self:UpdateBarsSize()
			end,
			get =function(info)
				return self.db.profile.bars_anchors[anchor_value].w
			end,
		}
	o.args.bars.args.style.args.StatusBarGroup.args.h = {
			name = L["Height"],
			type = "slider",
			order	= 17,
			min		= 1,
			max		= 200,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].h = val
				--self:InitFrames()
				
				self:UpdateBarsSize()
			end,
			get =function(info)
				return self.db.profile.bars_anchors[anchor_value].h
			end,
		}
	
	o.args.bars.args.style.args.StatusBarGroup.args.gap = {
		name = L["Gap"],
		type = "slider",
		order	= 18,
		min		= 0,
		max		= 32,
		step	= 1,
		set = function(info,val) 
			self.db.profile.bars_anchors[anchor_value].gap = val
			self:updateSortings()
		end,
		get =function(info)
			return self.db.profile.bars_anchors[anchor_value].gap
			end,
		}
		
	o.args.bars.args.style.args.StatusBarGroup.args.icon_gap = {
		name = L["Icon Gap"],
		type = "slider",
		order	= 18,
		min		= -32,
		max		= 32,
		step	= 1,
		set = function(info,val) 
			self.db.profile.bars_anchors[anchor_value].icon_gap = val
			self:UpdateAllBorder()
		end,
		get =function(info)
			return self.db.profile.bars_anchors[anchor_value].icon_gap
		end,
		}
	------------------------------------------------------------
	o.args.bars.args.style.args.deskBorder = {
			type = "group",
			name = L["Border configuration"],
			order = 19,
			embend = true, args = {},
		}
	o.args.bars.args.style.args.deskBorder.args.border = {
		order = 19.1,type = 'border',name = L["Border Texture"],
	--	dialogControl = 'LSM30_Border',
		values = LSM:HashTable("border"),
		set = function(info,value) self.db.profile.bars_anchors[anchor_value].border = value; self:UpdateAllBorder() end,
		get = function(info) return self.db.profile.bars_anchors[anchor_value].border end,
	}
					
	o.args.bars.args.style.args.deskBorder.args.bordercolor = {
		order = 19.2,name = L["Border Color"],type = "color", hasAlpha = true,
		set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].bordercolor={r,g,b,a}; self:UpdateAllBorder()  end,
		get = function(info) return self.db.profile.bars_anchors[anchor_value].bordercolor[1],self.db.profile.bars_anchors[anchor_value].bordercolor[2],self.db.profile.bars_anchors[anchor_value].bordercolor[3],self.db.profile.bars_anchors[anchor_value].bordercolor[4] end
	}
					
	o.args.bars.args.style.args.deskBorder.args.bordersize = {
		name = L["Border Size"],
		desc = L["Set Border Size"],
		type = "slider",
		order	= 19.3,
		min		= 0,
		max		= 32,
		step	= 1,
		set = function(info,val) 
			self.db.profile.bars_anchors[anchor_value].bordersize = val
			self:UpdateAllBorder()
		end,
		get =function(info)
			return self.db.profile.bars_anchors[anchor_value].bordersize
		end,
	}
	o.args.bars.args.style.args.deskBorder.args.borderinset = {
		name = L["Border Inset"],
		desc = L["Set Border Inset"],
		type = "slider",
		order	= 19.4,
		min		= 0,
		max		= 32,
		step	= 1,
		set = function(info,val) 
			self.db.profile.bars_anchors[anchor_value].borderinset = val
			self:UpdateAllBorder()
		end,
		get =function(info)
			return self.db.profile.bars_anchors[anchor_value].borderinset
			end,
		}
		
	---------------------------------------------------------------------
	
	o.args.bars.args.style.args.overlay_color_desc = {
			type = "group",
			name = L["Overlay Config"],
			order = 19.5, embend = true, args = {},
		}
		
	o.args.bars.args.style.args.overlay_color_desc.args.overlay_color = {
			order = 19.6,name = L["Color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].overlays.color={r,g,b,a}; self:UpdateBackgroundBarColor()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].overlays.color[1],self.db.profile.bars_anchors[anchor_value].overlays.color[2],self.db.profile.bars_anchors[anchor_value].overlays.color[3],self.db.profile.bars_anchors[anchor_value].overlays.color[4] end
		}
		
		--[[
	o.args.bars.args.style.args.overlay_color = {
			order = 19.6,name = "Color",type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) ALEAUI_COLOR_HAMEL1={r,g,b,a}; UPDATE_COLOR_HAMELEON()  end,
			get = function(info) return ALEAUI_COLOR_HAMEL1[1],ALEAUI_COLOR_HAMEL1[2],ALEAUI_COLOR_HAMEL1[3],ALEAUI_COLOR_HAMEL1[4] end
		}
		]]
	o.args.bars.args.style.args.overlay_color_desc.args.overlay_color_on = {
			order = 19.7,name = L["Auto color"],type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].overlays.auto = not self.db.profile.bars_anchors[anchor_value].overlays.auto; self:UpdateBackgroundBarColor(); end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].overlays.auto end
		}
		
	---------------------------------------------------------------------
	
	o.args.bars.args.style.args.desc_spark = {
			type = "group",
			name = L["Spark Config"],
			order = 23.1,
			embend = true, args = {},
		}
	o.args.bars.args.style.args.desc_spark.args.spark_color = {
			order = 23.2,name = L["Color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].castspark.color={r,g,b,a}; self:UpdateAllSparks()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].castspark.color[1],self.db.profile.bars_anchors[anchor_value].castspark.color[2],self.db.profile.bars_anchors[anchor_value].castspark.color[3],self.db.profile.bars_anchors[anchor_value].castspark.color[4] end
		}
	o.args.bars.args.style.args.desc_spark.args.spark_ontop = {
				order = 23.3,name = L["On Top"],type = "toggle",
				set = function(info,val) self.db.profile.bars_anchors[anchor_value].spark_ontop = not self.db.profile.bars_anchors[anchor_value].spark_ontop; self:UpdateAllSparks(); end,
				get = function(info) return self.db.profile.bars_anchors[anchor_value].spark_ontop end
			}
		--[[
	o.args.bars.args.style.args.desc_spark.args.spark_width = {
			name = "Width",
			type = "slider",
			disabled = true,
			order	= 23.4,
			min		= 0,
			max		= 100,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].castspark.w = val
				self:UpdateAllSparks()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].castspark.w
			end,
		}
	o.args.bars.args.style.args.desc_spark.args.spark_height = {
			name = "Height",
			type = "slider",
			disabled = true,
			order	= 23.5,
			min		= 0,
			max		= 100,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].castspark.h = val
				self:UpdateAllSparks()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].castspark.h
			end,
		}
		]]
		
		--[[
	o.args.bars.args.style.args.spark_alpha = {
			name = "Alpha",
			type = "slider",
			order	= 23.5,
			min		= 0,
			max		= 1,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].castspark.alpha = val
				self:UpdateAllSparks()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].castspark.alpha
			end,
		}
		]]
	o.args.bars.args.style.args.desc_ticks = {
			type = "group",
			name = L["Ticks Config"],
			order = 23.6, embend = true, args = {},
		}
		--[[
	o.args.bars.args.style.args.ticks_alpha = {
			name = "Alpha",
			type = "slider",
			order	= 23.8,
			min		= 0,
			max		= 1,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].dotticks.alpha = val
				self:UpdateAllTiks()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].dotticks.alpha
			end,
		}
		]]
		
	o.args.bars.args.style.args.desc_ticks.args.tick_ontop = {
				order = 23.8,name = L["On Top"],type = "toggle",
				set = function(info,val) self.db.profile.bars_anchors[anchor_value].tick_ontop = not self.db.profile.bars_anchors[anchor_value].tick_ontop; self:UpdateAllTiks();self:Update_SpellText(); end,
				get = function(info) return self.db.profile.bars_anchors[anchor_value].tick_ontop end
			}
			
	o.args.bars.args.style.args.desc_ticks.args.ticks_color = {
			order = 23.7,name = L["Color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].dotticks.color={r,g,b,a}; self:UpdateAllTiks()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].dotticks.color[1],self.db.profile.bars_anchors[anchor_value].dotticks.color[2],self.db.profile.bars_anchors[anchor_value].dotticks.color[3],self.db.profile.bars_anchors[anchor_value].dotticks.color[4] end
		}

	-------------------------------------------------------------------	
	o.args.bars.args.style.args.desc2 = {
			type = "group",
			name = L["Stack Text configuration"],
			order = 24, embend = true, args = {},
		}
	o.args.bars.args.style.args.desc2.args.stack_textcolor = {
			order = 25,name = L["Text color"],type = "color",
			set = function(info,r,g,b) self.db.profile.bars_anchors[anchor_value].stack.textcolor={r,g,b}; self:Update_StackText()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].stack.textcolor[1],self.db.profile.bars_anchors[anchor_value].stack.textcolor[2],self.db.profile.bars_anchors[anchor_value].stack.textcolor[3],1 end
		}
	o.args.bars.args.style.args.desc2.args.stack_font = {
			order = 26,name = L["Font"],type = 'font',
		--	dialogControl = 'LSM30_Font',
			values = LSM:HashTable("font"),
			set = function(info,key) self.db.profile.bars_anchors[anchor_value].stack.font = key; self:Update_StackText() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].stack.font end,
		}
	o.args.bars.args.style.args.desc2.args.stack_font_size = {
			name = L["Size"],
			type = "slider",
			order	= 27,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].stack.size = val
				self:Update_StackText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].stack.size
			end,
		}
	o.args.bars.args.style.args.desc2.args.stack_justifu = {
			type = "dropdown",	order = 28,
			name = L["Justify"],
			values = justifu,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].stack.justify = val
				self:Update_StackText()
			end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].stack.justify end
		}			
	o.args.bars.args.style.args.desc2.args.stack_text_flaggs = {
			type = "dropdown",	order = 29,
			name = L["Flags"],
			values = text_flaggs,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].stack.flags = val
				self:Update_StackText()
			end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].stack.flags end
		}
	o.args.bars.args.style.args.desc2.args.stack_font_alpha = {
			name = L["Transparent"],
			type = "slider",
			order	= 29.1,
			min		= 0,
			max		= 1,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].stack.alpha = val
				self:Update_StackText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].stack.alpha
			end,
		}
	
	o.args.bars.args.style.args.desc2.args.shadowsettings = {
			type = "group",
			name = L["Font shadow"],
			order = 29.2, embend = true, args = {}
		}
	o.args.bars.args.style.args.desc2.args.shadowsettings.args.stack_shadow_color = {
			order = 29.2,name = L["Shadow color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) 
				
				self.db.profile.bars_anchors[anchor_value].stack.shadow={r,g,b,a}; 
				self:Update_StackText()  
			end,

			get = function(info)
				local color = self.db.profile.bars_anchors[anchor_value].stack.shadow or { 0, 0, 0, 1}			
				return color[1],color[2],color[3],color[4] 
			end
		}
		
	o.args.bars.args.style.args.desc2.args.shadowsettings.args.stack_shadow_offset_x = {
			name = L["Shadow offset X"],
			type = "slider",
			order	= 29.3,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].stack.offset then self.db.profile.bars_anchors[anchor_value].stack.offset = {} end

				self.db.profile.bars_anchors[anchor_value].stack.offset[1] = val
				self:Update_StackText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].stack.offset and self.db.profile.bars_anchors[anchor_value].stack.offset[1] or 0
			end,
		}
		
	o.args.bars.args.style.args.desc2.args.shadowsettings.args.stack_shadow_offset_y = {
			name = L["Shadow offset Y"],
			type = "slider",
			order	= 29.4,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].stack.offset then self.db.profile.bars_anchors[anchor_value].stack.offset = {} end

				self.db.profile.bars_anchors[anchor_value].stack.offset[2] = val
				self:Update_StackText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].stack.offset and self.db.profile.bars_anchors[anchor_value].stack.offset[2] or 0
			end,
		}
	o.args.bars.args.style.args.desc3 = {
			type = "group",
			name = L["Timer Text configuration"],
			order = 30, embend = true, args = {}
		}	
	o.args.bars.args.style.args.desc3.args.timer_textcolor = {
			order = 31,name = L["Text color"],type = "color",
			set = function(info,r,g,b) self.db.profile.bars_anchors[anchor_value].timer.textcolor={r,g,b}; self:Update_TimeText() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].timer.textcolor[1],self.db.profile.bars_anchors[anchor_value].timer.textcolor[2],self.db.profile.bars_anchors[anchor_value].timer.textcolor[3],1 end
		}
	o.args.bars.args.style.args.desc3.args.timer_font = {
			order = 32,name = L["Font"],type = 'font',
		--	dialogControl = 'LSM30_Font',
			values = LSM:HashTable("font"),
			set = function(info,key) self.db.profile.bars_anchors[anchor_value].timer.font = key; self:Update_TimeText() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].timer.font end,
		}
	o.args.bars.args.style.args.desc3.args.timer_font_size = {
			name = L["Size"],
			type = "slider",
			order	= 33,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].timer.size = val
				self:Update_TimeText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].timer.size
			end,
		}
	o.args.bars.args.style.args.desc3.args.timer_justifu = {
			type = "dropdown",	order = 34,
			name = L["Justify"],
			values = justifu,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].timer.justify = val
				self:Update_TimeText()
			end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].timer.justify end
		}			
	o.args.bars.args.style.args.desc3.args.timer_text_flaggs = {
			type = "dropdown",	order = 35,
			name = L["Flags"],
			values = text_flaggs,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].timer.flags = val
				self:Update_TimeText()
			end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].timer.flags end
		}
	o.args.bars.args.style.args.desc3.args.timer_font_alpha = {
			name = L["Transparent"],
			type = "slider",
			order	= 35.1,
			min		= 0,
			max		= 1,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].timer.alpha = val
				self:Update_TimeText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].timer.alpha
			end,
		}
		
	o.args.bars.args.style.args.desc3.args.shadowsettings = {
			type = "group",
			name = L["Font shadow"],
			order = 35.2, embend = true, args = {}
		}
		
	o.args.bars.args.style.args.desc3.args.shadowsettings.args.timer_shadow_color = {
			order = 35.2,name = L["Shadow color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].timer.shadow={r,g,b,a}; self:Update_TimeText()  end,
			get = function(info) 
				local color = self.db.profile.bars_anchors[anchor_value].timer.shadow or { 0, 0, 0, 1}			
				return color[1],color[2],color[3],color[4]
			end
		}
		
	o.args.bars.args.style.args.desc3.args.shadowsettings.args.timer_shadow_offset_x = {
			name = L["Shadow offset X"],
			type = "slider",
			order	= 35.3,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].timer.offset then self.db.profile.bars_anchors[anchor_value].timer.offset = {} end

				self.db.profile.bars_anchors[anchor_value].timer.offset[1] = val
				self:Update_TimeText()
			end,
			get = function(info)
				return self.db.profile.bars_anchors[anchor_value].timer.offset and self.db.profile.bars_anchors[anchor_value].timer.offset[1] or 0
			end,
		}
		
	o.args.bars.args.style.args.desc3.args.shadowsettings.args.timer_shadow_offset_y = {
			name = L["Shadow offset Y"],
			type = "slider",
			order	= 35.4,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].timer.offset then self.db.profile.bars_anchors[anchor_value].timer.offset = {} end

				self.db.profile.bars_anchors[anchor_value].timer.offset[2] = val
				self:Update_TimeText()
			end,
			get = function(info)
				return self.db.profile.bars_anchors[anchor_value].timer.offset and self.db.profile.bars_anchors[anchor_value].timer.offset[2] or 0
			end,
		}
	o.args.bars.args.style.args.desc4 = {
			type = "group",
			name = L["Spell Text configuration."],
			order = 36, embend = true, args = {},
		}	
	o.args.bars.args.style.args.desc4.args.spell_textcolor = {
			order = 37,name = L["Text color"],type = "color",
			set = function(info,r,g,b) self.db.profile.bars_anchors[anchor_value].spell.textcolor={r,g,b}; self:Update_SpellText()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].spell.textcolor[1],self.db.profile.bars_anchors[anchor_value].spell.textcolor[2],self.db.profile.bars_anchors[anchor_value].spell.textcolor[3],1 end
		}
	o.args.bars.args.style.args.desc4.args.spell_font = {
			order = 38,name = L["Font"],type = 'font',
		--	dialogControl = 'LSM30_Font',
			values = LSM:HashTable("font"), --LSM:HashTable("font"),
			set = function(info,key) 
				self.db.profile.bars_anchors[anchor_value].spell.font = key
				self:Update_SpellText() 
			end,
			get = function(info) 
				--print("spell_text_flaggs", self.db.profile.bars_anchors[anchor_value].spell.font, anchor_value)
				return self.db.profile.bars_anchors[anchor_value].spell.font 
			end,
		}
	o.args.bars.args.style.args.desc4.args.spell_font_size = {
			name = L["Size"],
			type = "slider",
			order	= 39,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].spell.size = val
				self:Update_SpellText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].spell.size
			end,
		}
	o.args.bars.args.style.args.desc4.args.spell_justifu = {
			type = "dropdown",	order = 40,
			name = L["Justify"],
			values = justifu,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].spell.justify = val
				self:Update_SpellText()
			end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].spell.justify end
		}		
	o.args.bars.args.style.args.desc4.args.spell_text_flaggs = {
			type = "dropdown",	order = 41,
			name = L["Flags"],
			values = text_flaggs,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].spell.flags = val
				self:Update_SpellText()
			end,
			get = function(info)
				return self.db.profile.bars_anchors[anchor_value].spell.flags 
			end
		}
	o.args.bars.args.style.args.desc4.args.spell_font_alpha = {
			name = L["Transparent"],
			type = "slider",
			order	= 41.1,
			min		= 0,
			max		= 1,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].spell.alpha = val
				self:Update_SpellText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].spell.alpha
			end,
		}
	o.args.bars.args.style.args.desc4.args.spell_text_offset = {
			name = L["Offset X"],
			type = "slider",
			order	= 41.2,
			min		= -300,
			max		= 300,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].spell.offsetx = val
				self:Update_SpellText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].spell.offsetx
			end,
		}
	
	o.args.bars.args.style.args.desc4.args.shadowsettings = {
			type = "group",
			name = L["Font shadow"],
			order = 41.3, embend = true, args = {}
		}
		
	o.args.bars.args.style.args.desc4.args.shadowsettings.args.spell_shadow_color = {
			order = 41.3,name = L["Shadow color"] ,type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].spell.shadow={r,g,b,a}; self:Update_SpellText()  end,
			get = function(info) 
				local color = self.db.profile.bars_anchors[anchor_value].spell.shadow or { 0, 0, 0, 1}			
				return color[1],color[2],color[3],color[4]
			end
		}
		
	o.args.bars.args.style.args.desc4.args.shadowsettings.args.spell_shadow_offset_x = {
			name = L["Shadow offset X"],
			type = "slider",
			order	= 41.4,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].spell.offset then self.db.profile.bars_anchors[anchor_value].spell.offset = {} end

				self.db.profile.bars_anchors[anchor_value].spell.offset[1] = val
				self:Update_SpellText()
			end,
			get = function(info)
				return self.db.profile.bars_anchors[anchor_value].spell.offset and self.db.profile.bars_anchors[anchor_value].spell.offset[1] or 0
			end,
		}
		
	o.args.bars.args.style.args.desc4.args.shadowsettings.args.spell_shadow_offset_y = {
			name = L["Shadow offset Y"],
			type = "slider",
			order	= 41.5,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].spell.offset then self.db.profile.bars_anchors[anchor_value].spell.offset = {} end

				self.db.profile.bars_anchors[anchor_value].spell.offset[2] = val
				self:Update_SpellText()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].spell.offset and self.db.profile.bars_anchors[anchor_value].spell.offset[2] or 0
			end,
		}
		
	o.args.bars.args.style.args.descRaidIcon = {
			type = "group",
			name = L["Raid Mark configuration"],
			order = 41.6, embend = true, args = {},
		}
	o.args.bars.args.style.args.descRaidIcon.args.raidiconsize = {
			name = L["Size"],
			type = "slider",
			order	= 41.7,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].raidiconsize = val
				self:UpdateRaidIcons()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].raidiconsize or 10
			end,
		}
	
	o.args.bars.args.style.args.descRaidIcon.args.raidicon_xOffset = {
			name = L["Offset X"],
			type = "slider",
			order	= 41.8,
			min		= -1000,
			max		= 1000,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].raidicon_xOffset = val
				self:UpdateRaidIcons()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].raidicon_xOffset or 0
			end,
		}
	
	o.args.bars.args.style.args.descRaidIcon.args.raidicon_y = {
			name = L["Offset Y"],
			type = "slider",
			order	= 41.9,
			min		= -50,
			max		= 50,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].raidicon_y = val
				self:UpdateRaidIcons()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].raidicon_y or 5
			end,
		}
		
	o.args.bars.args.style.args.descRaidIcon.args.raidicon_alpha = {
			name = L["Transparent"],
			type = "slider",
			order	= 41.10,
			min		= 0,
			max		= 1,
			step	= 0.1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].raidicon_alpha = val
				self:UpdateRaidIcons()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].raidicon_alpha or 1
			end,
		}
	
	o.args.bars.args.style.args.group_header_settings = {
		
			type = "group",	order	= 41.11,
			name	= L["Group Settings"],
			args = {}
		}
	o.args.bars.args.style.args.group_header_settings.args.goBack = {
		order = 1, name = L['Back'], type = 'execute', width = 'full',
		set = function(info)
			AleaUI_GUI:SelectGroup(addon, 'bars', "style");
		end,
		get = function(info)
	
		end,
	}
	
	o.args.bars.args.style.args.group_header_settings.args.grow_up = {
			order = 1.1,name = L["Header on top"], type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].group_grow_up = not self.db.profile.bars_anchors[anchor_value].group_grow_up;self:updateSortings() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].group_grow_up end
		}
		
	o.args.bars.args.style.args.group_header_settings.args.group_bg_show = {
			order = 1,name = L["Show Background"], type = "toggle",
			set = function(info,val) self.db.profile.bars_anchors[anchor_value].group_bg_show = not self.db.profile.bars_anchors[anchor_value].group_bg_show;self:updateSortings() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].group_bg_show end
		}
	
	o.args.bars.args.style.args.group_header_settings.args.fontsettings = {
			type = "group",
			name = L["Font"],
			order = 9, embend = true, args = {}
		}
		
	o.args.bars.args.style.args.group_header_settings.args.fontsettings.args.textcolor = {
			order = 1.2,name = L["Text color"],type = "color",
			set = function(info,r,g,b) self.db.profile.bars_anchors[anchor_value].group_font_target_colorr={r,g,b}; self:UpdateLabelStyle(); self:updateSortings() end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].group_font_target_color[1],self.db.profile.bars_anchors[anchor_value].group_font_target_color[2],self.db.profile.bars_anchors[anchor_value].group_font_target_color[3],1 end
		}
	
	o.args.bars.args.style.args.group_header_settings.args.fontsettings.args.textcolorfocus = {
			order = 2,name = L["Focus Text color"],type = "color",
			set = function(info,r,g,b) self.db.profile.bars_anchors[anchor_value].group_font_focus_color={r,g,b}; self:UpdateLabelStyle(); self:updateSortings()  end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].group_font_focus_color[1],self.db.profile.bars_anchors[anchor_value].group_font_focus_color[2],self.db.profile.bars_anchors[anchor_value].group_font_focus_color[3],1 end
		}
		
	o.args.bars.args.style.args.group_header_settings.args.fontsettings.args.font = {
			order = 3,name = L["Font"],type = 'font',
		--	dialogControl = 'LSM30_Font',
			values = LSM:HashTable("font"), --LSM:HashTable("font"),
			set = function(info,key) 
				self.db.profile.bars_anchors[anchor_value].group_font_style.font = key
				self:UpdateLabelStyle()
			end,
			get = function(info) 
				--print("spell_text_flaggs", self.db.profile.bars_anchors[anchor_value].spell.font, anchor_value)
				return self.db.profile.bars_anchors[anchor_value].group_font_style.font 
			end,
		}
	o.args.bars.args.style.args.group_header_settings.args.fontsettings.args.size = {
			name = L["Size"],
			type = "slider",
			order	= 4,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].group_font_style.size = val
				self:UpdateLabelStyle()
				self:updateSortings()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].group_font_style.size
			end,
		}
		
	
		
	o.args.bars.args.style.args.group_header_settings.args.fontsettings.args.justifu = {
			type = "dropdown",	order = 5,
			name = L["Justify"],
			values = justifu,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].group_font_style.justify = val
				self:UpdateLabelStyle()
			end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].group_font_style.justify end
		}		
	o.args.bars.args.style.args.group_header_settings.args.fontsettings.args.flaggs = {
			type = "dropdown",	order = 6,
			name = L["Flags"],
			values = text_flaggs,
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].group_font_style.flags = val
				self:UpdateLabelStyle()
			end,
			get = function(info)
				return self.db.profile.bars_anchors[anchor_value].group_font_style.flags 
			end
		}
	
	o.args.bars.args.style.args.group_header_settings.args.shadowsettings = {
			type = "group",
			name = L["Font shadow"],
			order = 10, embend = true, args = {}
		}
		
	o.args.bars.args.style.args.group_header_settings.args.shadowsettings.args.shadow_color = {
		order = 8,name = L["Shadow color"],type = "color", hasAlpha = true,
		set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].group_font_style.shadow={r,g,b,a}; self:UpdateLabelStyle()  end,
		get = function(info) 
			local color = self.db.profile.bars_anchors[anchor_value].group_font_style.shadow or { 0, 0, 0, 1}			
			return color[1],color[2],color[3],color[4]
		end
	}
		
	o.args.bars.args.style.args.group_header_settings.args.shadowsettings.args.shadow_offset_x = {
			name = L["Shadow offset X"],
			type = "slider",
			order	= 9,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].group_font_style.offset then self.db.profile.bars_anchors[anchor_value].group_font_style.offset = {} end

				self.db.profile.bars_anchors[anchor_value].group_font_style.offset[1] = val
				self:UpdateLabelStyle()
			end,
			get = function(info)
				return self.db.profile.bars_anchors[anchor_value].group_font_style.offset and self.db.profile.bars_anchors[anchor_value].group_font_style.offset[1] or 0
			end,
		}
		
	o.args.bars.args.style.args.group_header_settings.args.shadowsettings.args.shadow_offset_y = {
			name = L["Shadow offset Y"],
			type = "slider",
			order	= 10,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.bars_anchors[anchor_value].group_font_style.offset then self.db.profile.bars_anchors[anchor_value].group_font_style.offset = {} end

				self.db.profile.bars_anchors[anchor_value].group_font_style.offset[2] = val
				self:UpdateLabelStyle()
			end,
			get = function(info)
				return	self.db.profile.bars_anchors[anchor_value].group_font_style.offset and self.db.profile.bars_anchors[anchor_value].group_font_style.offset[2] or 0
			end,
		}
	
	o.args.bars.args.style.args.group_header_settings.args.bg_color = {
			type = "group",
			name = L["Background color"],
			order = 11, embend = true, args = {}
		}
	
	o.args.bars.args.style.args.group_header_settings.args.bg_color.args.bg_target_color = {
		order = 12,name = L["Target color"],type = "color", hasAlpha = true,
		set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].group_bg_target_color={r,g,b,a}; self:UpdateLabelStyle()  end,
		get = function(info) 
			local color = self.db.profile.bars_anchors[anchor_value].group_bg_target_color		
			return color[1],color[2],color[3],color[4]
		end
	}
	
	o.args.bars.args.style.args.group_header_settings.args.bg_color.args.bg_focus_color = {
		order = 13,name = L["Focus color"],type = "color", hasAlpha = true,
		set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].group_bg_focus_color={r,g,b,a}; self:UpdateLabelStyle()  end,
		get = function(info) 
			local color = self.db.profile.bars_anchors[anchor_value].group_bg_focus_color	
			return color[1],color[2],color[3],color[4]
		end
	}
	
	o.args.bars.args.style.args.group_header_settings.args.bg_color.args.bg_offtarget_color = {
		order = 14,name = L["Offtargets color"],type = "color", hasAlpha = true,
		set = function(info,r,g,b,a) self.db.profile.bars_anchors[anchor_value].group_bg_offtargets_color={r,g,b,a}; self:UpdateLabelStyle()  end,
		get = function(info) 
			local color = self.db.profile.bars_anchors[anchor_value].group_bg_offtargets_color	
			return color[1],color[2],color[3],color[4]
		end
	}
	o.args.bars.args.style.args.group_header_settings.args.header_text_desc = {
		type = "group",
		name = L["Header text"],
		order = 15, embend = true, args = {},
	}
	
	for k,v in ipairs({"target", "player", "procs", "cooldowns", "offtargets"}) do
		o.args.bars.args.style.args.group_header_settings.args.header_text_desc.args[v.."textype"] = {
			name = v.." "..L["Type"],
			order = 15+k+0.2,
			type = "dropdown",						
			values = { 
				L["Show default name"],
				L["Show destination name"],
				L["Show custom name"],
			},
			set = function(info,val)
				self.db.profile.bars_anchors[anchor_value].header_custom_text[v][1] = val
			end,
			get = function(info, val) 
				return self.db.profile.bars_anchors[anchor_value].header_custom_text[v][1]
			end
		}	
	
		o.args.bars.args.style.args.group_header_settings.args.header_text_desc.args[v.."customtext"] = {
			type = "editbox",	order	= 15+k+0.1,
		--	width = "full",
			name = v.." "..L["Custom Text"],
			desc = L["Header custom text"],
			set = function(info,val) 
				self.db.profile.bars_anchors[anchor_value].header_custom_text[v][2] = val
			end,
			get = function(info) return self.db.profile.bars_anchors[anchor_value].header_custom_text[v][2] end

		}
	end
			
	o.args.bars.args.style.args.sortingdest = {
			type = "group",
			name = L["Sorting group configuration"],
			order = 42, embend = true, args = {}
		}
		
	o.args.bars.args.style.args.sortingdest.args.sort_func = {
		name = L["Sorting"],
		order = 42.1,
		type = "dropdown",
		width = "full",
		values = sorting_timer_table,
		set = function(info,val)
			self.db.profile.bars_anchors[anchor_value].sort_func = val; self:updateSortings()
		end,
		get = function(info, val) 
			return self.db.profile.bars_anchors[anchor_value].sort_func or 1
		end
	}
			
	for k,v in ipairs({"target", "player", "procs", "cooldowns", "offtargets"}) do		
		o.args.bars.args.style.args.sortingdest.args["sorting_group_"..v] = {	
			type = "group",	order	= 43+k*2,
			embend = true,
			name	= v,
			args = {}
		}
		
		
		o.args.bars.args.style.args.sortingdest.args["sorting_group_"..v].args.gap = {
			name = L["Gap"],
			type = "slider",
			order	= 1,
			min		= 0,
			max		= 50,
			step	= 1,
			set = function(info,val) 
			--	self.db.profile.bars_anchors[anchor_value].sorting[i].gap = val
				
				set_sort_value(v, "gap", val)
			end,
			get = function(info)
				return get_sort_value(v, "gap")-- self.db.profile.bars_anchors[anchor_value].sorting[i].gap
			end,
		}
		
		o.args.bars.args.style.args.sortingdest.args["sorting_group_"..v].args.alpha = {
			name = L["Transparent"],
			type = "slider",
			order	= 2,
			min		= 0,
			max		= 1,
			step	= 0.1,
			set = function(info,val) 
			--	self.db.profile.bars_anchors[anchor_value].sorting[i].alpha = val
				set_sort_value(v, "alpha", val)
			end,
			get = function(info)
				return get_sort_value(v, "alpha") -- self.db.profile.bars_anchors[anchor_value].sorting[i].alpha
			end,
		}
		
		if v ~= "offtargets" then
			o.args.bars.args.style.args.sortingdest.args["sorting_group_"..v].args.position = {
				name = L["Position"],
				order = 3,
				type = "dropdown",						
				values = { "1", "2", "3", "4" },
				set = function(info,val)
					update_sort_order(v, val)
				end,
				get = function(info, val) 
					return get_sort_value(v, "sort")
				end
			}						
		end
		
		o.args.bars.args.style.args.sortingdest.args["sorting_group_"..v].args.toggle = {
			name = L["Disabled"],
			type = "toggle",
			order	= 4,
			set = function(info,val) 
				set_sort_value(v, "disabled", not get_sort_value(v, "disabled"))
				C:updateSortings()
			end,
			get = function(info)
				return get_sort_value(v, "disabled") -- self.db.profile.bars_anchors[anchor_value].sorting[i].alpha
			end,
		}
	end
	--[[
	sorting = {
							{name = "target", 		gap = 10, alpha = 1, },
							{name = "player", 		gap = 10, alpha = 1, },
							{name = "procs",		gap = 15, alpha = .7 },
							{name = "offtargets",	gap = 6, alpha = .7,},
						},
						
		]]

	if #self.db.profile.bars_anchors > 1 then
		o.args.bars.args.style.args.delete = {
				type = 'execute',
				--width = "half",
				order = 9999,
				name = L['Remove Anchor'],
				func = function(info, value)
					
					if #self.db.profile.bars_anchors > 1 then
						C:DeleteAnchor(anchor_value)				
						anchor_value = nil
						
						o.args.bars.args.style.args = {}
						o.args.bars.args.style.args.CreateNew = {
							type = 'execute',
							--width = "half",
							order = 1,
							name = L['Add New Anchor'],
							func = function(info, value) 
								C:CreateNewAnhors()					
							end,
							}
						o.args.bars.args.style.args.Anchor = {
							name = L["Select Anchor"],
							order = 1,
							desc = L["Select Anchor Desc"],
							type = "dropdown",						
							values = function()
								local t = {}
								
								for k,v in ipairs(self.db.profile.bars_anchors) do						
									t[k] = v.name or k
								end
								
								return t
							end,
							set = function(info,val)
								self:SetAnchorTable(val)
							end,
							get = function(info, val) 
								return anchor_value
							end
						}
					end
				end,
			}
	else
		o.args.bars.args.style.args.delete = nil
	end
end

function C:OnAnchorStyleReset()
	
	anchor_value = nil					
	o.args.bars.args.style.args = {}
	o.args.bars.args.style.args.CreateNew = {
		type = 'execute',
		--width = "half",
		order = 1,
		name = L['Add New Anchor'],
		func = function(info, value) 
			C:CreateNewAnhors()					
		end,
		}
	o.args.bars.args.style.args.Anchor = {
		name = L["Select Anchor"],
		order = 1,
		desc = L["Select Anchor Desc"],
		type = "dropdown",						
		values = function()
			local t = {}
			
			for k,v in ipairs(self.db.profile.bars_anchors) do						
				t[k] = v.name or k
			end
			
			return t
		end,
		set = function(info,val)
			self:SetAnchorTable(val)
		end,
		get = function(info, val) 
			return anchor_value
		end
	}
	
end

function C:Cooldown(spellname)
	local opts = self.db.profile.classCooldowns[C.myCLASS][spellname]
	
	
	self.UpdateSpellCooldowns()
	cooldown_select = spellname
	
	o.args.coolline.args.ClassSpells.args.header1 = {
			name	= "",
			order	= 3,
			type = "group", args = {}, embend = true,
		}

	o.args.coolline.args.ClassSpells.args.header1.args.hide = {
			order = 4,name = L["Hide"], type = "toggle",
			set = function(info,val) opts.hide = not opts.hide; self.UpdateSpellCooldowns() end,
			get = function(info) return opts.hide end
		}
	
	o.args.coolline.args.ClassSpells.args.header1.args.annonce = {
			order = 4.1,name = L["Reporting"], type = "toggle",
			desc = L["Turn on/off spell cooldown report"],
			set = function(info,val) opts.reporting = not opts.reporting end,
			get = function(info) return opts.reporting end
		}
	o.args.coolline.args.ClassSpells.args.header1.args.hide_splash = {
			order = 4.2,name = L["Forced big splash"], type = "toggle",
			set = function(info,val) opts.hide_splash = not opts.hide_splash end,
			get = function(info) return opts.hide_splash end
		}
		
	o.args.coolline.args.ClassSpells.args.header1.args.mycolor = {
			name	= L["Color"],
			order	= 4.3,
			type = "group", args = {}, embend = true,
		}
		
	o.args.coolline.args.ClassSpells.args.header1.args.mycolor.args.colorr = {
			order = 5,name = L["Color"],type = "color",
			set = function(info,r,g,b) opts.color ={r,g,b}; end,
			get = function(info) return opts.color and opts.color[1] or 0 , opts.color and opts.color[2] or 0, opts.color and opts.color[3] or 0 end,
		}

	o.args.coolline.args.ClassSpells.args.header1.args.mycolor.args.color_on = {
			order = 6,name = L["Own color"],type = "toggle",
			set = function(info,val) opts.color_on = not opts.color_on; end,
			get = function(info) return opts.color_on end
		}
	o.args.coolline.args.ClassSpells.args.header1.args.SoundFile = {					
		type = "group",	order	= 10,
		embend = true,
		name	= L["Sound"],
		args = {						
			OnShow = {
				order = 1,type = 'sound',name = L["On Show"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onshow = value end,
				get = function(info) return opts.sound_onshow or "None"; end,
			},
			OnHide = {
				order = 1,type = 'sound',name = L["On Hide"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onhide = value end,
				get = function(info) return opts.sound_onhide or "None"; end,
			},
		}
	}
end

function C:ICooldown(spellname)
	local opts = self.db.profile.internal_cooldowns[spellname]
	
	ICD_select = spellname
	
	o.args.coolline.args.ICD.args.header1 = {
			name	= "",
			order	= 3,
			type = "group", args = {}, embend = true,
		}

	o.args.coolline.args.ICD.args.header1.args.hide = {
			order = 4,name = L["Hide"], type = "toggle",
			set = function(info,val) opts.hide = not opts.hide; end,
			get = function(info) return opts.hide end
		}
	
	o.args.coolline.args.ICD.args.header1.args.reporting = {
			order = 4.1,name = L["Reporting"], type = "toggle",
			desc = L["Turn on/off spell cooldown report"],
			set = function(info,val) opts.reporting = not opts.reporting end,
			get = function(info) return opts.reporting end
		}
		
	o.args.coolline.args.ICD.args.header1.args.hide_splash = {
			order = 4.2,name = L["Forced big splash"], type = "toggle",
			set = function(info,val) opts.hide_splash = not opts.hide_splash end,
			get = function(info) return opts.hide_splash end
		}
	
	o.args.coolline.args.ICD.args.header1.args.mycolor = {
			name	= L["Color"],
			order	= 4.3,
			type = "group", args = {}, embend = true,
		}
	
	o.args.coolline.args.ICD.args.header1.args.customTextureGroup = {
			name	= L["Custom Texture"],
			order	= 4.4,
			type = "group",embend = true,				
			args = {}
		}
	o.args.coolline.args.ICD.args.header1.args.customTextureGroup.args.custom_texture = {
			type = "editbox",	order	= 8,
			name = L["Custom Texture"],
			desc = L["Custom Texture Desc"],
			set = function(info,val) 
				opts.custom_texture = val
			end,
			get = function(info) return opts.custom_texture or "" end
		}
	o.args.coolline.args.ICD.args.header1.args.customTextureGroup.args.custom_texture_on= {
			order = 9,name = L["Custom Texture On"],type = "toggle",
			set = function(info,val) opts.custom_texture_on = not opts.custom_texture_on; end,
			get = function(info) return opts.custom_texture_on end
		}
			
	o.args.coolline.args.ICD.args.header1.args.mycolor.args.colorr = {
			order = 5,name = L["Color"],type = "color",
			set = function(info,r,g,b) opts.color ={r,g,b}; end,
			get = function(info) return opts.color and opts.color[1] or 0 , opts.color and opts.color[2] or 0, opts.color and opts.color[3] or 0 end,
		}

	o.args.coolline.args.ICD.args.header1.args.mycolor.args.color_on = {
			order = 6,name = L["Own color"],type = "toggle",
			set = function(info,val) opts.color_on = not opts.color_on; end,
			get = function(info) return opts.color_on end
		}
	o.args.coolline.args.ICD.args.header1.args.ICD = {
			type = "editbox", order	= 7,
			name = L["ICD"],
			set = function(info,val) 
				local num = tonumber(val)				
				if num then opts.icd = num end
			end,
			get = function(info) return opts.icd and tostring(opts.icd) or "" end
		}
	o.args.coolline.args.ICD.args.header1.args.spellID = {
			type = "editbox", order	= 8,
			name = L["SpellID"],
			set = function(info,val) 
				local num = tonumber(val)				
				if num then opts.spellid = num end
			end,
			get = function(info) return opts.spellid and tostring(opts.spellid) or "" end
		}
	
	o.args.coolline.args.ICD.args.header1.args.checkID = {
			order = 9,name = L["Check ID"], type = "toggle",
			set = function(info,val) opts.checkID = not opts.checkID; end,
			get = function(info) return opts.checkID end
		}
		
	o.args.coolline.args.ICD.args.header1.args.SoundFile = {					
		type = "group",	order	= 10,
		embend = true,
		name	= L["Sound"],
		args = {						
			OnShow = {
				order = 1,type = 'sound',name = L["On Show"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onshow = value end,
				get = function(info) return opts.sound_onshow or "None"; end,
			},
			OnHide = {
				order = 1,type = 'sound',name = L["On Hide"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onhide = value end,
				get = function(info) return opts.sound_onhide or "None"; end,
			},
		}
	}
end

function C:AuraCooldown(spellname)
	local opts = self.db.profile.auras_cooldowns[self.myCLASS][spellname]
	
	AuraCD_select = spellname
	
	o.args.coolline.args.Debuffs.args.header1 = {
			name	= "",
			order	= 3,
			type = "group", args = {}, embend = true,
		}

	o.args.coolline.args.Debuffs.args.header1.args.hide = {
			order = 4,name = L["Hide"], type = "toggle",
			set = function(info,val) opts.hide = not opts.hide; end,
			get = function(info) return opts.hide end
		}
	
	o.args.coolline.args.Debuffs.args.header1.args.reporting = {
			order = 4.1,name = L["Reporting"], type = "toggle",
			desc = L["Turn on/off spell cooldown report"],
			set = function(info,val) opts.reporting = not opts.reporting end,
			get = function(info) return opts.reporting end
		}
		
	o.args.coolline.args.Debuffs.args.header1.args.hide_splash = {
			order = 4.2,name = L["Forced big splash"], type = "toggle",
			set = function(info,val) opts.hide_splash = not opts.hide_splash end,
			get = function(info) return opts.hide_splash end
		}
		
	o.args.coolline.args.Debuffs.args.header1.args.mycolor = {
			name	= L["Color"],
			order	= 4.3,
			type = "group", args = {}, embend = true,
		}
		
	o.args.coolline.args.Debuffs.args.header1.args.mycolor.args.colorr = {
			order = 5,name = L["Color"],type = "color",
			set = function(info,r,g,b) opts.color ={r,g,b}; end,
			get = function(info) return opts.color and opts.color[1] or 0 , opts.color and opts.color[2] or 0, opts.color and opts.color[3] or 0 end,
		}

	o.args.coolline.args.Debuffs.args.header1.args.mycolor.args.color_on = {
			order = 6,name = L["Own color"],type = "toggle",
			set = function(info,val) opts.color_on = not opts.color_on; end,
			get = function(info) return opts.color_on end
		}
		--[[
	o.args.coolline.args.Debuffs.args.Debuffs = {
			type = "editbox", order	= 7,
			name = L["Duration"],
			set = function(info,val) 
				local num = tonumber(val)				
				if num then opts.icd = num end
			end,
			get = function(info) return opts.icd and tostring(opts.icd) or "" end
		}
		]]
	o.args.coolline.args.Debuffs.args.header1.args.spellID = {
			type = "editbox", order	= 8,
			name = L["SpellID"],
			set = function(info,val) 
				local num = tonumber(val)				
				if num then opts.spellid = num end
			end,
			get = function(info) return opts.spellid and tostring(opts.spellid) or "" end
		}
	
	o.args.coolline.args.Debuffs.args.header1.args.checkID = {
			order = 9,name = L["Check ID"], type = "toggle",
			set = function(info,val) opts.checkID = not opts.checkID; end,
			get = function(info) return opts.checkID end
		}

	o.args.coolline.args.Debuffs.args.header1.args.auraType = {
		order = 9.1,type = "dropdown",name = L["Type"],
		values = AuraCooldownType,
		set = function(info,value) opts.auraType = value; end,
		get = function(info) return opts.auraType or 1 end,
	}
	
--	AuraCooldownType
	
	o.args.coolline.args.Debuffs.args.header1.args.SoundFile = {					
		type = "group",	order	= 10,
		embend = true,
		name	= L["Sound"],
		args = {						
			OnShow = {
				order = 1,type = 'sound',name = L["On Show"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onshow = value end,
				get = function(info) return opts.sound_onshow or "None"; end,
			},
			OnHide = {
				order = 1,type = 'sound',name = L["On Hide"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onhide = value end,
				get = function(info) return opts.sound_onhide or "None"; end,
			},
		}
	}
end

function C:BarCooldownSpell(spellID)
	local opts = self.db.profile.bars_cooldowns[C.myCLASS][spellID]
	
	bar_cooldown_select = spellID
	
	o.args.bars.args.spellList4.args.header1 = {
			name	= "",
			order	= 3, embend = true,
			type = "group", args = {}
		}

	o.args.bars.args.spellList4.args.header1.args.hide = {
			order = 4,name = L["Hide"], type = "toggle",
			set = function(info,val) opts.hide = not opts.hide; C:UpdateBars_CooldownPart(); end,
			get = function(info) return opts.hide end
		}
	
	o.args.bars.args.spellList4.args.header1.args.color = {
		name	= L['Color'],
		order	= 6, embend = true,
		type = "group", args = {}
	}
	
	o.args.bars.args.spellList4.args.header1.args.color.args.colorr = {
		order = 5,name = L["Color"],type = "color",
		set = function(info,r,g,b) opts.color ={r,g,b}; end,
		get = function(info) return opts.color and opts.color[1] or 0 , opts.color and opts.color[2] or 0, opts.color and opts.color[3] or 0 end,
	}

	o.args.bars.args.spellList4.args.header1.args.color.args.color_on = {
		order = 6,name = L["Own color"],type = "toggle",
		set = function(info,val) opts.color_on = not opts.color_on; end,
		get = function(info) return opts.color_on end
	}
		
	o.args.bars.args.spellList4.args.header1.args.anchor = {
		name = L["Select Anchor"],
		order = 5,
		desc = L["Select Anchor Desc"],
		type = "dropdown",
		values = function()
			local t = {}							
			for k,v in ipairs(self.db.profile.bars_anchors) do						
				t[k] = v.name or k
			end							
			return t
		end,
		set = function(info,val)
			opts.set_anchor = val
		end,
		get = function(info, val) 
			return opts.set_anchor or 1
		end
	}
			
	o.args.bars.args.spellList4.args.header1.args.SoundFile = {					
		type = "group",	order	= 10,
		embend = true,
		name	= L["Sound"],
		args = {						
			OnShow = {
				order = 1,type = 'sound',name = L["On Show"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onshow = value end,
				get = function(info) return opts.sound_onshow or "None"; end,
			},
			OnHide = {
				order = 1,type = 'sound',name = L["On Hide"],
			--	dialogControl = 'LSM30_Sound',
				values = LSM:HashTable("sound"),
				set = function(info,value) opts.sound_onhide = value end,
				get = function(info) return opts.sound_onhide or "None"; end,
			},
		}
	}
	
	o.args.bars.args.spellList4.args.header1.args.delete = {
			type = 'execute',
			order = 21,
			name = L['SemiDelete'],
			desc = L['SemiDelDesc'],
			func = function(info, value)
				opts.deleted = true
				class_select = nil
				wipe(o.args.bars.args.spellList4.args)
				
				C:UpdateBars_CooldownPart();
				
				o.args.bars.args.spellList4.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.bars_cooldowns[C.myCLASS] or {}) do	
								if not v.deleted and not v.fulldel then
									t[k] = SpellString(k, 10, nil, true)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:BarCooldownSpell(val)
							C:UpdateBars_CooldownPart();
						end,
						get = function(info, val)
							return bar_cooldown_select
						end
					}
			
				o.args.bars.args.spellList4.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Player_EditBox_SPTimer",
						
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "bar_cooldowns")
									C:UpdateBars_CooldownPart();
								end	
							end
						end,
						get = function(info)end
					}
			end,
		}
		
		o.args.bars.args.spellList4.args.header1.args.fulldelete = {
			type = 'execute',
			order = 21,
			name = L['Full delete'],
			desc = L['FullDelDesc'],
			func = function(info, value)
				opts.fulldel = true
				class_select = nil
				wipe(o.args.bars.args.spellList4.args)
				C:UpdateBars_CooldownPart();
				o.args.bars.args.spellList4.args.Anchor = {
						name = L["Select Spell"],
						order = 2,
						desc = L["Select Spell"],
						width = "full",
						type = "dropdown",
						showSpellTooltip = true,
						values = function()
							local t = {}												
							for k,v in pairs(self.db.profile.bars_cooldowns[C.myCLASS] or {}) do	
								if not v.deleted and not v.fulldel then
									t[k] = SpellString(k, 10, nil, true)
								end
							end									
							return t
						end,
						set = function(info,val)
							C:BarCooldownSpell(val)
							C:UpdateBars_CooldownPart();
						end,
						get = function(info, val)
							return bar_cooldown_select
						end
					}
			
				o.args.bars.args.spellList4.args.AddNew = {
						type = "spellloader",	order	= 1,
						name = L["Spell ID"],
						desc = L["Change spellID"],
						filterType = "Player_EditBox_SPTimer",
						
						set = function(info,val)
							local num, tip = GetSpellOrItemID(val, "spell")
							if num then
								local spellname = GetSpellInfo(num)										
								if spellname then										
									C:SearchDBSpell(num, "bar_cooldowns")
									C:UpdateBars_CooldownPart();
								end	
							end
						end,
						get = function(info)end
					}
			end,
		}
end