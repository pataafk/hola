local addon, C = ...
local L = AleaUI_GUI.GetLocale("SPTimers")

local _
local parent = C.Parent
local spelllist = {}
C.AurasSpellList = spelllist

local SortBars
local enableLoop = true
local customStatusBar = false
local enableGroupedSpells = true

-- NEW GLOBALS ----

local NO_FADE 			= C.NO_FADE
local DO_FADE 			= C.DO_FADE
local DO_FADE_RED 		= C.DO_FADE_RED 
local DO_FADE_NORMAL	= nil
local FADED 			= C.FADED
local DO_FADE_UNLIMIT 	= C.DO_FADE_UNLIMIT
local UNITAURA 			= C.UNITAURA
local CLEU				= C.CLEU
local PLAYER_AURA 		= C.PLAYER_AURA
local OTHERS_AURA 		= C.OTHERS_AURA
local CUSTOM_AURA 		= C.CUSTOM_AURA
local CHANNEL_SPELL 	= C.CHANNEL_SPELL
local TOTEM_SPELL 		= C.TOTEM_SPELL
local SPELL_CAST 		= C.SPELL_CAST
local SPELL_SUMMON 		= C.SPELL_SUMMON
local SPELL_ENERGIZE 	= C.SPELL_ENERGIZE
local COOLDOWN_SPELL 	= C.COOLDOWN_SPELL
local NO_GUID 			= C.NO_GUID

local SOUND_INDEX = 40
------------------
local anchors = {}
C.Anchors = anchors

--Cache global variables
--Lua functions

local _G = _G
local type, ipairs, pairs, unpack, select, assert, pcall, tonumber, tostring = type, ipairs, pairs, unpack, select, assert, pcall, tonumber, tostring
local tinsert, tremove, tsort = table.insert, table.remove, table.sort 
local floor, abs, ceil = math.floor, math.abs, math.ceil
local len, sub, find, format, gsub = string.len, string.sub, string.find, string.format, string.gsub
local gmatch = string.gmatch
local match = string.match
local random = math.random

local wipe = wipe
local setmetatable, getmetatable  = setmetatable, getmetatable

local UnitGUID = UnitGUID
local UnitClass = UnitClass
local GetTime = GetTime
local CreateFrame = CreateFrame
local Ambiguate = Ambiguate
local UnitAura = UnitAura
local IsEncounterInProgress = IsEncounterInProgress
local InCombatLockdown = InCombatLockdown
local UnitChannelInfo = UnitChannelInfo
local GetSpellInfo = GetSpellInfo

-- GLOBALS: STANDARD_TEXT_FONT, UNKNOWN

local function GetSpellTag(destGuid, spellID, sourceGuid, auraType, auraID)
	return ( destGuid or NO_GUID or 'nil')..'-'..( spellID or 'nil' )..'-'..( auraType or 'nil' ) ..'-'..( auraID or 'nil')
end

C.GetSpellTag = GetSpellTag

local function OnTimerEnd(tag, str)
	
	if spelllist[tag] then
		--[==[
		if spelllist[tag][21] then 
			C:RemoveDotFromDB(spelllist[tag][3], spelllist[tag][5], "REMOVE FROM OnTimerEND")
		end
		]==]
		if spelllist[tag][SOUND_INDEX] then
			spelllist[tag][SOUND_INDEX] = false
			C:PlaySound(spelllist[tag][5], "sound_onhide", spelllist[tag][14])
		end
	end
end


local function OnTimerStart(tag)
	if spelllist[tag] then
		spelllist[tag][SOUND_INDEX] = true
		
		C:PlaySound(spelllist[tag][5], "sound_onshow", spelllist[tag][14])
		
	--	print("START TIMER",spelllist[tag][8])
	end
end

local function RemoveTagFrolList(tag)
	if spelllist[tag] then
		local guid = spelllist[tag][3]
		
		spelllist[tag] = nil
		C.RemoveGUIDFromList(guid)
	end
end

-- debug print ------------------
local old_print = print
local print = function(...)
	if C.dodebugging then	
		old_print("SPT_BARS, ", ...)
	end
end

local old_assert = assert
local assert = function(...)
	if C.dodebugging then	
	--	old_assert(...)
	end
end

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

function C:CheckForMissingBarsData()
	for i=1, #self.db.profile.bars_anchors do		
		if not self.db.profile.bars_anchors[i] then
			tremove(self.db.profile.bars_anchors, i)
			self:CheckForMissingBarsData()
			break
		end
	end
end

function C:InitFrames()
	self.myGUID = UnitGUID("player")
	
	for i=1, #C.db.profile.bars_anchors do	
		self:InitBarAnchor(i)
	end
end

function C:ProfileSwapBars()

	local inittest = false
	if self.testbar_shown then
		inittest = true
		self:DisableTestBars()
	end
	
	wipe(spelllist)
	
--	print("InitFrames", #anchors, #C.db.profile.bars_anchors)
	if #anchors > 0 then
		for i=1, #anchors do
			anchors[i]:ResetAnchor()
		end
	end
	
	for i=1, #C.db.profile.bars_anchors do	
		self:InitBarAnchor(i)
	end
	
	if inittest then
		self:TestBars()
	end
end


function C:DeleteAnchor(index)

	if self.db.profile.bars_anchors[index] then
		tremove(self.db.profile.bars_anchors, index)
		
		for i=1, #anchors do		
			if i == index then
				anchors[i]:ResetAnchor()
			end
		end
	end
end

do
	local mark = 0
	local testbar = false
	
	local maxtestbarval = 0
	
	local testbar_onupdate = CreateFrame("Frame")
	testbar_onupdate:Hide()
	testbar_onupdate.elapsed = 0
	testbar_onupdate:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed
		
		if self.elapsed < maxtestbarval then return end
		self.elapsed = 0
		self:Hide()
		maxtestbarval = 0
		
		C:TestBars()
		
	--	print("AuraEnd Testbars")
	end)
	
	function C:DisableTestBars()	
		self.testbar_shown = nil
		self.onUpdateHandler.elapsed = 0
		self.onUpdateHandler:Show()
		mark = 0		
		testbar = false
		
		testbar_onupdate:Hide()
		testbar_onupdate.elapsed = 0
		maxtestbarval = 0
		
	end
	
	function C:TestBars(force)
		if testbar or force then
			self.testbar_shown = nil
			self.onUpdateHandler.elapsed = 0
			self.onUpdateHandler:Show()
			mark = 0
			for tag, data in pairs(spelllist) do
				if data[14] == "TEST_BAR" then
					RemoveTagFrolList(tag)
				end
			end
			
			testbar_onupdate:Hide()
			testbar_onupdate.elapsed = 0
			maxtestbarval = 0
			
			SortBars('TestBars')
		else
			self.testbar_shown = true
			self.onUpdateHandler.elapsed = 99999
			self.onUpdateHandler:Hide()			

			for k,v in pairs(anchors) do
				local a = 0
				local group = 0
				local group_guid = 1
				
				for f=1, 40 do
					local t = random(1, 100)
					local name = "Test Bar №"..a.." of "..( v.opts.name or k )
					a = a +1
					 
					group = group + 1
					
					if mark >= 8 then
						mark = 1
					else
						mark = mark + 1
					end
					
					if group >= 5 then 
						group = 0
						group_guid = group_guid + 1
					end

					if maxtestbarval < t then
						maxtestbarval = t
					end
					
					C.Timer(t, GetTime()+t, "group"..group_guid, "group"..group_guid, -1, 1, "TEST_BAR"..k, "TEST_BAR", mark, name, "Interface\\Icons\\spell_shadow_shadowwordpain", a, name, name)
					
					testbar_onupdate:Show()
				end
			end
		end
		testbar = not testbar
	end
end

do
	local default_anchor = {
		name = 1,
		bar_number = 20,
		left_icon = true,
		right_icon = false,
		add_up = true,
		point = { 0, 0},
		w = 250,
		h = 14,
		target_name = true,
		gap = 4,
		icon_gap = 5,
		fortam_s = 1,
		border = "Flat",
		bordersize = 1, -- Added defaults
		borderinset = 0, -- Added defaults
		bordercolor = {80/255,80/255,80/255,1},
		show_header = false,
		group_grow_up = true,
		
		tick_ontop = false,
		spark_ontop = false,

		pandemia_color = { 200/255, 210/255, 210/255, 0.2 },
		pandemia_bp_style = 1,
		show_pandemia_bp = false,

		group_bg_show = false,
		group_bg_target_color = { 0,0,0,0 },
		group_bg_focus_color = { 1,1,0,0 },
		group_bg_offtargets_color = { 0,0,0,0},

		group_font_target_color = { 1, 1, 1},
		group_font_focus_color = { 1, 1, 0},

		group_font_style = {
			font = STANDARD_TEXT_FONT,
			alpha = 1,
			size = 12,
			flags = "OUTLINE",
			justify = "CENTER",
			shadow =  { 0, 0, 0, 1},
			offset = { 1, -1 },
		},
		overlays = {
			auto = true,
			color = { 1, 1, 1, 0.4 },
		},
		bar = {
			color = {118/255, 0, 0, 1},
			texture = "Flat",
			bgcolor = {0, 0, 0, 0.5},
			bgtexture = "Flat",
		},
		stack = {
			textcolor = {1, 1, 1},
			font = STANDARD_TEXT_FONT,
			alpha = 1,
			size = 14,
			flags = "OUTLINE",
			justify = "RIGHT",
			shadow =  { 0, 0, 0, 1},
			offset = { 1, -1 },
		},
		timer ={
			textcolor = {1, 1, 1},
			font = STANDARD_TEXT_FONT,
			alpha = 1,
			size = 14,
			flags = "OUTLINE",
			justify = "RIGHT",
			shadow =  { 0, 0, 0, 1},
			offset = { 1, -1 },
		},

		header_custom_text = {
			["target"] 		= { 2, "%target" },
			["player"] 		= { 2, "%player" },
			["procs"] 		= { 2, "%player" },
			["cooldowns"] 	= { 2, "%player" },
			["offtargets"] 	= { 2, "%id : %target" },
		},

		raidicon_xOffset = 0,
		raidicon_y = 5,
		raidiconsize = 10,
		raidicon_alpha = 1,

		spell ={
			textcolor = {1, 1, 1},
			font = STANDARD_TEXT_FONT,
			alpha = 1,
			size = 14,
			flags = "OUTLINE",
			justify = "LEFT",
			offsetx = 0,
			shadow =  { 0, 0, 0, 1},
			offset = { 1, -1 },
		},
		castspark = {
			color = {1, 1, 1, 1},
			alpha = 1,
		},
		dotticks = {
			color = {1, 1, 1, 1},
			alpha = 1,
		},
		sorting = {
			{name = "target", 		gap = 10, alpha = 1,  sort = 1, disabled = false },
			{name = "player", 		gap = 10, alpha = 1,  sort = 2, disabled = false },
			{name = "procs",		gap = 15, alpha = .7, sort = 3, disabled = false },
			{name = "cooldowns",	gap = 15, alpha =  1, sort = 4, disabled = false },
			{name = "offtargets",	gap = 6,  alpha = .7, sort = 5, disabled = false },
		},
	}

	function C:CreateNewAnhors()
		local anhor_number = #C.db.profile.bars_anchors+1
		
		C.db.profile.totalanchor = C.db.profile.totalanchor+1
		
		C.db.profile.bars_anchors[anhor_number] = deepcopy(default_anchor)
		C.db.profile.bars_anchors[anhor_number].name = C.db.profile.totalanchor
		
		self:InitBarAnchor(anhor_number)
		self:SetAnchorTable(anhor_number)
	end

	
	local function addDefaultOptions(t1, t2)
		for i, v in pairs(t2) do
			if t1[i] == nil then
				t1[i] = v
			elseif type(v) == "table" and type(t1[i]) == "table" then
				addDefaultOptions(t1[i], v)
			end
		end
	end
	
	function C.CheckBarOpts(opt)
	
		if #opt.sorting ~= #default_anchor.sorting then
			opt.sorting = nil
		end
		
		addDefaultOptions(opt, default_anchor)

		if opt and opt.sorting then
			for k,v in ipairs(opt.sorting) do
				if not v.sort then
					if v.name == "offtargets" then 
						v.sort = 5 
					else
						v.sort = k
					end
				end
			end
		end
	end
end

local function ResetAnchor(self)
	self.disabled = true
	self:Hide()
	self.mover:Hide()
	
	for i=1, #self.bars do		
		self.bars[i].disabled = true
		self.bars[i]:ClearAllPoints()
		self.bars[i].tag = nil
		self.bars[i]:Hide()
	end
end

function C:CopySettings(from, to)
	local a1 = C.db.profile.bars_anchors[to].point
	local a2 = C.db.profile.bars_anchors[to].name
	
	C.db.profile.bars_anchors[to] = deepcopy(C.db.profile.bars_anchors[from])
	C.db.profile.bars_anchors[to].point = deepcopy(a1)
	C.db.profile.bars_anchors[to].name = a2
	
--	print(to, C.db.profile.bars_anchors[to], #C.db.profile.bars_anchors)
	self:InitBarAnchor(to)	
	
	self:Visibility()
end

function C:UpdateStatusBars()
	wipe(spelllist)
	SortBars('UpdateStatusBars')
end

function C:Visibility()
	self:InterateBars("UpdateStyle")
end
function C:Update_StackText()
	self:InterateBars("UpdateStackText")
end
function C:Update_TimeText()
	self:InterateBars("UpdateTimeText")
end
function C:Update_SpellText()
	self:InterateBars("UpdateSpellText")
end
function C:UpdateAllBorder()
	self:InterateBars("UpdateBorder")	
end

function C:UpdateRaidIcons()
	self:InterateBars("UpdateRaidIcon")	
end

function C:UpdateBarsSize()
	self:InterateBars("UpdateBarSize")		
	SortBars('UpdateBarsSize')
end

function C:UpdateBackgroundBarColor()
	self:InterateBars("UpdateBarColor")	
end

function C:UpdateAllSparks()
	self:InterateBars("UpdateSpark_Color")	
end

function C:UpdateAllTiks()
	self:InterateBars("UpdateTick_Color")
end

function C:UpdateMovers()
	if C.db.profile.locked then
		for i=1, #anchors do
			if not anchors[i].disabled then		
				anchors[i]:Lock()
			end
		end
	else 
		for i=1, #anchors do
			if not anchors[i].disabled then		
				anchors[i]:Unlock()
			end
		end
	end
end

function C:InterateBars(...)
	for i=1, #anchors do
		if not anchors[i].disabled then
			for b=1, #anchors[i].bars do		
				for a=1, select("#", ...) do
					local func = select(a, ...)
					anchors[i].bars[b][func](anchors[i].bars[b], anchors[i], i)
				end
			end
		end
	end
end

local function round(num)
	return floor(num+0.5)
end

function C:GetRelativePoint(frame)
	local x, y = frame:GetCenter()
	local ux, uy = C.Parent:GetCenter()
	local screenWidth, screenHeight = C.Parent:GetRight(), C.Parent:GetTop()
	
	
	local LEFT = screenWidth / 4
	local TOP = screenHeight / 4
	
	local xpos, ypos = 0, 0
	local point1, point2 =  "CENTER", ""
	local point3, point4 =  "CENTER", ""

	--[[
					|
					|
					|
					|
					|
					|
	  ----------------------------- OX
					|
					|
					|
					|
					|
					OY
	
	]]
--	print("T1", LEFT, TOP)
	
	local rX, rY = round(x-ux), round(y-uy)
	
--	print("T2", "rX", rX, "rY", rY)

	if rX < -LEFT then
		point1, point3 = "LEFT", "LEFT"			
	elseif rX > LEFT then
		point1, point3 = "RIGHT", "RIGHT"			
	end
	
	if rY < -TOP then
		point2, point4 = "BOTTOM", "BOTTOM"
		
		if point1 == "CENTER" then point1 = '' end
		if point3 == "CENTER" then point3 = '' end
		
	elseif rY > TOP then
		point2, point4 = "TOP", "TOP"
		
		if point1 == "CENTER" then point1 = '' end
		if point3 == "CENTER" then point3 = '' end
		
	end
	
	if point1 == "CENTER" then
		xpos, ypos = rX, rY
	else
		
		if point1 == "LEFT" then
			xpos = frame:GetLeft() - C.Parent:GetLeft()
		elseif point1 == "RIGHT" then
			xpos = frame:GetRight() - C.Parent:GetRight()
		else
			xpos = rX
		end
		
		if point2 == "TOP" then
			ypos = frame:GetTop() - C.Parent:GetTop()
		elseif point2 == "BOTTOM" then
			ypos = frame:GetBottom() - C.Parent:GetBottom()
		else
			ypos = rY
		end
	end
	
	old_print(point2..point1, C.Parent, point4..point3, xpos, ypos)
end
	
function C:InitBarAnchor(i)
	
	self.CheckBarOpts(C.db.profile.bars_anchors[i])
	
	local opts = C.db.profile.bars_anchors[i]

	if not anchors[i] then
		local f = CreateFrame("Frame", nil , parent)
		
		f.bg_1 = f:CreateTexture()
		f.bg_1:SetAllPoints()
		f.bg_1:SetColorTexture(1,0,0,0)

		f.id = i
		f.index = 0
		f.bars = {}
		f.group = { target = {}, player = {}, procs = {}, cooldowns = {}}
		f.group_guid = {}
		f.guidsort = {}
		
		f.GetOpts = function(self)
			return C.db.profile.bars_anchors[self.id]
		end
		
		f.ResetAnchor = ResetAnchor
		
		f.Unlock = function(self)
			self.mover:Show()
			self.mover:EnableMouse(true)
		end		
		f.Lock = function(self)
			self.mover:Hide()
			self.mover:EnableMouse(false)
		end
		
		f.mover = CreateFrame("Frame", nil, f)
		f.mover.text = f.mover:CreateFontString(nil, "OVERLAY", "GameFontNormal");
		f.mover.text:SetPoint("CENTER", f.mover, "CENTER",0,0)
		f.mover.text:SetTextColor(1,1,1,1)
		f.mover.text:SetFont(STANDARD_TEXT_FONT,12, "OUTLINE")
		f.mover.text:SetJustifyH("CENTER")
		f.mover.text:SetText(L["Unlocked. Move group"].." "..i)
		
		
		f.mover.parent = f		
		f.mover:SetMovable(true)
		f.mover:RegisterForDrag("LeftButton")
		f.mover:SetScript("OnDragStart", function(self) 
			self:StartMoving() 
		end)
		f.mover:SetScript("OnDragStop", function(self) 
			self:StopMovingOrSizing()
			local x, y = self:GetCenter()
			local ux, uy = parent:GetCenter()

			self.parent.opts.point = { floor(x - ux + 0.5),floor(y - uy + 0.5) }

			for k,v in pairs(self.mover_add_button.editboxes) do
				v:UpdateText()
			end
			
			self:ClearAllPoints()
			self:SetPoint("CENTER", parent, "CENTER", self.parent.opts.point[1] or 0,self.parent.opts.point[2] or 0)	
			
		--	print('T', C:GetRelativePoint(self.parent))
		end)

		f.mover:SetClampedToScreen(true)		
		
		f.mover.bg_1 = f.mover:CreateTexture()
		f.mover.bg_1:SetAllPoints()
		f.mover.bg_1:SetColorTexture(0,0,0,1)
		
		f.mover:SetAlpha(.6)
		f.mover:Hide()

		anchors[i] = f
	end

	anchors[i].disabled = false
	anchors[i].id = i
	anchors[i].opts = C.db.profile.bars_anchors[i]
	anchors[i].sorting = C.db.profile.bars_anchors[i].sorting

	anchors[i].index = 0
	
	anchors[i].mover:ClearAllPoints()
	anchors[i].mover:SetPoint("CENTER", parent, "CENTER",opts.point[1] or 0,opts.point[2] or 0)				
	anchors[i].mover:SetSize( opts.w or 100 , opts.h or 20)
	
	anchors[i]:Show()
	
	local _left, _right = 0, 0
	
	if opts.left_icon then
		_left = _left + opts.h + opts.icon_gap
	end
	
	if opts.right_icon then
		_right = _right + opts.h + opts.icon_gap
	end
	
	anchors[i]:ClearAllPoints()
	anchors[i]:SetPoint("CENTER", anchors[i].mover,"CENTER", (_left/2) - (_right/2) , 0)
	anchors[i]:SetSize(1,opts.h+5)
	
	C.AddMoverButtons(anchors[i].mover, opts)

	for s=1, opts.bar_number do
		
		local bar = anchors[i].bars[s] or C.GetBar(anchors[i])
		
		
		bar:UpdateStyle()
		
		anchors[i].bars[s] = bar
		anchors[i].bars[s].disabled = false
		anchors[i].bars[s]:ClearAllPoints()
		anchors[i].bars[s]:SetParent(anchors[i])
		anchors[i].bars[s]:Hide()
	end

	for s=opts.bar_number+1, #anchors[i].bars do
		anchors[i].bars[s].disabled = true
		anchors[i].bars[s]:ClearAllPoints()
		anchors[i].bars[s]:Hide()
	end
	
	C:UpdateMovers()
end


do
    local day, hour, minute = 86400, 3600, 60
	
    local format = string.format
    local ceil = math.ceil
	local floor = math.floor
	local fmod = math.fmod
	
	local formats = {
		function(s)  -- 1h, 2m, 119s, 29.9
			if s >= hour then
				return "%dh", ceil(s / hour)
			elseif s >= minute*2 then
				return "%dm", ceil(s / minute)
			elseif s >= 30 then
				return "%ds", floor(s)
			end
			return "%.1f", s
		end,
		function(s, dur) -- 1h, 2m, 119s / 300 , 29.99 / 300
			if s >= hour then
				return "%dh", ceil(s / hour)
			elseif s >= minute*2 then
				return "%dm", ceil(s / minute), dur
			elseif s >= 30 then
				return "%ds / %.0f", floor(s), dur
			end
			return "%.2f / %.0f", s, dur
		end,
		function(s) -- 1:11m, 59s, 10s, 1s
			if s <= 60 then
				return ("%.0fs"):format(s)
			else
				return ("%d:%0.2dm"):format(s/60, fmod(s, 60))
			end
		end,
		function(s) -- 1:11m, 59.1s, 10.2s, 1.1s
			if s <= 60 then
				return ("%.1fs"):format(s)
			else
				return ("%d:%0.2dm"):format(s/60, fmod(s, 60))
			end
		end,
		
		function(s)  -- 1, 2, 119, 29.9
			if s >= hour then
				return "%d", ceil(s / hour)
			elseif s >= minute*2 then
				return "%d", ceil(s / minute)
			elseif s >= 30 then
				return "%d", floor(s)
			end
			return "%.1f", s
		end,
		function(s, dur) -- 1, 2, 119 / 300 , 29.99 / 300
			if s >= hour then
				return "%d", ceil(s / hour)
			elseif s >= minute*2 then
				return "%d", ceil(s / minute), dur
			elseif s >= 30 then
				return "%d / %.2f", floor(s), dur
			end
			return "%.2f / %.2f", s, dur
		end,
		function(s) -- 1:11, 59, 10, 1
			if s <= 60 then
				return ("%.0f"):format(s)
			else
				return ("%d:%0.2d"):format(s/60, fmod(s, 60))
			end
		end,
		function(s) -- 1:11, 59.1, 10.2, 1.1
			if s <= 60 then
				return ("%.1f"):format(s)
			else
				return ("%d:%0.2d"):format(s/60, fmod(s, 60))
			end
		end,
	}
	
    function C.FormatTime(t, s, dur)
		return formats[t]( ( s <= 0 and 0.00 or s), dur)
    end
end

do
	local numbers_pattern = '(%d+%,?%.?%d*)' -- "[%d]+%,?%.?[%d]*"
	local tooltipname = 'SPTimersGameToolTip2'
	local tooltipnamelefttext = tooltipname.."TextLeft2"
	
	local hidegametooltip = CreateFrame("Frame")
	hidegametooltip:Hide()
	
	local gametooltip = CreateFrame("GameTooltip", tooltipname, nil, "GameTooltipTemplate");
	gametooltip:SetOwner( hidegametooltip,"ANCHOR_NONE");
	gametooltip:SetScript('OnTooltipAddMoney', function()end)
	gametooltip:SetScript('OnTooltipCleared', function()end)
	gametooltip:SetScript('OnHide', function()end)
	gametooltip:SetScript('OnTooltipSetDefaultAnchor',function()end)
	
	local GetValues, GetAuraVal
	local preCahceCheckCustomText = {}
	
	local RAID_CLASS_COLORS = CUSTOM_RAID_COLORS or RAID_CLASS_COLORS
	
	local unknownClass = "FFA6A6A6"
	
	local cachedNameColors = {}
	local numCachedNameColors = 0
	
	local function GetGUIDClassColor(guid, name, isShort, isPlayer)
		if not cachedNameColors[name] then
			local class = C:GetGUIDClass(guid)
			
			local color = unknownClass
			if class then
				color = RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr or unknownClass
			end	
			
			local short = ( isShort and name ) or ( isPlayer and Ambiguate(name, "short") ) or name
			
			numCachedNameColors = numCachedNameColors+ 1
			
			if numCachedNameColors > 100 then
				numCachedNameColors = 0
				wipe(cachedNameColors)
			end
			
			cachedNameColors[name] = '|c'..color..short..'|r'
		end
		
		return cachedNameColors[name]
	end
	
	function C:ResetColoredNameCache()	
		numCachedNameColors = 0
		wipe(cachedNameColors)
	end
	
	local supportedTags = {
		['%stacks'] = function(text, data) 
			return gsub(text,"%%stacks", data[19])
		end,
		['%val1'] = function(text, data, opt, self)		
			return gsub(text,"%%val1", GetValues(self, 1))
		end,
		['%val2'] = function(text, data, opt, self)		
			return gsub(text,"%%val2", GetValues(self, 2))
		end,
		['%val3'] = function(text, data, opt, self)		
			return gsub(text,"%%val3", GetValues(self, 3))
		end,
		['%newval1'] = function(text, data, opt, self)
			return gsub(text, "%%newval1", GetAuraVal(self, 1))
		end,
		['%newval2'] = function(text, data, opt, self)
			return gsub(text, "%%newval2", GetAuraVal(self, 2))
		end,
		['%newval3'] = function(text, data, opt, self)
			return gsub(text, "%%newval3", GetAuraVal(self, 3))
		end,
		['%tickcount'] = function(text, data)
			if data[22] then
				return gsub(text,"%%tickcount", data[22])
			end
			return text
		end,
		['%sN'] = function(text, data, opt)
			if opt.short then		
			
				-- [3] destGGUID
				-- [4] sourceGUID
				
				return gsub(text,"%%sN", data[29] and GetGUIDClassColor(data[4], C:getShort(data[29]), true) or UNKNOWN)
			else
				return gsub(text,"%%sN", data[29] and GetGUIDClassColor(data[4], data[29], nil, data[43]) or UNKNOWN)
			end		
		end,
		['%spell'] = function(text, data, opt)
			if opt.short then		
				return gsub(text,"%%spell", C:getShort(data[8]))
			else
				return gsub(text,"%%spell", data[8])
			end		
		end,
		['%tN'] = function(text, data, opt)
			if opt.short then		
			
				-- [3] destGGUID
				-- [4] sourceGUID
				
				return gsub(text,"%%tN", data[28] and GetGUIDClassColor(data[3], C:getShort(data[28]), true) or UNKNOWN)
			else
				return gsub(text,"%%tN", data[28] and GetGUIDClassColor(data[3], data[28], nil, data[43]) or UNKNOWN)
			end	
		end,
		['%immolate'] = function(text, data, opt)
			return gsub(text, '%%immolate', C:GetImmolateBuffsStacks(data[3]))
		end,
	}
	
	function C:AddCustomTextHandler(tag, func)
		supportedTags[tag] = func
	end
	
	function C:PreCacheCustomTextCheck()
		for k in pairs(self.db.profile.procSpells) do
			local spellID = C.IsGroupUpSpell(k) or k
			local v = self.db.profile.procSpells[spellID]
			
			if v and v.custom_text_on and v.custom_text and v.custom_text ~= '' then
				--[==[
				for val in gmatch(v.custom_text, "[^ :\"-]+") do
					if supportedTags[val] then
						preCahceCheckCustomText[k] = preCahceCheckCustomText[k] or {}						
						preCahceCheckCustomText[k][#preCahceCheckCustomText[k]+1] = val
					end
				end
				]==]
				for tag in pairs(supportedTags) do
					if find(v.custom_text, '%'..tag)  then	
						preCahceCheckCustomText[k] = preCahceCheckCustomText[k] or {}						
						preCahceCheckCustomText[k][#preCahceCheckCustomText[k]+1] = tag
					end
				end
			end
		end
		for k in pairs(self.db.profile.othersSpells) do
			local spellID = C.IsGroupUpSpell(k) or k
			local v = self.db.profile.othersSpells[spellID]
			
			if v and v.custom_text_on and v.custom_text and v.custom_text ~= '' then
				--[==[
				for val in gmatch(v.custom_text, "[^ :\"-]+") do		
					if supportedTags[val] then
						preCahceCheckCustomText[k] = preCahceCheckCustomText[k] or {}						
						preCahceCheckCustomText[k][#preCahceCheckCustomText[k]+1] = val
					end
				end
				]==]
				for tag in pairs(supportedTags) do
					if find(v.custom_text, '%'..tag)  then	
						preCahceCheckCustomText[k] = preCahceCheckCustomText[k] or {}						
						preCahceCheckCustomText[k][#preCahceCheckCustomText[k]+1] = tag
					end
				end
			end
		end
		for k in pairs(self.db.profile.classSpells[self.myCLASS]) do
			local spellID = C.IsGroupUpSpell(k) or k
			local v = self.db.profile.classSpells[self.myCLASS][spellID]
			
			if v and v.custom_text_on and v.custom_text and v.custom_text ~= '' then
				
				--[==[
				local temp = v.custom_text:gsub('%[', ''):gsub('%]', '')
		
				print('T', v.custom_text, temp)
				
				for val in gmatch(temp, "[^ :\"-]+") do		
				
					print('T', val)
					
					if supportedTags[val] then
						preCahceCheckCustomText[k] = preCahceCheckCustomText[k] or {}						
						preCahceCheckCustomText[k][#preCahceCheckCustomText[k]+1] = val
					end
				end
				]==]
				
				for tag in pairs(supportedTags) do
					if find(v.custom_text, '%'..tag)  then	
						preCahceCheckCustomText[k] = preCahceCheckCustomText[k] or {}						
						preCahceCheckCustomText[k][#preCahceCheckCustomText[k]+1] = tag
					end
				end
			end
		end	
	end

	local auratypes = {
		['DEBUFF']	= 'HARMFUL',
		['BUFF']	= 'HELPFUL',
		['HARMFUL'] = 'HARMFUL',
		['HELPFUL'] = 'HELPFUL',
	}
	
	local patterns = {
		"(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
		"%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+%d+%,?%.?%d*%D+(%d+%,?%.?%d*)",
	}
	
	
	function GetValues(timer, i)
		local data = timer.data --timer.tag and spelllist[timer.tag] or nil
		if not data then return '0' end
		
		data[30] = data[30] or {}
		
		local value = data[30][i]
		
		gametooltip:ClearLines()
		
		local unit = C:FindUnitByGUID(data[3])

		if unit and not value then
			
			
			gametooltip:SetUnitAura(unit, data[8], nil, auratypes[data[11]] or "HARMFUL") 

			local line = _G[tooltipnamelefttext]:GetText()
			
			if line then 				
				value = match(line, patterns[i])			
				data[30][i] = value
			end
		end
		
		return value or "0"
	end
	
	function GetAuraVal(timer, i)
		local data = timer.data --timer.tag and spelllist[timer.tag] or nil
		if not data then 
			return ""
		end

		local unit = C:FindUnitByGUID(data[3])
		local value1, value2, value3, _, spellID, sUnit, name
		local val1, val2, val3
		
		-- [1] duration
		-- [2] endTime
		-- [3] destGGUID
		-- [4] sourceGUID
		-- [5] spellID
		-- [6] sourceUnit
		-- [7] aura counter
		-- [8] localized spellname
		-- [9] icon texture path
		
		if data[3] == C.myGUID then unit = 'player' end
		
		if unit then
			
			name, _, _, _, _, _, sUnit, _, _, spellID, _, _, value1, value2, value3 = AuraUtil.FindAuraByName(data[8], unit, ( auratypes[data[11]] or "HARMFUL" ) .. ( data[4] == C.myGUID and "|PLAYER" or "" ))
			-- 13 + 1  13 + 2 13 + 3
			
			if name and spellID == data[5] and UnitGUID(sUnit or '') == data[4] then
				val1, val2, val3 = value1, value2, value3
			end
		end
	
		if i == 1 then
			return val1 and tostring(val1) or ""
		elseif i == 2 then
			return val2 and tostring(val2) or ""
		elseif i == 3 then
			return val3 and tostring(val3) or ""
		end
		
		return ""
	end
	
	function C.CustomTextCreate(self)
		local data = self.data

		local text = data[23]
		local opt = self.opts
		
		local spellID = C.IsGroupUpSpell(data[5]) or data[5]
	--	print('T', text, data[5], preCahceCheckCustomText[data[5]])
		
		if text and preCahceCheckCustomText[spellID] then		
			for i=1, #preCahceCheckCustomText[spellID] do
				local val = preCahceCheckCustomText[spellID][i]		
				text = supportedTags[val](text, data, opt, self)
			end			
		end
		
		return text
	end
end

do
	C.targetEngaged = {}
	C.onUpdateHandler  = CreateFrame("Frame")
	
	local onUpdateHandler = C.onUpdateHandler	
	onUpdateHandler.elapsed = 0
	onUpdateHandler.active = false

	local function onUpdateCombat(self, elapsed)
	
		self.elapsed = self.elapsed + elapsed
		if self.elapsed < C.db.profile.throttleOutCombat then return end		
		self.elapsed = 0

		if not IsEncounterInProgress() and not InCombatLockdown() then
			self.active = false
			wipe(C.targetEngaged)
			wipe(C.pandemia_cache)
			C:OnCombatEndReset()
			self:SetScript("OnUpdate", nil)
		else
			local current = GetTime()
			
			for guid, last in pairs(C.targetEngaged) do		

			--	print('Target check', guid, last <= current)
				if last <= current then

					C.targetEngaged[guid] = nil

					C.Timer_Remove_DEAD(guid, true)
					C:RemovePandemia(nil, guid)	
			--		print("Clear DestGUID by noActive", guid)
				end	
			end
			
			C:OnCustomUpdateAuras()
		end	
	end
	
	--onUpdateHandler:SetScript("OnUpdate", onUpdateCombat)

	local events = CreateFrame('Frame')
	events:RegisterEvent('ZONE_CHANGED_NEW_AREA')
	events:RegisterEvent('PLAYER_REGEN_ENABLED')
	events:RegisterEvent('PLAYER_REGEN_DISABLED')
	
	events:SetScript('OnEvent', function(self,event,...)
		if event == 'ZONE_CHANGED_NEW_AREA' then
		
		--	print(event, 'Remove all auras and update player and pet auras')
			for tag, data in pairs(spelllist) do				
				RemoveTagFrolList(tag)
			end
			C:OnCustomUpdateAuras()
		elseif event == 'PLAYER_REGEN_ENABLED' then
			onUpdateHandler.elapsed = 0
			
		elseif event == 'PLAYER_REGEN_DISABLED' then
			if C.db.profile.bar_module_enabled then
				onUpdateHandler:SetScript("OnUpdate", onUpdateCombat)
				if C.testbar_shown then 
					C:TestBars(true) 
				end
			end
			onUpdateHandler.active = true	
		end
	--	print(event, ...)
	end)
end

function C:OnCustomUpdateAuras()
	C:UNIT_AURA('UNIT_AURA', 'player')
	C:UNIT_AURA('UNIT_AURA', 'pet')
	
	C:UNIT_AURA('UNIT_AURA', 'focus')
	
	C:UNIT_AURA('UNIT_AURA', 'boss1')
	C:UNIT_AURA('UNIT_AURA', 'boss2')
	C:UNIT_AURA('UNIT_AURA', 'boss3')
	C:UNIT_AURA('UNIT_AURA', 'boss4')
	C:UNIT_AURA('UNIT_AURA', 'boss5')
	
	C:UNIT_AURA('UNIT_AURA', 'arena1')
	C:UNIT_AURA('UNIT_AURA', 'arena2')
	C:UNIT_AURA('UNIT_AURA', 'arena3')
	C:UNIT_AURA('UNIT_AURA', 'arena4')
	C:UNIT_AURA('UNIT_AURA', 'arena5')
end

function C:OnCombatEndReset()
	
	for tag, data in pairs(spelllist) do	
		if data[11] == "DEBUFF" then
		--	spelllist[tag] = nil			
			print('OnCombatEndReset', tag)
			C.Timer_Remove_By_Tag(tag)
		end	
	end
	
	C:OnCustomUpdateAuras()
	
	SortBars('OnCombatEndReset')
end

do
	-- UTF-8 Reference:
	-- 0xxxxxxx - 1 byte UTF-8 codepoint (ASCII character)
	-- 110yyyxx - First byte of a 2 byte UTF-8 codepoint
	-- 1110yyyy - First byte of a 3 byte UTF-8 codepoint
	-- 11110zzz - First byte of a 4 byte UTF-8 codepoint
	-- 10xxxxxx - Inner byte of a multi-byte UTF-8 codepoint
	
	local char
	local string_byte = string.byte
	local sub = sub
	
	local function chsize(char)
		if not char then
			return 0
		elseif char > 240 then
			return 4
		elseif char > 225 then
			return 3
		elseif char > 192 then
			return 2
		else
			return 1
		end
	end
	 
	-- This function can return a substring of a UTF-8 string, properly handling
	-- UTF-8 codepoints.  Rather than taking a start index and optionally an end
	-- index, it takes the string, the starting character, and the number of
	-- characters to select from the string.
	 
	local function utf8sub(str, startChar, numChars)
	  local startIndex = 1
	  while startChar > 1 do
		  local char = string_byte(str, startIndex)
		  startIndex = startIndex + chsize(char)
		  startChar = startChar - 1
	  end
	 
	  local currentIndex = startIndex
	 
	  while numChars > 0 and currentIndex <= #str do
		local char = string_byte(str, currentIndex)
		currentIndex = currentIndex + chsize(char)
		numChars = numChars -1
	  end
	  return str:sub(startIndex, currentIndex - 1)
	end


	local shortCache = {}
	function C:getShort(text)
		
		if not shortCache[text] then
			local msg = ""
			local tbl = {}
			
			local tbl = {}
			for v in gmatch(text, "[^ :\"-]+") do
			  tinsert(tbl, v)
			end
			
			
			if #tbl > 1 then	
				for k,v in ipairs(tbl) do
					msg = msg..utf8sub(v, 1, 1)
				end
			else
				for k,v in ipairs(tbl) do
					msg = msg..v
				end
			end
			
			shortCache[text] = msg
			
			return shortCache[text]
		else
			return shortCache[text]
		end
	end	
end

local _colored = function(val)
   
   local white = val*0.81
   local black = (1-val)*0.23
   
   return white+black
end

local function UpdateBarColor(self)
	local data = self.tag and spelllist[self.tag] or nil

	local opt = self.opts
	
	local cColor = data and C:GetColor(data[5], data[14]) or opt.bar.color
	
	local r,g,b,a = cColor[1], cColor[2], cColor[3], cColor[4] or 1
	
	self.bar:SetStatusBarColor(r, g, b, a)
	
	if opt.overlays.auto then	
		self.bar.overlay2:SetColorTexture(_colored(r),_colored(g),_colored(b),a)
	else
		self.bar.overlay2:SetColorTexture(opt.overlays.color[1],opt.overlays.color[2],opt.overlays.color[3],opt.overlays.color[4])
	end
	
	self.fade_in_out_bg:SetColorTexture(r,g,b,0.7)
		
	if ( C.db.profile.back_bar_color ) then
		self.bar.bg2:SetVertexColor(r*0.8,g*0.8,b*0.8,opt.bar.bgcolor[4])
	else
		self.bar.bg2:SetVertexColor(opt.bar.bgcolor[1], opt.bar.bgcolor[2], opt.bar.bgcolor[3], opt.bar.bgcolor[4])
	end
	
	
	self.bar.pandemi:SetColorTexture(opt.pandemia_color[1], opt.pandemia_color[2],opt.pandemia_color[3],opt.pandemia_color[4])	
end

function C.BarTextUpdate(self)
	local data = self.tag and spelllist[self.tag] or nil
	if not data then return end
	local opt = self.opts
	
--	print(data[23])
	if data[23] then
		self.spellText:SetText(C.CustomTextCreate(self))
	elseif opt.target_name and data[11] ~= "BUFF" then
		if opt.short then	
			if opt.debug_info then
				self.spellText:SetText(C:getShort(data[28]).." "..tostring(data[5] or "").." "..tostring(data[13] or "").." ".. data[14])
			else
				self.spellText:SetText(C:getShort(data[28]))
			end
		else
			if opt.debug_info then
				self.spellText:SetText(data[28].." "..tostring(data[5] or "").." "..tostring(data[13] or "").." ".. data[14])
			else
				self.spellText:SetText(data[28])
			end
		end
	else
		if opt.short then
			if opt.debug_info then
				self.spellText:SetText(C:getShort(data[8]).." "..tostring(data[5] or "").." "..tostring(data[13] or "").." ".. data[14])
			else
				self.spellText:SetText(C:getShort(data[8]))
			end
		else
			if opt.debug_info then
				self.spellText:SetText(data[8].." "..tostring(data[5] or "").." "..tostring(data[13] or "").." ".. data[14])
			else
				self.spellText:SetText(data[8])
			end
		end
	end
end

local GUID_TimeInit = {}
local GUID_Valid = {}
local GUID_Stored = {}
local numRand = 0

local function AddGUIDToList(guid)
	if not GUID_TimeInit[guid] then

		local num = #GUID_Stored+1
	
		GUID_TimeInit[guid] = num
		GUID_Stored[num] = guid
	end
end

function C.RemoveGUIDFromList(guid)	
	if GUID_TimeInit[guid] then
		local delete = true
		for tag, data in pairs(spelllist) do
		--	data[3]-- [3] destGGUID
			
			if data[3] == guid then
				delete = false
				break
			end
		end
		
		if delete then
			tremove(GUID_Stored, GUID_TimeInit[guid])
			GUID_TimeInit[guid] = nil
			
			for i=1, #GUID_Stored do
				GUID_TimeInit[GUID_Stored[i]] = i
			end
		end
	end
end
	
function C.Timer(duration, endTime, destGuid, sourceGuid, spellID, auraID, auraType, func, raidIndex, spellName, icon, count, destName, sourceName, specialID, isPlayer, eventType)
	if not C.db.profile.bar_module_enabled or not duration then return end
	if endTime and ( endTime ~= 0 and duration ~= 0 ) and (endTime < GetTime()) then 
	--	print("T2", endTime-GetTime(), duration, spellName)	
		return
	end
	
	if C:GetTargetType(spellID) == 1 and destGuid ~= C.CurrentTarget then
		return false 
	end

	if destGuid == C.COOLDOWN_SPELL then
		return true
	elseif not C:UnitFilter_GUID(destGuid) then
		return false 
	end

	local tag = GetSpellTag(destGuid,spellID,sourceGuid,auraType,auraID)	
	local sorting,start,init  = false,false,false
	local tick_every, amount_def, anount_ext
	--local sorting_reason = ''

	if ( func ~= PLAYER_AURA and func ~= OTHERS_AURA ) and not endTime then
		endTime = GetTime()+duration
	end
	
	if not spelllist[tag] then
		init = true	
		spelllist[tag] = {
				nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 10
				nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 20
				nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 30
				nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, -- 40
				nil, nil, nil									  -- 43
			}		
			
		spelllist[tag][25] = {} -- maxValue addapt to per anchor
		spelllist[tag][26] = {} -- maxValue current per anchor

		start = true
		sorting = true
	--	sorting_reason = sorting_reason .. '[not tag]'
	end
	
	local data = spelllist[tag]

	local spellID = specialID or spellID

	if spellID and type(spellID)=='number' and spellID > 0 then
		spellName, _, icon = GetSpellInfo(spellID)
	end

	
	if ( data[1] ~= duration or data[2] ~= endTime ) then		
		if ( endTime - ( data[2] or 0 ) ) > 0.5 then
			start = true
		end
		sorting = true
	--	sorting_reason = sorting_reason .. '[duration or endTime not same '..spellName..']'
	elseif ( duration == 0 and endTime == 0  ) and eventType == 'UnitAura' and ( GetTime() - ( data[35] or 0 ) ) > 0.5 then
		if data[13] == FADED then
			start = true
		end
		
		sorting = true
	--	sorting_reason = sorting_reason .. '[duration and endTime are zeros and eventType is UnitAura]'
	end
	
	--[==[
	if spellID == 111400 then
		old_print('T0', start, sorting, init, duration, endTime, eventType,( GetTime() - ( data[35] or 0 ) ) )
	end
	]==]
	
	-- [1] duration
	-- [2] endTime
	-- [3] destGGUID
	-- [4] sourceGUID
	-- [5] spellID
	-- [6] sourceUnit
	-- [7] aura counter
	-- [8] localized spellname
	-- [9] icon texture path
	-- [10] destUnit
	-- [11] auraType BUFF DEBUFF or oher custom tag
	-- [12] spelllist tag
	-- [13] Fading status
	-- [14] source of call timer
	-- [15] time when fading start
	-- [16] time when fading end
	-- [17] raid mark
	-- [18] spell priority for sorting
	-- [19] stack count
	-- [20] 
	-- [21] show ticks
	-- [22] ticks left
	-- [23] custom text  string or false
	-- [24] shine tick time out  
	-- [25] haste  
	-- [26] pandemia
	-- [27] ticks_evert_s	
	-- [28] destName
	-- [29] sourceName
	-- [30] value_cache
	-- [31] isChanneling
	-- [32] amount_def
	-- [33] _lastupdate
	-- [34] bar
	-- [35] UA throttle
	-- [36] fading color
	-- [37] current timer
	-- [38] default duration
	-- [39] extended duration
	-- [40] sound index
	-- [41] shine show
	-- [42] first apply
	-- [43] isPlayer
	
	if sorting and start then
		if C:IsSingleDest(spellID) then
			for tagst, datast in pairs(spelllist) do
				if datast[4] == sourceGuid and datast[5] == spellID and datast[3] ~= destGuid then
					spelllist[tagst] = nil
				end
			end
		end
	end
	
	
--	old_print('Update from', data[14], 'to', func, '.Last update', GetTime()-( data[35] or GetTime() ), 'by', eventType)
--	old_print('Timers', data[1],'->',duration, data[2], '->', endTime,'sorting:',sorting,'start:',start)
	
	data[1] = duration													
	data[2] = endTime																	
	data[3] = destGuid																	
	data[4] = sourceGuid																
	data[5] = spellID																	
--	data[6] = sourceUnit																
	data[7] = auraID																	
	data[8] = spellName																	
	data[9] = C:GetCustomTextureBars(spellID) or icon																		
--	data[10] = destUnit																	
	data[11] = auraType																	
	data[12] = tag			
	data[13] = NO_FADE																	
	data[14] = func																		
--	data[15] = endTime + C.db.profile.delayfading_wait										
--	data[16] = data[15] + C.db.profile.delayfading_outanim									
	data[17] = raidIndex																
	data[18] = C:GetPriority(data[5])		
	
	if count and count < 200 then
		data[19] = count																
	end
	
	data[43] = isPlayer
	
	AddGUIDToList(destGuid)
									
	
	--[==[
	if data[21] then
		C:RegisterDotApply(destGuid, data[5])
	end
	]==]
	--[==[
	if data[21] and sorting then		
		tick_every, amount_def, anount_ext = C:GetDotInfo(data[5], destGuid)
	end
	]==]
	
	data[23] = C:GetCustomText(data[5])											
	
--	data[24], data[25], data[26] = C:GetCLEUSpellInfo(data[5])


--	data[27] = C:GetDotTickEvery(data[3], data[5]) or tick_every	
		
	data[28] = destName																	
	data[29] = sourceName																
	
	if sorting then
		data[30] = nil
	end
	
	data[31] = C:IsChanneling(data[5])											
	
--	if data[21] and sorting then data[32] = amount_def end

	if sorting then
		data[34] = nil
	end
	
	if data[34] then data[34]:SetCount(count, 'B') end
	
	data[35] = GetTime()+0.5
	
--	print('T1',  C.onUpdateHandler.active, destGuid, sourceGuid, spellName)
	if C.onUpdateHandler.active and destGuid and ( destGuid ~= C.myGUID ) then
		C.targetEngaged[destGuid] = GetTime()+C.db.profile.engageThrottle											
	end
	
	data[36] = DO_FADE_NORMAL
	
	if not data[37] then
		data[37] = data[1]
	end
	
	data[21] = C:GetShowTicks(data[5])	
	
	if init then
		data[38], data[39] = C:GetDefaultDuraton(spellID)
	
		-- [1] duration
		-- [2] endTime
	
		-- [22] ticks left
		-- [24] shine timeOut  
		-- [25] haste  
		-- [26] pandemia
		-- [27] ticks_evert_s	
		-- [32] tickUpdateTimeout
		if data[21] then
		--	data[22] = nil
		--	data[24] = nil
		--	data[25] = nil
			data[32] = nil
			C.UpdateTickEvery(data)
		else
		--	data[22] = nil
		--	data[24] = nil
		--	data[25] = nil
			data[27] = nil
		--	data[32] = nil
			data[32] = nil
		end
	end
	
	if start then
		data[41] = C.db.profile.shine_on_apply
	end
	
	if sorting then SortBars('C.Timer:sorting:') end
	
	if start and not data[SOUND_INDEX] then OnTimerStart(tag) end
end

function C.Timer_DOSE(destGuid, sourceGuid, spellID, auraID, auraType, func, raidIndex, count)
	
	local tag = GetSpellTag(destGuid,spellID,sourceGuid,auraType,auraID)--( destGuid or NO_GUID )..tostring(spellID)..( sourceGuid or NO_GUID )..auraType.."-"..auraID

	if spelllist[tag] then
	--	spelllist[tag][14] = func																		-- [14] source of call timer
		spelllist[tag][17] = raidIndex
		spelllist[tag][19] = count
	end
end

function C.Timer_Remove(destGuid, sourceGuid, spellID, auraID, auraType, instant, nored)
	
	local tag = GetSpellTag(destGuid,spellID,sourceGuid,auraType,auraID) --( destGuid or NO_GUID )..tostring(spellID)..( sourceGuid or NO_GUID )..auraType.."-"..auraID
	local sorting = false
	if spelllist[tag] then	
		if C.db.profile.delayfading and not instant then
			local curtime = GetTime()
			if spelllist[tag][13] == NO_FADE then
				OnTimerEnd(tag)
				if spelllist[tag][2] > curtime+0.2 and not nored then
					spelllist[tag][36] = DO_FADE_RED
				else
					spelllist[tag][36] = DO_FADE_NORMAL
				end
				
				spelllist[tag][13] = DO_FADE
	
				spelllist[tag][15] = curtime + C.db.profile.delayfading_wait
				spelllist[tag][16] = spelllist[tag][15]+ C.db.profile.delayfading_outanim

			end
		else
			OnTimerEnd(tag)
			spelllist[tag][13] = FADED
			sorting = true
		end
	end
	
	if sorting then SortBars('Timer_Remove') end
end

function C.Timer_Remove_By_Tag(tag, instant)
	
	local sorting = false
	if spelllist[tag] then	
		if C.db.profile.delayfading and not instant then
			local curtime = GetTime()
			if spelllist[tag][13] == NO_FADE then
				OnTimerEnd(tag)
				if spelllist[tag][2] > curtime+0.2 then
					spelllist[tag][36] = DO_FADE_RED
				else
					spelllist[tag][36] = DO_FADE_NORMAL
				end
				
				spelllist[tag][13] = DO_FADE
				
				spelllist[tag][15] = curtime + C.db.profile.delayfading_wait
				spelllist[tag][16] = spelllist[tag][15]+ C.db.profile.delayfading_outanim
			end
		else
			OnTimerEnd(tag)
			spelllist[tag][13] = FADED
			sorting = true
		end
	end
	
	if sorting then SortBars('Timer_Remove_By_Tag') end
end

function C.Timer_Remove_DEAD(destGUID, dored)
	local sorting = false
	
	for tag, data in pairs(spelllist) do
		if data[3] == destGUID then
			if data then	
				if C.db.profile.delayfading then			
					if data[13] == NO_FADE then
						OnTimerEnd(tag)
						if data[2] > GetTime()+0.2 and not dored then
							data[36] = DO_FADE_RED
						else
							data[36] = DO_FADE_NORMAL
						end
						
						data[13] = DO_FADE
				
						data[15] = GetTime() + C.db.profile.delayfading_wait
						data[16] = data[15]+ C.db.profile.delayfading_outanim
					end
				else
					OnTimerEnd(tag)
					spelllist[tag][13] = FADED
					sorting = true
				end
			end
		end
	end
	
	if sorting then SortBars('Timer_Remove_DEAD') end
end

function C.RemoveGUID_UA(guid, auraType, func, curtime)
	local sorting = false
	
	
	for tag, data in pairs(spelllist) do
	
	--	print("Remove UA", data[8], data[13], NO_FADE)
	
		if data[3] == guid and ( data[11] == 'DEBUFF' or data[11] == 'BUFF' ) and data[14] == func and data[35] < curtime then --and data[11] == auraType
			if C.db.profile.delayfading then
				if data[13] == NO_FADE then
					if data[1] == 0 and data[2] == 0 then
						data[13] = DO_FADE_UNLIMIT
					elseif data[2] > curtime+0.2 then
						data[36] = DO_FADE_RED
						data[13] = DO_FADE
					else
						data[36] = DO_FADE_NORMAL
						data[13] = DO_FADE
					end
	
					
					data[15] = curtime + C.db.profile.delayfading_wait
					data[16] = data[15]+ C.db.profile.delayfading_outanim
					
					
					OnTimerEnd(tag) 
				end

			else
			--	OnTimerEnd(tag, "733")
				OnTimerEnd(tag)
				spelllist[tag][13] = FADED
				sorting = true			
			end
		end		
	end
	
	if sorting then SortBars('RemoveGUID_UA') end
end


function C.SetCount(self, count, source)
	local data = self.tag and spelllist[self.tag] or nil
	if not data then 
		self.icon.stacktext:SetText('')
		self.icon2.stacktext:SetText('')
		return 
	end
		
	if count then
		data[19] = C:GetCheckStacks(data[5]) or count or 0
		
	--	old_print('SetCount:0', 'data[19]=', data[19], 'count=', count)
	--	self.lastCount = count
	--	self.lastSource = source
	end
	
	--old_print('SetCount:1', 'count=',count, 'source=', source, 'data[21]=',data[21], 'data[22]=', data[22], 'data[19]=', data[19])

	if data[21] and C.db.profile.tick_count_on_stacks then
		if data[22] then
			self.icon.stacktext:SetText(data[22])
			self.icon2.stacktext:SetText(data[22])
		else 		
			self.icon.stacktext:SetText((data[19] and data[19] > 1 and data[19] or '' ))
			self.icon2.stacktext:SetText((data[19] and data[19] > 1 and data[19] or '' ))
		end
	else		
		self.icon.stacktext:SetText(( data[19] and data[19] > 1 and data[19] or '' ))
		self.icon2.stacktext:SetText(( data[19] and data[19] > 1 and data[19] or '' ))	
	end
end

function C.UpdateTickEvery(data)
	if not data[32] or data[32] < GetTime() then
	
		local prev27 = data[27]
		
		data[27] = C:GetTicksEvery(data[5])
				
		if data[27] and data[27] > 0 then
			data[22] = C.Round(data[1]/data[27])
		end
		
		data[32] = GetTime()+data[27]
	end
end
	
	
do
	local raidIndexCoord = {
		[1] = { 0, .25, 0, .25 }, --"STAR"
		[2] = { .25, .5, 0, .25}, --MOON
		[3] = { .5, .75, 0, .25}, -- CIRCLE
		[4] = { .75, 1, 0, .25}, -- SQUARE
		[5] = { 0, .25, .25, .5}, -- DIAMOND
		[6] = { .25, .5, .25, .5}, -- CROSS
		[7] = { .5, .75, .25, .5}, -- TRIANGLE
		[8] = { .75, 1, .25, .5}, --  SKULL
	}
	
	
	--[[
	{ text = RAID_TARGET_1, tCoordLeft = 0, tCoordRight = 0.25, tCoordTop = 0, tCoordBottom = 0.25 };
	{ text = RAID_TARGET_2, tCoordLeft = 0.25, tCoordRight = 0.5, tCoordTop = 0, tCoordBottom = 0.25 };
	{ text = RAID_TARGET_3, tCoordLeft = 0.5, tCoordRight = 0.75, tCoordTop = 0, tCoordBottom = 0.25 };
	{ text = RAID_TARGET_4, tCoordLeft = 0.75, tCoordRight = 1, tCoordTop = 0, tCoordBottom = 0.25 };
	{ text = RAID_TARGET_5, tCoordLeft = 0, tCoordRight = 0.25, tCoordTop = 0.25, tCoordBottom = 0.5 };
	{ text = RAID_TARGET_6, tCoordLeft = 0.25, tCoordRight = 0.5, tCoordTop = 0.25, tCoordBottom = 0.5 };
	{ text = RAID_TARGET_7, tCoordLeft = 0.5, tCoordRight = 0.75, tCoordTop = 0.25, tCoordBottom = 0.5 };
	{ text = RAID_TARGET_8, tCoordLeft = 0.75, tCoordRight = 1, tCoordTop = 0.25, tCoordBottom = 0.5 };
	
	]]

	function C.SetMark(self, mark)
	
		if ( mark and mark > 0 and mark < 9 ) and C.db.profile.show_mark then
			if self.raidMark:IsShown() then
				self.raidMark:SetTexCoord(raidIndexCoord[mark][1],raidIndexCoord[mark][2],raidIndexCoord[mark][3],raidIndexCoord[mark][4])
			else
				self.raidMark:Show()
				self.raidMark:SetTexCoord(raidIndexCoord[mark][1],raidIndexCoord[mark][2],raidIndexCoord[mark][3],raidIndexCoord[mark][4])
			end
		else
			self.raidMark:Hide()
		end
	end
end	
		
do
	
	function C:updateSortings()
		SortBars('updateSortings')
	end
	
	local labels = {}

	
	local function SetLabel(self, number, size, bar)
	
		self.labels[number] = size or 1

		if bar then
			self._bars[number] = bar
		end
	end
	
	function C:UpdateLabelStyle()
		
		for i=1, #labels do
			
			local opt = labels[i]:GetParent().opts
			
			if opt then
				labels[i].text:SetJustifyH(opt.group_font_style.justify)
				labels[i].text:SetFont(C.LSM:Fetch("font",opt.group_font_style.font), opt.group_font_style.size, opt.group_font_style.flags)	
				labels[i].text:SetShadowColor(opt.group_font_style.shadow[1],opt.group_font_style.shadow[2],opt.group_font_style.shadow[3],opt.group_font_style.shadow[4])
				labels[i].text:SetShadowOffset(opt.group_font_style.offset[1],opt.group_font_style.offset[2])
				
				C.UpdateIconTextPostition(labels[i]:GetParent())
				
			end
		end
	end

	local function UpdateLabel(self)
		local totalsize = 0
	
		local header = self.show_header and self.size*1.5+self.gap_newgroup or self.gap_newgroup
		local a, a2 = 1, 1
		
		local fading = true
		
		for i=1, #self.labels do
			if self.labels[i] >= 1 then
				fading = false
				break
			end
		end

		for i=1, #self.labels do
			local startfrom = fading and header*self.labels[1] or header
			local barheight = (self.h+self.gap_normal)*self.labels[i]
			if self.parentopt.add_up then  -- рост вверх

				if self.parentopt.group_grow_up then -- плашка сверху
					if ( self._bars[i] ) then 
						self._bars[i]:SetPoint("BOTTOM", self, "BOTTOM", 0, totalsize)	
					else 
						old_print('No bar for label', i)
					end 
					totalsize = totalsize + barheight
				else -- плашка снизу
					if ( self._bars[i] ) then 
						self._bars[i]:SetPoint("BOTTOM", self, "BOTTOM", 0, startfrom+totalsize)
					else 
						old_print('No bar for label', i)
					end 
					totalsize = totalsize + barheight
				end

			else	-- рост вниз

				if self.parentopt.group_grow_up then	-- плашка сверху
					if ( self._bars[i] ) then 
						self._bars[i]:SetPoint("TOP", self, "TOP", 0, -startfrom-totalsize)
					else 
						old_print('No bar for label', i)
					end 
					totalsize = totalsize + barheight
				else	-- плашка снизу
					if ( self._bars[i] ) then 
						self._bars[i]:SetPoint("TOP", self, "TOP", 0, -totalsize)
					else 
						old_print('No bar for label', i)
					end 
					totalsize = totalsize + barheight
				end			

			end
		end
			
		if fading then
			a = 1*self.labels[1]			
			a2 = a-0.3
			if a2 < 0 then a2 = 0 end
			totalsize = totalsize + ( header * self.labels[1] ) 
		else
			totalsize = totalsize + header
		end
		
		self.text:SetAlpha(a2)
		self:SetAlpha(a)
		self:SetHeight(totalsize)	
	end
	

		
	function C:NewUpdateLabels()
	
		for i=1, #labels do	
			if not labels[i].free and #labels[i]._bars > 0 then
				labels[i]:UpdateLabel()
			end
		end
	end
	
	local function CreateGUIBarBG(parent)
		
		for i=1, #labels do	
			if labels[i].free then
				return labels[i]
			end
		end
		
		local f = CreateFrame("Frame",nil, parent)
		f:SetFrameStrata("LOW")
		
		local opt = parent.opts
		
		local b = f:CreateTexture(nil, "BACKGROUND", nil, 0)
		
		local b3 = f:CreateTexture(nil, "BACKGROUND", nil, 0)
		b3:SetAllPoints()
		b3:SetColorTexture(0,0,1,0)
		
		local b2 = f:CreateTexture(nil, "BACKGROUND", nil, 0)
		b2:SetColorTexture(1,0,0,0)
		
		local ft = f:CreateFontString(nil, "OVERLAY");
	
		ft:SetJustifyV("CENTER")
		
		ft:SetJustifyH(opt.group_font_style.justify)
		ft:SetFont( C.LSM:Fetch("font",opt.group_font_style.font), opt.group_font_style.size, opt.group_font_style.flags)	
		ft:SetShadowColor(opt.group_font_style.shadow[1],opt.group_font_style.shadow[2],opt.group_font_style.shadow[3],opt.group_font_style.shadow[4])
		ft:SetShadowOffset(opt.group_font_style.offset[1],opt.group_font_style.offset[2])
	
		f.text = ft
		f.text.bg = b2
		f.labels = {}
		f._bars = {}
		f.newfading = true
		
		f.SetLabel = SetLabel
		f.UpdateLabel = UpdateLabel
		f.background = b
		
		f.free = true
		
		labels[#labels+1] = f
		
		return f						
	end

	local function GetGUIDBarBG(parent, to, title, gap, unit)
	
		local f = CreateGUIBarBG(parent)
		
		local curparent = not ( f:GetParent() == parent )
	
		f:SetParent(parent)
		f.free = false
		
		local opt = parent.opts
		
		f.parentopt = opt
		f.h = opt.h
		f.w = opt.w
		f.gap_normal = opt.gap
		f.gap_newgroup = gap
		f.show_header = opt.show_header
		f.size = opt.group_font_style.size
		f.newfading = true
		
		if curparent then

			f.text:SetJustifyH(opt.group_font_style.justify)
			f.text:SetFont(C.LSM:Fetch("font",opt.group_font_style.font), opt.group_font_style.size, opt.group_font_style.flags)	
			f.text:SetShadowColor(opt.group_font_style.shadow[1],opt.group_font_style.shadow[2],opt.group_font_style.shadow[3],opt.group_font_style.shadow[4])
			f.text:SetShadowOffset(opt.group_font_style.offset[1],opt.group_font_style.offset[2])
			
			C.UpdateIconTextPostition(parent)
		end
		
		f:SetSize(f.w, 1)

		f.text:SetSize(f.w, f.size*1.2) --,f.h)	
		
		-- рост вверх, отступ между группами, отступ между барами, высота верхушки

		local parentanchor = parent == to
		
		if opt.add_up then
			if opt.group_grow_up then	-- плашка сверху
				f:SetPoint("BOTTOM", to, "TOP", 0, 0)
				f.background:SetPoint("TOP", f, "TOP", 0, -gap-opt.gap)
				f.background:SetPoint("BOTTOM", f, "BOTTOM", 0, 0)				
			--	print("T", parentanchor, opt.add_up, gap, opt.gap, f.size, abs(gap-opt.gap))
			else
				f:SetPoint("BOTTOM", to, "TOP", 0, parentanchor and -gap or 0)
				f.background:SetPoint("TOP", f, "TOP", 0, -opt.gap)
				f.background:SetPoint("BOTTOM", f, "BOTTOM", 0, gap)
			end
		else	
			if opt.group_grow_up then	-- плашка сверху готова
				f:SetPoint("TOP", to, "BOTTOM", 0, parentanchor and gap or 0)
				f.background:SetPoint("TOP", f, "TOP", 0, -gap)
				f.background:SetPoint("BOTTOM", f, "BOTTOM", 0, opt.gap)
			else -- плашка снизу готова
				f:SetPoint("TOP", to, "BOTTOM", 0, 0)	
				f.background:SetPoint("TOP", f, "TOP", 0, 0)
				f.background:SetPoint("BOTTOM", f, "BOTTOM", 0, gap+opt.gap)
			end
		end
	
		f.background:SetPoint("LEFT", parent.mover, "LEFT")
		f.background:SetPoint("RIGHT", parent.mover, "RIGHT")
	
		if unit == "target" then
			f.group_color = opt.group_bg_target_color
		elseif unit == "focus" then
			f.group_color = opt.group_bg_focus_color
		else
			f.group_color = opt.group_bg_offtargets_color
		end
	
		f.background:SetColorTexture(f.group_color[1],f.group_color[2],f.group_color[3],f.group_color[4])
		
		if opt.group_bg_show then f.background:Show() else f.background:Hide() end

		f.text:ClearAllPoints()

		if ( opt.group_grow_up ) then  
			f.text:SetPoint("TOP", f.background, "TOP", -1, 1)			
			f.text:SetJustifyV("BOTTOM")
		else		
			f.text:SetPoint("BOTTOM", f.background, "BOTTOM", -1, -1)				
			f.text:SetJustifyV("TOP")
		end
	
		if f.show_header then
			f.text:SetText(title or "TEST_TITLE")
			
			if unit == "focus" then
				f.text:SetTextColor(opt.group_font_focus_color[1],opt.group_font_focus_color[2], opt.group_font_focus_color[3],1)
			else
				f.text:SetTextColor(opt.group_font_target_color[1],opt.group_font_target_color[2], opt.group_font_target_color[3],1)
			end
			if opt.group_bg_show then f.text.bg:Show() else f.text.bg:Hide() end
		else
			f.text:SetText("")
			f.text.bg:Hide()
		end

		f:Show()

		return f
	end

	local function ClearAllGUIDBarBGs()
		for i=1, #labels do	
			if not labels[i].free then	
				wipe(labels[i].labels)
				wipe(labels[i]._bars)
				labels[i].free = true
				labels[i].prev = nil
				labels[i]:ClearAllPoints()
				labels[i]:Hide()
			end
		end	
	end
	
	--[==[
		data[1] = duration													
		data[2] = endTime																	
		data[3] = destGuid																	
		data[4] = sourceGuid																
		data[5] = spellID	
	]==]

	local sorting_functions = {
		function(x,y)		-- 1 priority from lower to upper
			if x[18] == y[18] then
				return x[5] > y[5]
			else
				return y[18] < x[18]
			end
		end,
		function(x,y)		-- 2 endtime from upper to lower
			if x[2] == y[2] then
				return x[5] < y[5]
			end
				
			return x[2] < y[2]	
		end,
		function(x,y)		-- 3 endtime from lower to upper
			if x[2] == y[2] then
				return x[5] > y[5]
			else
				return x[2] > y[2] 
			end		
		end,
	}

	function C:UpdateFormatTexts(anchor)
		for k,v in pairs(anchors) do
			
			if v.id == anchor then
				
				v.opts = self.db.profile.bars_anchors[anchor]
				
				for i, timer in ipairs(v.bars) do	
					timer:BarTextUpdate()
				end
			
			end
		end
	end
	
	local function CheckSpell(tag)
		if spelllist[tag][2] > 0 and spelllist[tag][2]+20 < GetTime() then
			RemoveTagFrolList(tag)	
			return false
		end
		
		if spelllist[tag][35] > 0 and spelllist[tag][35]+60 < GetTime() then
			RemoveTagFrolList(tag)	
			return false
		end

		if C:GetTargetType(spelllist[tag][5]) == 1 and spelllist[tag][3] ~= C.CurrentTarget then
			return false 
		end
	
		if spelllist[tag][3] == C.COOLDOWN_SPELL then
			return true
		elseif not C:UnitFilter_GUID(spelllist[tag][3]) then
			return false 
		end
	
		if spelllist[tag][13] == NO_FADE or spelllist[tag][13] == DO_FADE or spelllist[tag][13] == DO_FADE_UNLIMIT then
			return true
		end

		return false
	end

	local loop = CreateFrame("Frame", "SPTimers-Bar-OnUpdateV2-Loop")
	loop.last = GetTime()
	loop.elapsed = 0
	loop:Hide()
	loop:SetScript("OnUpdate", function(self, elapsed)
	--	self.elapsed = self.elapsed + elapsed
	--	if self.elapsed < 0.01 then return end
		self:Hide()
	--	self.elapsed = 0
		SortBars('loop')
	end)

	local function GetAnchor(spellid, destGUID, auraType, func)
		local group = C:GetGroup(spellid)
		
		if func == "TEST_BAR" then
			local anchor = tonumber(match(auraType, "TEST_BAR(%d+)")) or 1
			
			if destGUID == "group1" then
				return anchor, "player"
			elseif destGUID == "group2" then
				return anchor, "target"
			else
				return anchor, "offtargets"
			end			
		elseif group then
			return C:GetAnchor(spellid, destGUID), group
		elseif func == COOLDOWN_SPELL then
			return C:GetAnchor(spellid, COOLDOWN_SPELL), "cooldowns"
		elseif destGUID == C.myGUID then
			return C:GetAnchor(spellid, destGUID), "player"
		elseif C.db.profile.doswap then
			if destGUID == C.CurrentTarget or func == CHANNEL_SPELL or destGUID == UnitGUID("target") then
				return C:GetAnchor(spellid, destGUID), "target", C:GetUnitAlwaysShowAnchor(spellid, destGUID)
			else
				return C:GetOffAnchor(spellid, destGUID), "offtargets", C:GetUnitAlwaysShowAnchor(spellid, destGUID)
			end
		elseif destGUID == nil then
			if auraType == "BUFF" then
				return C:GetOffAnchor(spellid, destGUID), "player"
			else
				return C:GetOffAnchor(spellid, destGUID), "target"
			end
		end
		
		if destGUID == C.CurrentTarget or func == CHANNEL_SPELL or destGUID == UnitGUID("target") then
			return C:GetAnchor(spellid, destGUID), "offtargets", C:GetUnitAlwaysShowAnchor(spellid, destGUID)
		else
			return C:GetOffAnchor(spellid, destGUID), "offtargets", C:GetUnitAlwaysShowAnchor(spellid, destGUID)
		end
			
	--	return C:GetOffAnchor(spellid, destGUID), "offtargets", C:GetUnitAlwaysShowAnchor(spellid, destGUID)
	end
	
	local raidIdToString = {
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:11:11:0:-5|t",
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:11:11:0:-5|t",
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:11:11:0:-5|t",
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:11:11:0:-5|t",
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:11:11:0:-5|t",
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:11:11:0:-5|t",
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:11:11:0:-5|t",
		"|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:11:11:0:-5|t",
	}

	function C.UpdateIconTextPostition(parent)
		local opts = parent.opts
		local size = opts.group_font_style.size

		for i=1, 8 do	
			raidIdToString[i] = format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d:%d:%d:%d|t", i, 11, 11, 0, -size*0.3)
		end
	end
	
	local group_def_Names = {
		["target"] 		= L["Target"],
		["player"] 		= L["Player"],
		["procs"] 		= L["Procs"],
		["cooldowns"] 	= L["Cooldowns"],
		["offtargets"] 	= L["Offtarget"],
	}
	
	local UNKNOWN = UNKNOWN
	
	local function GetGroupHeaderName(anchor, datas, group_name, indexs)
		local opts = anchor.opts
		
		local config = opts.header_custom_text[group_name]
		--[[
		header_custom_text = {
			["target"] 		= { 1, "%target" },
			["player"] 		= { 1, "%player" },
			["procs"] 		= { 1, "%player" },
			["cooldowns"] 	= { 1, "%player" },
			["offtargets"] 	= { 1, "%id : %target" },	
		},
		]]
		
		if config[1] == 1 then
			return group_def_Names[group_name]
		elseif config[1] == 2 then
			return datas[28] or datas[29]
		elseif config[1] == 3 then
			local text = config[2]
			
			text = gsub(text,"%%target", datas[28] or datas[29])
			text = gsub(text,"%%id", indexs or 1)
			text = gsub(text,"%%player", C.myNAME)
			text = gsub(text,"%%mark",  datas[17] and raidIdToString[datas[17]] or "")
			
			return text
		else		
			return UNKNOWN
		end
		
	end
	
	local function GetPreferedBar(anchor, prefBar)
		if ( prefBar ) then
			for s=1, #anchor.bars do
				if ( anchor.bars[s].tag == prefBar and not anchor.bars[s].inUse ) then 
					anchor.bars[s].inUse = true
					return anchor.bars[s]
				end
			end
		end 

		for s=1, #anchor.bars do
			if ( not anchor.bars[s].inUse ) then 
				anchor.bars[s].inUse = true
				return anchor.bars[s]
			end
		end
	end 

	local function UpdateBar(anchor, label, f, data, group_alpha, unit)
		local opts = anchor.opts
		local bar = GetPreferedBar(anchor, data[12]) --anchor.bars[anchor.index]
		bar.tag = data[12]
		bar.data = data
		--spelllist[bar.tag][34] = bar
		bar._groupalpha = group_alpha
		bar:SetAlpha(group_alpha)
		
		local header = opts.show_header and label.size*1.5+label.gap_newgroup or label.gap_newgroup

		local startfrom = header -- fading and header*1 or 
		local barheight = (label.h+label.gap_normal)*anchor.index
		
		bar:ClearAllPoints()
		
		if opts.add_up then  -- рост вверх
			if opts.group_grow_up then -- плашка сверху				
				bar:SetPoint("BOTTOM", label, "BOTTOM", 0, barheight)
			else -- плашка снизу
				bar:SetPoint("BOTTOM", label, "BOTTOM", 0, startfrom+barheight)
			end
		else	-- рост вниз
			if opts.group_grow_up then	-- плашка сверху	
				bar:SetPoint("TOP", label, "TOP", 0, -startfrom-barheight)
			else	-- плашка снизу
				bar:SetPoint("TOP", label, "TOP", 0, -barheight)
			end			
		end
		
		
		label:SetLabel(f, nil, bar)		
		bar._label = label
		bar.index = f
		bar:SetMark(spelllist[bar.tag][17])
		bar:BarTextUpdate()							
		bar:SetCount(spelllist[bar.tag][19], 'D')							
		bar.icon.texture:SetTexture(spelllist[bar.tag][9])
		bar.icon2.texture:SetTexture(spelllist[bar.tag][9])
		bar:UpdateBarColor()
		
		if data[1] > anchor._maxmax then 
			anchor._maxmax = data[1]
		end

		bar._elapsed = 1
		bar.__elapsed = 1
	end
	
	local function GUID_SortFunc(x,y)
		return GUID_TimeInit[x] < GUID_TimeInit[y]
	end
	
	local function UpdateAnchor(index)
		
		local anchor = anchors[index]
		
		if anchor.disabled == true then return end

		local prev
		anchor.index = 0
	
		local opts = anchor.opts
		
		local sort_func = sorting_functions[opts.sort_func or 1]
		
		
		tsort(anchor.guidsort, GUID_SortFunc)
				
		for guid, tags in pairs(anchor.group_guid) do
			tsort(tags, sort_func)
		end
		
		tsort(anchor.group.target, sort_func)
		tsort(anchor.group.player, sort_func)
		tsort(anchor.group.procs, sort_func)
		
		local label = nil
		
		anchor._maxmax = 0

		for s=1, #anchor.bars do
			anchor.bars[s].inUse = false
		end

		for s=1, #anchor.sorting do
			local group_name  = anchor.sorting[s].name
			local group_alpha = anchor.sorting[s].alpha
			local group_gap   = anchor.sorting[s].gap
	
			if anchor.index >= opts.bar_number then break end
			if not anchor.sorting[s].disabled then
			
				if group_name == "offtargets" then
					prev = nil
					local indexes = 0
					
					for numGUID = 1, #anchor.guidsort do
						local guid = anchor.guidsort[numGUID]
						local datas = anchor.group_guid[guid]
						
				--	for guid, datas in pairs(anchor.group_guid) do
				--		if guid ~= '_NumList' then
							if anchor.index >= opts.bar_number then break end
							
							if not prev or not label then
								indexes = indexes + 1
								label = GetGUIDBarBG(anchor, ( label or anchor ), GetGroupHeaderName(anchor,datas[1], group_name, indexes), group_gap, ( guid == C.CurrentTarget and "target" ) or ( guid == C.FocusTarget and "focus" ))						
							elseif prev ~= guid then
								indexes = indexes + 1
								label = GetGUIDBarBG(anchor, ( label or anchor ), GetGroupHeaderName(anchor,datas[1], group_name, indexes), group_gap, ( guid == C.CurrentTarget and "target" ) or ( guid == C.FocusTarget and "focus" ))
							end
					
							for f=1, #datas do
								if anchor.index >= opts.bar_number then break end
								
								anchor.index = anchor.index + 1
								
								UpdateBar(anchor, label, f, datas[f], ( ( not C.db.profile.doswap and ( datas[f][3] == C.CurrentTarget or datas[f][3] == UnitGUID("target")) and 1 or group_alpha) ))

								prev = guid
							end
				--		end
					end
					
					break
				else
					local group2 = anchor.group[group_name]
					prev = nil
					
					for f=1, #group2 do
						if anchor.index == opts.bar_number then break end
						
						if not prev or not label then
							label = GetGUIDBarBG(anchor, ( label or anchor ),GetGroupHeaderName(anchor,group2[1], group_name,1) , group_gap, group_name)						
						elseif prev ~= group_name then
							label = GetGUIDBarBG(anchor, ( label or anchor ),GetGroupHeaderName(anchor,group2[1], group_name,1) , group_gap, group_name)
						end
						
						anchor.index = anchor.index + 1
						
				--		print("T", group2[f], group2[f][3], group2[f][12])
						
						UpdateBar(anchor, label, f, group2[f], group_alpha)
						
						prev = group_name
					end
			
				end
			end
		end

		local curtime = GetTime()
		
		for s=1, #anchor.bars do
			if ( anchor.bars[s].inUse ) then
				anchor.bars[s]:Show()
				anchor.bars[s]:Restore()
				anchor.bars[s]:OnUpdateText(1, curtime)
				anchor.bars[s]:Update(curtime)
				anchor.bars[s]:Fading(curtime)
				anchor.bars[s]:bgFade(curtime)
				
				--old_print('Show', s, anchor.bars[s].tag )

				if not anchor.bars[s].tag then
				--	old_print('No tag for bar')
				elseif not spelllist[anchor.bars[s].tag] then
				--	old_print('Oups no data for this tag')
				elseif spelllist[anchor.bars[s].tag][41] then
					anchor.bars[s].barShine_ag:Play()
					spelllist[anchor.bars[s].tag][41] = false
				end
			else
			--	old_print('Hide', s, anchor.bars[s].tag )

				anchor.bars[s].tag = nil
				anchor.bars[s]:Hide()
			end
		end
		--[==[
		for f=anchor.index+1, opts.bar_number do
			anchor.bars[f].tag = nil
			anchor.bars[f]:Hide()
		end
		]==]

		if not C.newOnUpdate:IsShown() then
			C.newOnUpdate:Show()
		end
	end
	--[==[
	local GroupedOfftargetSpells = {}
	local GrouperOfftargetSpells_Check = {}
	local MassiveTypeSpells = {}
	]==]
	function SortBars(reason)
		--[==[
		if enableLoop then
			if not update then
				loop:Show()
				return
			end
		end
		]==]

		--old_print('SortBars', reason)

		ClearAllGUIDBarBGs()
		
		for i=1, #anchors do		
			wipe(anchors[i].guidsort)
			wipe(anchors[i].group_guid)
			wipe(anchors[i].group.target)
			wipe(anchors[i].group.player)
			wipe(anchors[i].group.procs)
			wipe(anchors[i].group.cooldowns)
		end
		
		for tag, data in pairs(spelllist) do
		
			if data and CheckSpell(tag) then

				local anchor, group, copy_to1, copy_to2, copy_to3 = GetAnchor(data[5], data[3], data[11], data[14])

				if copy_to2 and anchor ~= copy_to2 then
					anchors[copy_to2].group[group][#anchors[copy_to2].group[group]+1] = data
				end
				
				if copy_to3 and anchor ~= copy_to3 then
					anchors[copy_to3].group[group][#anchors[copy_to3].group[group]+1] = data
				end
				
				if group == "offtargets" then	
					if not anchors[anchor].group_guid[data[3]] then 
						anchors[anchor].group_guid[data[3]] = {}						
						anchors[anchor].guidsort[#anchors[anchor].guidsort+1] = data[3]
					end
					anchors[anchor].group_guid[data[3]][#anchors[anchor].group_guid[data[3]]+1] = data
				else
					anchors[anchor].group[group][#anchors[anchor].group[group]+1] = data		
				end
			end
		end
	
		for i=1, #anchors do
			UpdateAnchor(i)
		end
	
		C:NewUpdateLabels()
	end

	C.SortBars = SortBars
end

function C.UpdateBarSize(self)	
	local opt = C.db.profile.bars_anchors[self.parent.id]
	self.opts = opt
	
--	print("T", opt.w, self.parent.id)
	self:SetSize(opt.w or 100 , opt.h or 20)

	self.bar.overlay2:SetHeight(opt.h)
	
	self.bar:SetReverseFill(opt.reverse_fill)
	self.bar:SetStatusBarTexture(C.LSM:Fetch("statusbar", opt.bar.texture))
	self.bar:SetStatusBarColor(unpack(opt.bar.color))

	self.bar:ClearAllPoints()
	
	-- opt.gap
	
	if opt.add_up then
		self.bar:SetPoint("TOP", self, "TOP", 0, 0)
	else
		self.bar:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
	end
	
	local _left, _right = 0, 0
	
	if opt.left_icon then
		_left = _left + opt.h + opt.icon_gap
	end
	
	if opt.right_icon then
		_right = _right + opt.h + opt.icon_gap
	end
	
	self.icon:SetSize(opt.h, opt.h)

	self.icon2:SetSize(opt.h, opt.h)
	
	
	self.parent:ClearAllPoints()
	self.parent:SetPoint("CENTER", self.parent.mover,"CENTER", (_left/2) - (_right/2) , 0)
	self.parent:SetSize(1,opt.h+5)
	
	
	self.bar:SetSize(opt.w-_left-_right,opt.h)
	self.parent.mover:SetSize(opt.w, opt.h)
end

function C.UpdateIcons(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt
	
	if opt.left_icon then f.icon:Show()
	else f.icon:Hide() end
	
	if opt.right_icon then f.icon2:Show()
	else f.icon2:Hide() end
	
	f.icon:SetSize(opt.h, opt.h)

	f.icon2:SetSize(opt.h, opt.h)
	
	f.icon:SetPoint("TOPRIGHT",f.bar,"TOPLEFT",-opt.icon_gap, 0)
	f.icon:SetPoint("BOTTOMRIGHT",f.bar,"BOTTOMLEFT",-opt.icon_gap, 0)
	
	f.icon2:SetPoint("TOPLEFT",f.bar,"TOPRIGHT",opt.icon_gap, 0)
	f.icon2:SetPoint("BOTTOMLEFT",f.bar,"BOTTOMRIGHT",opt.icon_gap, 0)
	
	local _left, _right = 0, 0
	
	if opt.left_icon then
		_left = _left + opt.h + opt.icon_gap
	end
	
	if opt.right_icon then
		_right = _right + opt.h + opt.icon_gap
	end
	
	f.parent:ClearAllPoints()
	f.parent:SetPoint("CENTER", f.parent.mover,"CENTER", (_left/2) - (_right/2) , 0)
	f.parent:SetSize(1,opt.h+5)
	
	f.parent.mover:SetSize(opt.w, opt.h)
end
function C.UpdateStackText(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt

	f.icon.stacktext:SetTextColor(unpack(opt.stack.textcolor))
	f.icon.stacktext:SetFont(C.LSM:Fetch("font",opt.stack.font),opt.stack.size,opt.stack.flags)
	f.icon.stacktext:SetJustifyH(opt.stack.justify)
	f.icon.stacktext:SetAlpha(opt.stack.alpha or 1)
	f.icon.stacktext:SetShadowColor(unpack(opt.stack.shadow or { 0, 0, 0, 1 }))
	f.icon.stacktext:SetShadowOffset(opt.stack.offset and opt.stack.offset[1] or 0,opt.stack.offset and opt.stack.offset[2] or 0)
	

	f.icon2.stacktext:SetTextColor(unpack(opt.stack.textcolor))
	f.icon2.stacktext:SetFont(C.LSM:Fetch("font",opt.stack.font),opt.stack.size,opt.stack.flags)
	f.icon2.stacktext:SetJustifyH(opt.stack.justify)
	f.icon2.stacktext:SetAlpha(opt.stack.alpha or 1)
	f.icon2.stacktext:SetShadowColor(unpack(opt.stack.shadow or { 0, 0, 0, 1 }))
	f.icon2.stacktext:SetShadowOffset(opt.stack.offset and opt.stack.offset[1] or 0,opt.stack.offset and opt.stack.offset[2] or 0)
	
	f.icon.stacktext:ClearAllPoints()
	f.icon2.stacktext:ClearAllPoints()
	
	if opt.stack.justify == 'LEFT' then
		f.icon.stacktext:SetPoint("BOTTOMLEFT", f.icon, "BOTTOMLEFT",0,0)	
		f.icon2.stacktext:SetPoint("BOTTOMLEFT", f.icon2, "BOTTOMLEFT",0,0)
	elseif opt.stack.justify == 'RIGHT' then
		f.icon.stacktext:SetPoint("BOTTOMRIGHT", f.icon, "BOTTOMRIGHT",0,0)
		f.icon2.stacktext:SetPoint("BOTTOMRIGHT", f.icon2, "BOTTOMRIGHT",0,0)
	elseif opt.stack.justify == 'CENTER' then
		f.icon.stacktext:SetPoint("BOTTOM", f.icon, "BOTTOM",0,0)
		f.icon2.stacktext:SetPoint("BOTTOM", f.icon2, "BOTTOM",0,0)
	end
end

function C.UpdateTimeText(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt

	f.timeText:SetTextColor(unpack(opt.timer.textcolor))
    f.timeText:SetFont(C.LSM:Fetch("font",opt.timer.font), opt.timer.size, opt.timer.flags)
    f.timeText:SetJustifyH(opt.timer.justify)
    f.timeText:SetAlpha(opt.timer.alpha or 1)
	
	f.timeText:SetWidth(opt.timer.size*4)

	f.timeText:SetShadowColor(unpack(opt.timer.shadow or { 0, 0, 0, 1 }))
	f.timeText:SetShadowOffset(opt.timer.offset and opt.timer.offset[1] or 0,opt.timer.offset and opt.timer.offset[2] or 0)
	
	if not opt.lefttext then
		f.timeText:ClearAllPoints()
		f.timeText:SetPoint("TOP", f.bar, "TOP")
		f.timeText:SetPoint("BOTTOM", f.bar, "BOTTOM")
		f.timeText:SetPoint("RIGHT", f.bar, "RIGHT",0,0)
	else
		f.timeText:ClearAllPoints()
		f.timeText:SetPoint("TOP", f.bar, "TOP")
		f.timeText:SetPoint("BOTTOM", f.bar, "BOTTOM")
		f.timeText:SetPoint("LEFT", f.bar, "LEFT", 0,0)
	end
	
  --  f.timeText:SetVertexColor(unpack(opt.timer.vertexcolor))
end
function C.UpdateSpellText(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt

	f.spellText:SetDrawLayer("ARTWORK")

	f.spellText:SetTextColor(unpack(opt.spell.textcolor))
    f.spellText:SetFont(C.LSM:Fetch("font",opt.spell.font),opt.spell.size,opt.spell.flags)
--    f.spellText:SetWidth(f.bar:GetWidth()*0.8)
 --   f.spellText:SetHeight(opt.h/2+1)
	f.spellText:SetWordWrap(false)
    f.spellText:SetJustifyH(opt.spell.justify)
    f.spellText:SetAlpha(opt.spell.alpha or 1)
	
	f.spellText:SetShadowColor(unpack(opt.spell.shadow or { 0, 0, 0, 1 }))
	f.spellText:SetShadowOffset(opt.spell.offset and opt.spell.offset[1] or 0,opt.spell.offset and opt.spell.offset[2] or 0)
	
	local _left, _right = 0, 0
	
	if opt.left_icon then
		_left = _left + opt.h + opt.icon_gap
	end
	
	if opt.right_icon then
		_right = _right + opt.h + opt.icon_gap
	end
	
	f.spellText:ClearAllPoints()
	f.spellText:SetPoint("CENTER", f, "CENTER", opt.spell.offsetx + -(_left/2) + (_right/2),0)
	f.spellText:SetWidth(opt.w-80)

--	self.bar:SetSize(opt.w-_left-_right,opt.h)
	
	--[==[
	if not opt.lefttext then
	
		-- таймер справа
		f.spellText:ClearAllPoints()		
		f.spellText:SetPoint("LEFT", f.bar, "LEFT", opt.spell.offsetx,0)
		f.spellText:SetPoint("RIGHT", f.timeText, "LEFT",opt.spell.offsetx,0)
	else
		f.spellText:ClearAllPoints()
		-- таймер слева
		f.spellText:SetPoint("LEFT", f.timeText, "RIGHT", opt.spell.offsetx,0)
		f.spellText:SetPoint("RIGHT", f.bar, "RIGHT",opt.spell.offsetx,0)
	end
	]==]
	
	
	
end
function C.UpdateTick_Color(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt
	
	if opt.dotticks and opt.dotticks.color and f.tiks then
		
		for i=1, #f.tiks do
			
			if opt.tick_ontop then
				f.tiks[i]:SetDrawLayer("OVERLAY")
			else
				f.tiks[i]:SetDrawLayer("ARTWORK", 5)
			end
			
			f.tiks[i]:SetVertexColor(opt.dotticks.color[1],opt.dotticks.color[2],opt.dotticks.color[3],opt.dotticks.color[4])	
		end
	end
	
end
function C.UpdateSpark_Color(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt
	
	f.bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	f.bar.spark:SetAlpha(1)
	f.bar.spark:SetWidth(10)		
	f.bar.spark:SetHeight(f.bar:GetHeight()*3)	
	f.bar.spark:SetBlendMode('ADD')
	f.bar.spark:SetPoint("CENTER",f.bar.sp1,"LEFT",0,0)
	f.bar.spark:SetPoint("TOP", f.bar.sp1, "TOP",0,10)
	f.bar.spark:SetPoint("BOTTOM", f.bar.sp1, "BOTTOM",0,-10)
	f.bar.spark:SetVertexColor(opt.castspark.color[1],opt.castspark.color[2],opt.castspark.color[3],opt.castspark.color[4])
	
	f.bar.shine:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	f.bar.shine:SetAlpha(0)
	f.bar.shine:SetWidth(10)
	f.bar.shine:SetHeight(50)		
	f.bar.shine:SetBlendMode('ADD')
	f.bar.shine:SetPoint("CENTER",f.bar.sp1,"LEFT",0,0)
	
	if opt.spark_ontop then
		
		f.bar.spark:SetDrawLayer("OVERLAY", 6)
		f.bar.shine:SetDrawLayer("OVERLAY", 6)
	else
		f.bar.spark:SetDrawLayer("ARTWORK", 3)
		f.bar.shine:SetDrawLayer("ARTWORK", 4)
	end
	
-- 	f.bar.shine:SetVertexColor(opt.castspark.color[1],opt.castspark.color[2],opt.castspark.color[3],opt.castspark.color[4])
end
function C.UpdateRaidIcon(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt
	
	local _left, _right = 0, 0
	
	if opt.left_icon then
		_left = _left + opt.h + opt.icon_gap
	end
	
	if opt.right_icon then
		_right = _right + opt.h + opt.icon_gap
	end
	
	f.raidMark:SetPoint("TOP", f, "TOP", -(_left/2) + (_right/2) + (opt.raidicon_xOffset or 0 ) , opt.raidicon_y or 5)
	f.raidMark:SetSize(opt.raidiconsize or 10, opt.raidiconsize or 10)
	f.raidMark:SetAlpha(opt.raidicon_alpha or 1)

end
function C.UpdateBorder(f)
	local opt = C.db.profile.bars_anchors[f.parent.id]
	f.opts = opt

	f.icon:SetPoint("TOPRIGHT",f.bar,"TOPLEFT",-opt.icon_gap, 0)
	f.icon:SetPoint("BOTTOMRIGHT",f.bar,"BOTTOMLEFT",-opt.icon_gap, 0)

	f.icon.bg:SetPoint("TOPLEFT", -opt.borderinset, opt.borderinset)
	f.icon.bg:SetPoint("BOTTOMRIGHT", opt.borderinset, -opt.borderinset)
	
	f.icon.bg:SetBackdrop({
		edgeFile = C.LSM:Fetch("border", opt.border),
		edgeSize = opt.bordersize,
	})
	f.icon.bg:SetBackdropBorderColor(opt.bordercolor[1], opt.bordercolor[2], opt.bordercolor[3], opt.bordercolor[4])
	
	f.icon2:SetPoint("TOPLEFT",f.bar,"TOPRIGHT",opt.icon_gap, 0)
	f.icon2:SetPoint("BOTTOMLEFT",f.bar,"BOTTOMRIGHT",opt.icon_gap, 0)	
	f.icon2.bg:SetPoint("TOPLEFT", -opt.borderinset, opt.borderinset)
	f.icon2.bg:SetPoint("BOTTOMRIGHT", opt.borderinset, -opt.borderinset)

	f.icon2.bg:SetBackdrop({
		edgeFile = C.LSM:Fetch("border", opt.border),
		edgeSize = opt.bordersize,
	})
	f.icon2.bg:SetBackdropBorderColor(opt.bordercolor[1], opt.bordercolor[2], opt.bordercolor[3], opt.bordercolor[4])
	
	
	f.bar.bg:SetPoint("TOPLEFT", f.bar, -opt.borderinset, opt.borderinset)
	f.bar.bg:SetPoint("BOTTOMRIGHT", f.bar, opt.borderinset, -opt.borderinset)
	f.bar.bg:SetBackdrop({
			edgeFile = C.LSM:Fetch("border", opt.border),
			edgeSize = opt.bordersize,
		})
	f.bar.bg:SetBackdropBorderColor(opt.bordercolor[1], opt.bordercolor[2], opt.bordercolor[3], opt.bordercolor[4])
	
	f.bar.bg2:SetTexture(C.LSM:Fetch("statusbar", opt.bar.bgtexture))
	f.bar.bg2:SetVertexColor(unpack(opt.bar.bgcolor))
end

do 
	local function Round(num) return floor(num+.5) end --.5
	
	local function getbarpos(timer, tik)
		local minValue, maxValue = timer:GetMinMaxValues()
		
		if tik > maxValue then tik = maxValue end
		
		if tik >= 0 then
			return tik / maxValue * timer:GetWidth()
		else
			return (maxValue+tik) / maxValue * timer:GetWidth()
		end
	end
	
	local function getbarcurrentpos(timer, value)
		local minValue, maxValue = timer:GetMinMaxValues()
		if value > maxValue then value = maxValue end
		
		return value/maxValue * timer:GetWidth()
	end

	local function getoverlay2point(timer, _time, value)
		local minValue, maxValue = timer:GetMinMaxValues()
		
		if value > maxValue then value = maxValue end
		if _time > maxValue then _time = maxValue end		
		
		local current_time = value - _time
		
		
		if current_time <= 0 then current_time = 0 end
		return current_time/maxValue * timer:GetWidth()
	end
	
	local function overlayWidth(timer, _time)
		local minValue, maxValue = timer:GetMinMaxValues()
		
		return _time/maxValue * timer:GetWidth()
	end
	
	local function CreateTickFrame(frame,opt)
		local f = frame.bar:CreateTexture(nil, "OVERLAY")
						
		if opt.tick_ontop then
			f:SetDrawLayer("OVERLAY")
		else
			f:SetDrawLayer("ARTWORK", 5)
		end

		f:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		f:SetAlpha(0.9)
		f:SetWidth(6)
		f:SetHeight(opt.h*1.8)
		f:SetBlendMode('ADD')
		f:SetVertexColor(opt.dotticks.color[1],opt.dotticks.color[2],opt.dotticks.color[3],opt.dotticks.color[4])	
		--[==[
		local text = frame.bar:CreateFontString(nil, 'OVERLAY')
		text:SetPoint('CENTER', f, 'CENTER', 0, 0)
		text:SetFont(STANDARD_TEXT_FONT, 10)
		
		f.text = text
		]==]
		f:Hide()
						
		return f
	end

	function C.OnValueChanged(self, value)
		local data 				= self.data --self.tag and spelllist[self.tag] or nil
		local opt 				= self.opts
		
	--	if not data then return end
		
		if value < 0 then return end
		
		local ignoreValue = true
		
		if not self.prevValue then
			self.prevValue = value
		end
		
		if (self.prevValue - value ) > 0 then
			ignoreValue = false
		end
		
		self.prevValue = value
		
		local current_position 	= getbarcurrentpos(self.bar, value)	
		local tickOverlap 		= C:TickOverlap(data[5]) 
		local castTime 			= C:GetCastTime(data[5]) or 0
		local overlaytime 		= castTime or 0
		
		local min1, max1 		= self.bar:GetMinMaxValues()
		
		local width 			= self.bar:GetWidth()
		
		if data[1] == 0 and data[2] == 0 then
			self.bar.spark:Hide()
		else
			if opt.reverse_fill then
				self.bar.sp1:SetPoint("TOPLEFT",self.bar,"TOPLEFT", -current_position+width, 0)
				self.bar.sp1:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", -current_position+width, 0)
			else
				self.bar.sp1:SetPoint("TOPLEFT",self.bar,"TOPLEFT", current_position, 0)
				self.bar.sp1:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", current_position, 0)
			end
			
			self.bar.spark:Show()
		end

		if C:IsPandemiaSpell(data[5]) and C.db.profile.show_pandemia_bp then
			
			local pandemiapoint = getbarpos(self.bar, ( max1 < data[38]*0.3 and max1 or data[38]*0.3 ))
		
			self.bar.pandemi:ClearAllPoints()
			
			if C.db.profile.pandemia_bp_style == 1 then
				self.bar.pandemi:SetWidth(2)
				if opt.reverse_fill then
					self.bar.pandemi:SetPoint("TOPLEFT",self.bar,"TOPLEFT", -pandemiapoint+width, 0)
					self.bar.pandemi:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", -pandemiapoint+width, 0)
				else
					self.bar.pandemi:SetPoint("TOPLEFT",self.bar,"TOPLEFT", pandemiapoint, 0)
					self.bar.pandemi:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", pandemiapoint, 0)
				end		
			elseif C.db.profile.pandemia_bp_style == 2 then
			
				if opt.reverse_fill then
				
					self.bar.pandemi:SetPoint("TOPLEFT",self.bar,"TOPLEFT", -pandemiapoint+width, 0)
					self.bar.pandemi:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", -pandemiapoint+width, 0)
					
					self.bar.pandemi:SetPoint("TOPRIGHT", self.bar, "TOPRIGHT", 0, 0)
					self.bar.pandemi:SetPoint("BOTTOMRIGHT", self.bar, "BOTTOMRIGHT", 0, 0)
					
				else
					self.bar.pandemi:SetPoint("TOPRIGHT",self.bar,"TOPLEFT", pandemiapoint, 0)
					self.bar.pandemi:SetPoint("BOTTOMRIGHT",self.bar,"BOTTOMLEFT", pandemiapoint, 0)
					
					self.bar.pandemi:SetPoint("TOPLEFT", self.bar, "TOPLEFT", 0, 0)
					self.bar.pandemi:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT", 0, 0)
					
				end
			
			end
			if not self.bar.pandemi:IsShown() then
				self.bar.pandemi:Show()
			end
		else
			if self.bar.pandemi:IsShown() then
				self.bar.pandemi:Hide()
			end
		end
		
		-- data[27] tick every seconds
		if tickOverlap and data[27] then
		
			if overlaytime > 0 then
				overlaytime = overlaytime+data[27]
			else
				overlaytime = data[27]
			end
		end

		if overlaytime and overlaytime > 0 then

	--		self.bar.overlay1:Hide()
			local over_width = 0
			
			if castTime > 0 then
				over_width = overlayWidth(self.bar, castTime)			
				self.bar.overlay2:Show()
				self.bar.overlay2:SetWidth(over_width)
			elseif castTime < 0 then
				over_width = overlayWidth(self.bar, abs(castTime))
				
				self.bar.overlay2:Show()
				self.bar.overlay2:SetWidth(over_width)
			else
				self.bar.overlay2:Hide()
			end
	
			local ov_2point = getoverlay2point(self.bar, overlaytime, value)
	
			if opt.reverse_fill then
				self.bar.sp2:SetPoint("TOPLEFT",self.bar,"TOPLEFT", -ov_2point-over_width+width, 0)
				self.bar.sp2:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", -ov_2point-over_width+width, 0)
			else
				self.bar.sp2:SetPoint("TOPLEFT",self.bar,"TOPLEFT", ov_2point, 0)
				self.bar.sp2:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", ov_2point, 0)
			end
			
		else
		--	self.bar.overlay1:Hide()
			self.bar.overlay2:Hide()
		end
			--data[13] == NO_FADE and
			
			-- 21 show ticks
	
		C.UpdateTickEvery(data)
		
		if data[27] and data[27] > 0 then
			data[22] = floor(value/data[27])+1
		end
			
		if not C.db.profile.hide_dot_ticks and data[27] and data[27] > 0 then
			local numTicks = Round( ( ( data[1] < max1 ) and data[1] or max1 )/data[27]) -- first and last shoud be skipped
			local lowertick = -1
			
			local shineTick = ( value <= max1 and value > 0 and not ignoreValue )
			
			if numTicks < 25 then
			
				for i=1, numTicks-1 do
				
					local tickPosition = getbarpos(self.bar, (numTicks-i)*data[27])
					local tickPostFloor = floor(tickPosition)
					
					if not self.tiks[i] then
						self.tiks[i] = CreateTickFrame(self,opt) 	
						
					--	self.tiks[i].text:SetText(i)
					end
					
					if opt.reverse_fill then
						self.tiks[i]:SetPoint("TOPLEFT",self.bar,"TOPLEFT", -(tickPostFloor)+opt.w, opt.h*0.4)
						self.tiks[i]:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", -(tickPostFloor)+opt.w, -opt.h*0.4)				
					else
						self.tiks[i]:SetPoint("TOPLEFT",self.bar,"TOPLEFT", (tickPostFloor), opt.h*0.4)
						self.tiks[i]:SetPoint("BOTTOMLEFT",self.bar,"BOTTOMLEFT", (tickPostFloor), -opt.h*0.4)
					end
					
					self.tiks[i].tickPosition = tickPosition
					if self.tiks[i]:IsShown() then
						self.tiks[i]:Hide()
					end
					
					if C.db.profile.showonlynext then
						if current_position <= self.tiks[i].tickPosition then
							if lowertick < i then lowertick = i	end
							--[==[
							if self.tiks[i].shine and not ignoreValue then
								self.bar.spark.shine:Play()
								self.tiks[i].shine = false
							end
							]==]
							
						--	if shineTick then self:ShineTick(data) end
							
							if self.tiks[i]:IsShown() then
								self.tiks[i]:Hide()
							end
						end
					elseif C.db.profile.ticksfade then
						if current_position <= self.tiks[i].tickPosition then		
							--[==[
							if self.tiks[i].shine and not ignoreValue then
								self.bar.spark.shine:Play()
								self.tiks[i].shine = false
							end
							]==]
							
						--	if shineTick then self:ShineTick(data) end
							if self.tiks[i]:IsShown() then
								self.tiks[i]:Hide()
							end
						else
							if not self.tiks[i]:IsShown() then
								self.tiks[i]:Show()
							end
						end
					else
						if current_position <= self.tiks[i].tickPosition then	
							--[==[
							if self.tiks[i].shine and not ignoreValue then
								self.bar.spark.shine:Play()
								self.tiks[i].shine = false
							end
							]==]
							
						--	if shineTick then self:ShineTick(data) end
						end		

						if self.tiks[i].tickPosition < self:GetWidth() then
							if not self.tiks[i]:IsShown() then
								self.tiks[i]:Show()
							end
						end				
					end
					
					for i=numTicks, #self.tiks do
						if self.tiks[i]:IsShown() then
							self.tiks[i]:Hide()
						end
					end
					
					if C.db.profile.showonlynext and lowertick > 0 and self.tiks[lowertick+1] then
						if not self.tiks[lowertick+1]:IsShown() then
							self.tiks[lowertick+1]:Show()
						end
					end
				end
			else
				for i=1, #self.tiks do
					self.tiks[i]:Hide()
				end	
			end
		else
			for i=1, #self.tiks do
				self.tiks[i]:Hide()
			end	
		end
	end
end


function C.UpdateStyle(self)	
	self:UpdateBorder()
	self:UpdateRaidIcon()
	self:UpdateTick_Color()
	self:UpdateSpark_Color()
	self:UpdateSpellText()
	self:UpdateTimeText()
	self:UpdateStackText()
	self:UpdateIcons()
	self:UpdateBarSize()	
end


local function Restore(self)	
	if self.__resize >= 1 then 
--		print("Fail to Resore")
		return 
	end
	self.__resize = 1

	self.timeText:SetAlpha(self.opts.timer.alpha)
	self.spellText:SetAlpha(self.opts.spell.alpha)
	self.icon.stacktext:SetAlpha(self.opts.stack.alpha)
	self.icon2.stacktext:SetAlpha(self.opts.stack.alpha)
	
	if self._label then self._label:SetLabel(self.index, 1) end
	
	self:SetAlpha(self._groupalpha)
	self:SetHeight(self.opts.h)
	self.bar:SetHeight(self.opts.h)
end

local function FadeOut(self, gettime)
	local data = self.data --self.tag and spelllist[self.tag] or nil
	
	local a = (data[16]-gettime)/C.db.profile.delayfading_outanim
	
	if a > 1 then
		a = 1
		print('Error if FadeOut a > 1')

 	end
	
	if a <= 0 and ( data[13] == DO_FADE or data[13] == DO_FADE_UNLIMIT )then
		self:Resize(0)
		
		data[13] = FADED
		
		if spelllist[self.tag] then
			spelllist[self.tag][13] = FADED	
		end

		SortBars('FadeOut')
	else
		self:Resize(a)
	end
end

local function Resize(self, value)
	local opt = self.opts
	
	self.__resize = value

	if self._label then
		self._label:SetLabel(self.index, value)
	end

	self.spellText:SetAlpha(opt.spell.alpha*value)
	self.timeText:SetAlpha(opt.timer.alpha*value)	
	self.icon.stacktext:SetAlpha(opt.stack.alpha*value)
	self.icon2.stacktext:SetAlpha(opt.stack.alpha*value)
	
	self:SetAlpha(self._groupalpha*value)
	self:SetHeight(opt.h*value)
	self.bar:SetHeight(opt.h*value)
	
--	print("Resize in ", value)
end
--[==[
local function GetNextValue(value, cur)
	local rate = GetFramerate()
	local limit = 30/rate
	
	local new = cur + math.min((value-cur)/3, math.max(value-cur, limit))
	if new ~= new then
		-- Mad hax to prevent QNAN.
		new = value
	end
	
	local nextValue = new
	
	if (cur == value or abs(new - value) < 2) then
		nextValue = value
	end
	
	return nextValue
end
]==]
local function Update(self, gettime, maxTime)
	local data = self.data --self.tag and spelllist[self.tag] or nil	
--	if not data then return end
	

	local val = data[2]-gettime
	
	 -- maxValue addapt to per anchor
	if data[25][self.parent.id] ~= data[1] then
		data[25][self.parent.id] = data[1]
	end
	
	 -- maxValue current per anchor
	if not data[26][self.parent.id] then
		data[26][self.parent.id] = data[1]
	end

	local minValue, maxValue = self.bar:GetMinMaxValues()
	
--	if not self._maxvalue then self._maxvalue = data[1] end
	
	if C.db.profile.adapttoonemax then
		if C.db.profile.bar_smooth then		
			if C.db.profile.maximumtime then	

				if data[25][self.parent.id] ~= ( C.db.profile.maximumtime_value or  data[1] ) then
					data[25][self.parent.id] = ( C.db.profile.maximumtime_value or  data[1] ) 
				end
			else
				if data[25][self.parent.id] ~= self.parent._maxmax then
					data[25][self.parent.id] = self.parent._maxmax
				end
			end
			
			data[37] = data[37] + (val-data[37])/C.db.profile.bar_smooth_value_v2*0.5
			
			data[26][self.parent.id] = data[26][self.parent.id] + (data[25][self.parent.id]-data[26][self.parent.id])/C.db.profile.bar_smooth_value_v2		
		--	data[26][self.parent.id] = GetNextValue(data[26][self.parent.id], data[25][self.parent.id]-data[26][self.parent.id])/C.db.profile.bar_smooth_value_v2
		else
			data[37] = val		
			data[26][self.parent.id] = C.db.profile.maximumtime and C.db.profile.maximumtime_value or data[1]
		end
	else
		if C.db.profile.bar_smooth then
			data[37] = data[37] + (val-data[37])/C.db.profile.bar_smooth_value_v2*0.5
			
			if C.db.profile.maximumtime then
				if data[25][self.parent.id] ~= ( C.db.profile.maximumtime_value or  data[1] ) then
					data[25][self.parent.id] = ( C.db.profile.maximumtime_value or  data[1] ) 
				end
			end
			
			data[26][self.parent.id] = data[26][self.parent.id] + (data[25][self.parent.id]-data[26][self.parent.id])/C.db.profile.bar_smooth_value_v2
		--	data[26][self.parent.id] = GetNextValue(data[26][self.parent.id], data[25][self.parent.id]-data[26][self.parent.id])/C.db.profile.bar_smooth_value_v2
			
		--	data[25][self.parent.id] = C.db.profile.maximumtime and C.db.profile.maximumtime_value or data[1]
		else
			data[37] = val
			data[26][self.parent.id] = C.db.profile.maximumtime and C.db.profile.maximumtime_value or data[1]
		end
	end
	
	if data[1] == 0 and data[2] == 0 then
		self.bar:SetMinMaxValues(0, 1)	
	else	
		self.bar:SetMinMaxValues(0, data[26][self.parent.id])
	end
	
--	old_print('T', data[37], data[25][self.parent.id], data[26][self.parent.id])

	if data[1] == 0 and data[2] == 0 then
		self.bar:SetValue(1)
		self.timeText:SetText("")
		self:UpdateBarOverlays(1)
	elseif val > 0 then	
	
	--	print('T2', val, data[37], data[1])
		
		self.bar:SetValue(data[37])
		self.timeText:SetFormattedText(C.FormatTime((self.opts.fortam_s or 1), data[37], data[1]))
		self:UpdateBarOverlays(data[37])
	else
		self.bar:SetValue(data[37])
		self.timeText:SetFormattedText(C.FormatTime((self.opts.fortam_s or 1), 0.00, data[1]))
		self:UpdateBarOverlays(0.00)
	end

	if data[31] then
		if not UnitChannelInfo("player") then
			spelllist[self.tag] = nil --ClearTag(self.tag)
			SortBars('Update:UnitChannelInfo')
			return
		end
	end
	
	if data[1] ~= 0 and data[2] ~= 0 and data[2] < gettime then			
		if C.db.profile.delayfading then
			if data[13] == NO_FADE then
				data[13] = DO_FADE
				data[15] = gettime + C.db.profile.delayfading_wait										
				data[16] = data[15] + C.db.profile.delayfading_outanim	
				
				if spelllist[self.tag] then
					spelllist[self.tag][13] = DO_FADE
					spelllist[self.tag][15] = gettime + C.db.profile.delayfading_wait	
					spelllist[self.tag][16]	= spelllist[self.tag][16] + C.db.profile.delayfading_outanim	
				end
				
				OnTimerEnd(self.tag)
			end
		elseif data[13] ~= FADED then
			data[13] = FADED
			OnTimerEnd(self.tag) 
			if spelllist[self.tag] then
				spelllist[self.tag][13] = FADED
			end
			SortBars('Update:FADED')
		end
	end
end

local function Fading(self, gettime)
	if not C.db.profile.delayfading then 
		self:Restore()
		return 
	end
	
	local data = self.data --self.tag and spelllist[self.tag] or nil	
--	if not data then return end

	if data[36] == DO_FADE_RED then
		self.bar:SetStatusBarColor(1, 0, 64/255, 1)
	else
		local cColor = C:GetColor(data[5], data[14]) or self.opts.bar.color
		
		self.bar:SetStatusBarColor(cColor[1],cColor[2],cColor[3],cColor[4] or 1)
	end
	--[[
	
			-- [15] time when fading start
			-- [16] time when fading end
	]]

--	print('Fading in', data[13], data[15])
	
	if ( data[13] == DO_FADE_UNLIMIT or data[13] == DO_FADE ) and data[15] < gettime then --and data[15] < gettime 
		self:FadeOut(gettime)
--		print('Fading elseif 3')
	elseif data[13] == NO_FADE then
		self:Restore()
--		print('Fading elseif 2')
	else
--		print('Fading elseif 1')
	end
end

local function bgFade(self, gettime)	
	if not C.db.profile.background_fading then return end
	local data = self.data --self.tag and spelllist[self.tag] or nil	
--	if not data then return end
	
	local dur = data[2] - gettime
	local cur = data[1]*0.2
	
	if cur > 5 then cur = 5 end
	if dur > cur then 
		self.fade_in_out_bg:Hide()
		self.fade_in_out_anim:Stop()
		return 
	end
	
	if dur <= 0 then return end
	
	if not self.fade_in_out_anim:IsPlaying() then				
		local m = dur/cur
		
		if m < .35 then m = .35 end
		
		self.fade_in_out_anim.a1:SetDuration(0.6*m)
		self.fade_in_out_anim.a2:SetDuration(0.6*m)
		
		self.fade_in_out_bg:Show()
		self.fade_in_out_anim:Play()
	end
end

local function OnUpdateText(self, elapsed, gettime)
	local data = self.data

	self.__elapsed = ( self.__elapsed or 0 ) + elapsed

	if self.__elapsed > 0.1 then
		self.__elapsed = 0
		self:SetCount(nil, 'C')
		
		if data[23] then
			self.spellText:SetText(C.CustomTextCreate(self))
		end
	end
end

local function OnApplyShine(self, elapsed)
	local opt = self.opts
	if not opt.shine_on_apply then return end

end

local function ShineTick(self, data) -- timeOut)	
	if not data[24] or data[24] < GetTime() then
		data[24] = GetTime()+data[27]
	--	self.bar.spark.shine:Play()
	end
end

do
	local trottle = 0

	local newOnUpdate = CreateFrame("Frame", "SPTimersNewOnUpdate")	
	
	local function newOnUpdateHandler(self, elapsed)
		local curtime = GetTime()
		local updlbl = false
		
	--	trottle = trottle + elapsed
	--	if trottle < 0.03 then return end
	--	trottle = 0
		
		for i=1, #anchors do
			if anchors[i].disabled ~= true then
				for b=1, #anchors[i].bars do 
					if ( anchors[i].bars[b].inUse) then
						anchors[i].bars[b]:OnUpdateText(elapsed, curtime)
						anchors[i].bars[b]:Update(curtime)
						anchors[i].bars[b]:Fading(curtime)
						anchors[i].bars[b]:bgFade(curtime)		
					--	anchors[i].bars[b]:OnApplyShine(curtime)
						updlbl = true
					end
				end
			end
		end
		
		if not updlbl then		
			self:Hide()
			return
		end
		
		if updlbl then C:NewUpdateLabels() end
	end

	newOnUpdate:SetScript("OnUpdate", newOnUpdateHandler)

	C.newOnUpdate = newOnUpdate
	C.newOnUpdate.handler = newOnUpdateHandler
end

function C.GetBar(anchor)

	local f =  CreateFrame("Frame", nil, anchor)
	f.parent = anchor
	f.opts = anchor.opts
	f.disabled = true
	f.__resize = 1
	f.tiks = {}

	local opt = f.opts
	
	f:SetSize(opt.w,opt.h)

	local b1 = f:CreateTexture(nil, "BACKGROUND", nil, 0)
	b1:SetPoint("TOP", f, "TOP")
	b1:SetPoint("BOTTOM", f, "BOTTOM")
	b1:SetPoint("LEFT", f, "LEFT")
	b1:SetPoint("RIGHT", f, "RIGHT")
	
	b1:SetColorTexture(1,0,0,0)

	local sb = CreateFrame("StatusBar", nil, f)
	sb:SetStatusBarTexture("Interface\\ChatFrame\\ChatFrameBackground")
	sb:SetMinMaxValues(0,1)
	
	local sbt = sb:GetStatusBarTexture()
--	sbt:SetDrawLayer("ARTWORK", 0)
	
	local barShine = sb:CreateTexture(nil, "ARTWORK", nil, 5)
	barShine:SetAllPoints(sb)
	barShine:SetColorTexture(1, 1, 1)
	barShine:SetAlpha(0)
	
	local barShine_ag = barShine:CreateAnimationGroup()
	local barShine_ag_a1 = barShine_ag:CreateAnimation("Alpha")
	barShine_ag_a1:SetFromAlpha(0)
	barShine_ag_a1:SetToAlpha(0.5)
	barShine_ag_a1:SetDuration(0.2)
	barShine_ag_a1:SetOrder(1)
	
	local barShine_ag_a2 = barShine_ag:CreateAnimation("Alpha")
	barShine_ag_a2:SetFromAlpha(0.5)
	barShine_ag_a2:SetToAlpha(0)
	barShine_ag_a2:SetDuration(0.4)
	barShine_ag_a2:SetOrder(2)
	
	
	local bb1 = sb:CreateTexture(nil, "BACKGROUND", nil, 0)
	bb1:SetAllPoints(sb)
	
	local bg1 = CreateFrame("Frame", nil, f)
	bg1:SetParent(f)
	
	local b = sb:CreateTexture(nil, "BACKGROUND", nil, 0)
	b:SetAllPoints()
	b:SetColorTexture(0,0,0,0)
	
	local fade_in_out = sb:CreateTexture(nil,"BORDER", 0)
	fade_in_out:SetAllPoints(sb)
	fade_in_out:Hide()
	fade_in_out:SetAlpha(0)
	
	local fade_in_out_ag = fade_in_out:CreateAnimationGroup()
	local fade_in_out_ag_a1 = fade_in_out_ag:CreateAnimation("Alpha")
	fade_in_out_ag_a1:SetFromAlpha(0)
	fade_in_out_ag_a1:SetToAlpha(0.8)
	fade_in_out_ag_a1:SetDuration(0.6)
	fade_in_out_ag_a1:SetOrder(1)
	
	local fade_in_out_ag_a2 = fade_in_out_ag:CreateAnimation("Alpha")
	fade_in_out_ag_a2:SetFromAlpha(0.8)
	fade_in_out_ag_a2:SetToAlpha(0)
	fade_in_out_ag_a2:SetDuration(0.6)
	fade_in_out_ag_a2:SetOrder(2)
		
	local libf = CreateFrame("Frame",nil, sb)

	local bg2 = CreateFrame("Frame", nil, libf)
	
	local stacktext = bg2:CreateFontString(nil, "ARTWORK");
	
	bg2:SetParent(libf)

	local libft = libf:CreateTexture(nil,"ARTWORK")
	libft:SetSize(opt.h,opt.h)
	libft:SetTexCoord(.1, .9, .1, .9)
	libft:SetAllPoints(libf)
	
	local ribf = CreateFrame("Frame",nil, sb)

	local bg3 = CreateFrame("Frame", nil, ribf)
	
	local stacktext2 = bg3:CreateFontString(nil, "OVERLAY")
	
	local ribft = ribf:CreateTexture(nil,"ARTWORK")
	ribft:SetSize(opt.h,opt.h)
	ribft:SetTexCoord(.1, .9, .1, .9)
	ribft:SetAllPoints(ribf)

	local ft_l = sb:CreateFontString(nil, "ARTWORK");
	ft_l:SetJustifyV("CENTER")

	local ft_r = sb:CreateFontString(nil, "ARTWORK");
	ft_r:SetJustifyV("CENTER")

	local rit = sb:CreateTexture(nil,"ARTWORK", nil, 6)
	rit:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
	
	local pandemi = sb:CreateTexture(nil, "ARTWORK", nil, 3)
	pandemi:SetAlpha(0.9)
	pandemi:SetWidth(2)
	pandemi:SetHeight(opt.h*1.8)
	pandemi:Hide()
	
	local sp1 = CreateFrame("Frame",nil,sb)
	sp1:SetParent(sb)
	sp1:SetWidth(1)
	sp1:SetHeight(f:GetHeight()*0.7)
	sp1:SetFrameLevel(4)
	sp1:SetAlpha(1)
	--[==[
	sp1:SetPoint("TOPLEFT",sb,"TOPLEFT", 10, 0)
	sp1:SetPoint("BOTTOMLEFT",sb,"BOTTOMLEFT", 10, 0)
	sp1:SetPoint('LEFT', sbt, 'LEFT', 0, 0)
	]==]

	local sp2 = CreateFrame("Frame",nil,sb)
	sp2:SetParent(sb)
	sp2:SetWidth(1)
	sp2:SetHeight(f:GetHeight()*0.9)
	sp2:SetFrameLevel(4)
	sp2:SetAlpha(1)

	sp2:SetPoint("TOPLEFT",sb,"TOPLEFT", 10, 0)
	sp2:SetPoint("BOTTOMLEFT",sb,"BOTTOMLEFT", 10, 0)
	
	local spark = sb:CreateTexture(nil, "ARTWORK", nil, 3)
	spark.parent = sp1

	local shine = sb:CreateTexture(nil, "ARTWORK", nil, 4)
	shine.parent = sp1

	local ag = shine:CreateAnimationGroup()
	local a1 = ag:CreateAnimation("Alpha")	
	a1:SetFromAlpha(0)
	a1:SetToAlpha(1)
	a1:SetDuration(0.1)
	a1:SetOrder(1)
	local a2 = ag:CreateAnimation("Alpha")
	a2:SetFromAlpha(1)
	a2:SetToAlpha(0)
	a2:SetDuration(0.1)
	a2:SetOrder(2)

	local overlay2 = sb:CreateTexture(nil, "ARTWORK", nil, 2)
	overlay2:SetColorTexture(1,1,1,1)	
	overlay2:SetWidth(20)
	overlay2:Hide()		
	overlay2:SetPoint("TOPLEFT",sp2,"TOPLEFT",0,0)
	overlay2:SetPoint("BOTTOMLEFT",sp2,"BOTTOMLEFT",0,0)
		
	f.raidMark = rit		
	f.fade_in_out_bg = fade_in_out
	f.fade_in_out_anim = fade_in_out_ag
	f.fade_in_out_anim.a1 = fade_in_out_ag_a1
	f.fade_in_out_anim.a2 = fade_in_out_ag_a2	
	f.background1 = b1	
	f.background = b
	f.bar = sb
	f.barShine = barShine
	f.barShine_ag = barShine_ag
	f.bar.bg = bg1
	f.bar.bg2 = bb1
	f.bar.texture = sbt
	f.bar.overlay2 = overlay2	
	f.bar.spark = spark
	f.bar.spark.shine = ag		
	f.bar.shine = shine	
	f.bar.pandemi = pandemi
	
	f.bar.sp1 = sp1
	f.bar.sp2 = sp2
	
	f.icon = libf
	f.icon.bg = bg2
	f.icon.texture = libft
	f.icon.stacktext = stacktext
	
	f.icon2 = ribf
	f.icon2.bg = bg3
	f.icon2.texture = ribft
	f.icon2.stacktext = stacktext2
	
	f.timeText = ft_r
	f.spellText = ft_l
	f.bar.frame = f
	
	f.Restore 				= Restore	
	f.FadeOut 				= FadeOut	
	f.Update 				= Update	
	f.Fading 				= Fading	
	f.bgFade 				= bgFade
	f.OnUpdateText			= OnUpdateText
	f.UpdateBarColor		= UpdateBarColor	
	f.Resize 				= Resize
	f.OnApplyShine			= OnApplyShine
	f.ShineTick				= ShineTick
	
	f.UpdateStackText 		= C.UpdateStackText
	f.UpdateTimeText 		= C.UpdateTimeText
	f.UpdateSpellText 		= C.UpdateSpellText
	f.UpdateBorder 			= C.UpdateBorder
	f.UpdateTick_Color 		= C.UpdateTick_Color
	f.UpdateSpark_Color 	= C.UpdateSpark_Color
	f.UpdateBarSize			= C.UpdateBarSize
	f.UpdateRaidIcon		= C.UpdateRaidIcon
	f.UpdateIcons			= C.UpdateIcons	
	f.UpdateBarOverlays		= C.OnValueChanged	
	f.UpdateStyle 			= C.UpdateStyle
	f.SetMark				= C.SetMark
	f.SetCount				= C.SetCount
	f.BarTextUpdate 		= C.BarTextUpdate

	return f
end