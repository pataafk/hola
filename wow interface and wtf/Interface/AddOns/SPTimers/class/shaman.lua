local addon, C = ...
if C.myCLASS ~= "SHAMAN" then return end

local L = AleaUI_GUI.GetLocale("SPTimers")
local colors = C.CustomColors

local ALL = "ALL"

--[[
	1 = Elem
	2 = Enchan
	3 = Restor
	
	spec = ALL,
]]

local spells = {

	[184073] = { spec = "1", color = { 0.631372549019608, 0.192156862745098, 0.227450980392157, }, duration = 10, color_on = true, cleu = true, },	
	
--	[8056] = { spec = ALL,duration = 8, color = colors.CHILL, cleu = true },
--	[16188] = { spec = ALL,duration = 1, color = colors.TEAL },
	[61295] = { spec = "3",duration = 15, color = colors.FROZEN, cleu = true },
--	[76780] = { duration = 50, pvpduration = 8, color = colors.PINK, cleu = true  },
	[51514] = { spec = ALL,cleu = true, duration = 50, pvpduration = 8, color = colors.CURSE },
	[79206] = { spec = ALL,duration = 10, color = colors.LGREEN },
	
--	[8050]  = { spec = ALL,custom_text = "%tN", cleu = true, duration = 30, color = colors.PURPLE, haste = true, pandemia = true },
	[16166] = { spec = ALL,duration = 20, color = colors.CURSE },
	[77762] = { spec = "1",duration = 6, color = colors.FIRE },
--	[30823] = { spec = ALL,duration = 15, color = colors.BLACK },
	
--	[53817]  = { spec = "2",duration = 12, color = colors.PURPLE},
	
	[114050] = { spec = "1",duration = 15, color = colors.PINK },
	[114051] = { spec = "2",duration = 15, color = colors.PINK },
	[114052] = { spec = "3",duration = 15, color = colors.PINK },
	
	[108271] = { spec = ALL,duration = 6, color = colors.BLACK },
--	[63685]  = { spec = ALL,duration = 5, color = colors.FROZEN },
	[73920]  = { spec = ALL,duration = 5, color = colors.FROZEN },
	
	[51533] = { spec = "2", duration = 15, cleu = true, group = "player", color = colors.DBLUE, whitelist_cleu = 5, },

--	[51730] = { duration = 3600, color = colors.BLACK },
--	[8024]  = { duration = 3600, color = colors.BLACK },
--	[8033]  = { duration = 3600, color = colors.BLACK },
--	[8017]  = { duration = 3600, color = colors.BLACK },
--	[8232]  = { duration = 3600, color = colors.BLACK },

}

local GetSpell = C.GetSpell

local cooldown = {
	
--	[GetSpell(8056)] = { spellid = 8056, color = colors.LRED },
	[GetSpell(51505)] = { spellid = 51505, color = colors.RED },
	[GetSpell(117014)] = { spellid = 117014, color = colors.BLACK },
	[GetSpell(17364)] = { spellid = 17364, color = colors.CURSE },
--	[GetSpell(73680)] = { spellid = 73680, color = colors.WOO },
	[GetSpell(60103)] = { spellid = 60103, color = colors.RED },

}


local function GetSpellNameGUI(spellID)
	local name, _, icon = GetSpellInfo(spellID)
	
	return "\124T"..icon..":14\124t "
end

local totems = {

	[1] = 3599,
	[2] = 2062,
	[3] = 5394,
	[4] = 8177,
}

function C:SetupClassSpells()  return spells end
function C:SetupClassCooldowns() return cooldown end

function C:SetupClassOptions()
	local order = 41
	
	self.options.args.bars.args.Shaman = {
			type = "group",
			name = "|c"..RAID_CLASS_COLORS[C.myCLASS].colorStr..(UnitClass('player')),
			order = order, embend = false,
			args = {}
			}
	--[[
	self.options.args.bars.args.showenchants = {
			order = order+1,name = L["Show enchants"],type = "toggle", width = "full",
			set = function(info,val) self.db.profile.showenchants = not self.db.profile.showenchants; self:UpdateEnchants() end,
			get = function(info) return self.db.profile.showenchants end
			}
	]]
	for i=1, 4 do
		
		order = order+ 3 + (6*(i-1))
		
		self.options.args.bars.args.Shaman.args["groupTotem"..i] = {
			type = "group",
			name = L["SHAMAN totem"..i] ,
			order = order, embend = true,
			args = {}
			}
			
		self.options.args.bars.args.Shaman.args["groupTotem"..i].args["showtotem"..i] = {
			order = order+(2*i),name = L["Show"],type = "toggle",
			set = function(info,val) self.db.profile.totems["totem"..i].show = not self.db.profile.totems["totem"..i].show; self:UpdateTotems() end,
			get = function(info) return self.db.profile.totems["totem"..i].show end
			}
		self.options.args.bars.args.Shaman.args["groupTotem"..i].args["colortotem"..i] = {
			order = order+(3*i),name = L["Color"], type = "color", hasAlpha = false,
			set = function(info,r,g,b) self.db.profile.totems["totem"..i].color ={r,g,b,1} end,
			get = function(info) return self.db.profile.totems["totem"..i].color[1],self.db.profile.totems["totem"..i].color[2],self.db.profile.totems["totem"..i].color[3],1 end
		}
		
		self.options.args.bars.args.Shaman.args["groupTotem"..i].args["prioritytotem"..i] = {
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
		self.options.args.bars.args.Shaman.args["groupTotem"..i].args["anchortotem"..i] = {
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
		self.options.args.bars.args.Shaman.args["groupTotem"..i].args["grouptotem"..i] = {
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
end