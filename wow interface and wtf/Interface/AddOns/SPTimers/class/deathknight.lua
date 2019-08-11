local addon, C = ...
if C.myCLASS ~= "DEATHKNIGHT" then return end

local L = AleaUI_GUI.GetLocale("SPTimers")
local colors = C.CustomColors
local ALL = "ALL"

--[[
	blood_runes = true,
	frost_runes = true,
	unholy_runes = true,
					
	blood_runes_color = {1, 0, 0, 1},
	frost_runes_color = {0, 0.43, 1, 1},
	unholy_runes_color = {0.2, 0.8, 0, 1},
	
	
	
	1 = blood
	2 = frost
	3 = uncholy
	
	spec = ALL,
]]

local spells = { 
	
	[55095] = { spec = ALL,color = colors.CHILL, duration = 30, pandemia = true, showTicks = true, tick = 3 },
	[55078] = { spec = ALL,color = colors.PURPLE, duration = 30, pandemia = true, showTicks = true, tick = 3 },
	[43265] = { spec = ALL,color = colors.RED, duration = 10, group = "player", cleu = true, whitelist_cleu = 5, blacklist_cleu = 3, blacklist = 3 },
--	[114866] = { spec = "1",color = colors.BLACK, duration = 5 },
--	[130735] = { spec = "2",color = colors.BLACK, duration = 5 },
	[130736] = { spec = "3",color = colors.BLACK, duration = 5 },
--	[73975]  = { duration = 10, color = colors.WOO },
	
	[56222]  = { spec = "1",color = colors.TAUNT, duration = 3 },
	[55233]  = { spec = "1",duration = 10, color = colors.RED },
	[81256]  = { spec = "1",duration = 12, color = colors.BROWN },
--	[49222]  = { spec = "1",duration = 300, color = colors.WOO2 },
	
	[81141]  = { spec = "1",duration = 15, color = colors.LRED },
--	[50421]  = { spec = "1",duration = 30, color = colors.WOO2 },
	[45524]  = { spec = ALL,duration = 8, color = colors.CHILL },
	[48792]  = { spec = ALL,duration = 12 },
	[51124]  = { spec = "2",duration = 30, color = colors.LRED, group = "procs", },
	[59052]  = { spec = "2",duration = 15, color = colors.WOO2, group = "procs", },
	[49039]  = { spec = ALL,duration = 10, color = colors.BLACK },
--	[91342]  = { spec = "3",duration = 30, target_affil = 2, color = colors.LGREEN}, -- "Shadow Infusion" pet
	[63560]  = { spec = "3",duration = 30, color = colors.LGREEN }, -- "Dark Transformation"
	[81340]  = { spec = "3",duration = 10, color = colors.CURSE },
	[47476]  = { spec = ALL,cleu = true, duration = 5 },	
	[91800]  = { spec = "3",cleu = true, duration = 3, color = colors.RED }, -- pet
	[91797]  = { spec = "3",cleu = true, duration = 4, color = colors.RED }, -- pet
--	[49016]  = { duration = 30, color = colors.LRED },
	[48707]  = { spec = ALL,duration = 5,  color = colors.LGREEN },
	
	[51052]  = { spec = ALL,cleu = true, color = colors.GOLD, duration = 3, group = "player", whitelist_cleu = 5, blacklist_cleu = 2, blacklist = 4 },
	[116888] = { spec = ALL,color = colors.LGREEN, duration = 3 },
	[108194] = { spec = ALL,cleu = true, color = colors.PINK, duration = 5 }, 
	
	[207349] = { spec = '3',cleu = true, duration = 20, color_on = true, whitelist_cleu = 5, color = {0.28, 0.26,0.32} },

--	[96268]  = { spec = ALL,color = colors.PINK, duration = 6 },
--	[114851] = { spec = "1",color = colors.DRED, duration = 24 },
	
--	[155159] = { spec = ALL,color = colors.CHILL, duration = 30, tick = 2},
}

local GetSpell = C.GetSpell

local cooldown = {
	[GetSpell(152280)] = { spellid = 152280, color = colors.WOO },	
	[GetSpell(47568)] = { spellid = 47568, color = colors.WOO },
	[GetSpell(48792)] = { spellid = 48792, color = colors.WOO },
--	[GetSpell(77575)] = { spellid = 77575, color = colors.WOO },
	[GetSpell(77606)] = { spellid = 77606, color = colors.WOO },
	[GetSpell(48707)] = { spellid = 48707, color = colors.WOO },
	[GetSpell(47476)] = { spellid = 47476, color = colors.WOO },
--	[GetSpell(49222)] = { spellid = 49222, color = colors.WOO },
	[GetSpell(49028)] = { spellid = 49028, color = colors.WOO },
	[GetSpell(43265)] = { spellid = 43265, color = colors.WOO },
--	[GetSpell(48982)] = { spellid = 48982, color = colors.WOO },
	[GetSpell(55233)] = { spellid = 55233, color = colors.WOO },
	[GetSpell(51271)] = { spellid = 51271, color = colors.WOO },
	[GetSpell(49206)] = { spellid = 49206, color = colors.WOO },
}
	
		
function C:SetupClassSpells()
	return spells
end

function C:SetupClassCooldowns() return cooldown end

function C:SetupClassOptions()
	local order = 60
	
	self.options.args.coolline.args.DKrunes = {
		type = "group",
		name = "|c"..RAID_CLASS_COLORS[C.myCLASS].colorStr.. L["Runes"],
		order = order+1, embend = false, args = {},
		}
	
	
	self.options.args.coolline.args.DKrunes.args.blood_runes_color = {					
		type = "group",	order = order+2,
		embend = true,
		name	= L["Blood"],
		args = {
		
			prototype1 = {
				order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
				width = 'full',
				set = function() end, 
				get = function() end,
				
				colorOpts = {
					order = 1, name = L["Color"],type = "color", hasAlpha = false, width = "half",
					set = function(info,r,g,b) self.db.profile.cooldownline.blood_runes_color={r,g,b} end,
					get = function(info) return self.db.profile.cooldownline.blood_runes_color[1],self.db.profile.cooldownline.blood_runes_color[2],self.db.profile.cooldownline.blood_runes_color[3],1 end
					},
				toggleOpts1 = {
					order = 2,name = L["Hide"],type = "toggle", width = "half",
					set = function(info,val) self.db.profile.cooldownline.blood_runes = not self.db.profile.cooldownline.blood_runes; self.UpdateSettings() end,
					get = function(info) return self.db.profile.cooldownline.blood_runes end
					},
				toggleOpts2 = {
					order = 3,name = L["Reporting"], type = "toggle", width = "half",
					desc = L["Turn on/off spell cooldown report"],
					set = function(info,val) self.db.profile.cooldownline.br_reporting = not self.db.profile.cooldownline.br_reporting end,
					get = function(info) return self.db.profile.cooldownline.br_reporting end
				},
			},
		},
	}
	
	self.options.args.coolline.args.DKrunes.args.frost_runes_color = {					
		type = "group",	order = order+3,
		embend = true,
		name	= L["Frost"],
		args = {
			prototype1 = {
				order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
				width = 'full',
				set = function() end, 
				get = function() end,
				
				colorOpts = {
					order = 1, name = L["Color"],type = "color", hasAlpha = false, width = "half",
					set = function(info,r,g,b) self.db.profile.cooldownline.frost_runes_color={r,g,b} end,
					get = function(info) return self.db.profile.cooldownline.frost_runes_color[1],self.db.profile.cooldownline.frost_runes_color[2],self.db.profile.cooldownline.frost_runes_color[3],1 end
					},
				toggleOpts1 = {
					order = 2,name = L["Hide"],type = "toggle", width = "half",
					set = function(info,val) self.db.profile.cooldownline.frost_runes = not self.db.profile.cooldownline.frost_runes; self.UpdateSettings() end,
					get = function(info) return self.db.profile.cooldownline.frost_runes end
					},
				toggleOpts2 = {
					order = 3,name = L["Reporting"], type = "toggle", width = "half",
					desc = L["Turn on/off spell cooldown report"],
					set = function(info,val) self.db.profile.cooldownline.fr_reporting = not self.db.profile.cooldownline.fr_reporting end,
					get = function(info) return self.db.profile.cooldownline.fr_reporting end
				},
			},
		},
	}

	self.options.args.coolline.args.DKrunes.args.uncholy_runes_color = {					
		type = "group",	order = order+4,
		embend = true,
		name	= L["Unholy"],
		args = {
			prototype1 = {
				order = 1, name = 'Test', type = 'SPTimers_CooldownToggleFrame',
				width = 'full',
				set = function() end, 
				get = function() end,
				
				colorOpts = {
					order = 1, name = L["Color"],type = "color", hasAlpha = false, width = "half",
					set = function(info,r,g,b) self.db.profile.cooldownline.unholy_runes_color={r,g,b}; end,
					get = function(info) return self.db.profile.cooldownline.unholy_runes_color[1],self.db.profile.cooldownline.unholy_runes_color[2],self.db.profile.cooldownline.unholy_runes_color[3],1 end
					},
				toggleOpts1 = {
					order = 2,name = L["Hide"],type = "toggle", width = "half",
					set = function(info,val) self.db.profile.cooldownline.unholy_runes = not self.db.profile.cooldownline.unholy_runes self.UpdateSettings() end,
					get = function(info) return self.db.profile.cooldownline.unholy_runes end
					},
				toggleOpts2 = {
					order = 3,name = L["Reporting"], type = "toggle", width = "half",
					desc = L["Turn on/off spell cooldown report"],
					set = function(info,val) self.db.profile.cooldownline.uh_reporting = not self.db.profile.cooldownline.uh_reporting end,
					get = function(info) return self.db.profile.cooldownline.uh_reporting end
				},
			},
		},
	}

end