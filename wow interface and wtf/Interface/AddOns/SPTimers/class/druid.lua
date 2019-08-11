local addon, C = ...
if C.myCLASS ~= "DRUID" then return end

local L = AleaUI_GUI.GetLocale("SPTimers")
local colors = C.CustomColors

local ALL = "ALL"

--[[
	1 = balance
	2 = feral
	3 = guardian
	4 = restor
	
	spec = ALL,
]]

local spells = { 
	
	[184073] 	 = { spec = '1', color = { 0.631372549019608, 0.192156862745098, 0.227450980392157, }, duration = 10, color_on = true, cleu = true, },	
	
	[339] 		= { spec = ALL,duration = 30 , cleu = true },
--	[48391] 	= { duration = 10 },
	[78675] 	= { spec = "1",duration = 10, color = colors.GOLD, cleu = true, group = "player", whitelist_cleu = 5 },
	
--	[2637]		= { duration = 40, pvpduration = 8 },
	[33786] 	= { spec = ALL,duration = 6 },
	
	[8921]  	= { spec = ALL,duration = 22, showTicks = true,  tick = 2, pandemia = true, cleu = true, haste = true, color = colors.PURPLE },	
	[164812]	= { spec = "1",duration = 22, showTicks = true, tick = 2, pandemia = true, cleu = true, haste = true, color = colors.PURPLE },
	
	[93402] 	= { spec = "1",duration = 18, showTicks = true, tick = 2, pandemia = true, cleu = true, haste = true, color = colors.ORANGE },
	[164815]	= { spec = "1",duration = 18, showTicks = true, tick = 2, pandemia = true, cleu = true, haste = true, color = colors.ORANGE },
	
--	[152221]	= { spec = "1",duration = 20, cleu = true, pandemia = true, color = colors.PURPLE, tick = 5, haste = true },
	
--	[93400] 	= { spec = "1",group = "procs", duration = 12, color = colors.CURSE },
	[106951] 	= { spec = "2",group = "player" }, -- cat
--	[50334] 	= { spec = "3",group = "player" }, -- bear
	
	[155625] 	= { spec = "2",duration = 14, showTicks = true, tick = 2, haste = true, pandemia = true, color = colors.PURPLE,},
	
	
--	[9005] 		= { duration = 4, color = colors.PINK },
--	[9007] 		= { color = colors.RED, duration = 18, cleu = true },

	[1822] 		= { spec = "2",duration = 15, showTicks = true, tick = 3, color = colors.LRED, cleu = true, pandemia = true },
	[155722] 	= { spec = "2",duration = 15, showTicks = true, tick = 3, color = colors.LRED, cleu = true, pandemia = true },
	
	
	[1079] 		= { spec = "2",duration = 24, showTicks = true, tick = 2, color = colors.RED, cleu = true, pandemia = true },
	[22570] 	= { spec = "2",color = colors.PINK, duration = 5 },
	[5217] 		= { spec = "2",color = colors.LBLUE },
	
	[52610] 	= { spec = "2", pandemia = true, color = colors.PURPLE },
--	[174544] 	= { spec = "2", pandemia = true, color = colors.PURPLE },
	
--	[127538] 	= { color = colors.PURPLE, duration = 12 },
	[1850] 		= { spec = ALL,duration = 15 },
	[81022] 	= { spec = "2",duration = 8 },

--	[132402] 	= { spec = "3",group = "player", duration = 6, color = colors.WOO2 },
--	[106922] 	= { spec = ALL,group = "player", duration = 20, color = colors.BLACK },
	[99] 		= { spec = ALL,duration = 3, cleu = true },
	[6795] 		= { spec = "3",duration = 3, color = colors.TAUNT  },
--	[33745] 	= { spec = "3",group = "target", duration = 15, color = colors.RED },
	[5211]  	= { spec = ALL,duration = 5, cleu = true, color = colors.PINK },
	
	[77758]  	= { spec = "3",duration = 16, showTicks = true, tick = 2, color = colors.LBLUE },
	[106830]	= { spec = "2",duration = 16, showTicks = true, tick = 3, color = colors.LBLUE, pandemia = true },
	[93622] 	= { spec = "3",group = "procs", color = colors.CURSE, duration = 5 },
--	[102795] 	= { duration = 3, color = colors.RED },
	[102359] 	= { spec = ALL,duration = 20, color = colors.BROWN },
	
	--[[
	[102351] = { group = "player", duration = 30, color = colors.WOO2 },
	[102352] = { group = "player", duration = 6, color = colors.TEAL },
	]]
	
	[117679] 	= { spec = "4",group = "player", duration =  30, color = colors.TEAL2 },
	[102558] 	= { spec = "3",group = "player", duration =  30, color = colors.TEAL2 },
	[102560] 	= { spec = "1",group = "player", duration =  30, color = colors.TEAL2 },
	[102543] 	= { spec = "2",group = "player", duration =  30, color = colors.TEAL2 },
	
	[144865]	= { spec = "2",group = "player" },
	
	[102342] 	= { spec = "4",group = "player", duration = 12 },
	[22812]  	= { spec = ALL,group = "player", duration = 12 },
	[61336]  	= { spec = "2;3",group = "player", color = colors.BLACK, duration = 12 },
	[124974] 	= { spec = ALL,color = colors.TEAL2, duration = 30 },
--	[132158] 	= { spec = "4",group = "player", color = colors.TEAL },
	[774]		= { spec = ALL,source = 2, group = "player", cleu = true, duration = 12, color = colors.REJUV, showTicks = true, tick =3 , pandemia = true },
	[8936] 	 	= { spec = "4",group = "player", duration = 6, color = colors.REGROW },
	[33763]  	= { spec = "4",source = 2, cleu = true, duration = 10},
	[48438]  	= { spec = "4",cleu = true, duration = 7, color = colors.LGREEN },
--	[29166]  	= { cleu = true, duration = 10 },
--	[100977] 	= { spec = "4",group = "player", color = colors.BLACK, cast = 2.5, duration = 10 },
	
	[145162]	= { spec = "3",color = colors.ELV_RAGE, }, -- cleu = true, whitelist_cleu = 2, duration = 20},
--	[145151]	= { color = colors.ELV_RAGE, }, -- cleu = true, whitelist_cleu = 2, duration = 30},
	[145152]	= { spec = "2",color = colors.ELV_RAGE, }, -- cleu = true, whitelist_cleu = 2, duration = 30},
	
--	[112071]	= { spec = "1",duration = 15 },

	[80313]		= { spec = "3", duration = 12, pandemia = true },
	
	
	[164547]	= { spec = "1",duration = 40, color = colors.INSANITY },
	[164545]	= { spec = "1",duration = 40, color = colors.GOLD	  },
}

local GetSpell = C.GetSpell

local cooldown = {
	[GetSpell(78674)] = { spellid = 78674, color = colors.CURSE },
	[GetSpell(5217)]  = { spellid = 5217, color = colors.LBLUE },
	[GetSpell(77758)] = { spellid = 77758, color = colors.LBLUE },
--	[GetSpell(33745)] = { spellid = 33745, color = colors.PURPLE },
--	[GetSpellInfo(33878)] = { spellid = 33878, color = colors.CURSE },
}


function C:SetupClassSpells() return spells end
function C:SetupClassCooldowns() return cooldown end


function C:SetupClassOptions()
	local order = 41
	--[==[
	self.options.args.bars.args[C.myCLASS] = {
		type = "group",
		name = L["DRUID totem1"],
		order = order,
		embend = false,
		args = {},		
	}

	for i=1, 3 do
		
		order = order+ 3 + (6*(i-1))
		
		self.options.args.bars.args[C.myCLASS].args["headertotem"..i] = {
			type = "group",
			name = L[C.myCLASS.." totem1"],
			order = order+1*i, args = {}, embend = true,
			}
			
		self.options.args.bars.args[C.myCLASS].args["headertotem"..i].args["showtotem"..i] = {
			order = order+(2*i),name = L["Show"],type = "toggle",
			set = function(info,val) self.db.profile.totems["totem"..i].show = not self.db.profile.totems["totem"..i].show; self:UpdateTotems() end,
			get = function(info) return self.db.profile.totems["totem"..i].show end
			}
		self.options.args.bars.args[C.myCLASS].args["headertotem"..i].args["colortotem"..i] = {
			order = order+(3*i),name = L["Color"], type = "color", hasAlpha = false,
			set = function(info,r,g,b) self.db.profile.totems["totem"..i].color ={r,g,b,1} end,
			get = function(info) return self.db.profile.totems["totem"..i].color[1],self.db.profile.totems["totem"..i].color[2],self.db.profile.totems["totem"..i].color[3],1 end
		}
		
		self.options.args.bars.args[C.myCLASS].args["headertotem"..i].args["prioritytotem"..i] = {
				name = L["Priority"],
				type = "slider",
				order	= order+(4*i),
				min		= -20,
				max		= 20,
				step	= 1,
				set = function(info,val) 
					self.db.profile.totems["totem"..i].priority = val
				end,
				get = function(info)
					return self.db.profile.totems["totem"..i].priority
				end,
			}
		self.options.args.bars.args[C.myCLASS].args["headertotem"..i].args["anchortotem"..i] = {
				name = L["Select Anchor"],
				order = order+(5*i),
				desc = L["Select Anchor Desc"],
				type = "dropdown",
				values = function()
					local t = {}							
					for k,v in ipairs(self.db.profile.bars_anchors) do						
						t[k] = ""..k..""
					end							
					return t
				end,
				set = function(info,val)
					self.db.profile.totems["totem"..i].anchor = val
				end,
				get = function(info, val) 
					return self.db.profile.totems["totem"..i].anchor or 1
				end
			}
		self.options.args.bars.args[C.myCLASS].args["headertotem"..i].args["grouptotem"..i] = {
				name = L["Select group"],
				order = order+(6*i),
				desc = L["Select group Desc"],
				type = "dropdown",
				values = function()		
					return {
						["player"] = "player",
						["procs"]  = "procs",
						["auto"]   = "auto",
						["target"] = "target",
					}
				end,
				set = function(info,val)
					self.db.profile.totems["totem"..i].group = val
				end,
				get = function(info, val) 
					return self.db.profile.totems["totem"..i].group or "auto"
				end
			}
	end
	]==]
end