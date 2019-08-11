local addon, C = ...
_G[addon] = C

C.LSM = LibStub("LibSharedMedia-3.0")

local L = AleaUI_GUI.GetLocale("SPTimers")
local message

local _G = _G
local myGUID, myCLASS
local options
local UnitGUID = UnitGUID
local math_floor = math.floor
local pairs = pairs
local ipairs = ipairs
local tinsert = table.insert
local debugprefix = addon.."_CORE, "
local assert = assert
local GetTime = GetTime
local UnitBuff = UnitBuff
local wipe = wipe
local IsInRaid, IsInGroup = IsInRaid, IsInGroup
local UnitClass = UnitClass
local format = format
local wipe = wipe
local UnitExists = UnitExists
local GetNumGroupMembers, GetNumSubgroupMembers = GetNumGroupMembers, GetNumSubgroupMembers
local UnitAura, GetSpellInfo = UnitAura, GetSpellInfo
local select = select
local GetRaidTargetIndex = GetRaidTargetIndex
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local IsSpellKnown = IsSpellKnown
local GetSpellCooldown = GetSpellCooldown
local GetSpellCharges = GetSpellCharges
local UnitChannelInfo = UnitChannelInfo
local UnitName = UnitName
local tonumber = tonumber
local GetItemInfo = GetItemInfo
local type = type
local match = string.match
local GetTotemInfo = GetTotemInfo
local CreateFrame = CreateFrame
local MAX_TOTEMS = MAX_TOTEMS

-- GLOBALS: SLASH_SPTIMERSDEBUG1, UIParent, ItemRefTooltip, ALEAUI_OnProfileEvent, AleaUI_GUI
-- GLOBALS: SPTIMERSDEBUGHandler
-- GLOBALS: DEFAULT_CHAT_FRAME

-- EVENTFRAME -----

do
	local __eg = CreateFrame("Frame")
	__eg:SetScript("OnEvent", function(self, event, ...)	
		
		if event == 'COMBAT_LOG_EVENT_UNFILTERED' then
			C[event](C, event, CombatLogGetCurrentEventInfo())
		else
			C[event](C, event, ...)
		end
	end)
	C.__eh = __eg
	
	C.RegisterEvent = function(self, event)
		assert(C[event], 'No methode for "'..event..'"')	
		__eg:RegisterEvent(event)
	end
	
	C.UnregisterEvent = function(self, event)	
		__eg:UnregisterEvent(event)
	end
	
	C.UnregisterAllEvents = function(self)
		__eg:UnregisterAllEvents()
	end
end

-- NEW GLOBALS ----

local UNITAURA 				= "UNITAURA"
local CLEU 					= "CLEU"
local PLAYER_AURA 			= "PLAYER_AURA"
local OTHERS_AURA 			= "OTHERS_AURA"
local CUSTOM_AURA 			= "CUSTOM_AURA"
local CHANNEL_SPELL 		= "CHANNEL_SPELL"
local TOTEM_SPELL 			= "TOTEM_SPELL"
local SPELL_CAST 			= "SPELL_CAST"
local SPELL_SUMMON 			= "SPELL_SUMMON"
local SPELL_ENERGIZE 		= "SPELL_ENERGIZE"
local NO_GUID 				= "NO_GUID"
local NO_FADE 				= "NO_FADE"
local DO_FADE 				= "DO_FADE"
local DO_FADE_RED 			= "DO_FADE_RED"
local FADED 				= "FADED"
local DO_FADE_UNLIMIT 		= "DO_FADE_UNLIMIT"
local COOLDOWN_SPELL 		= "COOLDOWN_SPELL"

C.NO_FADE 			= NO_FADE
C.DO_FADE 			= DO_FADE
C.DO_FADE_RED 		= DO_FADE_RED
C.FADED 			= FADED
C.DO_FADE_UNLIMIT 	= DO_FADE_UNLIMIT
C.UNITAURA 			= UNITAURA
C.CLEU 				= CLEU
C.PLAYER_AURA 		= PLAYER_AURA
C.OTHERS_AURA 		= OTHERS_AURA
C.CUSTOM_AURA 		= CUSTOM_AURA
C.CHANNEL_SPELL 	= CHANNEL_SPELL
C.TOTEM_SPELL 		= TOTEM_SPELL
C.SPELL_CAST 		= SPELL_CAST
C.SPELL_SUMMON 		= SPELL_SUMMON
C.SPELL_ENERGIZE 	= SPELL_ENERGIZE
C.COOLDOWN_SPELL 	= COOLDOWN_SPELL
C.NO_GUID			= NO_GUID


local parent = CreateFrame('Frame', addon..'Parent', UIParent);
parent:SetFrameLevel(UIParent:GetFrameLevel());
parent:SetPoint('TOPLEFT', UIParent, 'TOPLEFT');
parent:SetPoint('BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT');
parent:SetSize(UIParent:GetSize());

C.Parent = parent

C.myCLASS = select(2, UnitClass("player")) 

-- debug print ------------------
--C.dodebugging = true

local old_print = print
local print = function(...)
	if C.dodebugging then	
		old_print(GetTime(),debugprefix, ...)
	end
end

local old_assert = assert
local assert = function(...)
	if C.dodebugging then	
		old_assert(...)
	end
end

do
	local SendChatMessage = SendChatMessage
	local IsInRaid, IsInGroup = IsInRaid, IsInGroup
	local LE_PARTY_CATEGORY_INSTANCE = LE_PARTY_CATEGORY_INSTANCE
	local LE_PARTY_CATEGORY_HOME = LE_PARTY_CATEGORY_HOME
	
	function C.ChatMessage(msg, chat)
		
		if chat == "RAID_WARNING" then
			SendChatMessage(msg, "RAID_WARNING")
		elseif chat == "PARTY" then
			SendChatMessage(msg, "PARTY")
		elseif chat == "GUILD" then
			SendChatMessage(msg, "GUILD")
		else
			local chatType = "PRINT"
			if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) or IsInRaid(LE_PARTY_CATEGORY_INSTANCE) then
				chatType = "INSTANCE_CHAT"
			elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
				chatType = "RAID"
			elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
				chatType = "PARTY"
			end
			
			if chatType == "PRINT" then
				C.message(msg)
			else
				SendChatMessage(msg, chatType)
			end
		end
	--	AddOn:print("Message", msg, chatType)
	end
end

do
	local select = select
	local tostring = tostring
	local sub = string.sub	
	local icon = "\124TInterface\\Icons\\spell_shadow_shadowwordpain:10\124t"
	
	function C.message(...)
	--	old_print("SPTimers_Options:", ...)
		local msg = ""
		for i=1, select("#", ...) do
			
			msg = msg..tostring(select(i, ...))..","
		end	
		msg = sub(msg, 0, -2)
		
		DEFAULT_CHAT_FRAME:AddMessage(icon..addon..":"..msg)	
	end

end

message = C.message

---------------------------------

local function Round(num) return math_floor(num+.5) end
local function SecondsRound(num, numDecimals)
	numDecimals = numDecimals or 1
	
	if num > 2 then return math_floor(num+.5)
	else return math_floor(num*(10*numDecimals)+.5)/(10*numDecimals) end
end
local function SecondsRoundAllDuration(num, numDecimals)
	numDecimals = numDecimals or 1
	
	return math_floor(num*(10*numDecimals)+.5)/(10*numDecimals)
end

C.Round = Round
C.SecondsRound = SecondsRound
C.SecondsRoundAllDuration = SecondsRoundAllDuration

do

	--[==[
	name					[1]="Fade",
	rank					[2]="",
	texture					[3]="Interface\\Icons\\Spell_Magic_LesserInvisibilty",
	count					[4]=0,
	debuffType 				[5] = nil,
	duration				[6]=10,
	expirationTime			[7]=61437.969,
	caster					[8]="player",
	isStealable				[9]=false,
	nameplateShowPersonal	[10]=false,
	spellId					[11]=586,
	canApplyAura			[12]=true,
	isBossDebuff			[13]=false,
	isCastByPlayer 			[14]=true,
	nameplateShowAll		[15]=false,
	timeMod					[16]=1
	value1					[17]=
	value2					[18]=
	value3					[19]=
	]==]

	local several_auras = {}
	
	local function PlayerAurasFilter(spellID, filter_type, sUnit)
		local skip = false

		skip = C:GetWhiteListFilter(spellID, filter_type, skip)
		skip = C:GetBlackListFilter(spellID, filter_type, skip)
		skip = C:GetProcsFilter(spellID, filter_type, skip)
		skip = C:GetOthersFilter(spellID, filter_type, skip)
		
		if skip then skip = C:CheckUnitSource(sUnit, C:GetAffiliation(spellID)) end
		if skip then skip = C:CheckUnitSource('player', C:GetTargetAffiliation(spellID)) end
		
		return skip
	end
	
	local function OthersAurasFulter(spellID, filter_type, unit, sUnit)
		local skip = false
	
	--	skip = SPTimers:GetOthersFilter(spellID, filter_type, skip)
		skip = C:GetWhiteListFilter(spellID, filter_type, skip)
		skip = C:GetBlackListFilter(spellID, filter_type, skip)
		skip = C:GetProcsFilter(spellID, filter_type, skip)
		skip = C:GetOthersFilter(spellID, filter_type, skip)
		if C:IsChanneling(spellID) then skip = false end						
		if skip then skip = C:CheckUnitSource(sUnit, C:GetAffiliation(spellID)) end
		if skip then skip = C:CheckUnitSource(unit, C:GetTargetAffiliation(spellID)) end

		return skip
	end
	
	local _, spellName, icon, amount, debuffType, duration, endTime, sUnit, spellID, srcGUID, skip, dstGUID, filter, auraType, filter_type, index, sourceName
	
	-- 187616 caster unlimited aura
	
	-- 187620 melee agi use
	
	-- 187619 melee str aura
	--[==[
	local agiLTPSpellName = GetSpellInfo(187620)
	local intLTPSpellName = GetSpellInfo(187616)
	local strLTPSpellName = GetSpellInfo(187619)
	local healLTPSpellName = GetSpellInfo(187618)
	
	local function GetLTP(spellID, unit, duration, endTime)
	
		if not unit then return false end
		
		if spellID == 187616 or spellID == 187620 or spellID == 187619 then
			if duration == 0 and endTime == 0 then		
				local _, _, _, _, _, duration, endTime = UnitBuff(unit, agiLTPSpellName)						
				if duration and duration > 0 and endTime and endTime > 0 then
					return true, duration, endTime
				end				
				local _, _, _, _, _, duration, endTime = UnitBuff(unit, intLTPSpellName)						
				if duration and duration > 0 and endTime and endTime > 0 then
					return true, duration, endTime
				end
				
				local _, _, _, _, _, duration, endTime = UnitBuff(unit, strLTPSpellName)						
				if duration and duration > 0 and endTime and endTime > 0 then
					return true, duration, endTime
				end
			end
		elseif spellID == 187618 then
			if duration == 0 and endTime == 0 then	
				local _, _, _, _, _, duration, endTime = UnitBuff(unit, healLTPSpellName)
				if duration and duration > 0 and endTime and endTime > 0 then
					return true, duration, endTime
				end	
			
			end
			
		end
		
		return false
	end
	]==]
	
	local function PlayerAuras(unit)

		dstGUID = UnitGUID(unit)
		filter, auraType, filter_type, index = "HELPFUL", "BUFF", 2, 1
		
		wipe(several_auras)
		
		while ( true ) do
			spellName, icon, amount, debuffType, duration, endTime, sUnit, _, _, spellID = UnitAura(unit, index, filter)		
			if not spellName then break end
			
			--[==[
			local realLTP, durationLTP, endTimeLTP = GetLTP(spellID, sUnit, duration, endTime)
			if realLTP then
				duration, endTime = durationLTP, endTimeLTP
			end
			]==]
			if C:GetInternalCD(spellName, spellID) then
				local icd = C:GetICD(spellName, spellID)
				if icd > 0 and ( endTime ~= 0 and duration ~= 0 ) then
					icd = icd + endTime - duration
					--C.NewCooldown(spellName, icon, icd, "INTERNAL_CD")
					C.AddCooldown(spellID, spellID, duration, icd, icon, "INTERNAL_CD")
				end
			end
			
			if endTime ~= 0 and C:GetAuraCD(spellName, spellID, filter) then
				--C.NewCooldown(spellName.." buff", icon, endTime, "AURA_CD_BUFF")
				C.AddCooldown(spellID, spellID, duration, endTime-duration, icon, "AURA_CD_BUFF")
			end
			
			index = index + 1
			
			if PlayerAurasFilter(spellID, filter_type, sUnit) then
				srcGUID = UnitGUID(sUnit or "")
		
				if C:IsSeveralAuras(spellID) then
					several_auras[spellID] = ( several_auras[spellID] or 0 ) + 1
				end
					
				sourceName = UnitName(sUnit or "") or C.myNAME
				
				C:FillDuration(spellID, true, duration)
				
				C.Timer(duration, endTime, dstGUID, srcGUID, spellID, several_auras[spellID] or 1, auraType, PLAYER_AURA, GetRaidTargetIndex(unit), spellName, icon, amount, C.myNAME, sourceName, nil, true, 'UnitAura')
			end
		end

		filter, auraType, filter_type, index = "HARMFUL", "DEBUFF", 3, 1

		while ( true ) do
			spellName, icon, amount, debuffType, duration, endTime, sUnit, _, _, spellID = UnitAura(unit, index, filter)		
			if not spellName then break end
			
			if endTime ~= 0 and C:GetAuraCD(spellName, spellID, filter) then
				--C.NewCooldown(spellName.." debuff", icon, endTime,"AURA_CD_DEBUFF")
				C.AddCooldown(spellID, spellID, duration, endTime-duration, icon, "AURA_CD_DEBUFF")
			end
			
			index = index + 1
			
			if PlayerAurasFilter(spellID, filter_type, sUnit) then
				srcGUID = UnitGUID(sUnit or "")
				sourceName = UnitName(sUnit or "") or C.myNAME
				
				C:FillDuration(spellID, true, duration)
				
				C.Timer(duration, endTime, dstGUID, srcGUID, spellID,  1, auraType, PLAYER_AURA, GetRaidTargetIndex(unit), spellName, icon, amount, C.myNAME, sourceName, nil, true, 'UnitAura')
			end
		end
		
	--	C.RemoveGUID_UA(dstGUID, "BUFF", PLAYER_AURA, GetTime())
	--	C.RemoveGUID_UA(dstGUID, "DEBUFF", PLAYER_AURA, GetTime())
		C.RemoveGUID_UA(dstGUID, nil, PLAYER_AURA, GetTime())
	end

	local units = { 
		target = true,
		focus = true,
		pet = true,
		boss1 = true,
		boss2 = true,
		boss3 = true,
		boss4 = true,
		boss5 = true,
		arena1 = true,
		arena2 = true,
		arena3 = true,
		arena4 = true,
		arena5 = true,
		mouseover = true,
	}
	
	local raidUnits = {}
	local partyUnits = {}
	local nameplateUnits = {}
	
	for i=1, 40 do
		raidUnits['raid'..i] = true
	end
	for i=1, 4 do
		partyUnits['party'..i] = true
	end
	
	for i=1, 30 do
	--	nameplateUnits['nameplate'..i] = true
	end
	
	local function OthersAuras(unit)

	--	if not UnitCanAttack("player", unit) then return end
		
		if unit ~= "target" then 
		--	if UnitExists("target") and UnitIsUnit(unit, "target") then return end	
		--	if unit ~= "focus" and UnitExists("focus") and UnitIsUnit(unit, "focus") then return end
		end
		
		local isPlayer = UnitIsPlayer(unit)
		
		dstGUID = UnitGUID(unit)
		filter, auraType, filter_type, index = "HARMFUL", "DEBUFF", 3, 1

		while ( true ) do
			spellName, icon, amount, debuffType, duration, endTime, sUnit, _, _, spellID = UnitAura(unit, index, filter)		
			if not spellName then break end
	
			index = index + 1
			
			if OthersAurasFulter(spellID, filter_type, unit, sUnit) then
				srcGUID = UnitGUID(sUnit or "")
				
				C:FillDuration(spellID, isplayer, duration)
				
				C.Timer(duration, endTime, dstGUID, srcGUID, spellID, 1, auraType, OTHERS_AURA, GetRaidTargetIndex(unit), spellName, icon, amount, UnitName(unit), UnitName(sUnit or "") or UnitName(unit), nil, isPlayer, 'UnitAura')
			end
		end

		filter, auraType, filter_type, index = "HELPFUL", "BUFF", 2, 1

		while ( true ) do
			spellName, icon, amount, debuffType, duration, endTime, sUnit, _, _, spellID = UnitAura(unit, index, filter)		
			if not spellName then break end
	
			index = index + 1
			
			if OthersAurasFulter(spellID, filter_type, unit, sUnit) then
				srcGUID = UnitGUID(sUnit or "")
				
				C:FillDuration(spellID, isplayer, duration)
				
				C.Timer(duration, endTime, dstGUID, srcGUID, spellID, 1, auraType, OTHERS_AURA, GetRaidTargetIndex(unit), spellName, icon, amount,UnitName(unit), UnitName(sUnit or "") or UnitName(unit), nil, isPlayer, 'UnitAura')
			end
		end
		
	--	C.RemoveGUID_UA(dstGUID, "DEBUFF", OTHERS_AURA, GetTime())
	--	C.RemoveGUID_UA(dstGUID, "BUFF", OTHERS_AURA, GetTime())
		C.RemoveGUID_UA(dstGUID, nil, OTHERS_AURA, GetTime())
	end
	
	local __frf = CreateFrame("Frame")
	__frf:Show()
	__frf.elapsed = 0
	__frf:SetScript("OnUpdate", function(self, elapsed)
		
		self.elapsed = self.elapsed + elapsed
		if self.elapsed < 1 then return end
		self.elapsed = 0

		PlayerAuras("player")
	end)
	
	--C_Timer.NewTicker(1, function()
	--	PlayerAuras("player")
	--end)
	
	function C:UNIT_AURA(event, unit)
		if unit == "player" then 
			PlayerAuras(unit)
		elseif ( units[unit]  and  not UnitIsUnit(unit, 'player') ) then --( nameplateUnits[unit] and UnitIsEnemy('player', unit) ) )
			OthersAuras(unit)		
		end
	end
	
	
	function C:PLAYER_TARGET_CHANGED(event)
		if UnitExists("target") then
			self.CurrentTarget = UnitGUID("target")
			C:UNIT_AURA('UNIT_AURA', 'player')
			C:UNIT_AURA('UNIT_AURA', "target")
		else
			self.CurrentTarget = nil
		end
		
		self.SortBars('PLAYER_TARGET_CHANGED')
	end

	function C:UPDATE_MOUSEOVER_UNIT(event)
		if UnitExists("mouseover") then
			C:UNIT_AURA('UNIT_AURA', 'mouseover')
		end
	end
	
	function C:PLAYER_FOCUS_CHANGED()
		if UnitExists("focus") then
			self.FocusTarget = UnitGUID("focus")
			C:UNIT_AURA('UNIT_AURA', 'player')
			C:UNIT_AURA('UNIT_AURA', "focus")
		else
			self.FocusTarget = nil
			self.SortBars()
		end
	
	end
end


do
	local UnitName = UnitName
	function C.Erase(name)
		return name and UnitName(name) or name
	end
end

do
	
	local flagtort = {
		[COMBATLOG_OBJECT_NONE] = 0,
		[COMBATLOG_OBJECT_RAIDTARGET8] = 8,
		[COMBATLOG_OBJECT_RAIDTARGET7] = 7,
		[COMBATLOG_OBJECT_RAIDTARGET6] = 6,
		[COMBATLOG_OBJECT_RAIDTARGET5] = 5,
		[COMBATLOG_OBJECT_RAIDTARGET4] = 4,
		[COMBATLOG_OBJECT_RAIDTARGET3] = 3,
		[COMBATLOG_OBJECT_RAIDTARGET2] = 2,
		[COMBATLOG_OBJECT_RAIDTARGET1] = 1,
	}

	local truedEvents = {
		SPELL_CAST_SUCCESS = true,
		SPELL_AURA_REFRESH = true,
		SPELL_AURA_APPLIED_DOSE = true,
		SPELL_AURA_APPLIED = true,
		SPELL_AURA_REMOVED = true,
		SPELL_AURA_REMOVED_DOSE = true,
		SPELL_SUMMON = true,
		SPELL_ENERGIZE = true,
		SPELL_AURA_BROKEN = true,
		SPELL_AURA_BROKEN_SPELL = true,
		SPELL_MISSED = true,
	}

	local anchor, endTime, showticks, sourceFunc
	local name, stacks, duration, unitCaster, debuffType

	local externalHandlers = {}
	
	function C:AddToCLEUEvent(func)
		externalHandlers[#externalHandlers+1] = func
	end
	
	function C:COMBAT_LOG_EVENT_UNFILTERED(event, timestamp, eventType, hideCaster,
					srcGUID, srcName, srcFlags, srcFlags2,
					dstGUID, dstName, dstFlags, dstFlags2,
					spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType, ...)
			
		anchor, endTime, showticks, sourceFunc  = 1, nil, false, "CLEU"

		if eventType == "UNIT_DIED" or eventType == "UNIT_DESTROYED" or eventType == "SPELL_INSTAKILL" or eventType == "PARTY_KILL" then
			self.targetEngaged[dstGUID] = nil
			self:RemovePandemia(nil, dstGUID)
			C.Timer_Remove_DEAD(dstGUID)			
			return
		end

		if not truedEvents[eventType] then return end		
		if srcGUID ~= self.myGUID and srcGUID ~= self.petGUID then return end
		
		local skip = false
		for i=1, #externalHandlers do
			if externalHandlers[i](event, timestamp, eventType, hideCaster,
				srcGUID, srcName, srcFlags, flagtort[srcFlags2],
				dstGUID, dstName, dstFlags, flagtort[dstFlags2],
				spellID, spellName, spellSchool, auraType, amount, extraSchool, extraType, ...) then
				
				skip = true
			end
		end
		
		if skip then
			return
		end
	
		dstName = dstName or spellName or srcName or ""
		
		if eventType == "SPELL_CAST_SUCCESS" then 
			auraType = SPELL_CAST
		elseif eventType == "SPELL_SUMMON" then
			auraType = SPELL_SUMMON
		elseif eventType == "SPELL_ENERGIZE" then
			auraType = SPELL_ENERGIZE
		end

		if self:IsChanneling(spellID) then return end	
		if not self:GetCLEUFilter(spellID, auraType) then return end
		if not self:CLEU_AffilationCheck(srcFlags, spellID) then return end
		if not self:CLEU_AffilationCheckTarget(dstFlags, spellID) then return end

		
		local isPlayer = C.IsPlayer(dstFlags)

		if eventType == "SPELL_AURA_REFRESH" then
			C.Timer(self:GetDuration(spellID, dstGUID, 2, isPlayer), endTime, dstGUID, srcGUID, spellID, 1, auraType, CLEU, flagtort[dstFlags2], spellName, nil, amount, dstName, srcName, nil, isPlayer, eventType)
		elseif eventType == "SPELL_AURA_APPLIED_DOSE" then			
			C.Timer_DOSE(dstGUID, srcGUID, spellID, 1, auraType, CLEU, flagtort[dstFlags2], amount)
		elseif eventType == "SPELL_AURA_APPLIED" then
			C.Timer(self:GetDuration(spellID, dstGUID, 1, isPlayer), endTime, dstGUID, srcGUID, spellID, 1, auraType, CLEU, flagtort[dstFlags2], spellName, nil, 0, dstName, srcName, nil, isPlayer, eventType)
		elseif eventType == "SPELL_AURA_REMOVED" then
			self:RemovePandemia(spellID, dstGUID)
			C.Timer_Remove(dstGUID, srcGUID, spellID, 1, auraType)				
		elseif event == "SPELL_AURA_BROKEN" or event == "SPELL_AURA_BROKEN_SPELL" then
		
	--		print(eventType, srcName, spellID, spellName, dstName, dstGUID, srcGUID,auraType)
		elseif eventType == "SPELL_AURA_REMOVED_DOSE" then
			C.Timer_DOSE(dstGUID, srcGUID, spellID, 1, auraType, CLEU, flagtort[dstFlags2], amount)
		elseif eventType == "SPELL_SUMMON" then
			C.Timer(self:GetDuration(spellID, dstGUID, 1, isPlayer), endTime, dstGUID, srcGUID, spellID, 1, auraType, CUSTOM_AURA, flagtort[dstFlags2], spellName, nil, amount, dstName, srcName, nil, isPlayer, eventType)
		elseif eventType == "SPELL_CAST_SUCCESS" then
			C.Timer(self:GetDuration(spellID, dstGUID, 1, isPlayer), endTime, dstGUID, srcGUID, spellID, 1, auraType, CUSTOM_AURA, flagtort[dstFlags2], spellName, nil, amount, dstName, srcName, nil, isPlayer, eventType)
		elseif eventType == "SPELL_ENERGIZE" then
			C.Timer(self:GetDuration(spellID, nil, nil, isPlayer), endTime, dstGUID, srcGUID, spellID, 1, auraType, CUSTOM_AURA, flagtort[dstFlags2], spellName, nil, amount, dstName, srcName, nil, isPlayer, eventType)
		end
	end
end

do

	local spellname_list = {}
	
	local exists_cd = {}

	local GetSpellBaseCooldown = GetSpellBaseCooldown
	
	local function GetSpellCooldownCharges(spellID)
	
		if spellID == 53351 and IsSpellKnown(157707) then 
			spellID = 157708
		end
		
		local startTime, duration, enabled = GetSpellCooldown(spellID)
		local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID)
		if charges and charges ~= maxCharges then
			startTime = chargeStart
			duration = chargeDuration
		end
		return startTime, duration, enabled, charges, maxCharges
	end

	
	local cd_frame = CreateFrame("Frame")
	cd_frame:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = ( self.elapsed or 0 ) + elapsed
		
		if self.elapsed < 0.2 then return end
		self.elapsed = 0
		
		local curtime = GetTime()
		
		for k,v in pairs(spellname_list) do
			local startTime, duration, enabled, charges, maxCharges = GetSpellCooldownCharges(v)

			if enabled and duration and duration > 0 and not C.IsGCDCooldown(startTime, duration) then			
				exists_cd[v] = curtime
				C.Timer(duration, startTime+duration, COOLDOWN_SPELL, COOLDOWN_SPELL, v, 1, COOLDOWN_SPELL, COOLDOWN_SPELL, 0, k, nil, 0, k, k)
			end
		end
		
		for k,v in pairs(exists_cd) do			
			if v < curtime-1.5 then			
				C.Timer_Remove(COOLDOWN_SPELL, COOLDOWN_SPELL, k, 1, COOLDOWN_SPELL, nil, true)
				v = nil
			end
		end
	end)
	
	C.UpdateBarsSpellList = function(self)
		wipe(spellname_list)
		
		for spellid, data in pairs(options.bars_cooldowns[self.myCLASS] or {}) do
	
			if not data.hide and not data.deleted and not data.fulldel then
				spellname_list[GetSpellInfo(spellid)] = spellid
			end
		end
		
		
	end
	
	
	C.UpdateBars_CooldownPart = function(self)
		
		if options.bar_module_enabled then
			cd_frame:Show()
		else
			cd_frame:Hide()		
		end
		
		self:UpdateBarsSpellList()
	end
end

do
	local gcdStart
	local gcdDuration
	local gcdEndCheck

	local function CheckGCD()
		local event;
		local startTime, duration = GetSpellCooldown(61304);
		
		if(duration and duration > 0) then
			gcdStart, gcdDuration = startTime, duration;
			local endCheck = startTime + duration + 0.1;
			
			if(gcdEndCheck ~= endCheck) then
				gcdEndCheck = endCheck;
				C_Timer.After(duration + 0.1, CheckGCD)
			end
		else		
			gcdStart, gcdDuration = nil, nil;
			gcdEndCheck = 0;
		end
	end
	 
	local function GetGCD()
		local startTime, duration = GetSpellCooldown(61304);
		
		return duration or 0, startTime
	end
	
	local function IsGCDCooldown(start, duration)
		local startTime, durationTime = GetSpellCooldown(61304);
		return ( startTime == start and durationTime == duration )
	end
	
	C.GetGCD = GetGCD
	C.IsGCDCooldown = IsGCDCooldown
end

do

	local channel_spell = {}

	local function UpdateChannelInfo(haste, spellID)
		local spell, displayName, icon, startTime, endTime, _, _, _ = UnitChannelInfo("player")
		
		if spell then
			local playerName = C.myNAME -- UnitName("player")
			local targetName = UnitName("target") or playerName

			return C.Timer((endTime-startTime)/1000, endTime/1000, CHANNEL_SPELL, C.myGUID, CHANNEL_SPELL, 1, CHANNEL_SPELL, CHANNEL_SPELL, nil, spell, icon, 0, targetName, playerName, spellID)
		end
	end
	
	function C:ScanForChannelingSpell()
		for k,v in pairs(self.db.profile.classSpells[self.myCLASS]) do
			local spell = GetSpellInfo(k)
	
			if spell then
				if v.spellType == 2 then				
					channel_spell[spell] = k
				else				
					if channel_spell[spell] and not v.spellType ~= 2 then
						channel_spell[spell] = nil			
					end
				end
			end
		end
	end
	
	function C:UNIT_SPELLCAST_CHANNEL_START(event,unit,spell,lineID,spellID)	
		if unit ~= "player" then return end

		local spellID = channel_spell[spell]		
		if not spellID then return end
		
		local skip = false 
		
		skip = C:GetWhiteListFilter(spellID, "BUFF", skip)
		skip = C:GetBlackListFilter(spellID, "BUFF", skip)
			
		if skip then
			UpdateChannelInfo(true, spellID)
		end
	end
	
	function C:UNIT_SPELLCAST_CHANNEL_STOP(event,unit, spell, rank, lineID, spellID)
		if unit ~= "player" then return end		
		if not C:IsChanneling(spellID) then return end
		C.Timer_Remove(CHANNEL_SPELL, self.myGUID, CHANNEL_SPELL, 1, CHANNEL_SPELL)	
		
	end

	function C:UNIT_SPELLCAST_CHANNEL_UPDATE(event,unit, spell, rank, lineID, spellID)
		if unit ~= "player" then return end
		if not C:IsChanneling(spellID) then return end
	--	local showticks = self:GetCLEUSpellInfo(spellID)
		local skip = false 
		
		skip = C:GetWhiteListFilter(spellID, "BUFF", skip)
		skip = C:GetBlackListFilter(spellID, "BUFF", skip)
			
		if skip then
			UpdateChannelInfo(false, spellID)
		end
	end
	
	
	
	function C:UNIT_SPELLCAST_SENT(event,unit,spell,rank,target,lineID)
		if unit ~= "player" then return end
	--	if UnitExists('target') then
	--		self:UNIT_AURA(nil, "target")
	--	end
	end
	
	function C:UNIT_SPELLCAST_START(event,unit,spell,rank,lineID,spellID) --"unitID", "spell", "rank", lineID, spellID
		if unit ~= "player" then return end
	--	if UnitExists('target') then
	--		self:UNIT_AURA(nil, "target")
	--	end
	end
	
	function C:UNIT_SPELLCAST_SUCCEEDED(event,unit,spell,rank,lineID,spellID)
		if unit ~= "player" then return end
	--[==[	
		if spellID == 108853 then
			C.SpreadSpellCast = true
		else
			C.SpreadSpellCast = false
		end
	]==]	
	--	if UnitExists('target') then
	--		self:UNIT_AURA(nil, "target")
	--	end
	end
	
	function C:UNIT_SPELLCAST_STOP(event,unit,spell,rank,lineID,spellID)
		if unit ~= "player" then return end
	end
end


function C:PLAYER_LOGIN()
	self.myGUID = UnitGUID("player")
	local _,class = UnitClass("player")	
	self.myCLASS = class
	self.myNAME = UnitName("player")
end

function C:UNIT_PET(event, unit)
	if unit == "player" then
		if UnitExists("pet") then
			self.petGUID = UnitGUID("pet")
		else
			self.petGUID = nil
		end
	end
end

do
	
	local totemsName = {}
	local totemItems = {120217, 120218, 120219, 120214 }
	
	-- 5176 -- Fire , 5175 -- Earth, 5178 -- Air , 5177 -- Water
	
	local function GetTotemFilter(i)
		
		if not totemsName[i] then
			totemsName[i] = GetSpellInfo(totemItems[i])
		end
		
		return totemsName[i]
	end
	
	local loop = CreateFrame("Frame")
	loop.elapsed = 0
	loop:Hide()
	loop:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed

		local alldone = true
		
		for i=1, MAX_TOTEMS do
			if GetTotemFilter(i) == nil then		
				alldone = false
			end
		end
		
		if alldone then
		--	print("Complete cache item in "..format("%.1f", self.elapsed).."s.")
			
			for i=1, MAX_TOTEMS do
				C:PLAYER_TOTEM_UPDATE(nil, i)
			end
			
			self.elapsed = 0
			self:Hide()
		else 
		--	print('Still checking')
		end
	end)
	
	
	function C:UpdateTotems()
		if ( self.myCLASS == "SHAMAN" or self.myCLASS == "DRUID" ) then
			if ( self:ShowTotems("totem1") or self:ShowTotems("totem2") or self:ShowTotems("totem3") or self:ShowTotems("totem4") ) then
				self:RegisterEvent("PLAYER_TOTEM_UPDATE")
				loop:Show()
			end
		else	
			self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
			for i=1, MAX_TOTEMS do
				C:PLAYER_TOTEM_UPDATE(nil, i, true)
			end
		end
	end
	
	-- TOTEM_SPELL
	
	function C:PLAYER_TOTEM_UPDATE(event, totem, rem)
--		print("PLAYER_TOTEM_UPDATE", totem)
		local anchor = self:GetAnchor("totem"..totem)
		local haveTotem, totemName, startTime, duration, icon = GetTotemInfo(totem)

		if not rem and self:ShowTotems("totem"..totem) and haveTotem and ( GetTotemFilter(totem) ~= totemName )then
			C.Timer(duration, startTime+duration, self.myGUID, self.myGUID, "totem"..totem, 1, "BUFF", TOTEM_SPELL, nil, totemName, icon, 0,self.myNAME, self.myNAME)
		else
			C.Timer_Remove(self.myGUID, self.myGUID, "totem"..totem, 1, "BUFF")
		end
	end
end

do
	local delayupdate = CreateFrame("Frame", nil, UIParent)
	delayupdate.elapsed = 0
	delayupdate.updates = {}
	delayupdate:Show()
	delayupdate:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed
		
		if self.elapsed < 1 then return end
		
		for i=1, #delayupdate.updates do
			delayupdate.updates[i]()
		end
		
		wipe(self.updates)
		self:Hide()
	end)

	function C:PlayerLoginDelay(func)
		if type(func) == "function" then
			delayupdate.updates[#delayupdate.updates+1] = func
		end
	end
end

function C:CoreBarsStatusUpdate()
	if options.bar_module_enabled then
		
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
		self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
		self:RegisterEvent("UNIT_SPELLCAST_SENT")
		self:RegisterEvent("UNIT_SPELLCAST_START")
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:RegisterEvent("UNIT_SPELLCAST_STOP")
	else
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
		self:UnregisterEvent("PLAYER_FOCUS_CHANGED")
		self:UnregisterEvent("UPDATE_MOUSEOVER_UNIT")
		self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
		self:UnregisterEvent("UNIT_SPELLCAST_SENT")
		self:UnregisterEvent("UNIT_SPELLCAST_START")		
		self:UnregisterEvent("PLAYER_TOTEM_UPDATE")
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		self:UnregisterEvent("UNIT_SPELLCAST_STOP")
	end
	
	self:UpdateBars_CooldownPart()
end

local forced = true
function C:CheckDebugging()
	
	local _, battleTag = BNGetInfo()
	local myBTag = GetAddOnMetadata(addon, "Author")
	
	if battleTag then
		if myBTag == battleTag and forced then 
			self.dodebugging = true
			message("DEBUGGING ON")
		end

		self:UnregisterEvent("BN_CONNECTED")
		--self:UnregisterEvent("BN_SELF_ONLINE")
		self:UnregisterEvent("BN_INFO_CHANGED")
	end
end

C.BN_CONNECTED = C.CheckDebugging
C.BN_SELF_ONLINE = C.CheckDebugging
C.BN_INFO_CHANGED = C.CheckDebugging

SLASH_SPTIMERSDEBUG1 = '/sptimersdebugging'
function SPTIMERSDEBUGHandler(msg, editBox)
	C.dodebugging = not C.dodebugging
	
	message( (C.dodebugging and "DEBUGGING ON" or "DEBUGGING OFF" ) )
end

SlashCmdList["SPTIMERSDEBUG"] = SPTIMERSDEBUGHandler

do
	local raid = {}
	local raidClass = {}
	
	C.RaidRoster = raid
	C.RaidRoster_Class = raidClass
	
	local inraid = false

	local function LeaveFromRaidOrGroup()
		if not IsInRaid() then
			if inraid then inraid = false; wipe(raid) end
		elseif IsInRaid() then
			if not inraid then inraid = true end
		end
	end
	
	local function CheckUnit(unit)
		local guid = UnitGUID(unit)
		if not guid then return end
		
		local _, class = UnitClass(unit)
		
		raid[guid] = unit
		raidClass[guid] = class
	end
	
	function C:GetRaidGUID(guid)		
		return raid[guid]
	end
	
	function C:GetGUIDClass(guid)		
		return raidClass[guid] or false
	end
	--[==[
	local auratypes = {
		['DEBUFF']	= 'HARMFUL',
		['BUFF']	= 'HELPFUL',
		['HARMFUL'] = 'HARMFUL',
		['HELPFUL'] = 'HELPFUL',
	}
	
	function C:GuidAuraInfo(guid, spell, auratype)
		if not raid[guid] then return end

		local spellname = type(spell) == "number" and GetSpellInfo(spell) or spell
		
		local name, _, _, count, debuffType, duration, endTime, unitCaster, _, _, spellID = UnitAura(raid[guid], spellname, nil, auratypes[auratype])

		if name and ( spellname == name or spell == spellID ) then		
			return name, count, spellID, duration, endTime, unitCaster, debuffType
		end
		
		return nil
	end
	
	function C:NameAuraInfo(name, spell, auratype)
		
		local spellname = type(spell) == "number" and GetSpellInfo(spell) or spell
		
		local name, _, _, count, debuffType, duration, endTime, unitCaster, _, _, spellID = UnitAura(name, spellname, nil, auratypes[auratype])
		
		if name and ( spellname == name or spell == spellID ) then		
			return name, count, spellID, duration, endTime, unitCaster, debuffType
		end
		
		return nil
	end
	]==]
	
	function C:UpdateRaid()
		wipe(raid)
		wipe(raidClass)
		
		LeaveFromRaidOrGroup()
		
		if IsInRaid() then
		  for i = 1, GetNumGroupMembers() do
			CheckUnit(format("raid%d", i))
		  end
		end
		
		if IsInGroup() and not IsInRaid() then
		  for i = 1, GetNumSubgroupMembers() do
			CheckUnit(format("party%d", i))
		  end
		end
		
		CheckUnit("player")
	end
	
	C.GROUP_ROSTER_UPDATE = C.UpdateRaid
	C.PLAYER_ENTERING_WORLD = C.UpdateRaid
	C.PLAYER_ENTERING_BATTLEGROUND = C.UpdateRaid
	C.GROUP_JOINED = C.UpdateRaid
	C.GROUP_LEFT = C.UpdateRaid
	C.RAID_INSTANCE_WELCOME = C.UpdateRaid
	C.ZONE_CHANGED_NEW_AREA = C.UpdateRaid	
end

do
	local isInPetBattle = C_PetBattles.IsInBattle;
	function C:PET_BAR_UPDATE()	
		if ( options.hide_during_petbattle and isInPetBattle() ) then 
			parent:Hide() 
		else 
			parent:Show() 
		end
	end
	
	C.PET_BATTLE_OPENING_START = C.PET_BAR_UPDATE
	C.PET_BATTLE_OPENING_DONE = C.PET_BAR_UPDATE
	C.PET_BATTLE_CLOSE = C.PET_BAR_UPDATE
	C.PET_BATTLE_OVER = C.PET_BAR_UPDATE
end

local LSM_Update = CreateFrame("Frame")
LSM_Update:Hide()
LSM_Update:SetScript("OnUpdate", function(self, elapsed)
	self.elapsed = ( self.elapsed or 0 ) + elapsed
	
	if self.elapsed < 0.1 then return end
	
	C:Visibility()
	if ( C.UpdateSettings ) then 
		C.UpdateSettings()
	end

	C.UpdateCastBarsStyle()

	self:Hide()
	self.elapsed = 0
end)
C.LSM.RegisterCallback(LSM_Update, "LibSharedMedia_Registered", function(mtype, key)
	LSM_Update:Show();	
end)

local function ShowHideUI()
	if AleaUI_GUI:IsOpened(addon) then
		AleaUI_GUI:Close(addon)
	else
		AleaUI_GUI:Open(addon)
	end
end

function C:OnInitialize()
	
	self:ImportProfilesFromV2()
	
	self.myGUID = UnitGUID("player")

	local _,class = UnitClass("player")	
	self.myCLASS = class
	self.petGUID = UnitGUID("pet")
	self.myNAME = UnitName("player")

	self:DefaultOptions()

	self.options = self:OptionsTable()
	
	AleaUI_GUI:RegisterMainFrame(addon, self.options)
	
	if self.SetupClassOptions then
		self:SetupClassOptions()
	end

	self:InitSupports()
	
	options = self.db.profile
	
	self:RemoveSpellExists(options)
	
	self:CheckForMissingBarsData()

	self:InitFrames()
	if ( self.InitCooldownLine ) then 
		self:InitCooldownLine()
	end

	self:CastBarInit()
	--self:CoPToggle()
	self:PreCacheCustomTextCheck()
	
	self:RegisterEvent("UNIT_AURA")

--	self:RegisterEvent("PLAYER_REGEN_ENABLED")
--	self:RegisterEvent("PLAYER_REGEN_DISABLED")

--	self:RegisterEvent('ZONE_CHANGED')
	
	self:RegisterEvent("BN_CONNECTED")
	--self:RegisterEvent("BN_SELF_ONLINE")
	self:RegisterEvent("BN_INFO_CHANGED")
	
	self:RegisterEvent("PLAYER_LOGIN")

	self:PlayerLoginDelay(function() C:UpdateTotems() end)

	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
	self:RegisterEvent("GROUP_JOINED")
	self:RegisterEvent("GROUP_LEFT")
	
	self:RegisterEvent("RAID_INSTANCE_WELCOME")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	
	self:RegisterEvent("PET_BAR_UPDATE")
	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self:RegisterEvent("PET_BATTLE_OPENING_DONE")
	self:RegisterEvent("PET_BATTLE_CLOSE")
	self:RegisterEvent("PET_BATTLE_OVER")

	
	
	self:RegisterEvent("UNIT_PET")
	
	self:ScanForChannelingSpell()
	self:RebuildBanCD()
	self:CoreBarsStatusUpdate()
	self:CheckDebugging()
	self:UpdateBars_CooldownPart()
	self:InitVersionCheck()
	
	AleaUI_GUI.SlashCommand(addon, "/sptimers", ShowHideUI)
	AleaUI_GUI.MinimapButton(addon, { OnClick = ShowHideUI, texture = "Interface\\Icons\\spell_shadow_shadowwordpain" }, self.db.profile.minimap)
	
	ALEAUI_OnProfileEvent("SPTimersDB","PROFILE_CHANGED", function()	
		C:OnProfileChange()
	end)
	
	ALEAUI_OnProfileEvent("SPTimersDB","PROFILE_RESET", function()	
		C:OnProfileChange()
	end)
	
	if self.InitStatWeight then
		self.options.args.preset = self:InitStatWeight()
	end
	
	C:InitTalentCheck()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, unit)
	if unit ~= addon then return end
	C:OnInitialize()
	self:UnregisterAllEvents()
	self = nil
end)

function C:OnProfileChange()

	self.onUpdateHandler:SetScript("OnUpdate", nil)
	
	self.myGUID = UnitGUID("player")

	local _,class = UnitClass("player")	
	self.myCLASS = class
	self.petGUID = UnitGUID("pet")
	self.myNAME = UnitName("player")

	self:DefaultOptions()
	
	self.options = self:OptionsTable()
	
	AleaUI_GUI:RegisterMainFrame(addon, self.options)
	
	if self.SetupClassOptions then
		self:SetupClassOptions()
	end

	self:InitSupports()
	
	--self:OnAnchorStyleReset()
	
	options = self.db.profile
	
	self:RemoveSpellExists(options)
	
	self:CheckForMissingBarsData()
	
	self:ProfileSwapBars()
	self:InitCooldownLine()
	
	self:UpdateCastBarsVisible()
	self:DisableBlizzCastBars()
	self.UpdateCastBarsStyle()
	
	--self:CoPToggle()
	self:PreCacheCustomTextCheck()
	
	self:RegisterEvent("UNIT_AURA")
--	self:RegisterEvent("PLAYER_REGEN_ENABLED")
--	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_LOGIN")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
	self:RegisterEvent("GROUP_JOINED")
	self:RegisterEvent("GROUP_LEFT")
	self:RegisterEvent("RAID_INSTANCE_WELCOME")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("UNIT_PET")

	self:RebuildBanCD()
	self:CheckDebugging() 
	self:ScanForChannelingSpell()	
	self:CoreBarsStatusUpdate()
	self:UpdateTotems()
	self:UpdateBars_CooldownPart()	
	self:OnAnchorStyleReset()
	
	if self.InitStatWeight then
		self.options.args.preset = self:InitStatWeight()
	end

	AleaUI_GUI.GetMinimapButton(addon):Update(self.db.profile.minimap)
end

do
	local handlers = {}
	
	local function OnEvent(self, event)
		for i=1, #handlers do
			handlers[i]()
		end
	end

	local eventframe = CreateFrame("Frame")
	eventframe:SetScript("OnEvent", OnEvent)
	
	
	function C:AddToTalentCheck(handler)
		handlers[#handlers+1] = handler
	end
	
	local init = false
	
	function C:InitTalentCheck()
		eventframe:RegisterUnitEvent("PLAYER_SPECIALIZATION_CHANGED", "player", '')
		eventframe:RegisterEvent("PLAYER_TALENT_UPDATE")
		eventframe:RegisterEvent("PLAYER_LEVEL_UP")
		eventframe:RegisterEvent("SPELLS_CHANGED")
		eventframe:RegisterEvent("PLAYER_LOGIN")
		
		if init then
			for i=1, #handlers do
				handlers[i]()
			end
		end
		
		init = true
	end
end



do
	local mover_frames = {}
	
	local cL = 0.3
	local cR = 0.7
	local cT = 0.3
	local cB = 0.7
	-- X ->  Y ^
	-- 0, 0, 1, 1
	local function SetTextureRotation(texture, rotate)
		local  ulx,uly , llx,lly , urx,ury , lrx,lry
		
		if(rotate == 0 or rotate == 360) then
		   ulx,uly , llx,lly , urx,ury , lrx,lry = cT, cL ,cL,cB , cR,cT , cR,cB;
		elseif(rotate == 90) then
		   ulx,uly , llx,lly , urx,ury , lrx,lry = cR,cT , cT, cL , cR,cB , cL,cB;
		elseif(rotate == 180) then
		   ulx,uly , llx,lly , urx,ury , lrx,lry = cR,cB ,cR,cT , cL,cB , cT, cL;
		elseif(rotate == 270) then
		   ulx,uly , llx,lly , urx,ury , lrx,lry = cL,cB , cR,cB , cT, cL , cR,cT;
		end
		
		texture:SetTexCoord(ulx,uly , llx,lly , urx,ury , lrx,lry);
	end


	local function createbutton(parent, name)
		if not parent.buttons then parent.buttons = {} end
		
		local f = CreateFrame("Button", parent:GetName().."Button"..#parent.buttons+1, parent)
		f:SetFrameLevel(parent:GetFrameLevel() + 1)
		f.parent = parent
		
		f.icon = f:CreateTexture(nil, 'ARTWORK')
		f.icon:SetPoint('CENTER', f, 'CENTER', 0, 0)
		f.icon:SetSize(14, 14)
		f.icon:SetTexture([[Interface\Buttons\SquareButtonTextures]])
		f.icon:SetTexCoord(0.01562500, 0.20312500, 0.01562500, 0.20312500)
		
		if name == "LEFT" or name ==  "UP" or name ==  "DOWN" or name == "RIGHT" then
			SquareButton_SetIcon(f, name)
			f:SetText(' ')
			f.icon:Show()
		else		
			f:SetText(name)
			f.icon:Hide()
		end
		
		--UI-ChatIcon-ScrollDown-Down
		
		f:SetWidth(20) --ширина
		f:SetHeight(20) --высота
		f:SetNormalFontObject("GameFontNormalSmall")
		f:SetHighlightFontObject("GameFontHighlightSmall")
		f:SetBackdrop({
				bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
				edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
				edgeSize = 1,
				insets = {top = 0, left = 0, bottom = 0, right = 0},
					})
		f:SetBackdropColor(0,0,0,1)
		f:SetBackdropBorderColor(.3,.3,.3,1)
		
		f:SetScript("OnEnter", function(self)
				self:SetBackdropBorderColor(1,1,1,1) --цвет краев
			end)
			f:SetScript("OnLeave", function(self)
				self:SetBackdropBorderColor(.3,.3,.3,1) --цвет краев
			end)
			
		local t = f:GetFontString()
		t:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
		t:SetJustifyH("CENTER")
		t:SetJustifyV("CENTER")
		f.text = t
		
		return f
	end
	
	local function createeditboxe(parent)
		if not parent.editboxes then parent.editboxes = {} end
		local textbox = CreateFrame("EditBox", parent:GetName().."EditBox"..#parent.editboxes+1, parent)
		textbox:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
		textbox:SetFrameLevel(parent:GetFrameLevel() + 1)
		textbox:SetAutoFocus(false)
		textbox:SetWidth(50)
		textbox:SetHeight(20)
		textbox:SetJustifyH("LEFT")
		textbox:SetJustifyV("CENTER")
		textbox:SetBackdrop({
				bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
				edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
				edgeSize = 1,
				insets = {top = 0, left = 0, bottom = 0, right = 0},
					})
		textbox:SetBackdropColor(0,0,0,1)
		textbox:SetBackdropBorderColor(1,1,1,0.5)
		
		textbox.ok = createbutton(textbox, "OK")
		textbox.ok.editbox = textbox
		textbox.ok.text:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
		textbox.ok:SetSize(15,15)
		textbox.ok:SetPoint("RIGHT", textbox, "RIGHT", -2, 0)
		textbox.ok:Hide()
		
		textbox:SetScript("OnEscapePressed", function(self)
			self:ClearFocus()
		end)
		textbox:SetScript("OnEnterPressed", function(self)
			self.ChangePosition(self.ok)
		end)
		return textbox
	end
	
	local buttons_name = { "LEFT", "UP", "DOWN", "RIGHT" }
	local buttons_move = { { -1, 0 } , { 0, 1 }, { 0, -1} , { 1, 0} }
	
	function C:UpdateMoverPosition()
		for k,v in pairs(mover_frames) do
			k:UpdatePoint()
		end
	end
	
	local _unnm = 0
	local function CountUnnamesFrames()
		_unnm = _unnm + 1
		
		return _unnm
	end

	function C.AddMoverButtons(self, opts, tip, tomover, float)
		if not self.mover_add_button then			
			self.mover_add_button = CreateFrame("Frame", (self:GetName() or "SPTimersUnnamedFrame"..CountUnnamesFrames()).."MoverToolTip", self)
			self.mover_add_button.mover = self
			self.mover_add_button.opts = opts
			self.mover_add_button.tip = tip
			self.mover_add_button.tomover = tomover
			self.mover_add_button.float = float
			self.mover_add_button.buttons = {}
			self.mover_add_button.editboxes = {}
			self.mover_add_button:SetSize(120, 70)
			self.mover_add_button:SetClampedToScreen(true)
			self.mover_add_button:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground",})	
			self.mover_add_button:SetBackdropColor(0, 0, 0, 0.7)
			self.mover_add_button:Show()
			self.mover_add_button.UpdatePoint = function(self)
				
				self:ClearAllPoints()
				
				if self.tomover then
					self:SetPoint("TOP", self.mover, "TOP",0,-3)
					self:SetBackdropColor(0, 0, 0, 0)
				else
					if self.opts and not self.opts.add_up then
						self:SetPoint("BOTTOM", self.mover, "TOP",0, 3)
					else
						self:SetPoint("TOP", self.mover, "BOTTOM",0,-3)
					end
				end
				
				if options.show_more_buttons then 
					self:Show()
				else
					self:Hide()
				end
				
				for k,v in pairs(self.editboxes) do
					v:UpdateText()
				end
			end
			
			mover_frames[self.mover_add_button] = true
			
			for i=1,4 do				
				self.mover_add_button.buttons[i] = createbutton(self.mover_add_button, buttons_name[i])
				self.mover_add_button.buttons[i].i = i
				self.mover_add_button.buttons[i].owner = self.mover_add_button
				
				if i == 1 then
					self.mover_add_button.buttons[i]:SetPoint("TOPRIGHT", self.mover_add_button, "TOP", 0, -3)
				elseif i == 2 then
					self.mover_add_button.buttons[i]:SetPoint("TOPRIGHT", self.mover_add_button, "TOP", -21, -3)
				elseif i == 3 then
					self.mover_add_button.buttons[i]:SetPoint("TOPLEFT", self.mover_add_button, "TOP", 0, -3)
				elseif i == 4 then
					self.mover_add_button.buttons[i]:SetPoint("TOPLEFT", self.mover_add_button, "TOP", 21, -3)
				end
				
				self.mover_add_button.buttons[i]:SetScript("OnClick", function(self)
					
					if self.owner.opts then
						self.owner.opts.point[1] = (tonumber(self.owner.opts.point[1]) or 0) + buttons_move[self.i][1]
						self.owner.opts.point[2] = (tonumber(self.owner.opts.point[2]) or 0) + buttons_move[self.i][2]
						
						self.owner.mover:ClearAllPoints()
						self.owner.mover:SetPoint("CENTER", parent, "CENTER", self.owner.opts.point[1], self.owner.opts.point[2] )
					elseif self.owner.tip and self.owner.tip == "line" then
					
						C.db.profile.cooldownline.x = (tonumber(C.db.profile.cooldownline.x) or 0) + buttons_move[self.i][1]
						C.db.profile.cooldownline.y = (tonumber(C.db.profile.cooldownline.y) or 0) + buttons_move[self.i][2]
						
						self.owner.mover:ClearAllPoints()
						self.owner.mover:SetPoint("CENTER", parent, "CENTER", C.db.profile.cooldownline.x, C.db.profile.cooldownline.y)
					elseif self.owner.tip and self.owner.tip == "splash" then
						C.db.profile.cooldownline.slash_x = (tonumber(C.db.profile.cooldownline.slash_x) or 0) + buttons_move[self.i][1]
						C.db.profile.cooldownline.slash_y = (tonumber(C.db.profile.cooldownline.slash_y) or 0) + buttons_move[self.i][2]
						
						self.owner.mover:ClearAllPoints()
						self.owner.mover:SetPoint("CENTER", parent, "CENTER", C.db.profile.cooldownline.slash_x, C.db.profile.cooldownline.slash_y)
					end
					for k,v in pairs(self.owner.editboxes) do
						v:UpdateText()					
					end
				end)
			end
			
			if float then
				self.mover_add_button.buttons[5] = createbutton(self.mover_add_button, "=====")
				self.mover_add_button.buttons[5]:SetPoint("BOTTOM", self.mover_add_button, "BOTTOM", 0, 3)
				self.mover_add_button.buttons[5]:SetSize(50, 10)
				self.mover_add_button.buttons[5].owner = self.mover_add_button
				self.mover_add_button.buttons[5]:SetScript("OnClick", function(self)
					local a1,a2,a3,a4,a5 = self.owner:GetPoint()
					self.owner:ClearAllPoints()
					self.owner:SetPoint(a3,a2,a1,0, -a5)
				end)
			end
			
			for i=1,2 do				
				self.mover_add_button.editboxes[i] = createeditboxe(self.mover_add_button)
				self.mover_add_button.editboxes[i].i = i
				self.mover_add_button.editboxes[i].owner = self.mover_add_button
				
				if i == 1 then
					self.mover_add_button.editboxes[i]:SetPoint("TOPRIGHT", self.mover_add_button, "TOP", -1, -30)
				else
					self.mover_add_button.editboxes[i]:SetPoint("TOPLEFT", self.mover_add_button, "TOP", 1, -30)
				end
				
				self.mover_add_button.editboxes[i]:SetScript("OnTextChanged", function(self, user)
					if user then
						self.ok:Show()
						
						self.ok:SetScript("OnClick", self.ChangePosition)
					end
				end)
				
				self.mover_add_button.editboxes[i].ChangePosition = function(self)
					local num = tonumber(self.editbox:GetText())				
					if num then
						if self.editbox.owner.opts then
							self.editbox.owner.opts.point[self.editbox.i] = num
								
							self.editbox.owner.mover:ClearAllPoints()
							self.editbox.owner.mover:SetPoint("CENTER", parent, "CENTER", self.editbox.owner.opts.point[1], self.editbox.owner.opts.point[2])
						elseif self.editbox.owner.tip and self.editbox.owner.tip == "line" then
							
							if self.editbox.i == 1 then
								C.db.profile.cooldownline.x = num
							else
								C.db.profile.cooldownline.y = num
							end
							
							self.editbox.owner.mover:ClearAllPoints()
							self.editbox.owner.mover:SetPoint("CENTER", parent, "CENTER", C.db.profile.cooldownline.x, C.db.profile.cooldownline.y)
						elseif self.editbox.owner.tip and self.editbox.owner.tip == "splash" then
							if self.editbox.i == 1 then
								C.db.profile.cooldownline.slash_x = num
							else
								C.db.profile.cooldownline.slash_y = num
							end
							self.editbox.owner.mover:ClearAllPoints()
							self.editbox.owner.mover:SetPoint("CENTER", parent, "CENTER", C.db.profile.cooldownline.slash_x, C.db.profile.cooldownline.slash_y)
						end
					else
						self.editbox:UpdateText()
					end
					self:SetScript("OnClick", nil)
					self:Hide()
					
					self.editbox:ClearFocus()
				end
				self.mover_add_button.editboxes[i]:SetScript("OnShow", function(self) self:UpdateText() end)
				
				self.mover_add_button.editboxes[i].UpdateText = function(self)
					if self.owner.opts then
						self:SetText(tonumber(self.owner.opts.point and self.owner.opts.point[self.i]) or 0)
					elseif self.owner.tip and self.owner.tip == "line" then
						if self.i == 1 then
							self:SetText(tonumber(C.db.profile.cooldownline.x) or 0)
						else
							self:SetText(tonumber(C.db.profile.cooldownline.y) or 0)
						end
					elseif self.owner.tip and self.owner.tip == "splash" then
						if self.i == 1 then
							self:SetText(tonumber(C.db.profile.cooldownline.slash_x) or 0)
						else
							self:SetText(tonumber(C.db.profile.cooldownline.slash_y) or 0)
						end
					end
				end
				
				self.mover_add_button.editboxes[i]:UpdateText()
			end
		end
		self.mover_add_button.opts = opts
			
	--	self.mover_add_button.x = x
	--	self.mover_add_button.y = y
		self.mover_add_button:UpdatePoint()
	end
end


do
	
	local hooksecurefunc, select, UnitBuff, UnitDebuff, UnitAura, UnitGUID, GetGlyphSocketInfo, tonumber, strfind, strsub, strmatch =
      hooksecurefunc, select, UnitBuff, UnitDebuff, UnitAura, UnitGUID, GetGlyphSocketInfo, tonumber, strfind, strsub, strmatch

	local types = {
		spell      = "|cFFCA3C3CSpell ID:|r",
		item       = "|cFFCA3C3CItem ID:|r",
		talent     = "|cFFCA3C3CTalent ID:|r",
	}

	local function addLine(tooltip, id, type, type2)
		local found = false
		
		if type2 == 'spell' and not options.show_spellid_tooltip then return end
		if type2 == 'talent' and not options.show_spellid_tooltip then return end
		if type2 == 'item' and not options.show_item_spellid then return end

		-- Check if we already added to this tooltip. Happens on the talent frame
		for i = 1,15 do
			local frame = _G[tooltip:GetName() .. "TextLeft" .. i]
			local text
			if frame then text = frame:GetText() end
			if text and text == type then found = true break end
		end

		if not found then
			tooltip:AddDoubleLine(type, "|cffffffff" .. id)
		--	tooltip:Show()
		end
	end

	-- All types, primarily for linked tooltips
	local function onSetHyperlink(self, link)
		if not options.show_item_spellid and not options.show_spellid_tooltip then return end
		local type, id = match(link,"^(%a+):(%d+)")
		if not type or not id then return end
		if type == "spell" then
			addLine(self, id, types.spell, type)
		elseif type == "talent" then
			addLine(self, id, types.talent, type)
		elseif type == "item" then
			addLine(self, id, types.item, type)
		end
	end

	hooksecurefunc(ItemRefTooltip, "SetHyperlink", onSetHyperlink)
	hooksecurefunc(GameTooltip, "SetHyperlink", onSetHyperlink)

	-- Spells
	hooksecurefunc(GameTooltip, "SetUnitBuff", function(self, ...)
		local id = select(10, UnitBuff(...))
		if id then addLine(self, id, types.spell, 'spell') end
	end)

	hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self,...)
		local id = select(10, UnitDebuff(...))
		if id then addLine(self, id, types.spell, 'spell') end
	end)

	hooksecurefunc(GameTooltip, "SetUnitAura", function(self,...)
		local id = select(10, UnitAura(...))
		if id then addLine(self, id, types.spell, 'spell') end
	end)

	hooksecurefunc("SetItemRef", function(link, ...)
		local id = tonumber(link:match("spell:(%d+)"))
		if id then addLine(ItemRefTooltip, id, types.spell, 'spell') end
	end)

	GameTooltip:HookScript("OnTooltipSetSpell", function(self)
		local id = select(3, self:GetSpell())
		if id then addLine(self, id, types.spell, 'spell') end
	end)


	-- Items
	local function attachItemTooltip(self)
		local link = select(2, self:GetItem())
		if link then
			local id = select(3, strfind(link, "^|%x+|Hitem:(%-?%d+):(%d+):(%d+).*"))
			if id then addLine(self, id, types.item, 'item') end
		end
	end

	GameTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
	ItemRefTooltip:HookScript("OnTooltipSetItem", attachItemTooltip)
	ItemRefShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
	ItemRefShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
	ShoppingTooltip1:HookScript("OnTooltipSetItem", attachItemTooltip)
	ShoppingTooltip2:HookScript("OnTooltipSetItem", attachItemTooltip)
	
end

do
	local C = AleaUI_GUI
	C.SPTimers_CooldownToggleFrames = {}
	
	local function Update(self, panel, opts)
		
		self.free = false
		self:SetParent(panel)
		self:Show()	
		
		
		local toggleFrame1 = C:GetPrototype('toggle')
		toggleFrame1:Update(self.main, opts.toggleOpts1)
				
		local colorFrame = C:GetPrototype('color')
		colorFrame:Update(self.main, opts.colorOpts)
		
		local toggleFrame2 = C:GetPrototype('toggle')
		toggleFrame2:Update(self.main, opts.toggleOpts2)
				
		self.main.toggle1 = toggleFrame1
		self.main.colorFrame = colorFrame
		self.main.toggle2 = toggleFrame2
	end
	
	local function UpdateSize(self, panel, opts)
		if opts.width == 'full' then
			self:SetWidth(panel:GetWidth() - 25)
			self.main:SetWidth(panel:GetWidth() - 25)
		else
			self:SetWidth(180)
			self.main:SetWidth(160)
		end
		
		self.main.colorFrame:ClearAllPoints()
		self.main.colorFrame:SetPoint('TOPLEFT', self.main, 'TOPLEFT', 0, 10)
	
		self.main.toggle1:ClearAllPoints()
		self.main.toggle1:SetPoint('TOPLEFT', self.main, 'TOPLEFT', 110, 6)	
		self.main.toggle1:SetWidth(80)
		
		self.main.toggle2:ClearAllPoints()
		self.main.toggle2:SetPoint('TOPLEFT', self.main, 'TOPLEFT', 220, 6)
		self.main.toggle2:SetWidth(80)
	end
	
	local function Remove(self)
		self.free = true
		self:Hide()
		
		self.main.toggle1:SetWidth(180)
		self.main.toggle2:SetWidth(180)
		
		self.main.toggle1:Remove()
		self.main.colorFrame:Remove()
		self.main.toggle2:Remove()
	end
	
	local function CreateCoreButton(parent)
		local f = CreateFrame("Frame", nil, parent)
		f:SetSize(180, 35)
		f:SetFrameLevel(parent:GetFrameLevel() + 1)
		
		f:Show()

		return f
	end

	function C:CreateSPTimers_CooldownToggleFrame()
		
		for i=1, #C.SPTimers_CooldownToggleFrames do
			if C.SPTimers_CooldownToggleFrames[i].free then
				return C.SPTimers_CooldownToggleFrames[i]
			end
		end
		
		local f = CreateFrame("Frame", nil, UIParent)
		f:SetSize(180, 35)
		f.free = true
		
		f.main = CreateCoreButton(f)
		f.main:ClearAllPoints()
		f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 5, -5)
		f.main:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 0)
		--[[
		f.bg = f:CreateTexture()
		f.bg:SetAllPoints()
		f.bg:SetTexture(1, 1, 0, 0.4)
		]]
		f.Update = Update
		f.Remove = Remove
		f.UpdateSize = UpdateSize
		
		C.SPTimers_CooldownToggleFrames[#C.SPTimers_CooldownToggleFrames+1] = f
		
		return f
	end

	C.prototypes["SPTimers_CooldownToggleFrame"] = "CreateSPTimers_CooldownToggleFrame"
end

do
	-- Kui Nameplates fader	
	-- Frame fading functions
	-- (without the taint of UIFrameFade & the lag of AnimationGroups)
	
	local frameFadeFrame = CreateFrame('Frame')
	local FADEFRAMES = {}

	C.frameIsFading = function(frame)
		for index, value in pairs(FADEFRAMES) do
			if value == frame then
				return true
			end
		end
	end
	C.frameFadeRemoveFrame = function(frame)
		tDeleteItem(FADEFRAMES, frame)
	end
	C.frameFadeOnUpdate = function(self, elapsed)
		local frame, info
		for index, value in pairs(FADEFRAMES) do
			frame, info = value, value.fadeInfo

			if info.startDelay and info.startDelay > 0 then
				info.startDelay = info.startDelay - elapsed
			else
				info.fadeTimer = (info.fadeTimer and info.fadeTimer + elapsed) or 0

				if info.fadeTimer < info.timeToFade then
					-- perform animation in either direction
					if info.mode == 'IN' then
						frame:SetAlpha(
							(info.fadeTimer / info.timeToFade) *
							(info.endAlpha - info.startAlpha) +
							info.startAlpha
						)
					elseif info.mode == 'OUT' then
						frame:SetAlpha(
							((info.timeToFade - info.fadeTimer) / info.timeToFade) *
							(info.startAlpha - info.endAlpha) + info.endAlpha
						)
					end
				else
					-- animation has ended
					frame:SetAlpha(info.endAlpha)

					if info.fadeHoldTime and info.fadeHoldTime > 0 then
						info.fadeHoldTime = info.fadeHoldTime - elapsed
					else
						C.frameFadeRemoveFrame(frame)

						if info.finishedFunc then
							info.finishedFunc(frame)
							info.finishedFunc = nil
						end
					end
				end
			end
		end

		if #FADEFRAMES == 0 then
			self:SetScript('OnUpdate', nil)
		end
	end
	--[[
		info = {
			mode            = "IN" (nil) or "OUT",
			startAlpha      = alpha value to start at,
			endAlpha        = alpha value to end at,
			timeToFade      = duration of animation,
			startDelay      = seconds to wait before starting animation,
			fadeHoldTime    = seconds to wait after ending animation before calling finishedFunc,
			finishedFunc    = function to call after animation has ended,
		}

		If you plan to reuse `info`, it should be passed as a single table,
		NOT a reference, as the table will be directly edited.
	]]
	C.frameFade = function(frame, info)
		if not frame then return end
		if C.frameIsFading(frame) then
			-- cancel the current operation
			-- the code calling this should make sure not to interrupt a
			-- necessary finishedFunc. This will entirely skip it.
			C.frameFadeRemoveFrame(frame)
		end

		info        = info or {}
		info.mode   = info.mode or 'IN'

		if info.mode == 'IN' then
			info.startAlpha = info.startAlpha or 0
			info.endAlpha   = info.endAlpha or 1
		elseif info.mode == 'OUT' then
			info.startAlpha = info.startAlpha or 1
			info.endAlpha   = info.endAlpha or 0
		end

		frame:SetAlpha(info.startAlpha)
		frame.fadeInfo = info

		tinsert(FADEFRAMES, frame)
		frameFadeFrame:SetScript('OnUpdate', C.frameFadeOnUpdate)
	end
end