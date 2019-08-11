local addon, C = ...

local libS = LibStub:GetLibrary("AceSerializer-3.0")

local sptimersPattern = "(SPTimersSTART)(.+)::"
local sptimersStart = "SPTimersSTART(".. GetAddOnMetadata("SPTimers", "Version") ..")::"
local sptimersEnd   = "::SPTimersEND"

local function validate(str)

	local done, version = string.match(str,sptimersPattern)
	return done, version
end

local docompress = true --false


--WA B64

local table_concat = table.concat
local string_byte = string.byte
local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift
local fmt, tostring, string_char, strsplit = string.format, tostring, string.char, strsplit

local bytetoB64 = {
    [0]="a","b","c","d","e","f","g","h",
    "i","j","k","l","m","n","o","p",
    "q","r","s","t","u","v","w","x",
    "y","z","A","B","C","D","E","F",
    "G","H","I","J","K","L","M","N",
    "O","P","Q","R","S","T","U","V",
    "W","X","Y","Z","0","1","2","3",
    "4","5","6","7","8","9","(",")"
}

local B64tobyte = {
      a =  0,  b =  1,  c =  2,  d =  3,  e =  4,  f =  5,  g =  6,  h =  7,
      i =  8,  j =  9,  k = 10,  l = 11,  m = 12,  n = 13,  o = 14,  p = 15,
      q = 16,  r = 17,  s = 18,  t = 19,  u = 20,  v = 21,  w = 22,  x = 23,
      y = 24,  z = 25,  A = 26,  B = 27,  C = 28,  D = 29,  E = 30,  F = 31,
      G = 32,  H = 33,  I = 34,  J = 35,  K = 36,  L = 37,  M = 38,  N = 39,
      O = 40,  P = 41,  Q = 42,  R = 43,  S = 44,  T = 45,  U = 46,  V = 47,
      W = 48,  X = 49,  Y = 50,  Z = 51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,
    ["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["("]=62,[")"]=63
}

--This code is based on the Encode7Bit algorithm from LibCompress
--Credit goes to Galmok of European Stormrage (Horde), galmok@gmail.com
local encodeB64Table = {};

local function enc(str)
    local B64 = encodeB64Table;
    local remainder = 0;
    local remainder_length = 0;
    local encoded_size = 0;
    local l=#str
    local code
    for i=1,l do
        code = string_byte(str, i);
        remainder = remainder + bit_lshift(code, remainder_length);
        remainder_length = remainder_length + 8;
        while(remainder_length) >= 6 do
            encoded_size = encoded_size + 1;
            B64[encoded_size] = bytetoB64[bit_band(remainder, 63)];
            remainder = bit_rshift(remainder, 6);
            remainder_length = remainder_length - 6;
        end
    end
    if remainder_length > 0 then
        encoded_size = encoded_size + 1;
        B64[encoded_size] = bytetoB64[remainder];
    end
    return table_concat(B64, "", 1, encoded_size)
end

local decodeB64Table = {}

local function dec(str)
    local bit8 = decodeB64Table;
    local decoded_size = 0;
    local ch;
    local i = 1;
    local bitfield_len = 0;
    local bitfield = 0;
    local l = #str;
    while true do
        if bitfield_len >= 8 then
            decoded_size = decoded_size + 1;
            bit8[decoded_size] = string_char(bit_band(bitfield, 255));
            bitfield = bit_rshift(bitfield, 8);
            bitfield_len = bitfield_len - 8;
        end
        ch = B64tobyte[str:sub(i, i)];
        bitfield = bitfield + bit_lshift(ch or 0, bitfield_len);
        bitfield_len = bitfield_len + 6;
        if i > l then
            break;
        end
        i = i + 1;
    end
    return table_concat(bit8, "", 1, decoded_size)
end

	
	
	local copy_w, copy_h = 500, 300
	
	local copyframe = CreateFrame("Frame", nil, UIParent)
	copyframe:SetPoint("CENTER")
	copyframe:SetSize(copy_w, copy_h)
	
	copyframe.Scroll = CreateFrame("ScrollFrame", "SPTimersScrollFrame", copyframe, "UIPanelScrollFrameTemplate")
	copyframe.Scroll:SetFrameLevel(copyframe:GetFrameLevel() + 1)
	copyframe.Scroll:SetSize(copy_w, copy_h)
	copyframe.Scroll:SetPoint("TOPRIGHT", copyframe, "TOPRIGHT", -2, -2)
	copyframe.Scroll:SetPoint("BOTTOMLEFT", copyframe, "BOTTOMLEFT", 2, 2)
	copyframe.Scroll:SetClipsChildren(true)
	
	copyframe.Scroll.ScrollBar:SetParent(copyframe)	
	copyframe.Scroll.ScrollBar:SetScript('OnValueChanged', function(self, value)
		copyframe.Scroll:SetVerticalScroll(value);
	end)
	
	copyframe.editBox = CreateFrame("EditBox", nil, UIParent)
	copyframe.editBox:SetPoint('TOPLEFT', copyframe.Scroll, "TOPLEFT", 2, 1)
	copyframe.editBox:SetSize(copy_w, copy_h)
	
	copyframe.Scroll:SetScrollChild(copyframe.editBox)
	copyframe.Scroll:SetHorizontalScroll(-5)
	copyframe.Scroll:SetVerticalScroll(0)
	copyframe.Scroll:EnableMouse(true)
	
	copyframe.editBox:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
	copyframe.editBox:SetFrameLevel(copyframe:GetFrameLevel() + 1)
	copyframe.editBox:SetAutoFocus(false)
	copyframe.editBox:SetMultiLine(true)
	copyframe.editBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	copyframe:Hide()
	copyframe:SetBackdrop({
			bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
			edgeFile = [=[Interface\ChatFrame\ChatFrameBackground]=], --[=[Interface\ChatFrame\ChatFrameBackground]=]
			edgeSize = 1,
		})
	copyframe:SetBackdropColor(0 , 0 , 0 , 0.7) --цвет фона
	copyframe:SetBackdropBorderColor(1 , 1 , 1 , 1) --цвет фона
	
	copyframe.button = CreateFrame("Button",nil,copyframe)
	copyframe.button:SetPoint('TOP', copyframe, 'BOTTOM', 130, -10)
	copyframe.button:SetWidth(100)
	copyframe.button:SetHeight(20)
	
	copyframe.button.fs = copyframe.button:CreateFontString()
	copyframe.button.fs:SetPoint("CENTER")
	copyframe.button.fs:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
	copyframe.button.fs:SetText("Import")
	
	copyframe.button:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
	copyframe.button:GetNormalTexture():SetVertexColor(0,0,0,1)
	copyframe.button:SetScript("OnClick", function(self) copyframe:Hide(); copyframe.editBox:ClearFocus(); C:DeserializeImport() end)
	copyframe.button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", insets = {top = -2, left = -2, bottom = -2, right = -2}})
	copyframe.button:SetBackdropColor(0, 0, 0, 1)
	copyframe.button:SetHighlightTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	copyframe.button:Show()
	
	
	copyframe.button2 = CreateFrame("Button",nil,copyframe)
	copyframe.button2:SetPoint('TOP', copyframe, 'BOTTOM', -130, -10)
	copyframe.button2:SetWidth(100)
	copyframe.button2:SetHeight(20)
	
	copyframe.button2.fs = copyframe.button2:CreateFontString()
	copyframe.button2.fs:SetPoint("CENTER")
	copyframe.button2.fs:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
	copyframe.button2.fs:SetText("Select All")
	
	copyframe.button2:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
	copyframe.button2:GetNormalTexture():SetVertexColor(0,0,0,1)
	copyframe.button2:SetScript("OnClick", function(self) copyframe.editBox:HighlightText(0) end)
	copyframe.button2:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", insets = {top = -2, left = -2, bottom = -2, right = -2}})
	copyframe.button2:SetBackdropColor(0, 0, 0, 1)
	copyframe.button2:SetHighlightTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	copyframe.button2:Show()
	
	copyframe.button3 = CreateFrame("Button",nil,copyframe)
	copyframe.button3:SetPoint('TOP', copyframe, 'BOTTOM', 0, -10)
	copyframe.button3:SetWidth(100)
	copyframe.button3:SetHeight(20)
	
	copyframe.button3.fs = copyframe.button3:CreateFontString()
	copyframe.button3.fs:SetPoint("CENTER")
	copyframe.button3.fs:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
	copyframe.button3.fs:SetText("Close")
	
	copyframe.button3:SetNormalTexture("Interface\\Buttons\\WHITE8x8")
	copyframe.button3:GetNormalTexture():SetVertexColor(0,0,0,1)
	copyframe.button3:SetScript("OnClick", function(self) copyframe:Hide(); copyframe.editBox:ClearFocus(); AleaUI_GUI:Open(addon) end)
	copyframe.button3:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", insets = {top = -2, left = -2, bottom = -2, right = -2}})
	copyframe.button3:SetBackdropColor(0, 0, 0, 1)
	copyframe.button3:SetHighlightTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	copyframe.button3:Show()

	
function C:ExportProfile()
	local data1
	
	if docompress then
	
		local data3 = sptimersStart..libS:Serialize(self.db.profile)
		
	--	local data2 = libC:Compress(data3)
		
		data1 = enc(data3) -- libCE:Encode(data2)
	
		
	else

		data1 = sptimersStart..libS:Serialize(self.db.profile)
	end
	
	copyframe:Show()

	AleaUI_GUI:Close(addon)
	
	copyframe.editBox:SetText(data1)
	
	copyframe.editBox:HighlightText(0)
	
	copyframe.editBox:SetFocus()
	
	copyframe.button3:Show()
	copyframe.button2:Show()
	copyframe.button:Hide()
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
	
function C:DeserializeImport()
	
	local final_d = nil
	local done1, version = nil, nil
	
	if docompress then
	
		local data3 = copyframe.editBox:GetText()
		
		
	--	local data2 = libCE:Decode(data3)

		local data1, message = dec(data3) -- libC:Decompress(data2)
		
	--	dec(data)
		
		if(not data1) then
			print("SPTimers: error decompressing: " .. message)
			return
		end
		
		done1, version = validate(data1)
	
		if done1 then		
			data1:gsub(sptimersPattern, "")
		else
			self.message('Can not validate this import')
			return
		end
		
		local done, final = libS:Deserialize(data1)
		
		if (not done) then
			print("SPTimers: error deserializing " .. final)
			return
		end
		
		final_d = final
	else
		local data3 = copyframe.editBox:GetText()
		
		done1, version = validate(data3)
	
		if done1 then		
			data3:gsub(sptimersPattern, "")
		else
			self.message('Can not validate this import')
			return
		end
		
		
		local done, final = libS:Deserialize(data3)
		if (not done) then
			print("SPTimers: error deserializing " .. final)
			return
		end
		
		final_d = final
	end
	
	if ( final_d ) then
		local gentime = date("%H:%M:%S %a%b%d")

		for name,datas in pairs(final_d.internal_cooldowns) do		
			if datas.spellid then				
				if GetSpellInfo(datas.spellid) == nil or GetSpellInfo(datas.spellid) == "" then					
					final_d.internal_cooldowns[name] = nil					
				else					
					if GetSpellInfo(datas.spellid) ~= name then									
						final_d.internal_cooldowns[GetSpellInfo(datas.spellid)] = deepcopy(datas)					
						final_d.internal_cooldowns[name] = nil
					end
				end
			else
				final_d.internal_cooldowns[name] = nil
			end
		end
		
		for name,datas in pairs(final_d.cooldownline.block) do		
			if datas.spellid then				
				if GetSpellInfo(datas.spellid) == nil or GetSpellInfo(datas.spellid) == "" then					
					final_d.cooldownline.block[name] = nil					
				else					
					if GetSpellInfo(datas.spellid) ~= name then									
						final_d.cooldownline.block[GetSpellInfo(datas.spellid)] = deepcopy(datas)					
						final_d.cooldownline.block[name] = nil
					end
				end
			elseif datas.itemid then
				if GetItemInfo(datas.itemid) == nil or GetItemInfo(datas.itemid) == "" then					
					final_d.cooldownline.block[name] = nil					
				else					
					if GetItemInfo(datas.itemid) ~= name then									
						final_d.cooldownline.block[GetItemInfo(datas.itemid)] = deepcopy(datas)					
						final_d.cooldownline.block[name] = nil
					end
				end				
			else
				final_d.cooldownline.block[name] = nil
			end
		end
		
		for class, datas in pairs(final_d.classCooldowns) do
			
			for name,datas2 in pairs(datas) do
				
				if datas2.spellid then
					if GetSpellInfo(datas2.spellid) == nil or GetSpellInfo(datas2.spellid) == "" then					
						final_d.classCooldowns[class][name] = nil					
					else					
						if GetSpellInfo(datas2.spellid) ~= name then									
							final_d.classCooldowns[class][GetSpellInfo(datas2.spellid)] = deepcopy(datas)					
							final_d.classCooldowns[class][name] = nil
						end
					end
				else
					final_d.classCooldowns[class][name] = nil
				end
			end
		end
		
		
		for k,v in pairs(final_d.procSpells) do
			if GetSpellInfo(k) == nil or GetSpellInfo(k) == "" then
			--	print("Wrong procSpells spellID", k)		
				final_d.procSpells[k] = nil
			end
		end
		
		for k,v in pairs(final_d.othersSpells) do
			if GetSpellInfo(k) == nil or GetSpellInfo(k) == "" then
			--	print("Wrong othersSpells spellID", k)			
				final_d.othersSpells[k] = nil
			end
		end
		
		for class, datas in pairs(final_d.classSpells) do
			
			for i, val in pairs(datas) do
				if GetSpellInfo(i) == nil or GetSpellInfo(i) == "" then
			--		print("Wrong classSpells spellID", i)			

					final_d.classSpells[class][i] = nil
				end				
			end
		end
	
		self.message('Imported to "Import - '..gentime..' v'..version)
		
		SPTimersDB.profiles["Import - "..gentime..' v'..version] = deepcopy(final_d)
	end
	
	AleaUI_GUI:Open(addon)
end

function C:ImportProfile(str)
	
	copyframe.editBox:SetText("")
	copyframe:Show()
	copyframe.editBox:SetFocus()
	
	AleaUI_GUI:Close(addon)
	
	copyframe.button3:Show()
	copyframe.button2:Hide()
	copyframe.button:Show()
end

local function CopyProfile()

	SPTimersDB2.profiles = deepcopy(SPTimersDB.profiles)
		
	SPTimersDB2.profileKeys = SPTimersDB2.profileKeys or {}
	
	for owner, profilekey in pairs(SPTimersDB.profileKeys) do
		SPTimersDB2.profileKeys[owner] = SPTimersDB2.profileKeys[owner] or {}
		for i=1, 2 do
			SPTimersDB2.profileKeys[owner][i] = profilekey
		end
	end
	
	SPTimersDB.imported = true

	ReloadUI()
end


local function CopyProfile2()

	SPTimersDB.profiles = deepcopy(SPTimersDB2.profiles)
		
	SPTimersDB.profileKeys = deepcopy(SPTimersDB2.profileKeys)
	
	SPTimersDB2 = nil
	
	ReloadUI()
end

function C:ImportProfilesFromV1()
	if not false then return end
	
	if SPTimersDB2 == nil then SPTimersDB2 = {} end
	
	if SPTimersDB and not SPTimersDB.imported then
		AleaUI_GUI.ShowPopUp(
		   "SPTimers", 
		   "Do you want to import profiles from previous version?", 
		   { name = "Yes", OnClick = function() CopyProfile() end}, 
		   { name = "No", OnClick = function() end}		   
		)		
		return
	end
	
	if SPTimersDB and SPTimersDB.imported then
		if SPTimersDB.deleteme == nil then
			AleaUI_GUI.ShowPopUp(
			   "SPTimers", 
			   "Do you want to delete profiles from previous version?", 
			   { name = "Yes", OnClick = function() SPTimersDB = nil; collectgarbage("collect"); end}, 
			   { name = "No", OnClick = function() SPTimersDB.deleteme = false end}			   
			)
		end
	end
end


function C:ImportProfilesFromV2()
	if not true then return end
	if SPTimersDB2 == nil then return end

	if SPTimersDB2 then
		AleaUI_GUI.ShowPopUp(
		   "SPTimers", 
		   'Do you want to |cFF00FF00IMPORT|r profiles from previous BETA version ( 3.0.1 - 3.0.7 )?', 
		   { name = "Yes", OnClick = function() CopyProfile2() end}, 
		   { name = "No", OnClick = function() SPTimersDB2 = nil; end}		   
		)		
		return
	end
	
end