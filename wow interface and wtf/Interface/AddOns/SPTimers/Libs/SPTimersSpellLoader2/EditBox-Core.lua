local addon, SPTimers = ...
local C = AleaUI_GUI
C.spellloadereditboxFrames = {}

C.DDSpellLoader = {}
local DD = C.DDSpellLoader
local NUM_BUTTONS = 10
local BUTTON_HEIGHT = 20
local BUTTON_WIDTH = 96
local LIST_NUM_VALUES = 0

DD.list = {}
DD.list_data = {}

local list = DD.list
local list_data = DD.list_data

local wipe = table.wipe
local SpellData = _G["SPTimersSpellLoader"]
local buttons = {}
local _
local table_sort = table.sort
local statearrow = C.statearrow
local dropdownFrame
local update 

local lastvalue

local searhText = "Searching..."

function DD.buildList(value)
	
	if value and lastvalue ~= value then
		lastvalue = value
	end

	local found, _, spellString = string.find(lastvalue, "^|c%x+|H(.+)|h%[.*%]")	
	if found then return end
	
	if tonumber(lastvalue) then return end
	
	local query = "^" .. string.lower(lastvalue)
	
	if not SpellData.loader then
		SpellData:StartLoading()
	end
	
	wipe(list)

	if SpellData.loader:IsShown() then
		list[#list+1] = searhText
	end
	
	for spellID, name in pairs(SpellData.spellList) do
		if string.match(name, query) and ( not DD.spellFilter or DD.spellFilter(nil, spellID) ) then
			list[#list+1] = spellID
		end
	end
	
	table.sort(list, function(x, y)
		if x == searhText then
			return true
		end
		if y == searhText then
			return false
		end
		
		if SPTimers:SearchSpell(x) and SPTimers:SearchSpell(y) then
			return x < y
		end
		
		if SPTimers:SearchSpell(x) then
			return true
		end
		
		if SPTimers:SearchSpell(y) then
			return false
		end
	
		return x > y
	end)
	
	LIST_NUM_VALUES = #list
end

function update(self)
	local numItems = #list
	local offset = 0

	if numItems <= NUM_BUTTONS then
		self:Hide()
	else
		self:Show()
		FauxScrollFrame_Update(self, numItems, NUM_BUTTONS, BUTTON_HEIGHT)
		offset = FauxScrollFrame_GetOffset(self)
	end

	for line = 1, NUM_BUTTONS do
		local lineplusoffset = line + offset
		local button = buttons[line]
		
		if lineplusoffset > numItems then
			button:Hide()
			button.select:Hide()
		else
			local name, desc = nil, nil
			local key = list[lineplusoffset]
			
			if key == searhText then
				button.text:SetText(key)
				button:Disable()
				button.spellID = nil
			else
				local spellName, spellRank, spellIcon = GetSpellInfo(key)
				local existsindb, dbtype = SPTimers:SearchSpell(key, true)
				
				existsindb = existsindb and "|cFF00FF00" or ""
				dbtype = dbtype and '"'..dbtype..'"' or ""
				
				if( spellRank and spellRank ~= "" ) then
					button.text:SetFormattedText("|T%s:12:12:0:0|t %s%s (%s) %s", spellIcon, existsindb, spellName, spellRank, dbtype)
				else
					button.text:SetFormattedText("|T%s:12:12:0:0|t %s%s %s", spellIcon, existsindb, spellName, dbtype)
				end
				button:Enable()
				button.spellID = key
			end
			button.select:Hide()
			button:Show()
			
			dropdownFrame:SetHeight(BUTTON_HEIGHT*line)
		end
	end
end



dropdownFrame = CreateFrame("Frame",  "SPTimersFontDropDownFrame"..C:GetNumFrames())
dropdownFrame:SetSize(300, 200)
dropdownFrame.bg = dropdownFrame:CreateTexture()
dropdownFrame.bg:SetAllPoints()
dropdownFrame.bg:SetColorTexture(0, 0,0, 0.8)
dropdownFrame:SetHeight(BUTTON_HEIGHT*NUM_BUTTONS)
dropdownFrame.Update = function(self)
	update(self.scrollFrame)
end

dropdownFrame.border1 = CreateFrame("Frame", nil, dropdownFrame)
dropdownFrame.border1:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", -10, 10)
dropdownFrame.border1:SetPoint("BOTTOMRIGHT", dropdownFrame, "BOTTOMRIGHT", 10, -10)
dropdownFrame.border1:SetBackdrop({
	bgFile = [[Interface\Buttons\WHITE8x8]],
	edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
	edgeSize = 22,
	insets = {
		left = 5,
		right = 5,
		top = 5,
		bottom = 5,
	}
})
dropdownFrame.border1:SetBackdropColor(0, 0, 0, 1)
dropdownFrame.border1:SetBackdropBorderColor(1, 1, 1, 1)

dropdownFrame.scrollFrame = CreateFrame("ScrollFrame", "SPTimersFontScrillingFrame"..C:GetNumFrames() , dropdownFrame, "FauxScrollFrameTemplate")

dropdownFrame.scrollFrame:SetWidth(BUTTON_WIDTH)
dropdownFrame.scrollFrame:SetFrameLevel(dropdownFrame:GetFrameLevel()+1)
dropdownFrame.scrollFrame:SetPoint("TOPRIGHT",dropdownFrame, "TOPRIGHT", -25, 0)
dropdownFrame.scrollFrame:SetPoint("TOPLEFT",dropdownFrame, "TOPLEFT", -25, 0)
dropdownFrame.scrollFrame:EnableMouse(true)
dropdownFrame.scrollFrame:SetMovable(true)
dropdownFrame.scrollFrame:SetVerticalScroll(0)
dropdownFrame.scrollFrame:RegisterForDrag("LeftButton")
dropdownFrame.scrollFrame:Show()
dropdownFrame.scrollFrame.scroll = 0
dropdownFrame.scrollFrame:SetClampedToScreen(true)
dropdownFrame.scrollFrame:SetHeight(BUTTON_HEIGHT*NUM_BUTTONS)
dropdownFrame.scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
	FauxScrollFrame_OnVerticalScroll(self, offset, BUTTON_HEIGHT, update)
end)
DD.dropdownFrame = dropdownFrame

dropdownFrame.scrollFrame.ScrollBar:GetThumbTexture():SetDrawLayer("OVERLAY", 1)
dropdownFrame.scrollFrame.ScrollBar:SetFrameLevel(dropdownFrame.scrollFrame:GetFrameLevel()+2)
dropdownFrame.scrollFrame.ScrollBar.bg = dropdownFrame.scrollFrame.ScrollBar:CreateTexture(nil, "OVERLAY")
dropdownFrame.scrollFrame.ScrollBar.bg:SetAllPoints()
dropdownFrame.scrollFrame.ScrollBar.bg:SetColorTexture(0, 0, 0, 0)

dropdownFrame.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
	local reduce = self.scroll-( BUTTON_HEIGHT * delta)

	if reduce < 0 then
		reduce = 0
	elseif reduce > self:GetVerticalScrollRange() then
		reduce = self:GetVerticalScrollRange()
	end
	self.scroll = reduce
	self:SetVerticalScroll(self.scroll)
end)

	
local function Spell_OnClick(self)

	dropdownFrame.parent:SetText(self.spellID or "")
	dropdownFrame.parent:SetCursorPosition(string.len(self.spellID) or 0)
	
	DD.HideFonts()
end

for i = 1, NUM_BUTTONS do	
	if not buttons[i] then
		local button = CreateFrame("Button", nil, dropdownFrame)
		button:SetFrameLevel(dropdownFrame.scrollFrame:GetFrameLevel()+1)
		if i == 1 then
			button:SetPoint("TOPLEFT", dropdownFrame, "TOPLEFT", 0, 0)
			button:SetPoint("TOPRIGHT", dropdownFrame, "TOPRIGHT", 0, 0)
		else
			button:SetPoint("TOPRIGHT", buttons[i - 1], "BOTTOMRIGHT")
			button:SetPoint("TOPLEFT", buttons[i - 1], "BOTTOMLEFT")
		end
		button:SetNormalFontObject("GameFontNormal")
		
		button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
		
		button.select = button:CreateTexture(nil, "OVERLAY",1)
		button.select:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
		button.select:SetSize(BUTTON_WIDTH*0.2, BUTTON_WIDTH*0.2)
		button.select:SetPoint("LEFT", button, "LEFT", 0, 0)
		button.select:Hide()

		button.mouseup = button:CreateTexture(nil, "OVERLAY",1)
		button.mouseup:SetColorTexture(1, 1, 0, 0.3)
		button.mouseup:SetPoint("LEFT", button.select, "LEFT", 0, 0)
		button.mouseup:SetPoint("TOP", button, "TOP", 0, -2)
		button.mouseup:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 2)
		button.mouseup:Hide()
		
		button.text = button:CreateFontString(nil, "OVERLAY",1)
		button.text:SetFontObject(GameFontHighlightSmall)
		button.text:SetWidth(250)
		button.text:SetHeight(14)
		button.text:SetJustifyH("LEFT")
		button.text:SetPoint("LEFT", button, "LEFT",3, 0)
		button.text:SetPoint("RIGHT", button, "RIGHT", -3, 0)
		
		button:SetScript("OnClick", Spell_OnClick)
		
		button:SetScript("OnEnter", function(self, ...)
			self.mouseup:Show()		
	
			if not self.spellID then return end
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetHyperlink("spell:"..self.spellID)		
			GameTooltip:Show()
				
		end)
		button:SetScript("OnLeave", function(self, ...)
			self.mouseup:Hide()
			GameTooltip:Hide()
		end)
		
		buttons[i] = button
	end
end

local function UpdateDD(f)

	dropdownFrame.scrollFrame.border = (f and f.border )
	dropdownFrame.scrollFrame.statusbar = (f and f.statusbar )
	
	update(dropdownFrame.scrollFrame)
	
	if #list <= NUM_BUTTONS then
		dropdownFrame.scrollFrame:Hide()
	else
		dropdownFrame.scrollFrame:Show()
	end
	

	local realparent = C:GetRealParent(f)
	dropdownFrame:SetParent(realparent)
	dropdownFrame:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", -2, -8)
	dropdownFrame:SetWidth( f:GetWidth() > 170 and f:GetWidth() or 170)
	
	dropdownFrame:SetFrameLevel(realparent:GetFrameLevel()+10)
	dropdownFrame:Show()
	dropdownFrame.parent = f
	
	C:FreeDropDowns(dropdownFrame)
end

DD.UpdateDD = UpdateDD

function DD.HideFonts()
	
	if dropdownFrame:IsShown() then
		dropdownFrame:Hide()
		dropdownFrame.parent = nil
		dropdownFrame.scrollFrame.checkedkey = nil
		dropdownFrame.scrollFrame.border = nil
		dropdownFrame.scrollFrame.statusbar = nil
	end
end

if C.AddToFreeDropDown then
C:AddToFreeDropDown(dropdownFrame, DD.HideFonts)
end

function DD.ShowFonts(f)
	C:FreeDropDowns(dropdownFrame)
	
	if dropdownFrame.parent and dropdownFrame.parent ~= f then
		UpdateDD(f)
	elseif dropdownFrame.parent then
		dropdownFrame:Hide()
		dropdownFrame.parent = nil
		dropdownFrame.scrollFrame.checkedkey = nil
		dropdownFrame.scrollFrame.border = nil
		dropdownFrame.scrollFrame.statusbar = nil
	else
		UpdateDD(f)
	end
end

local spellFilters


do
	local playerFilters = {}
	local filterCache = {}
	
	local tooltip = CreateFrame("GameTooltip")
	tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	for i=1, 6 do
		tooltip["TextLeft" .. i] = tooltip:CreateFontString()
		tooltip["TextRight" .. i] = tooltip:CreateFontString()
		tooltip:AddFontStrings(tooltip["TextLeft" .. i], tooltip["TextRight" .. i])
	end
	
	local frame
	
	local function loadPlayerSpells(self)
		table.wipe(playerFilters)
		for tab=2, GetNumSpellTabs() do
			local offset, numSpells  = select(3, GetSpellTabInfo(tab))
			for i=1, numSpells  do			
				if GetSpellBookItemInfo(i + offset, tab) then
					tooltip:SetSpellBookItem(i + offset, tab)
					local spellName, spellID = tooltip:GetSpell()				
					if( spellName ) then
						playerFilters[spellID] = true
					end
				end
			end
		end
	end
		
	local function spellFilter(self, spellID)
		if( filterCache[spellID] ~= nil ) then return filterCache[spellID] end
		
		-- Very very few auras are over 100 yard range, and those are generally boss spells should be able to get away with this
		if( select(6, GetSpellInfo(spellID)) > 100 ) then
			filterCache[spellID] = true
			return false
		end
		
		-- We look for a description tag, 99% of auras have a description tag indicating what they are
		-- so we don't find one, then it's likely a safe assumption that it is not an aura
		tooltip:SetHyperlink("spell:" .. spellID)
		for i=1, tooltip:NumLines() do
			local text = tooltip["TextLeft" .. i]
			if( text ) then
				local r, g, b = text:GetTextColor()
				r = math.floor(r + 0.10)
				g = math.floor(g + 0.10)
				b = math.floor(b + 0.10)
				
				-- Gold first text, it's a profession link
				if( i == 1 and ( r ~= 1 or g ~= 1 or g ~= 1 ) ) then
					filterCache[spellID] = false
					return false
				-- Gold for anything else and it should be a valid aura
				elseif( r ~= 1 or g ~= 1 or b ~= 1 ) then
					filterCache[spellID] = true
					return true
				end
			end
		end

		filterCache[spellID] = false
		return false
	end
	spellFilters = {
	
		["Player_EditBox_SPTimer"] = function(self, spellID)
			if( not frame ) then
				frame = CreateFrame("Frame")
				frame:RegisterEvent("SPELLS_CHANGED")
				frame:SetScript("OnEvent", loadPlayerSpells)
				loadPlayerSpells(frame)
			end
		
			return playerFilters[spellID]
		end,
		["Aura_EditBox_SPTimer"] = spellFilter,
		
		['Disabled'] = function(self)			
			return 'Disabled'
		end
	}

end

local function Update(self, panel, opts)
	
	self.free = false
	self:SetParent(panel)
	self:Show()	
	
	if opts.filterType == 'Disabled' then
		self.main.spellFilter = 'Disabled'
	else	
		self.main.spellFilter = spellFilters[opts.filterType or ""]
	end
	
	self:SetDescription(opts.desc)
	self:SetName(opts.name)	
	self:UpdateState(opts.set, opts.get)
	
end

local function Remove(self)
	self.free = true
	self:Hide()	
end

local function SetName(self, name)
	self.main._rname = name
	self.main.text:SetText(name)
end

local function SetDescription(self, text)
	self.main.desc = text
end

local function UpdateState(self, set, get)
	
	self.main._OnClick = set
	self.main._OnShow = get

	self.main:SetText(self.main._OnShow() or "")
end


if not SPTimersLinkParse then
	hooksecurefunc("ChatEdit_InsertLink", function(...) return _G.SPTimersLinkParse(...) end)
end

function _G.SPTimersLinkParse(text)
	for i = 1, #C.spellloadereditboxFrames do
		local frame = C.spellloadereditboxFrames[i]
		if frame and not frame.free and frame:IsVisible() and frame.main:HasFocus() then
		--	frame.main:Insert(text)
			frame.main:SetText(text)
			return true
		end
	end
end

local function EditBox_OnReceiveDrag(self)
	local type, data, subType, subData = GetCursorInfo()	
	if( type == "spell" ) then
		local name = GetSpellLink(subData)
		self:SetText(name)
		self.ok:Show()
		ResetCursor()
	elseif( type == "item" ) then
		self:SetText(subType)
		self.ok:Show()
		ResetCursor()
	end
end

local function CreateCore(parent)

	local f = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	f:SetFontObject(ChatFontNormal)
	f:SetFrameLevel(parent:GetFrameLevel() + 1)
	f:SetAutoFocus(false)
	f:SetWidth(160)
	f:SetHeight(20)
	
	f:SetScript('OnHide', function(self) 
		DD.HideFonts(self)
	end)
	f:SetScript("OnReceiveDrag", EditBox_OnReceiveDrag)
	
	f:SetScript("OnEditFocusGained", function(self)
		DD.ShowFonts(self)
		dropdownFrame:Hide()
	end)
	f:SetScript("OnEditFocusLost", function(self)
		DD.HideFonts(self)
	end)

	f:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
		self.ok:Hide()
		self:SetText(self._OnShow() or "")
		C:GetRealParent(self):RefreshData()	
	end)
	
	local text = f:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
	text:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 3 , 2)
	text:SetJustifyH("LEFT")
	
	local okbttm = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
	okbttm:SetFrameLevel(f:GetFrameLevel()+1)
	okbttm:SetSize(40,20)
	okbttm:SetPoint("RIGHT", f, "RIGHT", 0, 0)
	okbttm:Hide()
	
	okbttm:SetScript("OnClick", function(self)
		self:Hide()
		self:GetParent():ClearFocus()
		self:GetParent()._OnClick(_, self:GetParent():GetText())	
		C:GetRealParent(self):RefreshData()	
	end)
	
	okbttm.text = okbttm:CreateFontString(nil, 'OVERLAY', "GameFontNormalSmall")
	okbttm.text:SetPoint("CENTER", okbttm, "CENTER", 0 , 0)
	okbttm.text:SetTextColor(1, 0.8, 0)
	okbttm.text:SetText("OK")
	okbttm.text:SetJustifyH("CENTER")
	
	f:SetScript("OnTextChanged", function(self, userInput)	
		if userInput then
			self.ok:Show()
		end
	
	--	DD.ShowFonts(self:GetParent())
	
		local value = self:GetText()		

		if value == "" then return end
		if not value then return end		
		if value and value:find('|H') then 
			self.ok:Show()
			return 
		end
		
		
		if self.spellFilter ~= 'Disabled' then
			DD.spellFilter = self.spellFilter
	
			DD.buildList(value, self)
			DD.UpdateDD(self)
		end
	end)
	
	
	f.mouseover = CreateFrame("Frame", nil, f)
	f.mouseover:SetFrameLevel(f:GetFrameLevel()-1)
	f.mouseover:SetSize(1,1)
	f.mouseover:SetPoint("TOPLEFT", text, "TOPLEFT", -3, 3)
	f.mouseover:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 3, -3)
	f.mouseover:SetScript("OnEnter", function(self)	
		C.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "show")
	end)
	f.mouseover:SetScript("OnLeave", function(self)
		C.Tooltip(self, self:GetParent()._rname, self:GetParent().desc, "hide")
	end)
	
	
	f.ok = okbttm
	f.text = text
	
	return f
end

function C:CreateLoaderEditBox()
	
	for i=1, #C.spellloadereditboxFrames do
		if C.spellloadereditboxFrames[i].free then
			return C.spellloadereditboxFrames[i]
		end
	end
	
	local f = CreateFrame("Frame", nil, UIParent)
	f:SetSize(180, 40)
	f.free = true
	
	f.main = CreateCore(f)
	f.main:SetPoint("TOPLEFT", f, "TOPLEFT", 13, -15)
	f.main:SetPoint("RIGHT", f, "RIGHT", -8, 0)
	
	--[[
	local bg = f:CreateTexture()
	bg:SetAllPoints()
	bg:SetTexture(0.5, 1, 0.5, 1)
	]]
	
	f.Update = Update
	f.Remove = Remove
	f.SetName = SetName
	f.UpdateState = UpdateState
	f.SetDescription = SetDescription
	
	C.spellloadereditboxFrames[#C.spellloadereditboxFrames+1] = f
	
	return f
end
	
C.prototypes["spellloader"] = "CreateLoaderEditBox"