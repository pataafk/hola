local addon, C = ...
local LSM = C.LSM

local disabled = true

--[[
	
	PLAYER_STARTED_MOVING
	PLAYER_STOPPED_MOVING

]]

local rotations = { "MS - 4orbs - SWP - MB - VT - DP - MB - SWI", }

local rotations_mov = {

	"Halo > G:SWD > G:PWS",
	"G:SWD > G:PWS > Halo",
	"G:PWS > Halo > G:SWD",
}


local function GetHaste()
	return (1+(UnitSpellHaste("player")/100))
end

local function GetGCD()
	
	local gcd = 1.5/GetHaste()
	
	gcd = gcd < 1 and 1 or gcd
	
	return gcd
end

local swp_name = GetSpellInfo(589)
local function SWP_IsUP(lowerThen)
	local name, rank, icon, count, debuffType, duration, expirationTime = UnitAura("target", swp_name, nil, "HARMFUL|PLAYER")	
	if name then
		if lowerThen then
			if duration < lowerThen then
				return true
			end
		else	
			return true
		end
	end
	return false
end

local vt_name = GetSpellInfo(34914)
local function VT_IsUP(lowerThen)
	local name, rank, icon, count, debuffType, duration, expirationTime = UnitAura("target", vt_name, nil, "HARMFUL|PLAYER")	
	if name then
		if lowerThen then
			if duration < lowerThen then
				return true
			end
		else	
			return true
		end
	end
	return false
end

local function BothDots_IsUP(lowerThen)
	
	local swp = SWP_IsUP(lowerThen)
	local vt = SWP_IsUP(lowerThen)
	
	if swp and vt then
		return true
	end
	
	return false
end

local priorityList = {
	
	[1] = function()
		-- Mind Blast 1st priority
		-- But if shadow orbs lower then 5
		local texture = select(3, GetSpellInfo(8092))
		local power = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
		
		if power == 5 then 	
			return false 
		elseif power == 4 then
			local name = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")	
			if not name then return false end
		end
		
		local start, duration, enabled = GetSpellCooldown(8092)
		local name, subText, text, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player")
		
		if duration > GetGCD() then 
			return false, texture, start, duration
		end
		
		
		return true, texture, start, duration
	end,
	
	[2] = function()
		-- second priority is swp only if we have 4 shadow orbs
		-- otherwise ignoring it
		
		local power = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
		
		if power < 4 then	
			return false 
		end
		
		local start, duration, enabled = GetSpellCooldown(8092)
		
		if duration > GetGCD() and  ( (start+duration) - GetTime() ) > 2/GetHaste() then
			return false	
		end
		
		local name = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")	
		if name then 		
			return false 
		end
		
		return true, select(3, GetSpellInfo(589))
		
	end,
	
	[3] = function()
		-- 3rd priority is vt
		-- if we have 5 orbs then start dotweawing
		
		
		local power = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
		
		if power < 4 then return false end
		
		local name = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")	
		if not name then return false end
		
		local name = UnitDebuff("target", (GetSpellInfo(34914)),nil, "PLAYER")		
		if name then return false end
		
		return true, select(3, GetSpellInfo(34914))
		
	end,

	[4] = function()
		-- 4rd priority is SWI
		-- if we have 5 orbs then start dotweawing
		
		local name, _, icon, count, debuffType, duration, expirationTime = UnitBuff("player", (GetSpellInfo(132573)),nil, "PLAYER")
		
		local swi, subText, text, texture, startTime, endTime = UnitChannelInfo("player")
		local swiname = GetSpellInfo(139139)
	
		if not name and not ( swi == swiname ) then return false end
	
		local start = expirationTime and expirationTime-duration or ( swi and startTime*0.001 ) or 0
		local durat = duration or ( swi and ( endTime - startTime )*0.001 ) or 0
		
		return true, select(3, GetSpellInfo(139139)), start, durat, true
		
	end,
	
	
	[5] = function()
		-- 5rd priority is DP
	
		local power = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
		
		local name = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")	
		if not name then return false end
		
		if power == 5 then return true, select(3, GetSpellInfo(2944)) end
		
		local name = UnitDebuff("target", (GetSpellInfo(34914)),nil, "PLAYER")		
		if not name then return false end
	
		local name = UnitDebuff("target", (GetSpellInfo(2944)),nil, "PLAYER")		
		if name then return false end
		
		if power == 3 then return true, select(3, GetSpellInfo(2944)) end
		
		
		return false, select(3, GetSpellInfo(2944))
		
	end,
	[6] = function()
		-- 6rd priority is MSp
		
		local start, duration, enabled = GetSpellCooldown(8092)
		
		local name1 = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")
		local name2 = UnitDebuff("target", (GetSpellInfo(34914)),nil, "PLAYER")
		local name3 = UnitDebuff("target", (GetSpellInfo(2944)),nil, "PLAYER")
		
		if name1 or name2 or name3 then return false end

		
		return true, select(3, GetSpellInfo(73510))				
	end,
	
	[7] = function()
		-- Mind Blast 1st priority
		-- But if shadow orbs lower then 5
		local texture = select(3, GetSpellInfo(8092))
		local power = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
		
		if power == 5 then 	
			return false 
		elseif power == 4 then
			local name = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")	
			if not name then return false end
		end
		
		local start, duration, enabled = GetSpellCooldown(8092)
		local name, subText, text, _, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo("player")
		
		
		if (start+duration) - GetTime() < 4 then
			return true, texture, start, duration		
		end
		if duration > GetGCD() then 
			return false, texture, start, duration
		end
		
		
		return true, texture
	end,
	
	[8] = function()
		-- 7rd priority for swp if mb cooldown loser then 3 sec
		
		local power = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
		
		if power < 4 then	
			return false 
		end
		
		local start, duration, enabled = GetSpellCooldown(8092)
	
		if duration > GetGCD() and ( (start+duration) - GetTime() ) > 4 then
			return false	
		end

		return true, select(3, GetSpellInfo(589)), start, duration-GetGCD()
	end,
	
	[9] = function()
		-- 5rd priority is DP
	
		local power = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
		local start, duration, enabled = GetSpellCooldown(8092)
		
		if power == 4 and start == 0 and duration == 0 then return true, select(3, GetSpellInfo(2944)) end
		
		local name = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")	
		if not name then return false end
		
		local name = UnitDebuff("target", (GetSpellInfo(34914)),nil, "PLAYER")		
		if not name then return false end
		
		local name = UnitDebuff("target", (GetSpellInfo(2944)),nil, "PLAYER")		
		if name then return false end
	
		if power == 2 and start == 0 and duration == 0 then return true, select(3, GetSpellInfo(2944)) end
		
		
		return false, select(3, GetSpellInfo(2944))
		
	end,
	--[[
	[10] = function()
		-- Halo
		local start, duration, enabled = GetSpellCooldown(120644)
		
		local name1 = UnitDebuff("target", (GetSpellInfo(589)),nil, "PLAYER")
		local name2 = UnitDebuff("target", (GetSpellInfo(34914)),nil, "PLAYER")
		local name3 = UnitDebuff("target", (GetSpellInfo(2944)),nil, "PLAYER")
		
		if not name1 and not name2 and not name3 then return false end

		if duration > GetGCD() then return false end
		
		return true, select(3, GetSpellInfo(120644))		
	end,
	]]
	[10] = function()
		-- 6rd priority is MSp		
		return true, select(3, GetSpellInfo(73510))		
	end,
}

function C:CoPToggle()
	if self.myCLASS ~= "PRIEST" then return end
	if self.db.profile.enable_cop and not disabled then		
		C.events:RegisterEvent("PLAYER_STARTED_MOVING")
		C.events:RegisterEvent("PLAYER_STOPPED_MOVING")
		C.events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		C.events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
		C.events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
		C.events:RegisterEvent("UNIT_SPELLCAST_START")
		C.events:RegisterEvent("UNIT_SPELLCAST_DELAYED")
		C.events:RegisterEvent("UNIT_POWER_FREQUENT")
		C.events:RegisterEvent("PLAYER_TARGET_CHANGED")
		C.events:RegisterEvent("SPELL_UPDATE_USABLE")
		C.events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		C.events:Show()
		
		C.events:PLAYER_TARGET_CHANGED()
	else
		C.events:UnregisterAllEvents()
		C.events:Hide()
		C.mainframe:Hide()
	end

end

function C:GetCoPGUI()
	
	if self.myCLASS ~= "PRIEST" then return end
	if disabled then return end
	
	local gui = {
		order = 5,
		name = "Clarity Of Power",type = "group", --guiInline = false,
		args = {},
	}
	
	gui.args.enable = {
		order = 1,name = "Enable",type = "toggle",
		set = function(info,val) self.db.profile.enable_cop = not self.db.profile.enable_cop; self:CoPToggle();end,
		get = function(info) return self.db.profile.enable_cop end
	}
	
	gui.args.rotation = {
		name = "Rotation",
		order = 2,
		type = "dropdown",
		width = "full",
		values = rotations,
		set = function(info,val)
			self.db.profile.cop_rotation = val
		end,
		get = function(info, val) 
			return self.db.profile.cop_rotation or 1
		end
	}
	
	gui.args.rotation_mov = {
		name = "Rotation on movement",
		order = 2,
		type = "dropdown",
		width = "full",
		values = rotations_mov,
		set = function(info,val)
			self.db.profile.cop_rotation_mov = val
		end,
		get = function(info, val) 
			return self.db.profile.cop_rotation_mov or 1
		end
	}
	
	return gui
end



local channeling = false
local moving = false

local events = CreateFrame("Frame")
events:Hide()
C.events = events

events:SetScript("OnEvent", function(self, event, ...)
	self[event](self, event, ...)
end)

events:SetScript("OnUpdate", function(self, elapsed)
	
	self.elapsed = ( self.elapsed or 0 ) + elapsed
	
	if self.elapsed < 0.1 then return end
	
	self.elapsed = 0
	C:UpdateOrder()
end)

function events:PLAYER_STARTED_MOVING()
	local name = UnitChannelInfo("player")
	if name then channeling = true
	else channeling = false end

	
	if moving ~= true and not channeling then 
		moving = true
		
--		print("Player Moving")
	end
end

function events:PLAYER_STOPPED_MOVING()
	local name = UnitChannelInfo("player")
	
	if name then channeling = true
	else channeling = false end
	
	if moving ~= false and not channeling then 
		moving = false
		
--		print("Player Stopped")
	end
end


function events:UNIT_SPELLCAST_CHANNEL_START(event, unit)
	if unit ~= "player" then return end
	C:UpdateOrder()
end
function events:UNIT_SPELLCAST_CHANNEL_STOP(event, unit)
	if unit ~= "player" then return end
	C:UpdateOrder()
end

function events:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit)
	if unit ~= "player" then return end
	C:UpdateOrder()
end
function events:UNIT_SPELLCAST_START(event, unit)
	if unit ~= "player" then return end
	C:UpdateOrder()
end
function events:UNIT_SPELLCAST_DELAYED(event, unit)
	if unit ~= "player" then return end
	C:UpdateOrder()
end
function events:UNIT_POWER_FREQUENT(event, unit, power)
	if unit ~= "player" or power ~= "SHADOW_ORBS" then return end
	C:UpdateOrder()
end
function events:PLAYER_TARGET_CHANGED(event)
	if not UnitExists("target") then
		C.mainframe:Hide()
		return 
	end
	C.mainframe:Show()
	C:UpdateOrder()
end

function events:SPELL_UPDATE_USABLE()
	C:UpdateOrder()
end
function events:SPELL_UPDATE_COOLDOWN()
	C:UpdateOrder()
end


local mainframe = CreateFrame("Frame", "SPTimersCOPFrameManager", UIParent)
mainframe:SetSize(155, 100)
mainframe:SetPoint("CENTER")
mainframe:Hide()
mainframe:SetClampedToScreen(true)
mainframe:SetMovable(true)
mainframe:RegisterForDrag("LeftButton")
mainframe:EnableMouse(true)
mainframe:SetScript("OnDragStart", mainframe.StartMoving)
mainframe:SetScript("OnDragStop", mainframe.StopMovingOrSizing)

C.mainframe = mainframe

local bg = mainframe:CreateTexture()
bg:SetAllPoints()
bg:SetColorTexture(1, 1, 1, 0.5)

C.icons = {}

local icon1 = CreateFrame("Frame", nil, mainframe)
icon1:SetSize(80, 80)
icon1.bg = icon1:CreateTexture()
icon1.bg:SetAllPoints()
icon1.bg:SetColorTexture(1, 0, 0, 0.5)
icon1:SetPoint("LEFT", mainframe, "LEFT", 5, 0)

icon1.cd = CreateFrame("Cooldown", nil, icon1, "CooldownFrameTemplate")
icon1.cd:SetAllPoints()
icon1.cd:SetDrawEdge(false)

local icon2 = CreateFrame("Frame", nil, mainframe)
icon2:SetSize(60, 60)
icon2.bg = icon2:CreateTexture()
icon2.bg:SetAllPoints()
icon2.bg:SetColorTexture(0, 1, 0, 0.5)
icon2:SetPoint("BOTTOMLEFT", icon1, "BOTTOMRIGHT", 5, 0)
icon2.cd = CreateFrame("Cooldown", nil, icon2, "CooldownFrameTemplate")
icon2.cd:SetAllPoints()
icon2.cd:SetDrawEdge(false)


C.icons[1] = icon1
C.icons[2] = icon2

function C:UpdateOrder()
	local checked = 0
	
	for i=1, #priorityList do
		
		local status, texture, startTime, duration, force = priorityList[i]()
	
		if status then
			checked = checked + 1
		
			C.icons[checked].bg:SetTexture(texture)
			
			if ( checked == 2 or force ) and startTime and duration and startTime > 0 and duration > 0 then
				C.icons[checked].cd:Show()
				C.icons[checked].cd:SetCooldown(startTime, duration)
			else
				C.icons[checked].cd:Hide()
			end
		
			if checked >= 2 then break end
		end
	end

end
