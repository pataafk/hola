local addon, ns = ...
local db
local backdrop, icon_backdrop = { }
local L = AleaUI_GUI.GetLocale("SPTimers")

local section, iconsize = 0, 0
local smed = ns.LSM
local sR = {}

local spellToItems = { gear={}, bags={} }
local lastItemUsed = {}

local function IsItemSpellCooldown(spellID)

    if ( spellToItems.gear[spellID] ) then
        return spellToItems.gear[spellID]
    end 

    if ( spellToItems.bags[spellID] ) then
        return spellToItems.bags[spellID]
    end 

    return false
end

local function SetLastItemUsed(spellID)
    lastItemUsed[spellID] = IsItemSpellCooldown(spellID)
end

-- debug print ------------------
local old_print = print
local print = function(...)
	if false then return end
	
	old_print("SPTimers-CooldownLine, ", ...)
end

local parent = ns.Parent
local mainframe = CreateFrame("Frame", "SPTimersCooldownLine", parent)
mainframe.OldAlpha = mainframe.SetAlpha
mainframe:SetClampedToScreen(true)


local eventFrame = CreateFrame('Frame')
--[==[
eventFrame:RegisterEvent('PET_BAR_UPDATE_COOLDOWN')
eventFrame:RegisterEvent('SPELL_UPDATE_COOLDOWN')
eventFrame:RegisterEvent('SPELLS_CHANGED')
eventFrame:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
eventFrame:RegisterEvent('PLAYER_TALENT_UPDATE')
eventFrame:RegisterEvent('RUNE_POWER_UPDATE')
eventFrame:RegisterEvent('BAG_UPDATE_COOLDOWN')
eventFrame:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player', '')
eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player", '')
]==]

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

	function DoBigSplash(frame)	
		local skip = false
		
		for i=1, #bigsplashparent.splashes do
			local f = bigsplashparent.splashes[i]
			if f.parent._texturePath == frame.parent._texturePath then
				skip = true
				break
			end
		end
	
        if not skip and not frame.splashing and db.slash_show then
			if ns:DoBigSplashCooldown( frame.parent.rawID) then return end

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
		
		if not skip and not frame.splashing and db.slash_show_small then
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

local SetValue, UpdateSettings

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
	local fs = ticks_f[num] or mainframe:CreateFontString(nil, "ARTWORK", 1)
	fs:SetFont(smed:Fetch("font", db.font), db.fontsize, db.fontflags)
	fs:SetTextColor(db.fontcolor.r, db.fontcolor.g, db.fontcolor.b, 0.5)
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

local function FakeSetAlpha(self)
	self:OldAlpha(0)
end

function UpdateSettings()
 
	if db.enabled then
		mainframe:Show()
        eventFrame:Show()	
        
        
        eventFrame:RegisterEvent('BAG_UPDATE_DELAYED')
        eventFrame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED')


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
        
        mainframe:ClearAllPoints()
		mainframe:SetPoint("CENTER", parent, "CENTER", db.x or 0, db.y or -240)
		
		ns.AddMoverButtons(mainframe, nil, "line", nil, true)
				
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
			if not ns.db.profile.locked then
				splashbigmover:EnableMouse(true)
				splashbigmover:Show()
			end
		else

			splashbigmover:EnableMouse(false)
			splashbigmover:Hide()
		end
		
		splashbigmover:ClearAllPoints()
		splashbigmover:SetPoint("CENTER", parent, "CENTER", db.slash_x, db.slash_y)
        
		ns.AddMoverButtons(splashbigmover, nil, "splash", true)
      
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
			eventFrame:UnregisterEvent("PET_BAR_UPDATE_COOLDOWN")
		else
			eventFrame:RegisterUnitEvent("PET_BAR_UPDATE_COOLDOWN")
			ns:PET_BAR_UPDATE_COOLDOWN()
		end
	
        eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
        ns:BAG_UPDATE_COOLDOWN()

		if db.hidefail then
			eventFrame:UnregisterEvent("UNIT_SPELLCAST_FAILED")
		else
			eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", "player", '')
		end
		
		eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player",'')
		
		if db.hideplay then
            eventFrame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
            eventFrame:UnregisterEvent("SPELL_UPDATE_CHARGES")
			eventFrame:UnregisterEvent("SPELLS_CHANGED")
			eventFrame:UnregisterEvent("ENCOUNTER_END")
		else
            eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
            eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
			eventFrame:RegisterEvent("SPELLS_CHANGED")
			eventFrame:RegisterEvent("ENCOUNTER_END")
			ns.RunCooldownCheck('START_UP')
		end
		
		if ( db.blood_runes and db.frost_runes and db.unholy_runes ) or ns.myCLASS ~= "DEATHKNIGHT" then
			eventFrame:UnregisterEvent("RUNE_POWER_UPDATE")
		elseif ns.myCLASS == "DEATHKNIGHT" then		
			eventFrame:RegisterEvent("RUNE_POWER_UPDATE")
		end
		
		if db.hidevehi then
			eventFrame:UnregisterEvent("UNIT_ENTERED_VEHICLE")
			eventFrame:UnregisterEvent("UNIT_EXITED_VEHICLE")			
			ns:UNIT_EXITED_VEHICLE()
		else
			eventFrame:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player", '')
			if UnitHasVehicleUI("player") then
				eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
				eventFrame:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player", '')
			end
		end
        
        ns.EnumirateCooldowns('Update')

        --[==[
		for _, frame in ipairs(cooldowns) do
			frame:Update()
		end
		
		for _, frame in ipairs(frames) do
			frame:Update()
		end
        ]==]
        ns:UpdateTooltip()
        
        ns:BAG_UPDATE_DELAYED()
        ns:PLAYER_EQUIPMENT_CHANGED()
	else
		eventFrame:UnregisterAllEvents()
        eventFrame:Hide()	
        mainframe:Hide()
	end
end

ns.UpdateSettings = UpdateSettings

function ns:InitCooldownLine()
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
    
    ns:BuildCooldownBlockList()

    UpdateSettings()
    
    ns:UnlockCooldownLine()
end

--[==[
    BAG_UPDATE_DELAYED
    PLAYER_EQUIPMENT_CHANGED
]==]

local isOnCD = false
local prevStacks = -1
local prevEndTime = -1

local spellsForCDCheck = {}
local recheckTimer = nil 

local function RecheckCDs()
    --old_print('RecheckCDs')
    eventFrame:GetScript('OnEvent')(eventFrame, 'SPELL_UPDATE_COOLDOWN')
end 

eventFrame:SetScript('OnEvent', function(self, event, ...) 

    --print(event, ...)

    if ( event == 'PLAYER_SPECIALIZATION_CHANGED' or event == 'PLAYER_TALENT_UPDATE' ) then
        --ns.RunCacheSpellBook()

    elseif ( event == 'SPELLS_CHANGED' ) then 
        --print(event, ...)

    elseif ( event == 'SPELL_UPDATE_COOLDOWN'  or event == 'SPELL_UPDATE_CHARGES' ) then
	
        --ns.RunCooldownCheck(event)

        --local spellID = FindBaseSpellByID(205351)
        local lowestCD = nil
        local currentTime = GetTime()

        for baseSpellID, spellInfo in pairs(spellsForCDCheck) do
            local spellID = spellInfo.spellID
            local startTime, duration, charges, maxCharges, isGCD, gcdStartTime, gcdDuration = ns.GetSpellCooldown_New(spellID)
       
            --old_print( spellID, (GetSpellInfo(spellID)), startTime, duration, charges, maxCharges, isGCD)

            if spellInfo.isOnCD and currentTime >= spellInfo.prevEndTime and ( maxCharges and charges == maxCharges or not maxCharges ) then
                spellInfo.isOnCD = false 
                spellInfo.prevStacks = nil 
                spellInfo.prevEndTime = nil 

                
                --old_print('RemoveCooldown:1', spellID, (GetSpellInfo(spellID)))
                
                ns.RemoveCooldown(spellID)
            elseif spellInfo.isOnCD and isGCD and spellInfo.prevEndTime > gcdStartTime+gcdDuration then
                --old_print('RemoveCooldown:3', spellID, (GetSpellInfo(spellID)))
                --old_print('    currentTime=', spellInfo.prevEndTime-currentTime, 'gcd=', spellInfo.prevEndTime - gcdStartTime+gcdDuration  )

                spellInfo.isOnCD = false 
                spellInfo.prevStacks = nil 
                spellInfo.prevEndTime = nil 

                ns.RemoveCooldown(spellID)
            elseif spellInfo.isOnCD and startTime == 0 and duration == 0 then
                spellInfo.isOnCD = false 
                spellInfo.prevStacks = nil 
                spellInfo.prevEndTime = nil 

                --old_print('RemoveCooldown:2', spellID, (GetSpellInfo(spellID)))

                ns.RemoveCooldown(spellID)
            elseif spellInfo.isOnCD and not isGCD and startTime and ( spellInfo.prevStacks ~= charges or spellInfo.prevEndTime ~= startTime+duration ) then
                spellInfo.prevStacks = charges
                spellInfo.prevEndTime = startTime+duration
                
                --old_print('UpdateCooldown:2', spellID, (GetSpellInfo(spellID)))

                ns.UpdateCooldown(spellID, duration, startTime)
            elseif not spellInfo.isOnCD and not isGCD and duration and duration >= 1.5 then 
                spellInfo.isOnCD = true
                spellInfo.prevStacks = charges
                spellInfo.prevEndTime = startTime+duration

                ns.AddCooldown(spellID, spellID, duration, startTime, nil, 'PLAYER_CD')
            elseif spellInfo.prevEndTime and currentTime >= spellInfo.prevEndTime then
                --old_print('Something happens', spellID, (GetSpellInfo(spellID)))               
            end 
            
            --[==[
            if ( startTime == 0 and duration == 0 ) or isGCD then 
                if ( spellInfo.isOnCD ) then 
                    spellInfo.isOnCD = false 
                    spellInfo.prevStacks = -1

                    ns.RemoveCooldown(spellID)
                end
            elseif ( not spellInfo.isOnCD and not isGCD ) then 
                spellInfo.isOnCD = true
                spellInfo.prevStacks = charges
                spellInfo.prevEndTime = startTime+duration

                ns.AddCooldown(spellID, spellID, duration, startTime, nil, 'PLAYER_CD')
            elseif ( spellInfo.prevStacks ~= charges and not isGCD) then 
                spellInfo.prevStacks = charges
                spellInfo.prevEndTime = startTime+duration
  
                ns.UpdateCooldown(spellID, duration, startTime)
            end 

            if ( spellInfo.isOnCD and startTime and duration and currentTime < spellInfo.prevEndTime  ) then 

                if ( spellInfo.prevEndTime ~= startTime+duration ) then 
                    spellInfo.prevEndTime = startTime+duration

                    ns.UpdateCooldown(spellID, duration, startTime)
                end
            elseif ( spellInfo.isOnCD and currentTime > spellInfo.prevEndTime ) then
                spellInfo.isOnCD = false 
                spellInfo.prevStacks = -1

                ns.RemoveCooldown(spellID)
            end
            ]==]

            if ( spellInfo.isOnCD ) then 
                if ( not lowestCD or lowestCD > spellInfo.prevEndTime ) then 
                    lowestCD = spellInfo.prevEndTime
                end
            end
        end

        if ( recheckTimer ) then
            recheckTimer:Cancel()
            recheckTimer = nil 
        --    old_print('Cancel timer')
        end 

        if ( lowestCD and (lowestCD-GetTime()) > 0 ) then 
        --    old_print('Run timer for', lowestCD-GetTime())
            recheckTimer = C_Timer.NewTimer(lowestCD-GetTime(), RecheckCDs)
        else 
        --    old_print('No lowestCD or', lowestCD and lowestCD-GetTime())
        end  

    elseif ( event == 'UNIT_SPELLCAST_SUCCEEDED' ) then
        local unitID, lineID, spellID1 = ...
        local _, _, _, _, _, spellID2 = strsplit('-', lineID)

        spellID2 = tonumber(spellID2)

        --old_print(spellID1, GetSpellInfo(spellID1), spellID2, (GetSpellInfo(spellID2)) )
     

        if (IsSpellKnown(spellID1) or IsSpellKnown(spellID2)) then
            local baseSpell = FindBaseSpellByID(spellID1)
            local cd, gcd = GetSpellBaseCooldown(baseSpell)
            local cd1, gcd1 = GetSpellBaseCooldown(spellID1)
            local charges, maxCharges = GetSpellCharges(spellID1)

            if ( cd > 0 or cd1 > 0 or ( maxCharges and maxCharges > 0 ) ) then
               
                --ns.CheckCooldown(spellID1, spellID2)

                spellsForCDCheck[baseSpell] = spellsForCDCheck[baseSpell] or {
                    isOnCD = false,
                    prevStacks = -1,
                    prevEndTime = -1,
                    spellID = spellID1,
                }

                spellsForCDCheck[baseSpell].spellID = spellID1
            else
                local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID1)
                local spellCount = GetSpellCount(spellID1);

                --old_print('CheckCooldown', GetSpellInfo(spellID1), spellID1, baseSpell,cd, gcd, cd1, gcd1)
                --old_print(charges, maxCharges, spellCount)
            end
        --    old_print(baseSpell, spellID1, spellID2)
        elseif ( IsItemSpellCooldown(spellID1) ) then

            --print('SetLastItemUsed', spellID1)
            SetLastItemUsed(spellID1)
        end
     
    elseif ( event == 'RUNE_POWER_UPDATE' ) then
        if ( not self.runeCheck ) then
            self.runeCheck = GetTime()
        end
    elseif ( event == 'BAG_UPDATE_COOLDOWN' ) then
        ns:BAG_UPDATE_COOLDOWN()
    elseif ( event == 'UNIT_SPELLCAST_FAILED') then
        --print(event, ...)
        local unit, castGUID, spellID = ...


        local info = lastItemUsed[spellID]

        if ( info ) then 
            ns.GlowCooldown('ITEM:'..info.itemID)
        else 
            ns.GlowCooldown(spellID)
        end
    elseif ( event == 'PET_BAR_UPDATE_COOLDOWN' ) then 
        ns:PET_BAR_UPDATE_COOLDOWN()

    elseif ( event == 'UNIT_ENTERED_VEHICLE' ) then 
        ns:UNIT_ENTERED_VEHICLE()
    elseif ( event == 'UNIT_EXITED_VEHICLE' ) then 
        ns:UNIT_EXITED_VEHICLE()
    elseif ( event == 'ACTIONBAR_UPDATE_COOLDOWN' ) then
        ns:ACTIONBAR_UPDATE_COOLDOWN()
    elseif ( event == 'BAG_UPDATE_DELAYED' ) then
        ns:BAG_UPDATE_DELAYED()
    elseif ( event == 'PLAYER_EQUIPMENT_CHANGED' ) then 
        ns:PLAYER_EQUIPMENT_CHANGED()
    end
end)
eventFrame:SetScript('OnUpdate', function(self) 

    if ( self.endTime ) then
        if self.endTime+0.05 < GetTime() then
            self.endTime = nil

            --print('Run check')

            for spellID1, spellID2 in pairs( self.delayCDCheck ) do
                self.delayCDCheck[spellID1] = nil
                ns.RunCheck(spellID1, spellID2) 
            end

            ns.CheckCooldownList('onupdate')
        end
    end

    if ( self.checkCD ) then
        if self.checkCD+0.05 < GetTime() then
            self.checkCD = nil

            --print('Run cd check')

            for spellID1, spellID2 in pairs( self.delayCDCheck ) do
                self.delayCDCheck[spellID1] = nil
                ns.RunCheck(spellID1, spellID2) 
            end
        end
    end

    if ( self.runeCheck ) then 
        if self.runeCheck+0.05 < GetTime() then
            self.runeCheck = nil

            --print('Rune check')

            for runeIndex=1, 6 do
                local startTime, duration, runeReady = GetRuneCooldown(runeIndex);
    
                if ( runeReady ) then
                    ns.RemoveCooldown('rune'..runeIndex)
                else
                    if ( not startTime ) then
                        return
                    end    
                    ns.AddCooldown(
                        'rune'..runeIndex,
                        nil, 
                        duration, 
                        startTime, 
                        "Interface\\PlayerFrame\\UI-PlayerFrame-Deathknight-SingleRune",
                        "RuneDeath"
                    )
                end
            end
        end
    end

    if ( self.checkItems ) then 
        if self.checkItems+0.05 < GetTime() then
            self.checkItems = nil

            ns:BAG_UPDATE_COOLDOWN(true)
        end
    end

    if ( self.checkPet ) then 
        if self.checkPet+0.05 < GetTime() then
            self.checkPet = nil

            ns:PET_BAR_UPDATE_COOLDOWN()
        end
    end
end)

function ns.RunCooldownCheck(ev)
    --[==[
    if ( not eventFrame.endTime or eventFrame.endTime-GetTime() > 0.05 ) then
        old_print('RunCooldownCheck Call by event', ev )
        eventFrame.endTime = GetTime()-0.05
    else 
        old_print('Skip from', ev)
    end
    ]==]

    eventFrame.endTime = GetTime()-0.05
end

function ns.UpdateSpellCooldowns(...)
    print('UpdateSpellCooldowns', ...)
end

function ns:UNIT_ENTERED_VEHICLE()
	if not UnitHasVehicleUI("player") then return end
	eventFrame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	ns:ACTIONBAR_UPDATE_COOLDOWN()
end

function ns:UNIT_EXITED_VEHICLE()
    eventFrame:UnregisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    
	for i=1, 8 do
        ns.RemoveCooldown("vhcle"..i)
	end
end

function ns:ACTIONBAR_UPDATE_COOLDOWN()  -- used only for vehicles
	for i = 1, 8, 1 do
		local b = _G["OverrideActionBarButton"..i]
		if b and HasAction(b.action) then
			local start, duration, enable = GetActionCooldown(b.action)
            if enable == 1 then
                local actionType, id, subType = GetActionInfo(b.action)

				if start > 0 and not ns:GetCooldown(id)then
					if duration > 3 then
                        ns.AddCooldown( "vhcle"..i,  nil, duration, start,  GetActionTexture(b.action), "PET_CD")
					end
				else
                    ns.RemoveCooldown("vhcle"..i)
				end
			end
		end
	end
end

function ns:PET_BAR_UPDATE_COOLDOWN()
    local endTime = nil

    for i = 1, 10, 1 do
        local start, duration, enable = GetPetActionCooldown(i)

        if duration > 1.5 then
            local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(i);
       
            if name then
                if start > 0 and not ns:GetCooldown(spellID) then --and not ns:GetCooldown(spellID) then
                    if duration > 3 then
                        ns.AddCooldown('PET:'..i, spellID, duration, start, isToken and _G[texture] or texture, "PET_CD")

                        if not endTime or endTime > duration+start then
                            endTime = duration+start
                        end
                    end
                else
                    ns.RemoveCooldown('PET:'..i)
                end
            end
        else
            ns.RemoveCooldown('PET:'..i)
        end
    end

    if ( endTime ) then
        eventFrame.checkPet = endTime
    end
end

eventFrame.delayCDCheck = {}

local match = string.match
	
function ns.GetItemID(link)
    local itemID = match(link, "|Hitem:(%-?%d+):")		
    if itemID then itemID = tonumber(itemID) end
    
    return itemID
end

do
    local GetSpellCooldown = GetSpellCooldown
    local GetSpellCharges = GetSpellCharges
    local GetSpellCount = GetSpellCount

    local nextCooldownCheck = nil
    local nextCooldownEndTime = nil

    local AddToActiveCooldown 

    local activeCooldowns = {}

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
    
    local function GetSpellCooldown_New(spellID)
        
        local gcdStartTime, gcdDuration = GetSpellCooldown(61304);
        local startTime, duration, enabled = GetSpellCooldown(spellID)

        local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID)
        local spellCount = GetSpellCount(spellID);
        
        --[==[
        old_print( spellID )
        old_print( startTime, duration, enabled )
        old_print( charges, maxCharges, chargeStart, chargeDuration )
        old_print( spellCount )
        ]==]
        startTime = startTime or 0
        duration = duration or 0

        if ( enabled == 0 ) then
            startTime = 0
            duration = 0
        end

        if charges then
            if charges ~= maxCharges then
                startTime = chargeStart
                duration = chargeDuration
            elseif charges == maxCharges then
                startTime = 0
                duration = 0
            end
        end

        if ( gcdStartTime > 0 and gcdStartTime == startTime and gcdDuration == duration ) then

            --print('IGNORE IN GCD ', spellID, gcdStartTime, gcdDuration,  startTime, duration)
            return nil, nil, nil, nil, true, gcdStartTime, gcdDuration
        end

        if ( ns.myCLASS == "DEATHKNIGHT" ) then
            local cost = GetSpellPowerCost(spellID)
            local costRunes = false

            if ( cost ) then
                for i=1, #cost do 
                    if ( cost[i].name == 'RUNES' ) then
                        costRunes = true
                        break
                    end
                end
            end
            if costRunes and ( GetRuneIgnore(startTime, duration) ) then
                return
            end
        end

        return startTime, duration, charges, maxCharges, false
    end
    
    function AddToActiveCooldown(spellID, startTime, duration, charges)
        
        activeCooldowns[spellID] = activeCooldowns[spellID] or {}

        activeCooldowns[spellID].startTime = startTime
        activeCooldowns[spellID].duration = duration
        activeCooldowns[spellID].charges = charges

        if ( not activeCooldowns[spellID].enable ) then
            activeCooldowns[spellID].enable = true

            ns.AddCooldown(spellID, spellID, duration, startTime, nil, 'PLAYER_CD')

            --print('Call by AddToActiveCooldown')

            if not eventFrame.endTime then
                eventFrame.endTime = startTime+duration
            elseif ( eventFrame.endTime > startTime+duration ) then
                if ( startTime+duration - GetTime() ) < 0.05 then
                    eventFrame.endTime = GetTime()+0.05
                else
                    eventFrame.endTime = startTime+duration
                end
            end
        end
    end

    function ns.CheckCooldownList(source)
        local checkEndTime = nil
        local runSpellID = nil
        local currentTime = GetTime()

        for spellID, cooldown in pairs(activeCooldowns) do 
            if ( cooldown.enable ) then
                local startTime, duration, charges, maxCharges, isGCD = GetSpellCooldown_New(spellID)

                if ( isGCD ) then 
                    --old_print( 'Spell is in GCD??', spellID, GetSpellInfo(spellID) )

                    if ( cooldown.startTime+cooldown.duration <= currentTime ) then 
                        cooldown.enable = false
                        --old_print('Remove cooldown By GCD', spellID, GetSpellInfo(spellID))
                        ns.RemoveCooldown(spellID)
                    else 
                        --old_print( 'Spell is in GCD and not endTime', spellID, GetSpellInfo(spellID) )
                    end
                else 
                    if ( startTime and charges and cooldown.startTime and cooldown.startTime > 0 and cooldown.duration > 0 and ( cooldown.charges or 0 ) < charges and maxCharges > charges) then
                        cooldown.startTime = startTime
                        cooldown.duration = duration
                        cooldown.charges = charges

                        if ( maxCharges ~= charges ) then
                            cooldown.enable = true
                            ns.AddCooldown(spellID, spellID, duration, startTime, nil, 'PLAYER_CD')
                        end
                    else 
                        if ( startTime == 0 and duration == 0 or (cooldown.startTime+cooldown.duration < GetTime()) ) then 
                            cooldown.enable = false
                            --old_print('Remove cooldown', spellID, GetSpellInfo(spellID))
                            ns.RemoveCooldown(spellID)
                        else
                            if ( startTime and duration and ( cooldown.startTime ~= startTime or cooldown.duration ~= duration ) ) then
                                cooldown.startTime = startTime
                                cooldown.duration = duration
                                --old_print('Update cooldown', spellID, GetSpellInfo(spellID))
                                ns.UpdateCooldown(spellID, duration, startTime)
                            else
                                --old_print('Cooldown stack', spellID, GetSpellInfo(spellID), startTime, duration,  cooldown.startTime, cooldown.duration )
                            end
                        end
                    end
                end

                if not checkEndTime or checkEndTime > cooldown.startTime+cooldown.duration then
                    checkEndTime = cooldown.startTime+cooldown.duration
                    runSpellID = spellID
                end
            end
        end

        if ( checkEndTime ) then
            --print('Call by checkEndTime from', GetSpellInfo(runSpellID))
            if not eventFrame.endTime or eventFrame.endTime > checkEndTime then
                eventFrame.endTime = checkEndTime
            end
        end
    end

    function ns.RunCheck(spellID1, spellID2) 
        if ( spellID1 ~= spellID2 ) then
                
            local spellTexture1, spellTextureReal1 = GetSpellTexture(spellID1)
            local spellTexture2, spellTextureReal2 = GetSpellTexture(spellID2)

            local startTime, duration, charges = GetSpellCooldown_New(spellID1)
            local startTime2, duration2, charges2 = GetSpellCooldown_New(spellID2)

            if ( startTime and startTime > 0 and duration > 0 and spellTexture1 == spellTextureReal1 ) then
                AddToActiveCooldown(spellID1, startTime, duration, charges) 
            end

            if ( startTime2 and startTime2 > 0 and duration2 > 0 and spellTexture2 == spellTextureReal2 ) then
                AddToActiveCooldown(spellID2, startTime2, duration2, charges2) 
            end
        else
            local startTime, duration, charges = GetSpellCooldown_New(spellID1)

            if ( startTime and startTime > 0 and duration > 0 ) then
                AddToActiveCooldown(spellID1, startTime, duration, charges) 
            end
        end
    end

    function ns.CheckCooldown(spellID1, spellID2)

        if ( spellID1 ~= spellID2 ) then
            eventFrame.delayCDCheck[spellID1] = spellID2
        else 
            eventFrame.delayCDCheck[spellID1] = spellID1
        end

        
        --print('Call by checkCooldown')
      
        eventFrame.checkCD = GetTime()
    end

    ns.GetSpellCooldown_New = GetSpellCooldown_New
end

do
	local GetItemInfo = GetItemInfo
	local GetInventoryItemCooldown, GetInventoryItemTexture = GetInventoryItemCooldown, GetInventoryItemTexture
	local GetContainerItemCooldown, GetContainerItemInfo = GetContainerItemCooldown, GetContainerItemInfo
	local GetContainerNumSlots = GetContainerNumSlots
	
	local bagUpdateThrottle = true
	
	local equippedItems = {}
    
    local function checkcd(name, tip)
		
		if tip == "item" then
			if db.hideinv then -- если скрывать все кд
			
			--	if block[name] == false then return true end
				if ns:GetCooldown(name) == false then return true end
			
		--		print(name, tip, "false")
				return false
			else
				if not ns:GetCooldown(name) then return true end
				if ns:GetCooldown(name) then return false end
			end
		elseif tip == "bag" then
			if db.hidebag then -- если скрывать все кд
			
			--	if block[name] == false  then return true end
				if ns:GetCooldown(name) == false then return true end
				
		--		print(name, tip, "false")
				return false
			else
				if not ns:GetCooldown(name) then return true end
				if ns:GetCooldown(name) then return false end
			end
		end
		
	--	print(name, tip, "true")
		return true
	end

	local function UpdateBag()
		bagUpdateThrottle = true
		
		wipe(equippedItems)
    
        local endTime = nil


        for spellID in pairs(lastItemUsed) do
            local info = lastItemUsed[spellID]

            if ( info.invID ) then 
                local start, duration, enable = GetInventoryItemCooldown("player", info.invID)

                if duration and duration > 20 and duration < 3601 and checkcd(info.itemID, "item") then
                    ns.AddCooldown('ITEM:'..info.itemID, info.itemID, duration, start, GetInventoryItemTexture("player", info.invID), "PLAYER_ITEMS")

                    if not endTime or endTime > duration+start then
                        endTime = duration+start
                    end
                else
                    ns.RemoveCooldown('ITEM:'..info.itemID)
                    lastItemUsed[spellID] = nil
                end
            elseif ( lastItemUsed[spellID].bag ) then
                local start, duration, enable = GetItemCooldown(info.itemID)
            
                if duration and duration > 20 and duration < 3601 and checkcd(info.itemID, "bag") then
                    local  _, _, _, _, icon = GetItemInfoInstant(info.itemID)

                    ns.AddCooldown('ITEM:'..info.itemID, info.itemID, duration, start, icon,"BAG_SLOTS")

                    if not endTime or endTime > duration+start then
                        endTime = duration+start
                    end
                else
                    ns.RemoveCooldown('ITEM:'..info.itemID)
                    lastItemUsed[spellID] = nil
                end
            end
        end

        if ( endTime ) then
            eventFrame.checkItems = endTime
        end
	end
	
    function ns:BAG_UPDATE_COOLDOWN(skip)
        if ( skip ) then
            UpdateBag()
        else
            if bagUpdateThrottle then
                bagUpdateThrottle = false
                C_Timer.After(0.1, UpdateBag)
            end
        end
    end
    
    function ns:BAG_UPDATE_DELAYED()
        spellToItems.bags = {}

        for i = 0, 4, 1 do -- (db.hidebag and -1) or
			for j = 1, GetContainerNumSlots(i), 1 do
            --    local start, duration, enable = GetContainerItemCooldown(i, j)                
            --    if enable == 1 then
                    local link = GetContainerItemLink(i, j)

                    if ( link ) then                    
                        local itemID = ns.GetItemID(link)

                        if ( itemID ) then
                            local spellName, spellID = GetItemSpell(itemID)

                            if ( spellName ) then
                                spellToItems.bags[spellID] = {
                                    itemID = itemID,
                                    spellName = spellName,
                                    bag = true
                                }
                            end
                        end
                    end
			--	end
			end
        end
    end

    function ns:PLAYER_EQUIPMENT_CHANGED()
        spellToItems.gear = {}

        for i = 1, 18, 1 do --(db.hideinv and 0) or
		--	local start, duration, enable = GetInventoryItemCooldown("player", i)
        --    if enable == 1 then
                local link = GetInventoryItemLink("player", i)

                if ( link ) then
                    local itemID = ns.GetItemID(link)

                    if ( itemID ) then
                        local spellName, spellID = GetItemSpell(itemID)

                        if ( spellName ) then
                
                            spellToItems.gear[spellID] = {
                                itemID = itemID,
                                spellName = spellName,
                                invID = i
                            }

                        end
                    end
                end
		--	end
        end
    end
end

--[==[
hooksecurefunc("UseAction", function(slot)
    local actionType,itemID = GetActionInfo(slot)
    if (actionType == "item") then
        print('UseAction', itemID, GetItemInfo(itemID))
    end
end)

hooksecurefunc("UseInventoryItem", function(slot)
    local itemID = GetInventoryItemID("player", slot);
    if (itemID) then
        print('UseInventoryItem', itemID, GetItemInfo(itemID))
    end
end)
hooksecurefunc("UseContainerItem", function(bag,slot)
    local itemID = GetContainerItemID(bag, slot)
    if (itemID) then
        print('UseContainerItem', itemID, GetItemInfo(itemID))
    end
end)
]==]


do

    local cooldowns = {}

    --[==[
    local cooldownLine = CreateFrame('Frame', nil, UIParent)

    cooldownLine:SetSize(400, 20)
    cooldownLine:SetPoint("CENTER", UIParent, "CENTER", 0, -200)

    cooldownLine.bg = cooldownLine:CreateTexture()
    cooldownLine.bg:SetAllPoints()
    cooldownLine.bg:SetColorTexture(0, 0, 0, 0.5)


    cooldownLine.points = {0, 1, 10, 30, 60, 120}

    local ceilSize = (400/( #ticks-1 ))

    for i=1, #cooldownLine.points do
        local text = cooldownLine:CreateFontString()
        text:SetFont(STANDARD_TEXT_FONT, 12, 'OVERLAY')
        text:SetPoint('CENTER', cooldownLine, 'LEFT', ceilSize*(i-1), 0)
        text:SetText( cooldownLine.points[i] )

        local texture = cooldownLine:CreateTexture()
        texture:SetColorTexture(0, 0, 0, 1)
        texture:SetSize(2, 30)
        texture:SetPoint('CENTER', cooldownLine, 'LEFT', ceilSize*(i-1), 0)
    end
    ]==]    

    mainframe:SetScript('OnUpdate', function(self, elapsed)
        local current = GetTime()
        local lineSize = db.w
      
        local ceilSize = (lineSize/( #ticks-1 ))

        local isactive = false
        
        for i=1, #cooldowns do 
            local timeLeft = cooldowns[i].endTime - current

            if ( timeLeft  >=  0 and cooldowns[i].enable ) then 
                local startPoint = 1
                local width = 1
                local nextStep = 1

                for i=#ticks-1, 1, -1 do 
                    if ( ticks[i] <= timeLeft ) then
                        startPoint = ticks[i]
                        nextStep = ticks[i+1]

                        nextWidth = ceilSize*i
                        width = ceilSize*(i-1)
                        break
                    end
                end

                local needToTransit = nextWidth-width
                local transitIn = nextStep-startPoint
                local transitStep = needToTransit/transitIn
                local sectionTransit = timeLeft-startPoint
                local offset = sectionTransit*transitStep

                --print('needToTransit=', needToTransit, 'transitIn=', transitIn )
                local fullOffset = width+offset

                if ( fullOffset > lineSize ) then
                    fullOffset = lineSize
                elseif ( fullOffset < 0 ) then
                    fullOffset = lineSize
                end

                cooldowns[i].frame.textcd:SetFormattedText(ns.FormatTimeCooldown(timeLeft))
                --cooldowns[i].frame:SetPoint('CENTER', cooldownLine, 'LEFT', fullOffset, 0)
                SetValue(cooldowns[i].frame, fullOffset)

                isactive = true
            elseif cooldowns[i].enable and ( 
                cooldowns[i].cdType == 'AURA_CD_BUFF' or 
                cooldowns[i].cdType == 'INTERNAL_CD' or 
                cooldowns[i].cdType == 'AURA_CD_DEBUFF' ) then 
               
                ns.RemoveCooldownByFrame(cooldowns[i].frame)
            else

            end
        end

        
        if not isactive and not mainframe.unlock then
            mainframe:SetAlpha(db.inactivealpha)
        else
            mainframe:SetAlpha(db.activealpha)
        end
    end)

    local function SortCooldownsFunc(x,y)
        return x.endTime < y.endTime
    end
    
    local function SortCooldowns(source)
        table.sort(cooldowns, SortCooldownsFunc)

        --print('SortFrames', source)

        local firstFrame = mainframe
        local frameLevel = 10
        local numCDs = #cooldowns

        for i=1, numCDs do 
            if ( cooldowns[i].enable ) then
                local f = cooldowns[i].frame

                f._frameLevel = 10+numCDs-i
                f:SetFrameLevel( f._frameLevel )
                f.barframe:SetFrameLevel(1)
                
                if db.vertical then
                    if db.reverse then
                        f.bar:SetPoint("BOTTOM", f.icon,"TOP",0, -1);
                        f.bar:SetPoint("TOP", firstFrame, "TOP");
                    else
                        f.bar:SetPoint("TOP", f.icon,"BOTTOM",0, 1);					
                        f.bar:SetPoint("BOTTOM", firstFrame, "BOTTOM");
                    end
                else
                    if db.reverse then
                        f.bar:SetPoint("LEFT",f.icon,"RIGHT",-1, 0);
                        f.bar:SetPoint("RIGHT", firstFrame, "RIGHT");
                    else
                        f.bar:SetPoint("RIGHT",f.icon,"LEFT",1, 0);
                        f.bar:SetPoint("LEFT", firstFrame, "LEFT");
                    end
                end

                firstFrame = f
            end
        end
    end
    
    function ns.EnumirateCooldowns(func) 
        for i=1, #cooldowns do 
            cooldowns[i].frame[func](cooldowns[i].frame)
        end
    end

    
    function ns.isMouseOverButton()
        --[==[
		for index, frame in pairs(cooldowns) do			
			if frame:IsMouseOver() then return true end
        end
        ]==]

        for i=1, #cooldowns do 
            if cooldowns[i].frame:IsMouseOver() then return true end
        end
	end
    
    
    function ns.AddCooldown(spellID, rawID, duration, startTime, texture, cdType)
        local exists = false

        for i=1, #cooldowns do 
            if ( cooldowns[i].spellID == spellID ) then
                exists = true
                break
            end
        end

        if not exists then
            --[==[
            local frame = CreateFrame('Frame', nil, mainframe)
            frame:SetSize(30, 30)
            frame.bg = frame:CreateTexture()
            frame.bg:SetAllPoints()
            frame.bg:SetTexture(texture or GetSpellTexture(spellID))
            frame.bg:SetAlpha(1)

            frame.timer = frame:CreateFontString()
            frame.timer:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)
            frame.timer:SetFont(STANDARD_TEXT_FONT, 12, 'OUTLINE')
            ]==]

            local frame = ns.CreateCooldownFrame()
            frame:Update()
            frame.enable  = true
            frame.cdType = cdType
            frame.name = GetSpellInfo(spellID) or spellID
            frame.endTime = startTime+duration

            frame._texturePath = ns:GetCustomCooldownTexture( (GetSpellInfo(spellID)) )  or ( spellID and GetSpellTexture(spellID) ) or texture
            frame.texture = frame._texturePath
            frame.icon:SetTexture(frame._texturePath)		
            frame.splashicon:SetTexture(frame._texturePath)
            frame.splashiconbug:SetTexture(frame._texturePath)
            frame.rawID = rawID
        
            local cColor = ns:GetCooldownColor(frame.name)

            if cColor then
                frame.bar:SetVertexColor(cColor[1], cColor[2], cColor[3], 0.6);
                frame.glow:SetVertexColor(cColor[1], cColor[2], cColor[3]);	
            else
                local dColor = ns:GetCooldownTypeColor(cdType)
                frame.bar:SetVertexColor(dColor[1], dColor[2], dColor[3], 0.6);
                frame.glow:SetVertexColor(dColor[1], dColor[2], dColor[3]);
            end
        
            cooldowns[#cooldowns+1] = {
                enable  = true,
                name = frame.name,
                spellID = spellID,
                endTime = startTime+duration,
                frame = frame,
                startTime = startTime,
                texture = texture,
                cdType = cdType,
                rawID = rawID,
            }

            SortCooldowns('AddCooldown')
        else 
            ns.UpdateCooldown(spellID, duration, startTime)
        end
    end

    function ns.RemoveCooldown(spellID)
        for i=1, #cooldowns do 
            if ( cooldowns[i].spellID == spellID ) then
                if ( cooldowns[i].enable == true ) then
                    cooldowns[i].enable = false
                    cooldowns[i].frame.enable  = false
                    cooldowns[i].frame:Hide()
                    cooldowns[i].frame.barframe:Hide()
                    cooldowns[i].frame:Splash()

                    if cooldowns[i].frame.showtooltip then 
                        cooldowns[i].frame.showtooltip:HideTooltip() 
                        cooldowns[i].frame.showtooltip.child = nil
                        cooldowns[i].frame.showtooltip = nil
                    end
                    SortCooldowns('RemoveCooldown')
                end
                break
            end
        end
    end

    function ns.RemoveCooldownByFrame(frame)
        for i=1, #cooldowns do 
            if ( cooldowns[i].frame == frame ) then
                if ( cooldowns[i].enable == true ) then
                    cooldowns[i].enable = false
                    cooldowns[i].frame.enable  = false
                    cooldowns[i].frame:Hide()
                    cooldowns[i].frame.barframe:Hide()
                    cooldowns[i].frame:Splash()

                    if cooldowns[i].frame.showtooltip then 
                        cooldowns[i].frame.showtooltip:HideTooltip() 
                        cooldowns[i].frame.showtooltip.child = nil
                        cooldowns[i].frame.showtooltip = nil
                    end
                    SortCooldowns('RemoveCooldown')
                end
                break
            end
        end
    end

    function ns.UpdateCooldown(spellID, duration, startTime)
        for i=1, #cooldowns do 
            if ( cooldowns[i].spellID == spellID ) then

                if ( 
                    cooldowns[i].enable ~= true or 
                    cooldowns[i].startTime ~= startTime or 
                    cooldowns[i].endTime ~= startTime + duration
                ) then
                    cooldowns[i].enable  = true
                    cooldowns[i].startTime = startTime
                    cooldowns[i].endTime = startTime + duration
                    cooldowns[i].frame:Show()
                    cooldowns[i].frame.enable  = true
                    cooldowns[i].frame.barframe:Show()
                    cooldowns[i].frame.endTime = startTime+duration

                    SortCooldowns('UpdateCooldown')
                end

                break
            end
        end
    end

    function ns.GlowCooldown(spellID)
        if #cooldowns == 0 then return end
        for i=1, #cooldowns do
            if cooldowns[i].spellID == spellID then
                if cooldowns[i].endTime - GetTime() > 1 then
                    cooldowns[i].frame:Glow()
                end
                break
            end
        end
    end

    function ns.GetCooldownsList()
        return cooldowns
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
	
    function ns.FormatTimeCooldown(s)
        local t = db.fortam_s or 1
        
        return formats[t](s)
    end

    
	function ns.ButtonOnClick(self, button) -- - осталось до перезарядки "]
		if not ns:GetAnonce(self.f.name, self.f.cdType) then return end
		
		if button == "LeftButton" then
			local compspellName = self.f.spellID --gsub(self.f.name, stackspellpattern, "")
			local spellLink = GetSpellLink(compspellName) or compspellName

			
			ns.ChatMessage(spellLink..L[" - remains cooldown"]..format(ns.FormatTimeCooldown(self.f.endTime-GetTime())))
		elseif button == "RightButton" and self.barbutton then		
            ns.RemoveCooldownByFrame(self.f)
		end
		if self.tooltip then self.parent:HideTooltip() end
	end		
end

do
    local t_coord_1 = 0.08
        
    local Update = function(f)
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

    local StopPulse = function(self)
        self.pulse:Hide()
        self:SetAlpha(1)
    end
    local PulseIn = function(self)
        self.pulse.elapsed = self:GetAlpha()
        self.pulse.step = 1 - self.pulse.elapsed
        self.pulse.mode = 'IN'
        self.pulse:Show()
    end
    local PulseOut = function(self)
        self.pulse.elapsed = self:GetAlpha()
        self.pulse.step = -2 + self.pulse.elapsed
        self.pulse.mode = 'OUT'
        self.pulse:Show()
    end
    
    local Splash = function(self)
        DoBigSplash(self.splashbig)
        DoSmallSplash(self.splashsmall)
    end

    local IsMouseOver = function(self)
        if not self.enable then return false end
        return MouseIsOver(self.button) or self.button.enter
    end
    local Glow = function(self)
        self.elapsed = 1
        self:SetFrameLevel(50)
    end
    local PulseOnUpdate = function(self, elapsed)
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
    end

    local FrameOnUpdate = function(self, elapsed)
        self.elapsed = self.elapsed - elapsed
        
        if self.elapsed > -0.5 then 
            self:SetFrameLevel(50) 
        else
            self:SetFrameLevel(self._frameLevel) 
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
    end

    function ns.CreateCooldownFrame()
        local f = CreateFrame("Frame", nil, mainframe.border)
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
        f.button:SetScript("OnClick", ns.ButtonOnClick )			
        f.button:SetScript("OnEnter", ns.OnEnter)			
        f.button:SetScript("OnLeave", ns.OnLeave)
        
        f.border = CreateFrame("Frame", nil, f)
        f.border:SetFrameLevel(f:GetFrameLevel()-1)
        f.border:SetPoint("TOPLEFT",-db.icon_borderinset, db.icon_borderinset) -- Implemented 'insets'
        f.border:SetPoint("BOTTOMRIGHT",db.icon_borderinset, -db.icon_borderinset) -- Implemented 'insets'
        f.border:SetBackdrop(icon_backdrop)
        f.border:SetBackdropBorderColor(db.bordercolor.r, db.bordercolor.g, db.bordercolor.b, db.bordercolor.a)

        f:SetScript("OnUpdate", FrameOnUpdate)
        
        
        f.elapsed = 0

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
        f.pulse:SetScript("OnUpdate", PulseOnUpdate)


        f.glow = f.border:CreateTexture(nil,"ARTWORK");
        f.glow:SetPoint("CENTER",f.icon,"CENTER");
        f.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border") --"Interface\\Tooltips\\UI-Tooltip-Background") --"Interface\\AddOns\\Forte_Core\\Textures\\Spark2");
        f.glow:SetBlendMode("ADD");
        f.glow:Hide()
        
        f.barframe = CreateFrame("Frame", nil, mainframe.border)
        f.barframe:SetFrameLevel(f:GetFrameLevel()-2)
        
        f.bar = f.barframe:CreateTexture(nil,"ARTWORK", nil, 3);
        f.bar:Show()
        f.bar:SetAlpha(0.6)
        -- db.vertical and (db.reverse
        
        f.textcd = f:CreateFontString(nil, "ARTWORK", nil, 5)
        f.textcd:SetPoint("BOTTOM", f, "BOTTOM")

        f.Glow = Glow
        f.IsMouseOver = IsMouseOver
        f.StopPulse = StopPulse
        f.PulseIn = PulseIn
        f.PulseOut = PulseOut    
        f.Splash = Splash
        f.Update = Update

        return f
    end
end


function ns:UnlockCooldownLine()

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
		--OnUpdate(mainframe, 2)
		
		splashbigmover:EnableMouse(false)
		splashbigmover:Hide()
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
		
			local endTime, curtime = 0, GetTime()
            
			if self.f.endTime and self.f.endTime > curtime then
				endTime = self.f.endTime - curtime
			end
			
			self.l:SetText("\124T"..self.f.texture..":12\124t")
			self.r:SetText(format(" %.1f ", endTime))		
			
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
	
	function ns:UpdateTooltip()
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
		f:SetScript("OnClick", ns.ButtonOnClick )
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
	
	local loop = CreateFrame("Frame")
	loop:Hide()
	loop.elapsed = 0
	loop.trottle = 0
	loop:SetScript("OnUpdate", function(self,elapsed)
		self.elapsed = self.elapsed + elapsed
		self.trottle = self.trottle + elapsed
		
		if MouseIsOver(cd_tooltip) or ns.isMouseOverButton() then 
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
        
        local cooldowns = ns.GetCooldownsList()

        for i=1, #cooldowns do 
            if cooldowns[i].frame:IsMouseOver() then 
                
                --print(cooldowns[i].frame.name, cooldowns[i].frame.cdType, ns:GetAnonce(cooldowns[i].frame.name, cooldowns[i].frame.cdType))

				if ns:GetAnonce(cooldowns[i].frame.name, cooldowns[i].frame.cdType) then 
					frames[#frames+1] = cooldowns[i].frame
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
	
	function ns.OnEnter(self)
		self.enter = true
		TotalMouseover()
	end
	
	function ns.OnLeave(self)
		self.enter = nil
		TotalMouseover()
	end
	
end


local cachedNameToTableKey = {}

function ns:GetCooldownBlockName(name)
	return cachedNameToTableKey[name]
end

local function BuildCooldownBlockList()
	for k,v in pairs(db.blockList) do		
		if v.itemid then
			cachedNameToTableKey[v.itemid] = k
		elseif v.spellid then
			cachedNameToTableKey[v.spellid] = k
		end
	end
end

function ns:BuildCooldownBlockList()
	C_Timer.After(1, BuildCooldownBlockList)
	C_Timer.After(1.5, BuildCooldownBlockList)
end


--[==[
    PET_BAR_UPDATE_COOLDOWN
    ACTIONBAR_UPDATE_COOLDOWN
    BAG_UPDATE_COOLDOWN
    SPELL_UPDATE_COOLDOWN
    SPELLS_CHANGED
    UNIT_SPELLCAST_FAILED
    UNIT_SPELLCAST_SUCCEEDED
]==]
