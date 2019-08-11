local addon, C = ...
local w, h
local L = AleaUI_GUI.GetLocale("SPTimers")

local pingWorkAround = true

local events = {
	"UNIT_SPELLCAST_CHANNEL_START",
	"UNIT_SPELLCAST_CHANNEL_STOP",
	"UNIT_SPELLCAST_CHANNEL_UPDATE",
	
	--"UNIT_SPELLCAST_SENT",
	"UNIT_SPELLCAST_START",
	"UNIT_SPELLCAST_DELAYED",
	
	"UNIT_SPELLCAST_INTERRUPTED",
	"UNIT_SPELLCAST_STOP",
	--"UNIT_SPELLCAST_SUCCEEDED",
	
	"UNIT_SPELLCAST_INTERRUPTIBLE",
	"UNIT_SPELLCAST_NOT_INTERRUPTIBLE",
}	

local colors = {
	["notinterruptible"] = {0.2,0.2,0.2,1},
	["interruptible"] = { .6, .2, .2, 1},
	
	["ping"] = { 1, 1, 1, 0.5 },
	["ticks"] = {150/255, 225/255, 239/255, 1},
}

local spelldb = {
	[15407]  = { ticks = 4, amount = 4, every = 3/4, haste = true },
	[48045]  = { ticks = 5, amount = 5, every = 1, haste = true }, -- Mind Sear Normal
--	[179338]  = { ticks = 5, amount = 5, every = 1, haste = true }, -- Mind Sear Normal
	
	
	[129197] = { ticks = 4, amount = 4, every = 1, haste = true },	
	[103103] = { ticks = 4, amount = 4, every = 1, haste = true },
	
	[47540] = { ticks = 1, amount = 1, every = 1, haste = true },
	[64843] = { ticks = 4, amount = 4, every = 1, haste = true },
	
	[205065] = { ticks = 4, amount = 4, every = 1, haste = true },

}

local channeling_info = {}

local function Round(num) return math.floor(num+.5) end --.5

local function getbarpos(bar, tik)
	local minValue, maxValue = bar:GetMinMaxValues()
	if tik >= 0 then
		return tik / maxValue * bar:GetWidth()
	else
		return (maxValue+tik) / maxValue * bar:GetWidth()
	end
end

local bordersize = 1

local function SameUnit(u1,u2)
	if u1 and u2 and UnitIsUnit(u1, u2) then
		return false
	end
	return true
end

local SetPing = function(self, value)
	--self:Hide()
	--if SameUnit(self.parent.unit, "player") then return end
	
	if not value then 
		self:Hide()
		return 
	end

	
	if value >= 0.25 then
		value = 0.25
	end

	local minv, maxv = self.parent:GetMinMaxValues()
	local width, height = self.parent:GetWidth(), self.parent:GetHeight()
	local mywidth = width/maxv*value


	self:SetSize(mywidth, height)
	
	local left1 = self.parent:GetRight()
	local left2 = self:GetRight() or 0
	
	if left2 >= left1 then
		self:SetSize(mywidth-abs(left2-left1), height)
	end
	
	self:Show()
	
	if self.text then
		self.text:Show()
	end
end

local function DrawLatency(f, name)	
	if f.parent.unit ~= "player" then return end
	

	if channeling_info[name] then
		for i=1, #f.tiks do
			if f.tiks[i]:IsShown() then
				f.tiks[i].latensy:SetPing(f.ping)
			else
				f.tiks[i].latensy:Hide()
			end
		end		
		f.channelLatency:SetPing(f.ping)
	--	f.channelLatency.text:SetFormattedText("%d", f.ping*1000)
		f.castLatency:Hide()
		f.castLatency.text:Hide()
	else
		for i=1, #f.tiks do		
			f.tiks[i].latensy:Hide()
		end		
		f.channelLatency:Hide()
		f.channelLatency.text:Hide()
	--	f.castLatency.text:SetFormattedText("%d", f.ping*1000)

		f.castLatency:SetPing(f.ping)
	end
end

local function CreateTicks(f)
	
	local opts = C.db.profile.castBars[f.unit]
	local h = f:GetHeight()
	
	local tick = f.ticksparent:CreateTexture(nil, "ARTWORK")
	tick:SetAlpha(1)
	tick:SetWidth(1)
	tick:SetHeight(h)
	tick:SetColorTexture(opts.tick_color[1],opts.tick_color[2],opts.tick_color[3],opts.tick_color[4])
	
	local lat3 = f.ticksparent:CreateTexture(nil, "ARTWORK")
	lat3.parent = f
	lat3:SetHeight(h)
	lat3:SetPoint("LEFT", tick, "RIGHT")
	lat3.SetPing = SetPing
	lat3:SetColorTexture(opts.ping_color[1],opts.ping_color[2],opts.ping_color[3],opts.ping_color[4])

	tick.latensy = lat3
	
	return tick
end

local function DrawTicks(f, name)	

	for i=1, #f.tiks do
		f.tiks[i]:Hide()
	end

	if f.parent.unit ~= "player" then return end

	if channeling_info[name] then
	
	--	print(f.parent.unit)
		
		local haste = f.haste or UnitSpellHaste("player")
		local tick_every, amount_to_show
		local tick = channeling_info[name].every
		local duration = f.duration
		
		if channeling_info[name].haste then
			tick_every	= tick/(1+(haste/100))
		else
			tick_every	= tick
		end
		
		amount_to_show = Round(duration/tick_every) - 1
			
		if f.duration2 > 0 then			
			amount_to_show = amount_to_show + 1
		end

		for i=1, amount_to_show do
			w,h = f:GetWidth(), f:GetHeight()
			
			f.tiks[i] = f.tiks[i] or CreateTicks(f)

			local tick_position = floor(getbarpos(f, tick_every*i))
			
			if false then
				f.tiks[i]:SetPoint("LEFT",f,"LEFT", -(tick_position)+w, 0)			
			else
				f.tiks[i]:SetPoint("LEFT",f,"LEFT", (tick_position), 0)
			end

			f.tiks[i]:Show()
		end
	end
end

local function CastBarOnUpdate(f, elapsed)
	local curtime = GetTime()
	if curtime > f.endTime then
		f:Hide()
		return  
	end
	
	local curdur
	
	if f.nap == 1 then -- cast
		curdur = curtime - f.startTime
	else -- channel
		curdur = f.endTime - curtime
	end
	local v = f.duration2-f.duration

	if f.opts.ping and f.unit == "player" then
		if v > 0 then
			f.rightText:SetFormattedText(" |cFFFF0000MS:%d|r %.1f | %.1f + %.1f ", f.ping*1000, curdur, f.duration, v)
		else
			f.rightText:SetFormattedText(" |cFFFF0000MS:%d|r %.1f | %.1f ", f.ping*1000, curdur, f.duration)
		end
	else
		if v > 0 then
			f.rightText:SetFormattedText(" %.1f | %.1f + %.1f ", curdur, f.duration, v)
		else
			f.rightText:SetFormattedText(" %.1f | %.1f ", curdur, f.duration)
		end
	end
	
	f:SetValue(curdur)
end

-- name, subText, text, texture, startTime / 1000, endTime / 1000, isTradeSkill, notInterruptible = UnitChannelInfo("unit")
-- name, subText, text, texture, startTime / 1000, endTime / 1000, isTradeSkill, castID, notInterruptible = UnitCastingInfo("unit")

local function OnCast(f, unit)

	local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)	
	
	if name then
		f:ShowGCD(name)	
	end
	
	if not startTime or not endTime then 
		f:Hide()
		return 
	end
	
--	print("T1",name, GetSpellCooldown(name)-GetTime(), GetSpellCooldown(castID)-GetTime())

	
	f.startTime		= startTime*0.001
	f.endTime		= endTime*0.001
	f.duration		= f.endTime - f.startTime
	f.duration2		= 0
	f.nap			= 1

	if pingWorkAround then
		local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
		f.ping			= f.castTime_Start and latencyWorld*0.001 or 0
	else
		f.ping			= f.castTime_Start and ( f.startTime - f.castTime_Start ) or 0
	end

	f.icon:SetTexture(texture)
	
	if f.opts.target_name and f.curTarget then
		f.leftText:SetText(name.." -> "..f.curTarget)
	else		
		f.leftText:SetText(name)
	end

	


	f:SetMinMaxValues(0, f.duration)
	f:DrawTicks(name)
	f:UpdateIntrerruptState(notInterruptible)
	f:DrawLatency(name)
	--f:SetReverseFill(false)

	f:Show()
end

local function OnCastUpdate(f, unit)
	
	local name, text, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
	if not startTime or not endTime then 
		f:Hide()
		return 
	end

	
	f.startTime		= startTime*0.001
	f.endTime		= endTime*0.001
	f.nap			= 1
	
	f.duration2		= f.endTime - f.startTime

	f.icon:SetTexture(texture)
	
	if f.opts.target_name and f.curTarget then
		f.leftText:SetText(name.." -> "..f.curTarget)
	else		



		f.leftText:SetText(name)
	end

	f:DrawTicks(name)
	f:SetMinMaxValues(0, f.duration2)
	f:UpdateIntrerruptState(notInterruptible)
	f:DrawLatency(name)

	f:Show()
end

local function OnChannel(f, unit)
	
	local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
	if not startTime or not endTime then 
		f:Hide()
		return 
	end

	
--	print("OnChannel")
	
--	print("T2", name, GetSpellCooldown(name)-GetTime())
	
	f.startTime		= startTime*0.001
	f.endTime		= endTime*0.001
	f.duration		= f.endTime - f.startTime
	f.duration2		= 0
	f.nap			= -1
	f.haste			= UnitSpellHaste("player")

	if pingWorkAround then
		local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
		f.ping			= f.castTime_Start and latencyWorld*0.001 or 0
	else
		f.ping			= f.castTime_Start and ( f.startTime - f.castTime_Start ) or 0
	end
	
	
	f.icon:SetTexture(texture)
	
	if f.opts.target_name and f.curTarget then
		f.leftText:SetText(name.." -> "..f.curTarget)
	else		
		f.leftText:SetText(name)
	end
	
	f:SetMinMaxValues(0, f.duration)
	f:DrawTicks(name)
	f:UpdateIntrerruptState(notInterruptible)
	f:DrawLatency(name)

	
	f:Show()
end

local function OnChannelUpdate(f, unit)
	
	local name, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo(unit)
	if not startTime or not endTime then 
		f:Hide()
		return 
	end

	
--	print("OnChannelUpdate", f.endTime, endTime/1000, (endTime/1000)-f.endTime, f.parent.unit)

--	f.duration2 	= f.endTime - f.startTime
	
	f.startTime		= startTime*0.001
	f.endTime		= endTime*0.001
	f.duration2 	= f.endTime - f.startTime --f.duration + abs((endTime/1000)-f.endTime)
	f.nap			= -1

	
	f.icon:SetTexture(texture)

	
	if f.opts.target_name and f.curTarget then
		f.leftText:SetText(name.." -> "..f.curTarget)
	else		
		f.leftText:SetText(name)
	end

	


	f:SetMinMaxValues(0, f.duration2)
	f:UpdateIntrerruptState(notInterruptible)

	f:DrawTicks(name)
	f:DrawLatency(name)

	f:Show()
end

local test_bar = false
local function TestCastBar(f)
	
	if not test_bar then
		f.startTime		= GetTime()-90
		f.endTime		= GetTime()+90
		f.duration		= f.endTime - f.startTime
		f.duration2		= 0
		f.nap			= 1

		if pingWorkAround then
			local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
			f.ping			= f.castTime_Start and latencyWorld*0.001 or 0
		else
			f.ping			= f.castTime_Start and ( f.startTime - f.castTime_Start ) or 0
		end

		--print("OnCast")
		
		f.icon:SetTexture("Interface\\Icons\\spell_shadow_shadowwordpain")
		f.leftText:SetText("TestCastBar")
		f:SetMinMaxValues(0, f.duration)
		f:DrawTicks(name)
		f:UpdateIntrerruptState(true)
		f:DrawLatency(name)
		--f:SetReverseFill(false)
		
--		f.castTime_Start = nil
		f:Show()
	else
		f:Hide()
	end
end


local function UpdateVisual(f)
	local opts = C.db.profile.castBars[f.unit]
	
	f.mover:SetSize(opts.w, opts.h)
	if f.mover2 then
		f.mover2:SetSize(opts.w, opts.h)
	end
	
	f.opts = opts
	f:SetStatusBarTexture(C.LSM:Fetch("statusbar",opts.startusbar))
	f:GetStatusBarTexture():SetDrawLayer("ARTWORK")
	f:SetStatusBarColor(unpack(opts.color_inter))
	f:SetPoint("TOPRIGHT", f.mover, "TOPRIGHT", -0, -0)
	f:SetPoint("BOTTOMRIGHT", f.mover, "BOTTOMRIGHT", -0, 0)
	f:SetSize(opts.w-opts.h-opts.icon_gap, opts.h)
	
	f.channelLatency:SetStatusBarColor(opts.ping_color[1],opts.ping_color[2],opts.ping_color[3],opts.ping_color[4])
	f.channelLatency:SetSize(40, opts.h)
	f.channelLatency.text:SetFont(C.LSM:Fetch("font",opts.font), opts.font_size, opts.font_flag)
	
	f.castLatency:SetStatusBarColor(opts.ping_color[1],opts.ping_color[2],opts.ping_color[3],opts.ping_color[4])
	f.castLatency:SetSize(40, opts.h)
	f.castLatency.text:SetFont(C.LSM:Fetch("font",opts.font), opts.font_size, opts.font_flag)
	
	f.border:SetBackdrop({
		edgeFile = C.LSM:Fetch("border",opts.border), 
		edgeSize = opts.border_size, 
	})
	f.border:SetBackdropBorderColor(unpack(opts.border_color))
	
	f.border:SetPoint("LEFT", -opts.border_inset, 0)		
	f.border:SetPoint("RIGHT", opts.border_inset, 0)
	f.border:SetPoint("TOP", 0, opts.border_inset)		
	f.border:SetPoint("BOTTOM", 0, -opts.border_inset)
	
	f.bg:SetColorTexture(unpack(opts.color_bg))

	f.icon:SetSize(opts.h,opts.h)
	f.icon:SetPoint("TOPRIGHT", f, "TOPLEFT", -opts.icon_gap, 0)
	f.icon:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", -opts.icon_gap, 0)
	
	f.icon.border:SetBackdrop({
		edgeFile = C.LSM:Fetch("border",opts.border), 
		edgeSize = opts.border_size, 
	})
	f.icon.border:SetBackdropBorderColor(unpack(opts.border_color))
	f.icon.border:SetPoint("LEFT", f.icon,"LEFT",-opts.border_inset, 0)		
	f.icon.border:SetPoint("RIGHT", f.icon,"RIGHT", opts.border_inset, 0)
	f.icon.border:SetPoint("TOP", f.icon,"TOP",0, opts.border_inset)		
	f.icon.border:SetPoint("BOTTOM", f.icon,"BOTTOM",0, -opts.border_inset)
	
	f.icon.bg:SetColorTexture(unpack(opts.color_bg))
	
	f.rightText:SetTextColor(unpack(opts.font_color))
	f.rightText:SetFont(C.LSM:Fetch("font",opts.font), opts.font_size, opts.font_flag)
	f.rightText:SetAlpha(opts.font_alpha)
	
	f.leftText:SetTextColor(unpack(opts.font_color))
	f.leftText:SetFont(C.LSM:Fetch("font",opts.font), opts.font_size, opts.font_flag)
	f.leftText:SetAlpha(opts.font_alpha)
	
	for i=1, #f.tiks do
		f.tiks[i]:SetColorTexture(unpack(opts.tick_color))
		f.tiks[i]:SetHeight(opts.h)
		
		f.tiks[i].latensy:SetColorTexture(opts.ping_color[1],opts.ping_color[2],opts.ping_color[3],opts.ping_color[4])
		f.tiks[i].latensy:SetHeight(opts.h)
	end
end
	
local function CreateCastBar(frame, w, h, drawticks)
	w, h = w or 200, h or 20
	
	
	local mover = CreateFrame("StatusBar", nil, frame)
	mover:SetSize(w,h)
	mover:SetPoint("CENTER", frame, "CENTER", 0, 0)
	mover:SetFrameStrata("LOW")
	
	local f = CreateFrame("StatusBar", nil, mover)
	f:SetFrameLevel(mover:GetFrameLevel()+1)
	f.parent = frame
	
	f:SetFrameStrata("LOW")

	f.ticksparent = CreateFrame("Frame", nil, f)
	f.ticksparent:SetFrameLevel(f:GetFrameLevel()+2)
	f.tiks = {}
	
	f.mover = mover
	
	f.unit = frame.unit
	
	local lat1 = CreateFrame("StatusBar", nil, f)
	lat1:SetFrameLevel(f:GetFrameLevel()+1)
	lat1.parent = f
	lat1:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
	lat1:GetStatusBarTexture():SetDrawLayer("ARTWORK")
	lat1:SetFrameStrata("LOW")

	lat1:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -0)
	lat1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 0, 0)

	lat1.SetPing = SetPing
	lat1:Hide()
	
	lat1.text = f.ticksparent:CreateFontString(nil, "OVERLAY", nil, 4)

	lat1.text:SetJustifyH("LEFT")
	lat1.text:SetJustifyV("BOTTOM")
	lat1.text:SetTextColor(1,0,0)
	lat1.text:SetPoint("BOTTOMLEFT", lat1, "BOTTOMLEFT", 1,1)
	lat1.text:SetSize(40,12)

	local lat2 = CreateFrame("StatusBar", nil, f)
	lat2:SetFrameLevel(f:GetFrameLevel()+1)
	lat2.parent = f
	lat2:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
	lat2:GetStatusBarTexture():SetDrawLayer("ARTWORK")
	lat2:SetFrameStrata("LOW")

	lat2:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
	lat2:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)

	lat2.SetPing = SetPing
	lat2:Hide()
	
	local gcd = CreateFrame("StatusBar", nil, mover)
	gcd:SetFrameLevel(f:GetFrameLevel()+3)
	gcd.parent = f
	gcd:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
	gcd:SetStatusBarColor(1, 1, 1, 0.5)
	
	gcd:GetStatusBarTexture():SetDrawLayer("ARTWORK")
	gcd:SetPoint("BOTTOMLEFT", mover, "TOPLEFT", 0, 2)
	gcd:SetPoint("BOTTOMRIGHT", mover, "BOTTOMRIGHT", 0, 2)
	gcd:SetSize(3, 3)
	gcd:Hide()
	gcd:SetScript("OnUpdate", function(self, elapsed)
		
		local num = GetTime() - self._startTime
		self:SetValue(num)
		if num > self._duration then
			self._startTime = 0
			self._duration = 0
			self:Hide()
		end
	end)
	
	f.gcd = gcd
	
	lat2.text = f.ticksparent:CreateFontString(nil, "OVERLAY", nil, 4)

	lat2.text:SetJustifyH("RIGHT")
	lat2.text:SetJustifyV("BOTTOM")
	lat2.text:SetTextColor(1,0,0)
	lat2.text:SetPoint("BOTTOMRIGHT", lat2, "BOTTOMRIGHT", 1,1)
	lat2.text:SetSize(40,12)
	
	f.border = CreateFrame("Frame", nil, f)
	f.UpdateIntrerruptState = function(self, state)
		local opts = C.db.profile.castBars[self.unit]
		if state then
			self:SetStatusBarColor(opts.color_notinter[1],opts.color_notinter[2],opts.color_notinter[3],opts.color_notinter[4])

		else
			self:SetStatusBarColor(opts.color_inter[1],opts.color_inter[2],opts.color_inter[3],opts.color_inter[4])

		end
	end
	
	
	f.DrawTicks = DrawTicks
	f.DrawLatency = DrawLatency
	f.OnChannelUpdate = OnChannelUpdate
	f.OnCast = OnCast
	f.OnCastUpdate = OnCastUpdate
	f.OnChannel = OnChannel
	f.CastBarOnUpdate = CastBarOnUpdate
	f.TestCastBar = TestCastBar
	
	f.ShowGCD = function(self)
		
		if self.unit ~= "player" then return end
		if not self.opts.showGCD then return end

		local start, duration, enabled  = GetSpellCooldown(61304)
	
		if start and start > 0 and duration <= 1.5 then
			self.gcd:SetMinMaxValues(0, duration)
			self.gcd._startTime = start
			self.gcd._duration = duration
			
			self.gcd:Show()
		end
	end
	
	local bg = f:CreateTexture(nil,"BACKGROUND")
	bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	bg:SetAllPoints(f)

	
	f.bg = bg
	
	local icon = f:CreateTexture(nil,"ARTWORK")




	icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	f.icon = icon
	
	bg = f:CreateTexture(nil,"BACKGROUND")
	bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	bg:SetAllPoints(f.icon)
	bg:SetColorTexture(0,0,0,1)
	
	f.icon.bg = bg
	
	f.icon.border = CreateFrame("Frame", nil, f)

	for i, event in ipairs(events) do
		frame:RegisterEvent(event)
	end
	
	local rightText = f.ticksparent:CreateFontString(nil, "ARTWORK", nil, 2);
	rightText.parent = f
	rightText:SetPoint("RIGHT", f, "RIGHT")
	
	rightText:SetJustifyH("RIGHT")
	
	local leftText = f.ticksparent:CreateFontString(nil, "ARTWORK", nil, 2);
	leftText.parent = f
	leftText:SetPoint("LEFT", f, "LEFT")
	leftText:SetPoint("RIGHT", rightText, "LEFT")
	leftText:SetJustifyH("LEFT")
	
	f.castLatency = lat2
	f.channelLatency = lat1

	f.leftText = leftText
	f.rightText = rightText
	
	f.UpdateVisual = UpdateVisual

	
	f:Hide()
	
	frame.castBar = f
	
	f:UpdateVisual()
	
	f:SetScript("OnUpdate", f.CastBarOnUpdate)

	
	function frame:UNIT_SPELLCAST_CHANNEL_START(event, unit)
		-- if SameUnit(unit, self.unit) then return end
	
		 if SameUnit(self.unit, unit) then return end
		self.castBar:OnChannel(unit)	
	end
	
	if f.unit == "player" then		
		frame:RegisterEvent("UNIT_SPELLCAST_SENT")
		function frame:UNIT_SPELLCAST_SENT(event, unit, spell, rank, target)	
			if not UnitIsUnit(self.unit, unit) then return end
			
			self.castBar.curTarget = (target and target ~= "") and target or nil
			self.castBar.castTime_Start = GetTime()
		end
		
		
		frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
		function frame:UNIT_SPELLCAST_SUCCEEDED(event, unitID, spell, rank, lineID, spellID)	

			if unitID == "player" then
				
			--	print("T", spell, spellID)
				
				if spell then
					f:ShowGCD(spell)	
				end
			end
			
		end
		
	end
	
	if f.unit == "target" or f.unit == "targettarget" then
		frame:RegisterEvent("PLAYER_TARGET_CHANGED")
		function frame:PLAYER_TARGET_CHANGED()
			if not UnitExists(f.unit) then 
				self.castBar:Hide()
				return
			end
			self:CastBarUpdate()
		end
	end
	
	if string.match(f.unit, "(boss)%d")  then
		frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		function frame:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
			if not UnitExists(f.unit) then return end
			self:CastBarUpdate()
		end
	end
	
	if string.match(f.unit, "(arena)%d") then
		frame:RegisterEvent("ARENA_OPPONENT_UPDATE")
		function frame:ARENA_OPPONENT_UPDATE()
			if not UnitExists(f.unit) then return end
			self:CastBarUpdate()
		end
	end
	
	if f.unit == "focus" then
		frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
		function frame:PLAYER_FOCUS_CHANGED()
			if not UnitExists(f.unit) then return end
			self:CastBarUpdate()

		end
	end
	
	function frame:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit)
		-- if SameUnit(unit, self.unit) then return end
		
		 if SameUnit(unit, self.unit) then return end
		self.castBar:OnChannelUpdate(unit)	
	end
	
	function frame:UNIT_SPELLCAST_START(event, unit)
		-- if SameUnit(unit, self.unit) then return end
		if SameUnit(unit, self.unit) then return end
		self.castBar:OnCast(unit)
	end
	
	function frame:UNIT_SPELLCAST_DELAYED(event, unit)
		-- if SameUnit(unit, self.unit) then return end
		
		 if SameUnit(unit, self.unit) then return end
		self.castBar:OnCastUpdate(unit)
	end

	function frame:UNIT_SPELLCAST_INTERRUPTED(event, unit)
		-- if SameUnit(unit, self.unit) then return end
		
		 if SameUnit(unit, self.unit) then return end
		self.castBar:Hide()
	end
	
	frame.UNIT_SPELLCAST_STOP = frame.UNIT_SPELLCAST_INTERRUPTED
	frame.UNIT_SPELLCAST_CHANNEL_STOP = frame.UNIT_SPELLCAST_INTERRUPTED
	
	function frame:UNIT_SPELLCAST_INTERRUPTIBLE(event, unit)
		-- if SameUnit(unit, self.unit) then return end
		
		 if SameUnit(unit, self.unit) then return end
		self.castBar:UpdateIntrerruptState(false)
	end
	
	function frame:UNIT_SPELLCAST_NOT_INTERRUPTIBLE(event, unit)
		-- if SameUnit(unit, self.unit) then return end
		
		 if SameUnit(unit, self.unit) then return end
		self.castBar:UpdateIntrerruptState(true)
	end

	frame.CastBarUpdate = function(self)
		self:UNIT_SPELLCAST_INTERRUPTED()
		if UnitChannelInfo(self.unit) then self:UNIT_SPELLCAST_CHANNEL_START(_, self.unit) end
		if UnitCastingInfo(self.unit) then self:UNIT_SPELLCAST_START(_, self.unit) end
	end
	
	return mover
end

local function _addmover(f, opts)
	
		f.mover = CreateFrame("Frame", nil, f)
		f.mover.text = f.mover:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		f.mover.text:SetPoint("CENTER", f.mover, "CENTER",0,0)
		f.mover.text:SetTextColor(1,1,1,1)
		f.mover.text:SetFont(STANDARD_TEXT_FONT,12, "OUTLINE")
		f.mover.text:SetJustifyH("CENTER")
		f.mover.text:SetText("Unlocked. Move castbar for "..f.unit)
		
		f.mover:EnableMouse(true)
		f.mover.parent = f		
		f.mover:SetMovable(true)
		f.mover:RegisterForDrag("LeftButton")
		f.mover:SetScript("OnDragStart", function(self) self:StartMoving() end)
		f.mover:SetScript("OnDragStop", function(self) 
			self:StopMovingOrSizing()
			local x, y = self:GetCenter()
			local ux, uy = C.Parent:GetCenter()

			self.parent.opts.point = { floor(x - ux + 0.5),floor(y - uy + 0.5) }

			for k,v in pairs(self.mover_add_button.editboxes) do
				v:UpdateText()
			end
		end)

		f.mover:SetClampedToScreen(true)		
		
		f.mover.bg_1 = f.mover:CreateTexture()
		f.mover.bg_1:SetAllPoints()
		f.mover.bg_1:SetColorTexture(0,0,0,1)
		
		f.mover:SetAlpha(.6)
		f.mover:Show()
		
		f.castBar.mover2 = f.mover
		
		f.mover:ClearAllPoints()
		f.mover:SetPoint("CENTER", C.Parent, "CENTER",opts.point[1] or 0, opts.point[2] or 0)				
		f.mover:SetSize( opts.w or 100 , opts.h or 20)
		
		f.opts = opts
		
		f:ClearAllPoints()
		f:SetPoint("CENTER", f.mover,"CENTER", 0, 0)
		f:SetSize(1,1)
		
		C.AddMoverButtons(f.mover, opts)

		
end

local castbar_frames = {}

local function UpdateCastBarsStyle()	
	for name, frame in pairs(castbar_frames) do
		frame.castBar:UpdateVisual()
	end
end

C.UpdateCastBarsStyle = UpdateCastBarsStyle


function C:CastBarInit()

	for spellid, db in pairs(spelldb) do
		local id = GetSpellInfo(spellid)
		--[[
		if not id then
			print(id, "error with C:CastBarInit() on", spellid)
		end
		]]
		if id then
			channeling_info[id] = db
		end
	end

	castbar_frames.playerCastBar = CreateFrame("Frame", nil, self.Parent)
	castbar_frames.playerCastBar:SetSize(1,1)
	castbar_frames.playerCastBar:SetPoint("CENTER", 0, -310)
	castbar_frames.playerCastBar.unit = "player"
	castbar_frames.playerCastBar:SetScript("OnEvent", function(self, event, ...)	
		self[event](self, event, ...)	
	end)
	
	CreateCastBar(castbar_frames.playerCastBar, 410, 20)
	
	_addmover(castbar_frames.playerCastBar, self.db.profile.castBars.player)
	
	castbar_frames.targetCastBar = CreateFrame("Frame", nil, self.Parent)
	castbar_frames.targetCastBar:SetSize(1,1)
	castbar_frames.targetCastBar:SetPoint("CENTER", 0, -310)
	castbar_frames.targetCastBar.unit = "target"
	castbar_frames.targetCastBar:SetScript("OnEvent", function(self, event, ...)	
		self[event](self, event, ...)	
	end)
	
	CreateCastBar(castbar_frames.targetCastBar, 410, 20)
	
	_addmover(castbar_frames.targetCastBar, self.db.profile.castBars.target)
	
	castbar_frames.targettargetCastBar = CreateFrame("Frame", nil, self.Parent)
	castbar_frames.targettargetCastBar:SetSize(1,1)
	castbar_frames.targettargetCastBar:SetPoint("CENTER", 0, -310)
	castbar_frames.targettargetCastBar.unit = "targettarget"
	castbar_frames.targettargetCastBar:SetScript("OnEvent", function(self, event, ...)	
		self[event](self, event, ...)	
	end)
	
	CreateCastBar(castbar_frames.targettargetCastBar, 410, 20)
	
	_addmover(castbar_frames.targettargetCastBar, self.db.profile.castBars.targettarget)
	
	
	castbar_frames.focusCastBar = CreateFrame("Frame", nil, self.Parent)
	castbar_frames.focusCastBar:SetSize(1,1)
	castbar_frames.focusCastBar:SetPoint("CENTER", 0, -310)
	castbar_frames.focusCastBar.unit = "focus"
	castbar_frames.focusCastBar:SetScript("OnEvent", function(self, event, ...)	
		self[event](self, event, ...)	
	end)
	
	CreateCastBar(castbar_frames.focusCastBar, 410, 20)
	
	_addmover(castbar_frames.focusCastBar, self.db.profile.castBars.focus)
	
	castbar_frames.petCastBar = CreateFrame("Frame", nil, self.Parent)
	castbar_frames.petCastBar:SetSize(1,1)
	castbar_frames.petCastBar:SetPoint("CENTER", 0, -310)
	castbar_frames.petCastBar.unit = "pet"
	castbar_frames.petCastBar:SetScript("OnEvent", function(self, event, ...)	
		self[event](self, event, ...)	
	end)
	
	CreateCastBar(castbar_frames.petCastBar, 410, 20)
	
	_addmover(castbar_frames.petCastBar, self.db.profile.castBars.pet)
	
	self:UnlockCastBars()
	self:UpdateCastBarsVisible()
	self:DisableBlizzCastBars(true)
end

local hidenframe = CreateFrame("Frame")
hidenframe:SetAlpha(0)
hidenframe:SetScale(0.001)
hidenframe:Hide()
hidenframe.Show = un_fun
hidenframe.unit = ""
hidenframe.buffsOnTop = false
hidenframe.auraRows = 0

local BlizzCastBars = {
	['CastingBarFrame'] = true,
	['PetCastingBarFrame'] = true,	
	['FocusFrameSpellBar'] = true,
	['TargetFrameSpellBar'] = true,
}

local function ReHide(self)
	if not C.db.profile.disableBlizzard then return end
	self:Hide()
end

function C:DisableBlizzCastBars(skip)
	if self.db.profile.disableBlizzard then
		for k, v in pairs(BlizzCastBars) do			
			if _G[k] and v then			
				v = false
				
				_G[k]:Hide()
				_G[k]:HookScript("OnShow", ReHide)
			end
		end
	end
end

function C:TestCastBars()
	
	for name,frame in pairs(castbar_frames) do
		
		frame.castBar:TestCastBar()
	end
	if not test_bar then
		test_bar = true
	else
		test_bar = false
	end
end

function C:UpdateCastBarsVisible()
	
	if self.db.profile.playerCastBar then
		castbar_frames.playerCastBar:Show()
	else
		castbar_frames.playerCastBar:Hide()
	end

	if self.db.profile.targetCastBar then
		castbar_frames.targetCastBar:Show()
	else
		castbar_frames.targetCastBar:Hide()
	end
	
	if self.db.profile.targettargetCastBar then
		castbar_frames.targettargetCastBar:Show()
	else
		castbar_frames.targettargetCastBar:Hide()
	end
	
	if self.db.profile.focusCastBar then
		castbar_frames.focusCastBar:Show()
	else
		castbar_frames.focusCastBar:Hide()
	end
	
	if self.db.profile.petCastBar then
		castbar_frames.petCastBar:Show()
	else
		castbar_frames.petCastBar:Hide()
	end
end

function C:UnlockCastBars()
	if self.db.profile.locked then
		castbar_frames.playerCastBar.mover:Hide()
		castbar_frames.targetCastBar.mover:Hide()
		castbar_frames.targettargetCastBar.mover:Hide()
		castbar_frames.focusCastBar.mover:Hide()
		castbar_frames.petCastBar.mover:Hide()
		
		castbar_frames.playerCastBar.mover:EnableMouse(false)
		castbar_frames.targetCastBar.mover:EnableMouse(false)
		castbar_frames.targettargetCastBar.mover:EnableMouse(false)
		castbar_frames.focusCastBar.mover:EnableMouse(false)
		castbar_frames.petCastBar.mover:EnableMouse(false)
		
	else
		castbar_frames.playerCastBar.mover:Show()
		castbar_frames.targetCastBar.mover:Show()
		castbar_frames.targettargetCastBar.mover:Show()
		castbar_frames.focusCastBar.mover:Show()
		castbar_frames.petCastBar.mover:Show()
		
		castbar_frames.playerCastBar.mover:EnableMouse(true)
		castbar_frames.targetCastBar.mover:EnableMouse(true)
		castbar_frames.targettargetCastBar.mover:EnableMouse(true)
		castbar_frames.focusCastBar.mover:EnableMouse(true)
		
		castbar_frames.petCastBar.mover:EnableMouse(true)
	end
end

local myCastBars = { "player", "target", "targettarget", "focus", "pet" }
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
}
function C:GetCastBarGUI()
	
	local gui_option = {
		order = 4,name = L["Cast Bars"],type = "group", --guiInline = false,
		args = {
			disableBlizzard = {
				order = 1,name = L["Disable Blizzard castbar"],type = "toggle", width = "full",
				set = function(info,val) self.db.profile.disableBlizzard = not self.db.profile.disableBlizzard; self:DisableBlizzCastBars();end,
				get = function(info) return self.db.profile.disableBlizzard end
			},
			show_playerCastBar = {
				order = 2,name = L["Show player castbar"],type = "toggle", width = "full",
				set = function(info,val) self.db.profile.playerCastBar = not self.db.profile.playerCastBar; self:UpdateCastBarsVisible(); end,
				get = function(info) return self.db.profile.playerCastBar end
			},
			show_targetCastBar = {
				order = 3,name = L["Show target castbar"],type = "toggle", width = "full",
				set = function(info,val) self.db.profile.targetCastBar = not self.db.profile.targetCastBar; self:UpdateCastBarsVisible(); end,
				get = function(info) return self.db.profile.targetCastBar end
			},
			show_targettargetCastBar = {
				order = 3,name = L["Show target of target castbar"],type = "toggle", width = "full",
				set = function(info,val) self.db.profile.targettargetCastBar = not self.db.profile.targettargetCastBar; self:UpdateCastBarsVisible();end,
				get = function(info) return self.db.profile.targettargetCastBar end
			},
			show_focusCastBar = {
				order = 4,name = L["Show focus castbar"],type = "toggle", width = "full",
				set = function(info,val) self.db.profile.focusCastBar = not self.db.profile.focusCastBar; self:UpdateCastBarsVisible(); end,
				get = function(info) return self.db.profile.focusCastBar end
			},
			
			show_petCastBar = {
				order = 4,name = L["Show pet castbar"],type = "toggle", width = "full",
				set = function(info,val) self.db.profile.petCastBar = not self.db.profile.petCastBar; self:UpdateCastBarsVisible(); end,
				get = function(info) return self.db.profile.petCastBar end
			},
		},
	}
				
	for k,v in ipairs(myCastBars) do
		
		gui_option.args[v] = {
			type = "group",	order	= k,
			guiInline = false,
			name	= v,
			args = {},
		}
		
		if v == "player" then
		gui_option.args[v].args.ping = {
			order = 1,name = L["Show latency text"],type = "toggle",
			set = function(info,val) self.db.profile.castBars[v].ping = not self.db.profile.castBars[v].ping; self.UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].ping end
		
		}
		end
	
		if v == "player" then
		gui_option.args[v].args.target_name = {
			order = 1,name = L["Show target name"],type = "toggle",
			set = function(info,val) self.db.profile.castBars[v].target_name = not self.db.profile.castBars[v].target_name; self.UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].target_name end
		
		}		
		end
		
		if v == "player" then
		gui_option.args[v].args.showGCD = {
			order = 1,name = L["Show GCD"],type = "toggle",
			set = function(info,val) self.db.profile.castBars[v].showGCD = not self.db.profile.castBars[v].showGCD; self.UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].showGCD end
		
		}		
		end
		
		gui_option.args[v].args.separator1 = {
			type = "group",
			name = "",
			order = 20,
			embend = true, args = {},
		}
					
		gui_option.args[v].args.separator1.args.w = {
			name = L["Width"],
			desc = L["Set bar Width"],
			type = "slider",
			order	= 21,
			min		= 1,
			max		= 1920,
			step	= 1,
			set = function(info,val) 
				self.db.profile.castBars[v].w = val
				UpdateCastBarsStyle()
			end,
			get =function(info)
				return self.db.profile.castBars[v].w
			end,
		}
		gui_option.args[v].args.separator1.args.h = {
			name = L["Height"],
			desc = L["Set bar Height"],
			type = "slider",
			order	= 22,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.castBars[v].h = val
				UpdateCastBarsStyle()
			end,
			get =function(info)
				return self.db.profile.castBars[v].h
			end,
		}
		
		gui_option.args[v].args.separator1.args.color_interr = {
			order = 28,name = L["Interruptible"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.castBars[v].color_inter={r,g, b, a};UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].color_inter[1],self.db.profile.castBars[v].color_inter[2],self.db.profile.castBars[v].color_inter[3],self.db.profile.castBars[v].color_inter[4] end
		}
		
		gui_option.args[v].args.separator1.args.color_notinterr = {
			order = 28,name = L["Not interruptible"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.castBars[v].color_notinter={r,g, b, a};UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].color_notinter[1],self.db.profile.castBars[v].color_notinter[2],self.db.profile.castBars[v].color_notinter[3],self.db.profile.castBars[v].color_notinter[4] end
		}
		
		gui_option.args[v].args.separator1.args.color_background = {
			order = 28,name = L["Background"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.castBars[v].color_bg={r,g, b, a};UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].color_bg[1],self.db.profile.castBars[v].color_bg[2],self.db.profile.castBars[v].color_bg[3],self.db.profile.castBars[v].color_bg[4] end
		}
		if v == "player" then
		gui_option.args[v].args.separator1.args.color_tick = {
			order = 28,name = L["Ticks color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.castBars[v].tick_color={r,g, b, a};UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].tick_color[1],self.db.profile.castBars[v].tick_color[2],self.db.profile.castBars[v].tick_color[3],self.db.profile.castBars[v].tick_color[4] end
		}
		end
		gui_option.args[v].args.separator1.args.color_ping = {
			order = 28,name = L["Ping color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.castBars[v].ping_color={r,g, b, a};UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].ping_color[1],self.db.profile.castBars[v].ping_color[2],self.db.profile.castBars[v].ping_color[3],self.db.profile.castBars[v].ping_color[4] end
		}
		
		gui_option.args[v].args.fontGroup = {
			type = "group",
			name = "",
			order = 29,
			embend = true, args = {},
		}
		
		gui_option.args[v].args.fontGroup.args.font = {
			order = 32,name = L["Font"],type = 'font',
			values = C.LSM:HashTable("font"),
			set = function(info,key) self.db.profile.castBars[v].font = key;UpdateCastBarsStyle()  end,
			get = function(info) return self.db.profile.castBars[v].font end,
		}
		gui_option.args[v].args.fontGroup.args.fontsize = {
			name = L["Size"],
			type = "slider",
			order	= 33,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val)		
				self.db.profile.castBars[v].font_size = val
				UpdateCastBarsStyle()
			end,
			get = function(info)
				return	self.db.profile.castBars[v].font_size
			end,
		}
		
		gui_option.args[v].args.separator1.args.icon_gap = {
			name = L["Gap"],
			type = "slider",
			order	= 34.2,
			min		= 0,
			max		= 50,
			step	= 0.1,
			set = function(info,val)
				self.db.profile.castBars[v].icon_gap = val
				UpdateCastBarsStyle()
			end,
			get = function(info)
				return self.db.profile.castBars[v].icon_gap and self.db.profile.castBars[v].icon_gap or 0
			end,
		}
		
		--[[
		gui_option.args[v].args.justifu = {
			type = "select",	order = 28,
			name = L["Justify"],
			values = justifu,
			set = function(info,val) 
				self.db.profile.castBars[v].justify = val
			end,
			get = function(info) return self.db.profile.castBars[v].justify end
		}
		]]
		
		gui_option.args[v].args.fontGroup.args.fontflaggs = {
			type = "dropdown",	order = 34,
			name = L["Flags"],
			values = text_flaggs,
			set = function(info,val) 
				self.db.profile.castBars[v].font_flag = val
				UpdateCastBarsStyle()
			end,
			get = function(info) return self.db.profile.castBars[v].font_flag end
		}
		gui_option.args[v].args.fontGroup.args.textshadowcolor = {
			order = 34.1,name = L["Text Shadow color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.castBars[v].font_shadow_color={r,g,b,a};UpdateCastBarsStyle() end,
			get = function(info) 
				local color = self.db.profile.castBars[v].font_shadow_colo or { 0,0,0,1}
				
				return color[1],color[2],color[3],color[4] 
			end
		}
		gui_option.args[v].args.fontGroup.args.fontshadowoffset_x = {
			name = L["Shadow offset X"],
			type = "slider",
			order	= 34.2,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.castBars[v].font_shadow_offset then self.db.profile.castBars[v].font_shadow_offset = {} end

				self.db.profile.castBars[v].font_shadow_offset[1] = val
				UpdateCastBarsStyle()
			end,
			get = function(info)
				return self.db.profile.castBars[v].font_shadow_offset and self.db.profile.castBars[v].font_shadow_offset[1] or 0
			end,
		}
		gui_option.args[v].args.fontGroup.args.fontshadowoffset_y = {
			name = L["Shadow offset Y"],
			type = "slider",
			order	= 34.3,
			min		= -10,
			max		= 10,
			step	= 0.1,
			set = function(info,val)
				if not self.db.profile.castBars[v].font_shadow_offset then self.db.profile.castBars[v].font_shadow_offset = {} end

				self.db.profile.castBars[v].font_shadow_offset[2] = val
				
				UpdateCastBarsStyle()
			end,
			get = function(info)
				return self.db.profile.castBars[v].font_shadow_offset and self.db.profile.castBars[v].font_shadow_offset[2] or 0
			end,
		}


		gui_option.args[v].args.borderDsk = {
			type = "group",
			name = L["Borders"],
			order = 25, embend = true, args = {},
		}
		gui_option.args[v].args.borderDsk.args.border = {
			order = 26,type = 'border',name = L["Border Texture"],
			values = C.LSM:HashTable("border"),
			set = function(info,value) self.db.profile.castBars[v].border = value; UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].border end,
		}
		gui_option.args[v].args.borderDsk.args.statusbar = {
			order = 26,type = 'statusbar',name = L["Texture"],
			values = C.LSM:HashTable("statusbar"),
			set = function(info,value) self.db.profile.castBars[v].startusbar = value; UpdateCastBarsStyle() end,
			get = function(info) return self.db.profile.castBars[v].startusbar end,
		}
		gui_option.args[v].args.borderDsk.args.bordersize = {
			name = L["Border Size"],
			desc = L["Set Border Size"],
			type = "slider",
			order	= 27,
			min		= 1,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.castBars[v].border_size = val
				UpdateCastBarsStyle()
			end,
			get =function(info)
				return self.db.profile.castBars[v].border_size
			end,
		}
		gui_option.args[v].args.borderDsk.args.bordercolor = {
			order = 28,name = L["Border Color"],type = "color", hasAlpha = true,
			set = function(info,r,g,b,a) self.db.profile.castBars[v].border_color={r,g,b,a}; UpdateCastBarsStyle()end,
			get = function(info) return self.db.profile.castBars[v].border_color[1],self.db.profile.castBars[v].border_color[2],self.db.profile.castBars[v].border_color[3],self.db.profile.castBars[v].border_color[4] end
		}
		gui_option.args[v].args.borderDsk.args.borderinset = {
			name = L["Border Inset"],
			desc = L["Set Border Inset"],
			type = "slider",
			order	= 29,
			min		= -32,
			max		= 32,
			step	= 1,
			set = function(info,val) 
				self.db.profile.castBars[v].border_inset = val
				UpdateCastBarsStyle()
			end,
			get =function(info)
				return self.db.profile.castBars[v].border_inset
			end,
		}
						
	end
	
	return gui_option
end