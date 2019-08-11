local addon, C = ...
local options
local smed = C.LSM
local L = AleaUI_GUI.GetLocale("SPTimers")

local IsSpellKnown = IsSpellKnown
local _G = _G
local tonumber = tonumber
local wipe = table.wipe
local MAX_TALENT_TIERS = MAX_TALENT_TIERS
local NUM_TALENT_COLUMNS = NUM_TALENT_COLUMNS
local GetTalentInfo = GetTalentInfo
local ceil = ceil
local tostring = tostring
local GetItemInfo = GetItemInfo
local CreateFrame = CreateFrame
local gmatch = gmatch
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitClass = UnitClass
local IsLoggedIn = IsLoggedIn
local GetSpellLink = GetSpellLink
local MouseIsOver = MouseIsOver
local abs = abs
local unpack = unpack
local GetSpellTabInfo = GetSpellTabInfo
local GetFlyoutInfo = GetFlyoutInfo
local GetFlyoutSlotInfo = GetFlyoutSlotInfo
local format = format
local GetInventoryItemLink = GetInventoryItemLink
local GetContainerItemLink = GetContainerItemLink
local GetPetActionCooldown = GetPetActionCooldown
local GetPetActionInfo = GetPetActionInfo
local GetActionInfo = GetActionInfo
local GetActionTexture = GetActionTexture
local GetSpellCharges = GetSpellCharges
local GetRuneCooldown = GetRuneCooldown
local floor = floor
local time = time
local gsub = gsub
local tinsert = table.insert
local tsort = table.sort
local tremove = table.remove
local match = string.match

-- debug print ------------------
local old_print = print
local print = function(...)
	if true then return end
	
	old_print("SPTimers-CooldownLine, ", ...)
end

local parent = C.Parent
local mainframe = CreateFrame("Frame", "SPTimersCooldownLine", parent)
mainframe:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)
mainframe.OldAlpha = mainframe.SetAlpha

local InCombatRes = {
	[20484] = true, -- druid br
	[61999] = true, -- dk br
	[20707] = true, -- warlock
	
	[95750] = true,  -- warlock br
	[126393] = true, -- hunter
}


local disable_spells = {
	[73899] = true,
	[86346] = true,
	[108501] = true,
}

local GetSpellBaseCooldown = GetSpellBaseCooldown
local mycooldowns = {
	[527] = 8*6000,
	[88423] = 8*6000,
	[4987] = 8*6000,
	[77130] = 8*6000,
	[115450] = 8*6000,
	[73685] = 15*6000,
	[18562] = 30*6000,
	[8092] = 8*6000,
	[32379] = 9*6000,
}
local talentcooldowns = {	
	[61295] = { 6*6000, 157812, 5*6000 },
}

local cooldowns_placeholder = {
	[114049] = ( GetSpellInfo(114049) ), 
	[86346] = ( GetSpellInfo(86346) ),
}

local minimumCooldown = {
	[8092] = 0.75,
	[205448] = 0.75,
}

local function MyGetSpellBaseCooldown(spellID)
	
	local basecd = GetSpellBaseCooldown(spellID)
	
	if basecd and basecd == 0 then
		if mycooldowns[spellID] then 
			return mycooldowns[spellID]
		elseif talentcooldowns[spellID] then
			return ( IsSpellKnown(talentcooldowns[spellID][2]) and talentcooldowns[spellID][3] or talentcooldowns[spellID][1])
		end		
	end

	return basecd
end

local ccDuration = 0
local ccEndTimeTime = 0
local capGCD = nil
local capGCDTimeOut = -1


local function GetRuneIgnore(startTime, duration)
	for i=1, 6 do
		local start, runeDuration, runeReady = GetRuneCooldown(i);
		if not runeReady then
			if start then			
				if abs(duration - runeDuration) < 0.001 then
					return true
				end
			end
		end
	end
	
	return false
end

local function GetMinimumCooldownDuration(spellID, duration, startTime)
	
	if ccEndTimeTime < GetTime() then
		ccDuration = 0
	end
	
	if C.IsGCDCooldown(startTime, duration) then
		return false
	end
	
	if C.myCLASS == 'DEATHKNIGHT' then
		if GetRuneIgnore(startTime, duration) then
			return false
		end
	end
	
	return ( duration > 1.5 or minimumCooldown[spellID]) and ( abs(duration - ccDuration) > 0.001 )-- C.SecondsRoundAllDuration(duration, 2) ~= ccDuration
end

local gcdDisHook = CreateFrame('Frame')
gcdDisHook:RegisterUnitEvent('UNIT_SPELLCAST_START', 'player', '')
--gcdDisHook:RegisterUnitEvent('UNIT_SPELLCAST_SEND', 'player')
gcdDisHook:SetScript('OnEvent', function(self, event, unit, spell, rank, line, spellID)
	if spellID == 13262 then
		capGCD = true
		capGCDTimeOut = GetTime()+1.6
	else
		capGCD = false
	end
end)

local ccDisHook = CreateFrame('Frame')
ccDisHook:RegisterEvent("LOSS_OF_CONTROL_ADDED")
ccDisHook:RegisterEvent("LOSS_OF_CONTROL_UPDATE")
ccDisHook:SetScript('OnEvent', function(self, event, index)

	if event == "LOSS_OF_CONTROL_ADDED" then
		
		local locType, spellID2, text, iconTexture, startTime, timeRemaining, duration2, lockoutSchool, priority, displayType = C_LossOfControl.GetEventInfo(index);
		
		if locType == "SCHOOL_INTERRUPT" then
			ccDuration = duration2 or 0
		--	ccDuration = C.SecondsRoundAllDuration(ccDuration, 2)
			ccEndTimeTime = startTime+duration2
		end
	else
		if ccEndTimeTime < GetTime() then
			ccDuration = 0
		end
	end
end)


local stackspellpattern = " №%d"
mainframe:SetClampedToScreen(true)

local splashbigmover = CreateFrame("Frame", "SPTimersCooldownLineSplashBigMover", parent)
splashbigmover:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground",})
splashbigmover:SetBackdropColor(0, 0, 0, 0.8)
splashbigmover.text = splashbigmover:CreateFontString(nil, "OVERLAY", "GameFontNormal");
splashbigmover.text:SetPoint("CENTER", splashbigmover, "CENTER",0,0)
splashbigmover.text:SetTextColor(1,1,1,1)
splashbigmover.text:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
splashbigmover.text:SetJustifyH("CENTER")
splashbigmover.text:SetText(L["Big Cooldown Splash Unlocked"])
splashbigmover:SetClampedToScreen(true)

local pairs, ipairs = pairs, ipairs
local tinsert, tremove = tinsert, tremove
local GetTime = GetTime
local random = math.random
local strmatch = strmatch
local UnitExists, HasPetUI = UnitExists, HasPetUI
local GetSpellInfo = GetSpellInfo

local db
local backdrop, icon_backdrop = { }


local section, iconsize = 0, 0
local BOOKTYPE_SPELL, BOOKTYPE_PET = BOOKTYPE_SPELL, BOOKTYPE_PET

local BookType = {
	[BOOKTYPE_SPELL] = "PLAYER_CD",
	[BOOKTYPE_PET]	 = "PET_CD"
}

local flyOutCooldown = {}
local flyOutCooldownList = {}

local bigsplashparent, DoBigSplash
do
	local function OnSplashUpdate(self, elapsed)
		local _i = 0
		for i, frame in ipairs(self.splashes) do
			_i = _i+1
			frame.elapsed = frame.elapsed + elapsed			
			if ( frame.elapsed <= db.splash_big.time_in ) then
				frame.splashing = true
				
				local scale = frame:GetScale()+(elapsed*db.splash_big.step_in)
				frame:SetScale( ( scale > 0 and scale or 0.00001) )
				
				if db.splash_big.alpha_in ~= 0 then 
					local alpha = frame:GetAlpha() +(elapsed*db.splash_big.alpha_in)
					frame:SetAlpha( ( alpha > 0 and alpha or 0 ) )				
				end
			elseif ( frame.elapsed > db.splash_big.time_in+db.splash_big.time_out ) then
				frame:Hide()
				frame:SetScale(1)
				frame:SetAlpha(db.slash_alpha)
				frame.splashing = false
				frame.throttle = GetTime()+1
				tremove(self.splashes, i)
			elseif ( db.splash_big.time_out > 0 ) and ( frame.elapsed < db.splash_big.time_in+db.splash_big.time_out ) then
				frame.splashing = true
				
				local scale = frame:GetScale()+(elapsed*db.splash_big.step_out)			
				frame:SetScale( ( scale > 0 and scale or 0.00001) )
				
				if db.splash_big.alpha_out > 0 or db.splash_big.alpha_out < 0 then			
					local alpha = frame:GetAlpha()+(elapsed*db.splash_big.alpha_out)
					frame:SetAlpha( ( alpha > 0 and alpha or 0 ) )					
				end
			end
		end
		if _i == 0 then
			self:Hide()
		end
	end
	
	bigsplashparent = CreateFrame("Frame", "SPTimersCooldownLineSplashBig", parent)
	bigsplashparent.splashes = {}
	bigsplashparent:Hide()
	bigsplashparent:SetPoint("CENTER", splashbigmover, "CENTER")
	bigsplashparent:SetScript("OnUpdate", OnSplashUpdate)

	function DoBigSplash(frame, name)	
		local skip = false
		
		for i=1, #bigsplashparent.splashes do
			local f = bigsplashparent.splashes[i]
			if f.parent._texturePath == frame.parent._texturePath then
				skip = true
				break
			end
		end
	
		if not skip and not frame.splashing and name and db.slash_show then
			if C:DoBigSplashCooldown(name) then return end

			print('Do Splash', name)
			
			if not frame.throttle or ( frame.throttle < GetTime() ) then
				
				local f = frame.parent
				
				local icon = f.icon:GetTexture()
			
				f.splashicon:SetTexture(f._texturePath)
				f.splashiconbug:SetTexture(f._texturePath)

				local texcoord = 0.2
				frame.elapsed = 0
				frame:Show()
				tinsert(bigsplashparent.splashes, frame)
				OnSplashUpdate(bigsplashparent, 0)

				bigsplashparent:Show()
			end
		end
	end
end

local smallsplash, DoSmallSplash
do
	local function OnSplashUpdateSmall(self, elapsed)
		local _i = 0
		for i, frame in ipairs(self.splashes) do
			_i = _i+1
			frame.elapsed = frame.elapsed + elapsed
			
			if ( frame.elapsed <= db.splash_small.time_in ) then
				frame.splashing = true

				local scale = frame:GetScale()+(elapsed*db.splash_small.step_in)
				frame:SetScale( ( scale > 0 and scale or 0.00001) )
				
				if db.splash_small.alpha_in ~= 0 then 
					local alpha = frame:GetAlpha()+(elapsed*db.splash_small.alpha_in)
					frame:SetAlpha( ( alpha > 0 and alpha or 0 ) )				
				end

			--	print("Splash IN ", frame.elapsed)
			elseif ( frame.elapsed > db.splash_small.time_in+db.splash_small.time_out ) then
				frame:Hide()
				frame:SetScale(1)
				frame:SetAlpha(db.slash_small_alpha)
				frame.splashing = false
				frame.throttle = GetTime()+1
				tremove(self.splashes, i)
			--	print("Splash FADE ", frame.elapsed)
			elseif ( db.splash_small.time_out > 0 ) and ( frame.elapsed < db.splash_small.time_in+db.splash_small.time_out ) then
				frame.splashing = true

				local scale = frame:GetScale()+(elapsed*db.splash_small.step_out)
				frame:SetScale( ( scale > 0 and scale or 0.00001) )
			
				if db.splash_small.alpha_out > 0 or db.splash_small.alpha_out < 0 then 
					local alpha = frame:GetAlpha()+(elapsed*db.splash_small.alpha_out)
					frame:SetAlpha( ( alpha > 0 and alpha or 0 ) )				
				end

			--	print("Splash OUT ", frame.elapsed)
			end
		end
		if _i == 0 then
			self:Hide()
		end
	end
	
	smallsplash = CreateFrame("Frame", "SPTimersCooldownLineSplashSmall", mainframe)
	smallsplash.splashes = {}
	smallsplash:Hide()
	smallsplash:SetScript("OnUpdate", OnSplashUpdateSmall)

	function DoSmallSplash(frame)
		local skip = false
		
		for i=1, #smallsplash.splashes do
			local f = smallsplash.splashes[i]
			if f.parent._texturePath == frame.parent._texturePath then
				skip = true
				break
			end
		end
		
		if not skip and not frame.splashing and db.slash_show_small and frame.parent.name then
			if not frame.throttle or ( frame.throttle < GetTime() ) then
				
				local f = frame.parent
				
				f.splashicon:SetTexture(f._texturePath)
				f.splashiconbug:SetTexture(f._texturePath)

				frame.elapsed = 0
				frame:Show()
				tinsert(smallsplash.splashes, frame)
				OnSplashUpdateSmall(smallsplash, 0)
				smallsplash:Show()
			end
		end
	end
end

local spells = { [BOOKTYPE_SPELL] = { }, [BOOKTYPE_PET] = { }, }
local sR = {}

local frames, cooldowns, specialspells, placeholder = { }, { }, { }, { }

----------------------------------
-- Mage
--placeholder[125430] = 112948

-- Warlock 
--placeholder[175707] = 30283

----------------------------------
--[==[
do
	local GetActiveSpecGroup = GetActiveSpecGroup	
	local talentID, talentName
	
	local talents = {}
	local patternString = SPELL_RECAST_TIME_CHARGES_SEC
	local patternString1 = gsub(patternString, "%%.3g","(.+)")
	
	local hidegametooltip = CreateFrame("Frame")
	hidegametooltip:Hide()
	local gametooltip = CreateFrame("GameTooltip", "SPTimers_CooldownLina_GameToolTip", nil, "GameTooltipTemplate");
	gametooltip:SetOwner( hidegametooltip,"ANCHOR_NONE");
	
	local function ChechForFalseSpells(realname, realspellID, values)
		for spellid, name in pairs(values) do			
			if name == realname and spellid ~= realspellID then
				values[spellid] = nil
				break
			end
		end
		
		values[realspellID] = realname
	end
	
	local function FindCDFromTooltip(spellID)
		local cd = 0		
		gametooltip:SetHyperlink("spell:"..spellID)				

		for i=1, gametooltip:NumLines() do		
			local line = _G[gametooltip:GetName().."TextRight"..i]:GetText()			
			if line then
				local cd1 = match(line, patternString1)				
				if tonumber(cd1) then 
					cd = tonumber(cd1)
					break
				end			
			end
		end		
		return cd
	end
	
	local function UpdateTalentsSpells(values)
	
		wipe(talents)

		for tier=1, MAX_TALENT_TIERS do
			talents[tier] = talents[tier] or false
			
			for column=1, NUM_TALENT_COLUMNS do
				local talentID, name, iconTexture, selected, available = GetTalentInfo(tier, column, GetActiveSpecGroup());
	
				if selected then
					gametooltip:SetTalent(talentID)
				
					local name, _, spellID = gametooltip:GetSpell()
					
					 talents[tier] = spellID or false
				end
			end
		end
		for i,spellID in pairs(talents) do
			if spellID then
				local name = GetSpellInfo(spellID)
				local cd = MyGetSpellBaseCooldown(spellID)		

				if cd and cd > 0 then
					ChechForFalseSpells(name, spellID, values)
				else				
					cd = FindCDFromTooltip(spellID)				
					if cd and cd > 0 then					
						ChechForFalseSpells(name, spellID, values)
					end
				end
			end
		end
	end
	
	C.CacheTaletsIDs = UpdateTalentsSpells
end
]==]

local SetValue, UpdateSettings, createfs, RuneCheck

local function SetValueH(this, v, just)
	this:SetPoint(just or "CENTER", mainframe, "LEFT", v, 0)
end
local function SetValueHR(this, v, just)
	this:SetPoint(just or "CENTER", mainframe, "LEFT", db.w - v, 0)
end
local function SetValueV(this, v, just)
	this:SetPoint(just or "CENTER", mainframe, "BOTTOM", 0, v)
end
local function SetValueVR(this, v, just)
	this:SetPoint(just or "CENTER", mainframe, "BOTTOM", 0, db.w - v)
end

local ticks, ticks_f = {}, {}

local function AddTick(num, text, offset, just)
	local fs = ticks_f[num] or mainframe:CreateFontString(nil, "OUTLINE", 4)
	fs:SetFont(smed:Fetch("font", db.font), db.fontsize, db.fontflags)
	fs:SetTextColor(db.fontcolor.r, db.fontcolor.g, db.fontcolor.b, 1)
	fs:SetShadowColor(db.fontshadowcolor.r, db.fontshadowcolor.g, db.fontshadowcolor.b, db.fontshadowcolor.a)
	fs:SetShadowOffset(db.fontshadowoffset[1],db.fontshadowoffset[2])
	
	if text > 60 then
		text = ceil(text/60)
	end
	
	fs:SetText(tostring(text))
	fs:SetWidth(db.fontsize * 3)
	fs:SetHeight(db.fontsize + 2)
	fs:SetShadowColor(db.bgcolor.r, db.bgcolor.g, db.bgcolor.b, 1)
	fs:SetShadowOffset(1, -1)
	if just then
		fs:ClearAllPoints()
		if db.vertical then
			fs:SetJustifyH("CENTER")
			just = db.reverse and ((just == "LEFT" and "TOP") or "BOTTOM") or ((just == "LEFT" and "BOTTOM") or "TOP")
		elseif db.reverse then
			just = (just == "LEFT" and "RIGHT") or "LEFT"
			offset = offset + ((just == "LEFT" and 1) or -1)
			fs:SetJustifyH(just)
		else
			offset = offset + ((just == "LEFT" and 1) or -1)
			fs:SetJustifyH(just)
		end
	else
		fs:SetJustifyH("CENTER")
	end
	ticks_f[num] = fs
	SetValue(fs, offset, just)
end

local st = "0 1 10 30 60 120 300"
local min_len

local function SetupTicks()
	min_len = db.w/(#ticks-1)
	
	local last_len = 0
	local last_value = 0
	
	wipe(sR)
	for num, value in ipairs(ticks) do
		local point, justify
		if num == 1 then
			point = 1
		elseif num == #ticks then
			point = db.w
		else
			point = min_len*(num-1)
		end
		
		if num == 1 then
			justify = "LEFT"
		elseif num == #ticks then
			justify = "RIGHT"
		end
		
		sR[num] = { last_value, value-last_value }

		last_len = point
		last_value = value
		
		AddTick(num, value, point, justify)
	end
end

local cachedNameToTableKey = {}

function C:GetCooldownBlockName(name)
	return cachedNameToTableKey[name]
end

local function BuildCooldownBlockList()
	for k,v in pairs(db.blockList) do		
		if v.itemid then
			local name = GetItemInfo(v.itemid)		
			if name then
				cachedNameToTableKey[name] = k
			end
		elseif v.spellid then
			local name = GetSpellInfo(v.spellid)	
			if name then
				cachedNameToTableKey[name] = k
			end
		end
	end
end

function C:BuildCooldownBlockList()
	C_Timer.After(1, BuildCooldownBlockList)
	C_Timer.After(1.5, BuildCooldownBlockList)
end


local function FakeSetAlpha(self)
	self:OldAlpha(0)
end

function UpdateSettings()
	if db.enabled then
		mainframe:Show()
		
		if db.vertical then	
			mainframe:SetWidth(db.h or 18)
			mainframe:SetHeight(db.w or 130)		
		else
			mainframe:SetWidth(db.w or 130)
			mainframe:SetHeight(db.h or 18)		
		end

		if db.hide_cooldown_line then
			mainframe.SetAlpha = FakeSetAlpha
		else
			mainframe.SetAlpha = mainframe.OldAlpha
		end
		
		mainframe:SetAlpha(db.inactivealpha)
		
		mainframe:SetPoint("CENTER", parent, "CENTER", db.x or 0, db.y or -240)
		
		C.AddMoverButtons(mainframe, nil, "line", nil, true)
				
		mainframe.bg = mainframe.bg or mainframe:CreateTexture(nil, "ARTWORK")
		mainframe.bg:SetTexture(smed:Fetch("statusbar", db.statusbar))
		mainframe.bg:SetVertexColor(db.bgcolor.r, db.bgcolor.g, db.bgcolor.b, db.bgcolor.a)
		mainframe.bg:SetAllPoints(mainframe)
		
		if db.vertical then
			mainframe.bg:SetTexCoord(1,0, 0,0, 1,1, 0,1)
		else
			mainframe.bg:SetTexCoord(0,1, 0,1)
		end
		
		mainframe.border = mainframe.border or CreateFrame("Frame", nil, mainframe)
		mainframe.border:SetPoint("TOPLEFT",-db.borderinset, db.borderinset) -- Implemented 'insets'
		mainframe.border:SetPoint("BOTTOMRIGHT",db.borderinset, -db.borderinset) -- Implemented 'insets'
		backdrop = {
			edgeFile = smed:Fetch("border", db.border),
			edgeSize = db.bordersize,
		}
		mainframe.border:SetBackdrop(backdrop)
		mainframe.border:SetBackdropBorderColor(db.bordercolor.r, db.bordercolor.g, db.bordercolor.b, db.bordercolor.a)
		
		icon_backdrop = {
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			insets = { left = db.icon_background_inset, right = db.icon_background_inset, top = db.icon_background_inset, bottom = db.icon_background_inset },
			
			edgeFile = smed:Fetch("border", db.icon_border),
			edgeSize = db.icon_bordersize,
		}
		
		
		splashbigmover:SetSize(db.slash_size, db.slash_size)		
		bigsplashparent:SetSize(db.slash_size, db.slash_size)
		bigsplashparent:SetAlpha(db.slash_alpha)
		
		
		if db.slash_show then
			if not C.db.profile.locked then
				splashbigmover:EnableMouse(true)
				splashbigmover:Show()
			end
		else

			splashbigmover:EnableMouse(false)
			splashbigmover:Hide()
		end
		
		splashbigmover:SetPoint("CENTER", parent, "CENTER", db.slash_x, db.slash_y)
		
		C.AddMoverButtons(splashbigmover, nil, "splash", true)
		
		mainframe.overlay = mainframe.overlay or CreateFrame("Frame", nil, mainframe.border)
		mainframe.overlay:SetFrameLevel(24)

		iconsize = (db.h) + (db.iconplus or 4)
		SetValue = (db.vertical and (db.reverse and SetValueVR or SetValueV)) or (db.reverse and SetValueHR or SetValueH)

		smallsplash:ClearAllPoints()
		smallsplash:SetSize(iconsize, iconsize)
		smallsplash:SetAlpha(db.slash_small_alpha)
		
		if db.vertical then
			if db.reverse then
				smallsplash:SetPoint("CENTER", mainframe, "TOP", 0, 0);
			else	
				smallsplash:SetPoint("CENTER", mainframe, "BOTTOM", 0, 0);
			end
		else
			if db.reverse then
				smallsplash:SetPoint("CENTER", mainframe, "RIGHT", 0, 0);
			else
				smallsplash:SetPoint("CENTER", mainframe, "LEFT", 0, 0);
			end
		end
		
		for k,v in pairs(ticks_f) do
			v:Hide()
		end
		
		wipe(ticks_f)
		wipe(ticks)
		for v in gmatch(db.custom_text_timer, "[^ ]+") do
			if #ticks == 0 and tonumber(v) ~= 0 then
				tinsert(ticks, 0)
			end
			tinsert(ticks, tonumber(v))
		end
		
		SetupTicks()
		
		if db.hidelinetext then
			for k,v in pairs(ticks_f) do
				v:Hide()
			end
		else
			for k,v in pairs(ticks_f) do
				v:Show()
			end
		end
		
		if db.hidepet then
			mainframe:UnregisterEvent("UNIT_PET")
			mainframe:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
		else
			mainframe:RegisterUnitEvent("UNIT_PET", "player", '')
			mainframe:UNIT_PET()
		end
		--[[
		if db.hidebag and db.hideinv then
			mainframe:UnregisterEvent("BAG_UPDATE_COOLDOWN")
		else]]
			mainframe:RegisterEvent("BAG_UPDATE_COOLDOWN")
			mainframe:BAG_UPDATE_COOLDOWN()
		--end
		
		if db.hidefail then
			mainframe:UnregisterEvent("UNIT_SPELLCAST_FAILED")
		else
			mainframe:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player", '')
		end
		
		mainframe:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player",'')
		
		if db.hideplay then
			mainframe:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
			mainframe:UnregisterEvent("SPELLS_CHANGED")
			mainframe:UnregisterEvent("ENCOUNTER_END")
		else
			mainframe:RegisterEvent("SPELL_UPDATE_COOLDOWN")
			mainframe:RegisterEvent("SPELLS_CHANGED")
			mainframe:RegisterEvent("ENCOUNTER_END")
			mainframe:SPELL_UPDATE_COOLDOWN()
		end
		
		if ( db.blood_runes and db.frost_runes and db.unholy_runes ) or C.myCLASS ~= "DEATHKNIGHT" then
			mainframe:UnregisterEvent("RUNE_POWER_UPDATE")
			--mainframe:UnregisterEvent("RUNE_TYPE_UPDATE")
			
		elseif C.myCLASS == "DEATHKNIGHT" then
			
			mainframe:RegisterEvent("RUNE_POWER_UPDATE")
			--mainframe:RegisterEvent("RUNE_TYPE_UPDATE")
		end
		
		if db.hidevehi then
			mainframe:UnregisterEvent("UNIT_ENTERED_VEHICLE")
			mainframe:UnregisterEvent("UNIT_EXITED_VEHICLE")			
			mainframe:UNIT_EXITED_VEHICLE()
		else
			mainframe:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player", '')
			if UnitHasVehicleUI("player") then
				mainframe:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
				mainframe:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player", '')
			end
		end
		
		for _, frame in ipairs(cooldowns) do
			frame:Update()
		end
		
		for _, frame in ipairs(frames) do
			frame:Update()
		end
		
		C:UpdateTooltip()
	else
		
		mainframe:UnregisterAllEvents()
		mainframe:Hide()
	
	end
end

C.UpdateSettings = UpdateSettings
	
function C:InitCooldownLine()
	
	db = self.db.profile.cooldownline
	
	if db.transferList then

		for k,v in pairs(db.block) do		
			if v.spellid then
				db.blockList['spell:'..v.spellid] = v
			elseif v.itemid then
				db.blockList['item:'..v.itemid] = v
			end
		end
		
		db.transferList = false
		db.block = {}
	end
	
	for k,v in pairs(db.blockList) do		
		if v.itemid then
			GetItemInfo(v.itemid)
		end
	end
	
	C:BuildCooldownBlockList()

	if C.myCLASS == "DEATHKNIGHT" then
		local runecd = {  -- fix by NeoSyrex
			[GetSpellInfo(50977) or "Death Gate"] = 11,
			[GetSpellInfo(43265) or "Death and Decay"] = 11,
			[GetSpellInfo(42650) or "Army of the Dead"] = 11,
			[GetSpellInfo(49184) or "Howling Blast"] = 8,
			[GetSpellInfo(130736) or "Soul Reaper"] = 6,
		}
		RuneCheck = function(name, duration)
			local rc = runecd[name]
			if not rc or (rc <= duration and (rc > 10 or rc >= duration)) then
				return true
			end
		end
	end
	
	if IsLoggedIn() then
		mainframe:PLAYER_LOGIN()
	else
		mainframe:RegisterEvent("PLAYER_LOGIN")
	end
	
	C:UnlockCooldownLine()
end

function mainframe:PLAYER_LOGIN()
	UpdateSettings()
	mainframe:RegisterEvent("PLAYER_LEAVING_WORLD")
end

function mainframe:PLAYER_ENTERING_WORLD()

	if not db.hideplay then
		mainframe:RegisterEvent("SPELLS_CHANGED")
		mainframe:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		mainframe:RegisterEvent("ENCOUNTER_END")
		mainframe:SPELLS_CHANGED()
		mainframe:SPELL_UPDATE_COOLDOWN()
	end
end

function mainframe:PLAYER_LEAVING_WORLD()
	
	mainframe:RegisterEvent("PLAYER_ENTERING_WORLD")
	mainframe:UnregisterEvent("SPELLS_CHANGED")
	mainframe:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
	mainframe:UnregisterEvent("ENCOUNTER_END")
end

local iconback = { 
	bgFile="Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
	tile = true,
}

local elapsed, throt, ptime, isactive = 0, 1.5, 0, false

local function UpdateBarPoits()
	
	if ( true ) then return end

	for i=1, #cooldowns do
		local f = cooldowns[i]
		local prep
		if i == 1 then prep = mainframe 
		else prep = cooldowns[i-1].icon end
		
		if db.vertical then
			if db.reverse then
				f.bar:SetPoint("TOP", prep, "TOP", 0, 0);
			else				
				f.bar:SetPoint("BOTTOM", prep, "BOTTOM", 0, 0);
			end
		else
			if db.reverse then
				f.bar:SetPoint("RIGHT", prep, "RIGHT", 0, 0);
			else
				f.bar:SetPoint("LEFT", prep, "LEFT", 0, 0);
			end
		end
	end
end

local function getNextPoint(fromgroup)
	if fromgroup == 1 or not fromgroup then
		return mainframe
	else
		for i, frame in ipairs(cooldowns) do
			if frame._group == fromgroup-1 and frame.currentActive and not frame.hiden then
				return frame.icon
			end
		end
	end
	
	return nil
end

local function UpdateBar_Point(frame, toframe)
	local offset = iconsize*0.5
	if toframe == mainframe then
		offset = 0		
	end
	
	if db.vertical then
		if db.reverse then
			frame.bar:SetPoint("TOP", toframe, "TOP", 0, -offset);
		else				
			frame.bar:SetPoint("BOTTOM", toframe, "BOTTOM", 0, offset);
		end
	else
		if db.reverse then
			frame.bar:SetPoint("RIGHT", toframe, "RIGHT", -offset, 0);
		else
			frame.bar:SetPoint("LEFT", toframe, "LEFT", offset, 0);
		end
	end	
end


function C:UpdateSingleBar()
	local _i = 0
	local _lastfr = nil
	local gettime = GetTime()
	local prep
	
	for i, frame in ipairs(cooldowns) do
		if not frame.hiden then
			_i = _i + 1
			if ( frame.endtime - gettime ) < db.minimal_time_to_fade then -- this one 
				if _i == 1 or not prep then 
					prep = mainframe
				else
					prep = _lastfr
				end
				
				UpdateBar_Point(frame, prep)
				
				_lastfr = frame
			else
				local point = getNextPoint(frame._group)
				
				if point then
					UpdateBar_Point(frame, point)
				end
			end
		end
	end
end


local function SortCooldownsFunc(x,y)
	return x.endtime < y.endtime
end

local function SortCooldowns()
	tsort(cooldowns, SortCooldownsFunc)
end

local function SkipAura(skipaura, frame)
	
	if skipaura then
		if frame.isplayer == "AURA_CD_BUFF" or frame.isplayer == "AURA_CD_DEBUFF" then
			return false
		end
	end
	
	return true
end

local function IsItMe(frame, name, texture, spellID, isplayer, force)
	if ( frame.name == name ) and 
		( texture and frame.texture == texture or ( not texture ) ) and 
		( isplayer and frame.isplayer == isplayer or ( not isplayer ) or force ) and 
		( spellID and frame.spellID == spellID or ( not spellID ) ) then
		
		return true
	end
	
	return false
end

local function ClearCooldown(f, name, texture, spellID)
	name = name or (f and f.name)
	
	for index, frame in ipairs(cooldowns) do
		if (spellID and (frame.spellID == spellID) or not spellID and ( frame.name == name and ( texture and frame.texture == texture or ( not texture ) ) ) ) then
		
			C:PlaySoundCooldown(name, "sound_onhide")
			
			print("CLEAR CD", name)
			if not frame.hiden then frame:Splash() end
			
			frame:Hide()
			frame.name = nil
			frame.endtime = nil
			frame.isplayer = nil
			frame.index = nil
			frame.spellID = nil
			frame.texture = nil
			frame.position = nil			
		
			frame.hiden = nil
			frame._group = nil
			frame.currentActive = nil
			frame._currentTickLine = nil
			
			if frame.showtooltip then 
				frame.showtooltip:HideTooltip() 
				frame.showtooltip.child = nil
				frame.showtooltip = nil
			end

			tinsert(frames, tremove(cooldowns, index))

			SortCooldowns()

			C:UpdateFading1()
			C:UpdateSingleBar()
			
			break
		end
	end
end

local function HideCooldown(f, name, texture)
	name = name or (f and f.name)
	for index, frame in ipairs(cooldowns) do
	--	if IsItMe(frame, name, texture, spellID, false, false) then
		if frame.name == name and ( texture and frame.texture == texture or ( not texture ) ) then
			frame:Hide()
			
			frame.hiden = true
			frame.spellID = nil
			frame._group = nil
			frame.currentActive = nil
			frame._currentTickLine = nil
			
			if frame.showtooltip then 
				frame.showtooltip:HideTooltip() 
				frame.showtooltip.child = nil
				frame.showtooltip = nil
			end

			SortCooldowns()
			
			C:UpdateFading1()
			C:UpdateSingleBar()
			
			break
		end
	end
end

do
    local hour, minute = 3600, 60
    local format = string.format
    local ceil = math.ceil
	local floor = math.floor
	local fmod = math.fmod
	
	local formats = {
		function(s)  -- 1h, 2m, 119s, 29.9
			if s >= hour then
				return " %dh ", ceil(s / hour)
			elseif s >= minute*2 then
				return " %dm ", ceil(s / minute)
			elseif s >= 30 then
				return " %ds ", ceil(s)
			end
			return " %.1f ", s
		end,
		function(s) -- 1:11m, 59s, 10s, 1s
			if s <= 60 then
				return (" %.0fs "):format(ceil(s))
			else
				return (" %d:%0.2dm "):format(s/60, fmod(s, 60))
			end
		end,
		function(s) -- 1:11m, 59.1s, 10.2s, 1.1s
			if s <= 60 then
				return (" %.1fs "):format(ceil(s))
			else
				return (" %d:%0.2dm "):format(s/60, fmod(s, 60))
			end
		end,	
		function(s)  -- 1, 2, 119, 29.9
			if s >= hour then
				return " %d ", ceil(s / hour)
			elseif s >= minute*2 then
				return " %d ", ceil(s / minute)
			elseif s >= 30 then
				return " %d ", ceil(s)
			end
			return " %.1 f", s
		end,
		function(s) -- 1:11, 59, 10, 1
			if s <= 60 then
				return (" %.0f "):format(ceil(s))
			else
				return (" %d:%0.2d "):format(s/60, fmod(s, 60))
			end
		end,
		function(s) -- 1:11, 59.1, 10.2, 1.1
			if s <= 60 then
				return (" %.1f "):format(s)
			else
				return (" %d:%0.2d "):format(s/60, fmod(s, 60))
			end
		end,
	}
	
    function C.FormatTimeCooldown(s)
		local t = db.fortam_s or 1
		
		return formats[t](s)
    end
	
	
	function C.ButtonOnClick(self, button) -- - осталось до перезарядки "]
		if not C:GetAnonce(self.f.name, self.f.isplayer) then return end
		
		if button == "LeftButton" then
			local compspellName = gsub(self.f.name, stackspellpattern, "")
			
			local spellLink = GetSpellLink(compspellName) or compspellName

			
			C.ChatMessage(spellLink..L[" - remains cooldown"]..format(C.FormatTimeCooldown(self.f.endtime-GetTime())))
		elseif button == "RightButton" and self.barbutton then		
			HideCooldown(self.f)
		end
		if self.tooltip then self.parent:HideTooltip() end
	end		
end

local function SetupIcon(frame, position, tthrot, active, fl, tN, tV)
	throt = (throt < tthrot and throt) or tthrot
	if not frame.hiden then isactive = active or isactive end

	if fl then		
		local frame_level = (#cooldowns-fl+1) * 2 + 8
		frame:SetFrameLevel( frame_level <= 0 and 8 or frame_level )
	else
		frame:SetFrameLevel(mainframe.border:GetFrameLevel()+1)
	end

	
	if not frame._tN then
		frame._tN = tN
	end
	
	if frame._tN ~= tN then
		frame._tN = tN
		C:UpdateFading1()
		C:UpdateSingleBar()
	end
	
	frame.position = position
	
	if frame.endtime-GetTime() > 0 then
		frame.textcd:SetFormattedText(C.FormatTimeCooldown(frame.endtime-GetTime()))
	else
		frame.textcd:SetText("")
	end
	SetValue(frame, position)
end

local function gettick(timer)
	for k,v in ipairs(ticks) do  
	   if timer < v then
		  return k,v
	   end 
	end
	return 
end

local function OnUpdate(this, a1, ctime, dofl)
	elapsed = elapsed + a1
	C:DoFading()
--	if elapsed < 0.01 then return end
--	elapsed = 0

	if #cooldowns == 0 then
		if not mainframe.unlock then
			mainframe:SetScript("OnUpdate", nil)
			mainframe:SetAlpha(db.inactivealpha)
		end
		return
	end
	
	ctime = ctime or GetTime()
	if ctime > ptime then
		dofl, ptime = true, ctime + 0.4
	end
	isactive, throt = false, 1.5
	for index, frame in pairs(cooldowns) do
		local remain = frame.endtime - ctime		
		local tN, tV = gettick(remain)
	
		frame.index = index
		if ticks[3] and remain < ticks[3] and remain < 30 then --10
			if not frame.hiden then isactive = true end
			if remain > ticks[2] then --1 >1
				SetupIcon(frame, min_len*((tN-2)+(remain-sR[tN][1])/sR[tN][2]), 0.02, true, index, tN, tV)  -- 1 + (remain - 1) / 2
			elseif remain > 0 then
				if min_len*((tN-2)+(remain-sR[tN][1])/sR[tN][2]) < 0 then
					SetupIcon(frame, 0, 0.02, true, index, tN, tV)
				else
					SetupIcon(frame, min_len*((tN-2)+(remain-sR[tN][1])/sR[tN][2]), 0.02, true, index)
				end
			elseif remain > -0.1 then
				SetupIcon(frame, 1, 0.02, true, -1, tN, tV)
				if not frame.hiden then frame:Splash() end
				frame:SetAlpha(1+(remain/0.1))
			else
				throt = (throt < 0.2 and throt) or 0.2
				ClearCooldown(frame)
			end
		elseif tV and ( remain < tV ) then
			if not frame.hiden then isactive = true end
			SetupIcon(frame,  min_len*((tN-2)+(remain-sR[tN][1])/sR[tN][2]) , 0.02*tN, true, index, tN, tV)  -- 5 + (remain - 120) / 240
		else
			SetupIcon(frame, db.w , 2, false, nil, tN, tV)
		end
	end
	
	if not isactive and not mainframe.unlock then
		mainframe:SetAlpha(db.inactivealpha)
	end
end

do

	local butns = {}
	local frames = {}
	local createbutton
	
	local cd_tooltip = CreateFrame("Frame", "SPTimersCooldownLineCDToolTip", parent)
	cd_tooltip:SetSize(100, 20)
	cd_tooltip:SetPoint("BOTTOM", mainframe, "TOP",0,0)
	cd_tooltip:SetBackdrop({bgFile = "Interface\\ChatFrame\\ChatFrameBackground",})	
	cd_tooltip:SetBackdropColor(0, 0, 0, 0.7)
	cd_tooltip:Hide()
	cd_tooltip:SetFrameStrata("TOOLTIP")
	cd_tooltip:SetScript("OnUpdate", function(self)
		for k,v in ipairs(butns) do
			v:updatebuttontext()
		end
	end)
	
	local function updatebuttontext(self)
		if self:IsShown() then
		
			local endtime, curtime = 0, GetTime()
				
			if self.f.endtime and self.f.endtime > curtime then
				endtime = self.f.endtime - curtime
			end
			
			self.l:SetText("\124T"..self.f.texture..":12\124t")
			self.r:SetText(format(" %.1f ", endtime))		
			
			self:SetText(self.f.name)
		end
		
		return false
	end
	
	cd_tooltip.AddButtons = function(self, data)
		if not data then return end
		if #data == 0 then return end
		
		for k,v in ipairs(butns) do
			v:Hide()
		end
		
		for i, frame in ipairs(data) do
			local btn = butns[i] or createbutton(i)
			btn.f = frame
			btn:Show()
			btn.updatebuttontext = updatebuttontext
			
			btn:updatebuttontext()
			
			butns[i] = btn
		end
		
		self:SetSize(200, 20*#data)
	end

	local to = "BOTTOM"
	local to2 = "TOP"
	local x = 0
	local y = 0
	
	function C:UpdateTooltip()
		if db.tooltip_anchor_to == 1 then -- СВЕРХУ
			to, to2, x, y = "BOTTOM", "TOP", 0, db.tooltip_anchor_gap
		elseif db.tooltip_anchor_to == 2 then -- СНИЗУ
			to, to2, x, y = "TOP", "BOTTOM", 0, db.tooltip_anchor_gap
		elseif db.tooltip_anchor_to == 3 then -- СЛЕВА
			to, to2, x, y = "RIGHT", "LEFT", db.tooltip_anchor_gap, 0
		elseif db.tooltip_anchor_to == 4 then
			to, to2, x, y = "LEFT", "RIGHT", db.tooltip_anchor_gap, 0
		end

		local a1,a2,a3,a4,a5 = cd_tooltip:GetPoint()
		cd_tooltip:ClearAllPoints()	
		if db.tooltip_anchor_to_frame == 2 then
			cd_tooltip:SetPoint(to, mainframe, to2,x,y)
		else
			cd_tooltip:SetPoint(to, a2, to2,x,y)
		end
	end
	
	function createbutton(index)
		local f = CreateFrame("Button", "SPTimersCooldownLineCDToolTipButton"..index, cd_tooltip)
		f:SetFrameLevel(cd_tooltip:GetFrameLevel() + 1)
		f.parent = cd_tooltip
		f:SetHeight(20) --высота
		f:SetWidth(100) --ширина
		f:SetText("Button"..index)
		f:SetNormalFontObject("GameFontNormalSmall")
		f:SetHighlightFontObject("GameFontHighlightSmall")
		f:SetPoint("BOTTOMLEFT", cd_tooltip, "BOTTOMLEFT", 0, 20*(index-1))
		f:SetPoint("BOTTOMRIGHT", cd_tooltip, "BOTTOMRIGHT", 0, 20*(index-1))
		
		--local t = f:GetFontString()
		--t:SetJustifyH("CENTER")
		
		f.l = f:CreateFontString()
		f.l:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		f.l:SetPoint("LEFT")
		f.l:SetJustifyH("LEFT")
		
		f.r = f:CreateFontString()
		f.r:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
		f.r:SetPoint("RIGHT")
		f.r:SetJustifyH("RIGHT")
		
		f:RegisterForClicks("LeftButtonUp", "RightButtonUp")			
		f:SetScript("OnClick", C.ButtonOnClick )
		f.tooltip = true
		--[[
		f.UpdateText = function(self)
			if self.f.name and self:IsShown() then
				self:SetText(self.f.name.." "..self.f.textcd:GetText())
			end
		end
		]]
		return f
	end
	
	local function isMouseOverButton()
		for index, frame in pairs(cooldowns) do			
			if frame:IsMouseOver() then return true end
		end
	end
	
	local loop = CreateFrame("Frame")
	loop:Hide()
	loop.elapsed = 0
	loop.trottle = 0
	loop:SetScript("OnUpdate", function(self,elapsed)
		self.elapsed = self.elapsed + elapsed
		self.trottle = self.trottle + elapsed
		
		if MouseIsOver(cd_tooltip) or isMouseOverButton() then 
			self.elapsed = 0
			cd_tooltip:SetAlpha(1)
		end
		
		if self.elapsed > 1 then
			
			if self.trottle < 0.05 then return end
			self.trottle = 0
				
			local a = cd_tooltip:GetAlpha() - 0.1
				
			if a < 0 then
				cd_tooltip:HideTooltip()
				return 
			end
			cd_tooltip:SetAlpha(a)
		end
	end)
	cd_tooltip.HideTooltip = function(self)
		self:Hide()
		loop:Hide()
		for k,v in pairs(butns) do
			v:Hide()
		end
		self:SetAlpha(1)	
	end
	
	local function TotalMouseover()
		if not db.show_tooltip then return end
		if db.hide_cooldown_line then return end
		
		wipe(frames)
		for index, frame in pairs(cooldowns) do
			if frame:IsMouseOver() then 
				if C:GetAnonce(frame.name, frame.isplayer) then 
					tinsert(frames, frame)
				end
			end
		end
	
		if #frames > 0 then
			cd_tooltip:Show()
			cd_tooltip:SetAlpha(1)
			loop:Show()
			loop.elapsed = 0
			cd_tooltip:AddButtons(frames)
			cd_tooltip.child = frames[1]
			frames[1].showtooltip = cd_tooltip
			
			cd_tooltip:ClearAllPoints()
			if db.tooltip_anchor_to_frame == 2 then
				cd_tooltip:SetPoint(to, mainframe, to2,x,y)
			else
				cd_tooltip:SetPoint(to, frames[1], to2, x,y)
			end
		
		end
	--	print("Total:"..#frames)
	end
	
	function C.OnEnter(self)
		self.enter = true
		TotalMouseover()
	end
	
	function C.OnLeave(self)
		self.enter = nil
		TotalMouseover()
	end
	
end

do

	local trottle = 1
	local last_trotte = 0
	
	local group = {}

	local banspell = {
		["rune1"] = true,
		["rune2"] = true,
		["rune3"] = true,
		["rune4"] = true,
		["rune5"] = true,
		["rune6"] = true,
	}
	
	function C:UpdateFading1()
		wipe(group)
	
		if last_trotte > 0 then
			last_trotte = last_trotte - 0.2
		end
		
	--	old_print('Reset fading throttle by 0.5')
		
		local first, dur = nil, 0
		local curtime = GetTime()
		
		local _i, total = 0, 0
		
		for i, frame in ipairs(cooldowns) do
			if not frame.hiden and frame.position > 0 then
				local remain = frame.endtime - curtime
				if not first then
					first = frame
					dur = frame.position
					_i = 1
					total = 1
					frame._group = _i
					frame._state = 1
					frame.currentActive = true
					group[_i] = {}
					group[_i]._current = 1
					group[_i]._total = total
					tinsert(group[_i], frame)
				--	print("1", frame.name)
				else
		
					if abs(dur - frame.position) < iconsize*0.5 and ( remain > db.minimal_time_to_fade ) and not banspell[frame.name] then
						frame._group = _i
						total = total + 1
						group[_i]._total = total
						tinsert(group[_i], frame)
					else
						first = frame
						dur = frame.position				
						_i = _i + 1
						frame.currentActive = true
						frame._group = _i
						total = 1
						frame._state = 1
						group[_i] = {}
						group[_i]._current = 1
						group[_i]._total = total
						tinsert(group[_i], frame)
					end
				end
			end
		end
	end
	
	function C:DoFading()
		if GetTime() - last_trotte < trottle then return end		

		last_trotte = GetTime()

		for gr, t in ipairs(group) do
			if t._total > 0 then
				if t._current >= t._total then 
					t._current = 0 
				end
				
				t._current = t._current + 1
				
				for index=1, #t do
					local value = t[index]
					
					if ( value.endtime - GetTime() ) < db.minimal_time_to_fade or #t == 1 then
						if db.mouse_events and not db.hide_cooldown_line then
							value.button:EnableMouse(true)
						else
							value.button:EnableMouse(false)
						end
						
						value:StopPulse()
						value.currentActive = true
					elseif index == t._current then
						value:PulseIn()
						value.currentActive = true	
					else
						value:PulseOut()
						value.currentActive = false
					end
				end
			end
		end
		
		C:UpdateSingleBar()
	end
end



local function NewCooldown(name, icon, endtime, isplayer, force, spellID)
	local f
	
	if not db.enabled then return end
	if C:GetCooldown(name) then return end

	for index, frame in pairs(cooldowns) do
	--	if IsItMe(frame, name, texture, spellID, isplayer, force) then
		if (spellID and (frame.spellID == spellID) or not spellID and ( frame.name == name and frame.texture == icon ) ) and ( frame.isplayer == isplayer or force ) then
			f = frame
			break
		elseif frame.endtime == endtime then
	--		return
		end
	end
	
	if not f then
		f = f or tremove(frames)
		if not f then

			f = CreateFrame("Frame", nil, mainframe.border)
			f.button = CreateFrame("Button", nil, f)
			f.button.f = f
			f.button:SetPoint("TOPLEFT", f, "TOPLEFT")
			f.button:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT")

			if db.mouse_events and not db.hide_cooldown_line then
				f.button:EnableMouse(true)
			else
				f.button:EnableMouse(false)
			end
			
			f.button:SetFrameLevel(f:GetFrameLevel()+1)
			f.button.barbutton = true
			f.button:RegisterForClicks("LeftButtonUp", "RightButtonUp")			
			f.button:SetScript("OnClick", C.ButtonOnClick )			
			f.button:SetScript("OnEnter", C.OnEnter)			
			f.button:SetScript("OnLeave", C.OnLeave)
			f.IsMouseOver = function(self)
				if self.hiden then return false end
				return MouseIsOver(self.button) or self.button.enter
			end
			
			f.border = CreateFrame("Frame", nil, f)
			f.border:SetFrameLevel(f:GetFrameLevel()-1)
			f.border:SetPoint("TOPLEFT",-db.icon_borderinset, db.icon_borderinset) -- Implemented 'insets'
			f.border:SetPoint("BOTTOMRIGHT",db.icon_borderinset, -db.icon_borderinset) -- Implemented 'insets'
			f.border:SetBackdrop(icon_backdrop)
			f.border:SetBackdropBorderColor(db.bordercolor.r, db.bordercolor.g, db.bordercolor.b, db.bordercolor.a)
		
			f:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = self.elapsed - elapsed
				
				if self.elapsed > -0.5 then 
					self:SetFrameLevel(50) 
				end
				
				if self.elapsed < 0 then return end
				self.glow:Hide()
					
				local x,y = self:GetSize()				
				local x1, y1 = x*4*self.elapsed, y*4*self.elapsed
				
				if ( x1 <= x*2.5 ) or ( y1 <= y*2.5 ) then
					self.elapsed = 0
					self.glow:Hide()
					return
				end
				self.glow:SetAlpha(self.elapsed*2)
				self.glow:SetSize(x*3*self.elapsed, y*3*self.elapsed)
				self.glow:Show()
			end)
			
			
			f.elapsed = 0

			f.Glow = function(self)
				self.elapsed = 1
				self:SetFrameLevel(50)
			end
			local t_coord_1 = 0.08
			
			f.icon = f:CreateTexture(nil, "ARTWORK", nil, 5)
			f.icon:SetTexCoord(t_coord_1, 1-t_coord_1, t_coord_1, 1-t_coord_1)
			f.icon:SetPoint("TOPLEFT", 1, -1)
			f.icon:SetPoint("BOTTOMRIGHT", -1, 1)
			f.icon.f = f
			
			f.splashsmall = CreateFrame("Frame", nil, smallsplash)
			f.splashsmall.types = "small"
			f.splashsmall.parent = f
			f.splashsmall:SetAlpha(0.6)
			f.splashsmall:SetPoint("CENTER",smallsplash,"CENTER")
			f.splashsmall:SetFrameStrata("HIGH")
			f.splashsmall:Hide()
			
			f.splashsmall.border = CreateFrame("Frame", nil, f.splashsmall)		
			f.splashsmall.border:SetPoint("TOPLEFT",-db.icon_borderinset, db.icon_borderinset) -- Implemented 'insets'
			f.splashsmall.border:SetPoint("BOTTOMRIGHT",db.icon_borderinset, -db.icon_borderinset) -- Implemented 'insets'
			f.splashsmall.border:SetBackdrop(icon_backdrop)
			f.splashsmall.border:SetBackdropBorderColor(db.icon_bordercolor.r, db.icon_bordercolor.g, db.icon_bordercolor.b, 0.8)
			
			f.splashicon = f.splashsmall:CreateTexture(nil, "ARTWORK", nil, 3)

			f.splashicon:SetTexCoord(t_coord_1, 1-t_coord_1, t_coord_1, 1-t_coord_1)
			f.splashicon:SetPoint("TOPLEFT", 1, -1)
			f.splashicon:SetPoint("BOTTOMRIGHT", -1, 1)

			f.splashbig = CreateFrame("Frame", nil, bigsplashparent)
			f.splashbig.types = "big"
			f.splashbig.parent = f
			f.splashbig:SetAlpha(0.6)
			f.splashbig:SetPoint("CENTER",bigsplashparent,"CENTER")
			f.splashbig:SetFrameStrata("LOW")
			f.splashbig:Hide()
			
			f.splashbig.border = CreateFrame("Frame", nil, f.splashbig)
			f.splashbig.border:SetPoint("TOPLEFT",-db.icon_borderinset, db.icon_borderinset) -- Implemented 'insets'
			f.splashbig.border:SetPoint("BOTTOMRIGHT",db.icon_borderinset, -db.icon_borderinset) -- Implemented 'insets'
			f.splashbig.border:SetBackdrop(icon_backdrop)
			f.splashbig.border:SetBackdropBorderColor(db.icon_bordercolor.r, db.icon_bordercolor.g, db.icon_bordercolor.b, 0.8)
			
			f.splashiconbug = f.splashbig:CreateTexture(nil, "ARTWORK", nil, 3)
			f.splashiconbug:SetTexCoord(t_coord_1, 1-t_coord_1, t_coord_1, 1-t_coord_1)
			f.splashiconbug:SetPoint("TOPLEFT", 1, -1)
			f.splashiconbug:SetPoint("BOTTOMRIGHT", -1, 1)
			

			f.pulse = CreateFrame("Frame", nil, f)
			f.pulse.duration = 1
			f.pulse.elapsed = 0
			f.pulse.f = f
			f.pulse:Hide()
			f.pulse:SetScript("OnUpdate", function(self, elapsed)
				self.elapsed = self.elapsed + ( elapsed * self.step )
				
				if self.mode == 'IN' and self.elapsed >=1 then -- 0 -> 1
					self.f:SetAlpha(self.elapsed/self.duration)
					self:Hide()
				elseif ( self.mode == 'OUT' and self.elapsed <= 0 ) then -- 1 -> 0
					self.f:SetAlpha(self.elapsed/self.duration)
					self:Hide()
				else
					if self.f.glow:IsShown() then
						self.f:SetAlpha(1)
					else
						if ( self.mode == 'IN' and self.elapsed >= 0.5 ) then						
							self.f.button:EnableMouse(db.mouse_events and not db.hide_cooldown_line)
						elseif ( self.mode == 'OUT' and self.elapsed <= 0.5 ) then						
							self.f.button:EnableMouse(false)
						end
						self.f:SetAlpha(self.elapsed/self.duration)
					end
				end
			end)
			
			--[==[
			f.pulse:SetScript("OnUpdate", function(self, elapsed)
				local rate = GetFramerate()
				local limit = 30/rate
				
				local value = self.To
				local cur = self.f:GetAlpha()*100
		
				local new = cur + min((value-cur)/3, max(value-cur, limit))
				if new ~= new then
					new = value
				end
				self.f:SetAlpha(new/100)			
				if (cur == value or abs(new - value) < 2) then
					self.f:SetAlpha(value/100)
					self:Hide()
				end
				old_print(self.f:GetAlpha())
				
			end)
			]==]

			f.StopPulse = function(self)
				self.pulse:Hide()
				self:SetAlpha(1)
			end
			f.PulseIn = function(self)
				--[==[
					
					0 -> 1
					
					0 -> 1
					
					0.3 - > 0.7
					
					0.5 - > 0.5
					
					0.2 - > 0.8
					
				]==]
				
				self.pulse.elapsed = self:GetAlpha()
				self.pulse.step = 1 - self.pulse.elapsed
				self.pulse.mode = 'IN'
				self.pulse:Show()
			end
			f.PulseOut = function(self)
				--[==[
					
					1 -> 0
					
					1 -> 1
					
					0.7 - > 1.3
					
					0.5 - > 1.5
					
					0.2 - > 1.8
					
				]==]
				self.pulse.elapsed = self:GetAlpha()
				self.pulse.step = -2 + self.pulse.elapsed
				self.pulse.mode = 'OUT'
				self.pulse:Show()
			end
			
			f.Splash = function(self)
				DoBigSplash(self.splashbig, self.name)
				DoSmallSplash(self.splashsmall)
			end

			f.glow = f.border:CreateTexture(nil,"ARTWORK");
			f.glow:SetPoint("CENTER",f.icon,"CENTER");
			f.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border") --"Interface\\Tooltips\\UI-Tooltip-Background") --"Interface\\AddOns\\Forte_Core\\Textures\\Spark2");
			f.glow:SetBlendMode("ADD");
			f.glow:Hide()
			
			f.barframe = CreateFrame("Frame", nil, f)
			f.barframe:SetFrameLevel(f:GetFrameLevel()-2)
			
			f.bar = f.barframe:CreateTexture(nil,"ARTWORK", nil, 3);
			f.bar:Show()
			f.bar:SetAlpha(0.6)
			-- db.vertical and (db.reverse
			
			f.textcd = f:CreateFontString(nil, "ARTWORK", nil, 5)
			f.textcd:SetPoint("BOTTOM", f, "BOTTOM")

			f.Update = function(f)
				f:SetWidth(iconsize)
				f:SetHeight(iconsize)
				
				if db.mouse_events and not db.hide_cooldown_line then
					f.button:EnableMouse(true)
				else
					f.button:EnableMouse(false)
				end
			
				f.button:SetSize(iconsize, iconsize)
				
				f.splashbig:SetSize(db.slash_size, db.slash_size)
				f.splashsmall:SetSize(iconsize*1.5, iconsize*1.5)
				
				f.border:SetBackdrop(icon_backdrop)
				f.border:SetBackdropColor(db.icon_backgroundcolor.r,db.icon_backgroundcolor.g,db.icon_backgroundcolor.b,db.icon_backgroundcolor.a)				
				f.border:SetBackdropBorderColor(db.icon_bordercolor.r, db.icon_bordercolor.g, db.icon_bordercolor.b, db.icon_bordercolor.a)
				f.border:SetPoint("TOPLEFT",-db.icon_borderinset, db.icon_borderinset) -- Implemented 'insets'
				f.border:SetPoint("BOTTOMRIGHT",db.icon_borderinset, -db.icon_borderinset) -- Implemented 'insets'
				
				f.splashbig.border:SetBackdrop(icon_backdrop)
				f.splashbig.border:SetBackdropColor(db.splash_background_color.r,db.splash_background_color.g,db.splash_background_color.b,db.splash_background_color.a)
				f.splashbig.border:SetBackdropBorderColor(db.icon_bordercolor.r, db.icon_bordercolor.g, db.icon_bordercolor.b, db.icon_bordercolor.a)
				f.splashbig.border:SetPoint("TOPLEFT", -db.icon_borderinset, db.icon_borderinset) -- Implemented 'insets'
				f.splashbig.border:SetPoint("BOTTOMRIGHT", db.icon_borderinset, -db.icon_borderinset) -- Implemented 'insets'
			
				f.splashsmall.border:SetBackdrop(icon_backdrop)
				f.splashsmall.border:SetBackdropColor(db.splashsmall_background_color.r,db.splashsmall_background_color.g,db.splashsmall_background_color.b,db.splashsmall_background_color.a)
				f.splashsmall.border:SetBackdropBorderColor(db.icon_bordercolor.r, db.icon_bordercolor.g, db.icon_bordercolor.b, db.icon_bordercolor.a)
				f.splashsmall.border:SetPoint("TOPLEFT",  -db.icon_borderinset, db.icon_borderinset) -- Implemented 'insets'
				f.splashsmall.border:SetPoint("BOTTOMRIGHT", db.icon_borderinset, -db.icon_borderinset) -- Implemented 'insets'
			
				if db.hidestatusbar then
					f.bar:Hide()
				else
					f.bar:Show()
				end
				f.bar:SetTexture("Interface\\ChatFrame\\ChatFrameBackground") --"Interface\\Tooltips\\UI-Tooltip-Background");
				f.bar:ClearAllPoints()
				
				if db.vertical then
					f.bar:SetSize(db.h, db.h)
					if db.reverse then
						f.bar:SetPoint("BOTTOM",f.icon,"TOP",0, -1);
						f.bar:SetPoint("TOP", mainframe, "TOP");
					else
						f.bar:SetPoint("TOP",f.icon,"BOTTOM",0, 1);					
						f.bar:SetPoint("BOTTOM", mainframe, "BOTTOM");
					end
				else
					f.bar:SetSize(db.h, db.h)
					if db.reverse then
						f.bar:SetPoint("LEFT",f.icon,"RIGHT",-1, 0);
						f.bar:SetPoint("RIGHT", mainframe, "RIGHT");
					else
						f.bar:SetPoint("RIGHT",f.icon,"LEFT",1, 0);
						f.bar:SetPoint("LEFT", mainframe, "LEFT");
					end
				end
				
				f.textcd:SetFont(smed:Fetch("font", db.icon_font), db.icon_fontsize, db.icon_fontflaggs)
				f.textcd:SetTextColor(db.icon_fontcolor.r, db.icon_fontcolor.g, db.icon_fontcolor.b, db.icon_fontcolor.a)
				f.textcd:SetSize(iconsize*2, db.icon_fontsize)
				f.textcd:SetShadowColor(db.icon_fontshadowcolor.r, db.icon_fontshadowcolor.g, db.icon_fontshadowcolor.b, db.icon_fontshadowcolor.a)
				f.textcd:SetShadowOffset(db.icon_fontshadowoffset[1],db.icon_fontshadowoffset[2])
				
			end
			
			f:Update()
		end
		tinsert(cooldowns, f)
	--	print("1", name, isplayer)
	end	

	if force or f.isplayer ~= isplayer or f.name ~= name or f.endtime ~= endtime or f.texture ~= icon or f.spellID ~= spellID then
	
	--	print("NEW_COOLDOWN", name, force, (f.isplayer ~= isplayer), ( f.name ~= name),(f.endtime ~= endtime), (f.texture == icon) )
		
		local ctime = GetTime()
		local t_coord = 0.08
		f:SetWidth(iconsize)
		f:SetHeight(iconsize)
		
		f:SetAlpha((endtime - ctime > ticks[#ticks]) and 0.6 or 0.8)
		f.name, f.endtime, f.isplayer, f.texture = name, endtime, isplayer, icon
		f.spellID = spellID
		
		f.hiden = nil
		f.position = 0
		f._group = nil
		f.currentActive = nil
		f._currentTickLine = nil
		
		C:PlaySoundCooldown(name, "sound_onshow")
		
		f._texturePath = C:GetCustomCooldownTexture(name) or ( spellID and GetSpellTexture(spellID) ) or icon
		
		f.icon:SetTexture(f._texturePath)		
		f.splashicon:SetTexture(f._texturePath)
		f.splashiconbug:SetTexture(f._texturePath)
				
		--[[
			"PLAYER_ITEMS"
			"BAG_SLOTS"
			"PET_CD"
			"VEHICLE_CD"
			"PLAYER_CD"
			"INTERNAL_CD"	
		]]
		local cColor = C:GetCooldownColor(name)

		if cColor then
			local cR,cG,cB = unpack(cColor)		
			f.bar:SetVertexColor(cR,cG,cB, 0.6);
			f.glow:SetVertexColor(cR,cG,cB);	
		else
			local dColor = C:GetCooldownTypeColor(isplayer)
			local cR,cG,cB = unpack(dColor)
			f.bar:SetVertexColor(cR,cG,cB, 0.6);
			f.glow:SetVertexColor(cR,cG,cB);
		end
		f:Show()
		
		SortCooldowns()
		mainframe:SetScript("OnUpdate", OnUpdate)
		
		mainframe:SetAlpha(db.activealpha)
		OnUpdate(mainframe, 2, ctime)
		
		C:UpdateFading1()
		C:UpdateSingleBar()
	end
end

local function UpdateCooldownStyle()
	for index, frame in pairs(cooldowns) do
		frame:Update()
	end
	for index, frame in pairs(frames) do 
		frames:Update()
	end
end

mainframe.NewCooldown, mainframe.ClearCooldown, mainframe.UpdateCooldownStyle = NewCooldown, ClearCooldown, UpdateCooldownStyle
C.NewCooldown, C.ClearCooldown, C.UpdateCooldownStyle = NewCooldown, ClearCooldown, UpdateCooldownStyle

do
	local GetSpellBookItemName, GetSpellBookItemInfo = GetSpellBookItemName, GetSpellBookItemInfo
	local function CacheBook(btype)
		local lastId, spellName, last, subSpellName
		local slotType, spellId
		
		wipe( spells[btype])
		
		local sb = spells[btype]
	
		local _, _, offset, numSpells = GetSpellTabInfo(2)
		
		for i = 1, offset + numSpells, 1 do
			spellName, subSpellName = GetSpellBookItemName(i, btype)
			
			if not spellName then break end
			
			local slotType, spellId = GetSpellBookItemInfo(i, btype)		
			local isPassive = IsPassiveSpell(i, btype);
	
			if spellId and not disable_spells[spellId] and not isPassive then
				if slotType == "FLYOUT" then
					local _, _, numSlots, isKnown = GetFlyoutInfo(spellId)
					for fi = 1, ((isKnown and numSlots) or 0), 1 do
						local flySpellId, _, _, flySpellName, _ = GetFlyoutSlotInfo(spellId, fi)
						last = flySpellName
						if flySpellId then
							local flycd = MyGetSpellBaseCooldown(flySpellId)
							if flycd and flycd > 2499 and flycd < 1200000 then
								sb[flySpellId] = specialspells[flySpellId] or flySpellName
								
						--		flyOutCooldown[flySpellId] = spellId
								
						--		flyOutCooldownList[spellId] = flyOutCooldownList[spellId] or {}
								
						--		if flyOutCooldownList[spellId][flySpellId] == nil then
						--			flyOutCooldownList[spellId][flySpellId] = flyOutCooldownList[spellId][flySpellId] or true
						--		end
							end
						end
					end
				elseif slotType ~= "FUTURESPELL" and spellId ~= last then
					local name, _, _, _, _, _, spellID = GetSpellInfo(i, btype) 
					
					last = spellId
			--		local spellcd = MyGetSpellBaseCooldown(spellId)
					
					if spellId ~= spellID  then
				--	old_print('T', spellName, subSpellName, isPassive, slotType, spellId, spellID, spellcd)
					end
					
					if spellID then
						sb[spellID] = name
						if specialspells[name] then
							sb[ specialspells[name] ] = name
						end
					end
					--[==[
					sb[spellId] = spellName
					if specialspells[spellName] then
						sb[ specialspells[spellName] ] = spellName
					end
					]==]
				end
			end
		end
	end

	function mainframe:SPELLS_CHANGED()

		CacheBook(BOOKTYPE_SPELL)
		if not db.hidepet then
			CacheBook(BOOKTYPE_PET)
		end
		
	--	C.CacheTaletsIDs(spells[BOOKTYPE_SPELL])
		
		for name, opts in pairs(C:GetPlayerCooldownList()) do
			if not disable_spells[opts.spellid] and opts.spellid and GetSpellInfo(name) and IsSpellKnown(opts.spellid) then			
				spells[BOOKTYPE_SPELL][opts.spellid] = name
			end
		end
	end
	
	C.UpdateSpellCooldowns = mainframe.SPELLS_CHANGED
end


do

	local selap = 0
	local spellthrot = CreateFrame("Frame", nil, mainframe)
	local GetSpellCooldown, GetSpellTexture,GetSpellCharges = GetSpellCooldown, GetSpellTexture,GetSpellCharges
	
	local function GetSpellCooldownCharges(spellID)
	
		if cooldowns_placeholder[spellID] then
			spellID = cooldowns_placeholder[spellID] 
		end
		
		local startTime, duration, enabled, modRate = GetSpellCooldown(spellID)
		local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID)
		local charger = false
		
		if InCombatRes[spellID] then 
			charges = nil;
			maxCharges = nil;
		end
		
		if charges and charges ~= maxCharges then
			charger = true
		end

		
		return ( charger and chargeStart or startTime ), ( charger and chargeDuration or duration ), charges, maxCharges, modRate
	end
	
	local function CheckSpellBook(btype)
		for id, name in pairs(spells[btype]) do
			local texture = GetSpellTexture(id)
			local start, duration, currentCharges, maxCharges, modRate = GetSpellCooldownCharges(id)
			
			--[==[
			if start and duration and duration > 0 and GetMinimumCooldownDuration(id, duration, start) then
				print('Check1', id, name)
				print('Check2', C:GetCooldown(name))
				print('Check3', (not RuneCheck or RuneCheck(name, duration)) )
				print('Check4', C:IsFlyCDLastUsed(id))
				print('Check5', GetMinimumCooldownDuration(id, duration, start))
			end
			]==]
			
			if start and duration and duration > 0 and not C:GetCooldown(name) and (not RuneCheck or RuneCheck(name, duration)) and C:IsFlyCDLastUsed(id) and GetMinimumCooldownDuration(id, duration, start) then		
				if false and maxCharges and maxCharges > 1 then
					if ( maxCharges ~= currentCharges) then
					--	for i=1, currentCharges do
					--		ClearCooldown(nil, name..format(stackspellpattern, i), texture, id, skipWarning)
					--	end
					
						NewCooldown(name..format(stackspellpattern, currentCharges), texture, start+duration*(1+(maxCharges-i)), BookType[btype], nil, id)			
					end
				else
					NewCooldown(name, texture, start + duration, BookType[btype],nil,id)
					
					for index, frame in ipairs(cooldowns) do
						if frame.name == name and frame.texture == texture then
							if frame.endtime > start + duration + 0.1 then
								frame.endtime = start + duration
							end
							break
						end
					end
				end
			else
				if false and maxCharges and maxCharges > 1 then					
					for i=1, currentCharges do
						ClearCooldown(nil, name..format(stackspellpattern, i), texture, id)
					end
				else
					ClearCooldown(nil, name, texture, id) 
				end
			end
		end
	end
	spellthrot:SetScript("OnUpdate", function(this, a1)
		selap = selap + a1
		if selap < 0.3 then return end
		selap = 0
		this:Hide()
		CheckSpellBook(BOOKTYPE_SPELL)
		if not db.hidepet and HasPetUI() then
			CheckSpellBook(BOOKTYPE_PET)
		end
	end)
	spellthrot:Hide()
	
	function mainframe:SPELL_UPDATE_COOLDOWN()
		spellthrot:Show()
	end
	
	mainframe.ENCOUNTER_END = mainframe.SPELL_UPDATE_COOLDOWN
end

do

	local function checkcd(name, tip)
		
		if tip == "item" then
			if db.hideinv then -- если скрывать все кд
			
			--	if block[name] == false then return true end
				if C:GetCooldown(name) == false then return true end
			
		--		print(name, tip, "false")
				return false
			else
				if not C:GetCooldown(name) then return true end
				if C:GetCooldown(name) then return false end
			end
		elseif tip == "bag" then
			if db.hidebag then -- если скрывать все кд
			
			--	if block[name] == false  then return true end
				if C:GetCooldown(name) == false then return true end
				
		--		print(name, tip, "false")
				return false
			else
				if not C:GetCooldown(name) then return true end
				if C:GetCooldown(name) then return false end
			end
		end
		
	--	print(name, tip, "true")
		return true
	end


	
	local GetItemInfo = GetItemInfo
	local GetInventoryItemCooldown, GetInventoryItemTexture = GetInventoryItemCooldown, GetInventoryItemTexture
	local GetContainerItemCooldown, GetContainerItemInfo = GetContainerItemCooldown, GetContainerItemInfo
	local GetContainerNumSlots = GetContainerNumSlots
	
	local bagUpdateThrottle = true
	
	local equippedItems = {}
	
	local function UpdateBag()
		bagUpdateThrottle = true
		
		wipe(equippedItems)
		
		for i = 1, 18, 1 do --(db.hideinv and 0) or
			local start, duration, enable = GetInventoryItemCooldown("player", i)
			if enable == 1 then
				local name = GetItemInfo(GetInventoryItemLink("player", i))
				
				equippedItems[name] = true
				
				if start > 0 and checkcd(name, "item") then
					if duration > 3 and duration < 3601 then
						NewCooldown(name and 'ITEM:'..name or name, GetInventoryItemTexture("player", i), start + duration, "PLAYER_ITEMS")
					end
				else
					ClearCooldown(nil, name and 'ITEM:'..name or name)
				end
			end
		end
		for i = 0, 4, 1 do -- (db.hidebag and -1) or
			for j = 1, GetContainerNumSlots(i), 1 do
				local start, duration, enable = GetContainerItemCooldown(i, j)
				if enable == 1 then
					local name = GetItemInfo(GetContainerItemLink(i, j))
					
					if not equippedItems[name] then
						if start > 0 and checkcd(name, "bag") then
							if duration > 3 and duration < 3601 then
								NewCooldown(name and 'ITEM:'..name or name, GetContainerItemInfo(i, j), start + duration, "BAG_SLOTS")
							end
						else
							ClearCooldown(nil, name and 'ITEM:'..name or name)
						end
					end
				end
			end
		end
	end
	
	function mainframe:BAG_UPDATE_COOLDOWN()
		if bagUpdateThrottle then
			bagUpdateThrottle = false
			C_Timer.After(0.3, UpdateBag)
		end
	end
end

function mainframe:PET_BAR_UPDATE_COOLDOWN()
	for i = 1, 10, 1 do
		local start, duration, enable = GetPetActionCooldown(i)
		if enable == 1 then
			local name, _, texture = GetPetActionInfo(i)
			if name then
				if start > 0 and not C:GetCooldown(name)then
					if duration > 3 then
						NewCooldown(name, texture, start + duration, "PET_CD")
					end
				else
					ClearCooldown(nil, name)
				end
			end
		end
	end
end

function mainframe:UNIT_PET(a1)
	if UnitExists("pet") and not HasPetUI() then
		mainframe:RegisterEvent("PET_BAR_UPDATE_COOLDOWN")
	else
		mainframe:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
	end
end

local GetActionCooldown, HasAction = GetActionCooldown, HasAction

function mainframe:ACTIONBAR_UPDATE_COOLDOWN()  -- used only for vehicles
	for i = 1, 8, 1 do
		local b = _G["OverrideActionBarButton"..i]
		if b and HasAction(b.action) then
			local start, duration, enable = GetActionCooldown(b.action)
			if enable == 1 then
				if start > 0 and not C:GetCooldown(GetActionInfo(b.action))then
					if duration > 3 then
						NewCooldown("vhcle"..i, GetActionTexture(b.action), start + duration, "VEHICLE_CD")
					end
				else
					ClearCooldown(nil, "vhcle"..i)
				end
			end
		end
	end
end

function mainframe:UNIT_ENTERED_VEHICLE()
	if not UnitHasVehicleUI("player") then return end
	mainframe:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	mainframe:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player", '')
	mainframe:ACTIONBAR_UPDATE_COOLDOWN()
end

function mainframe:UNIT_EXITED_VEHICLE()
	mainframe:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	for index, frame in ipairs(cooldowns) do
		if strmatch(frame.name, "vhcle") then
			ClearCooldown(nil, frame.name)
		end
	end
end

local failborder
----------------------------------------------------
function mainframe:UNIT_SPELLCAST_FAILED(unit, spell)
----------------------------------------------------
	if #cooldowns == 0 then return end
	local currentCharges, maxCharges = GetSpellCharges(spell)
	if maxCharges then
		local total = 0
		for index, frame in pairs(cooldowns) do		
			for cd=1 , (maxCharges-currentCharges) do
				if frame.name == spell..format(stackspellpattern, cd) then
					total = total + 1
					if frame.endtime - GetTime() > 1 then
						frame:Glow()
					end
				end
			end
			
			if total == maxCharges then break end
		end
	else
		for index, frame in pairs(cooldowns) do
			if frame.name == spell then
				if frame.endtime - GetTime() > 1 then
					frame:Glow()
				end
				break
			end
		end
	end
end

function mainframe:UNIT_SPELLCAST_SUCCEEDED(unit, spell, rank, lineID, spellID)

	if unit ~= 'player' then return end
	
	if flyOutCooldown[spellID] then
		for id in pairs(flyOutCooldownList[flyOutCooldown[spellID]]) do
			if id == spellID then			
				flyOutCooldownList[flyOutCooldown[spellID]][id] = true
			else
				flyOutCooldownList[flyOutCooldown[spellID]][id] = false
			end
		end
	end
--	flyOutCooldown[flySpellId] = spellId							
--	flyOutCooldownList[spellId] = flyOutCooldownList[spellId] or {}
--	flyOutCooldownList[spellId][flySpellId] = flyOutCooldownList[spellId][flySpellId] or -1						
end

function C:IsFlyCDLastUsed(spellID)
	
	local spell = flyOutCooldown[spellID]

	if spell then
		return flyOutCooldownList[spell][spellID]
	end
	
	return true
end

function C:RegisterAsShareSpellCooldown(tag, spellID)
	flyOutCooldown[spellID] = tag
	flyOutCooldownList[tag] = flyOutCooldownList[tag] or {}
	flyOutCooldownList[tag][spellID] = false
end

C:RegisterAsShareSpellCooldown('Warlock:BurstCooldown', 18540)
C:RegisterAsShareSpellCooldown('Warlock:BurstCooldown', 1122)


do
	local RUNETYPE_BLOOD = 1;
	local RUNETYPE_UNHOLY = 2;
	local RUNETYPE_FROST = 3;
	local RUNETYPE_DEATH = 4;
		
	local iconTextures = {
		[RUNETYPE_BLOOD] = "Interface\\AddOns\\"..addon.."\\media\\BlizzardBlood",
		[RUNETYPE_UNHOLY]= "Interface\\AddOns\\"..addon.."\\media\\BlizzardUnholy",
		[RUNETYPE_FROST] = "Interface\\AddOns\\"..addon.."\\media\\BlizzardFrost",
		[RUNETYPE_DEATH] = "Interface\\AddOns\\"..addon.."\\media\\BlizzardDeath",
	}
	
	local runeName = {
		"RuneBlood",
		"RuneUnholy",
		"RuneFrost",
		"RuneDeath",
	}
	
	local indexToType = {1,1,2,2,3,3}
	
	local function UpdateDKRunes(runeIndex, force)
		if ( runeIndex == 1 or runeIndex == 2 ) and db.blood_runes then return end
		if ( runeIndex == 5 or runeIndex == 6 ) and db.frost_runes then return end
		if ( runeIndex == 3 or runeIndex == 4 ) and db.unholy_runes then return end
		
		local start, duration, runeReady = GetRuneCooldown(runeIndex);
	--	local runeType = GetRuneType(runeIndex)

		if ( not start ) then
			return
		end 

		if runeReady then
			ClearCooldown(nil, "rune"..runeIndex)
		else
			NewCooldown("rune"..runeIndex, "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune", start + duration, runeName[indexToType[4]], force)
		end
	end
	function mainframe:RUNE_POWER_UPDATE(runeIndex, isEnergize)
		UpdateDKRunes(runeIndex)				
	end
	
	function mainframe:RUNE_TYPE_UPDATE(runeIndex)
		UpdateDKRunes(runeIndex, true)
	end	
end

function C:UnlockCooldownLine()

	mainframe:SetMovable(true)
	mainframe:SetResizable(true)
	mainframe:RegisterForDrag("LeftButton")
	mainframe:SetScript("OnDragStart", function(this) this:StartMoving() end)
	mainframe:SetScript("OnDragStop", function(this) 
		this:StopMovingOrSizing()
		local x, y = this:GetCenter()
		local ux, uy = parent:GetCenter()
		db.x, db.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
		this:ClearAllPoints()
		UpdateSettings()
	end)
	splashbigmover:SetMovable(true)
	splashbigmover:SetResizable(true)
	splashbigmover:RegisterForDrag("LeftButton")
	splashbigmover:SetScript("OnDragStart", function(this) this:StartMoving() end)
	splashbigmover:SetScript("OnDragStop", function(this) 
		this:StopMovingOrSizing()
		local x, y = this:GetCenter()
		local ux, uy = parent:GetCenter()
		db.slash_x, db.slash_y = floor(x - ux + 0.5), floor(y - uy + 0.5)
		this:ClearAllPoints()
		UpdateSettings()
	end)

	if not self.db.profile.locked then
		mainframe.unlock = true
		mainframe:EnableMouse(true)
		mainframe:SetAlpha(db.activealpha)
		
		splashbigmover:EnableMouse(true)
		splashbigmover:Show()
	else
		mainframe.unlock = nil
		mainframe:EnableMouse(false)
		OnUpdate(mainframe, 2)
		
		splashbigmover:EnableMouse(false)
		splashbigmover:Hide()
	end
end

--[==[
do
	local icd_cache = CreateFrame("Frame")
	icd_cache:RegisterEvent("PLAYER_LOGIN")
	icd_cache:RegisterEvent("PLAYER_LOGOUT")
	icd_cache.logginin = false
	icd_cache.elapsed = 0
	icd_cache:Hide()
	icd_cache:SetScript("OnUpdate", function(self, elapsed)
		if not self.logginin then return end		
		self.elapsed = self.elapsed - elapsed		
		if self.elapsed > 0 then return end	
		if not SPTimersICD_Cache then SPTimersICD_Cache = {} end
		for k,v in pairs(SPTimersICD_Cache) do	
			if v.timer > time() then
				NewCooldown(v.name, v.icon, GetTime()+v.endtime, v.isplayer)
			end
		end	
		wipe(SPTimersICD_Cache)		
		self:Hide()
		self:SetScript("OnUpdate", nil)
	end)

	icd_cache:SetScript("OnEvent", function(self, event)
		if not SPTimersICD_Cache then SPTimersICD_Cache = {} end	
		if event == "PLAYER_LOGIN" then
			self.elapsed = 0.3
			self.logginin = true
			self:Show()
		elseif event == "PLAYER_LOGOUT" then
			wipe(SPTimersICD_Cache)
			for i, f in ipairs(cooldowns) do
				if f.isplayer == "INTERNAL_CD" then
					local lastdur = f.endtime - GetTime()
					local _endtime = time() + lastdur
					
					SPTimersICD_Cache[f.name..f.isplayer] = { timer = _endtime, isplayer = f.isplayer, name = f.name, endtime = lastdur, icon = f.icon:GetTexture() }
				end
			end
		end
	end)
end
]==]