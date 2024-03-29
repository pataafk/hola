if select(2, GetAddOnInfo('ElvUI_KnightFrame')) and IsAddOnLoaded('ElvUI_KnightFrame') then return end

local SLE, T, E, L, V, P, G = unpack(select(2, ...)) 
local KF, Info, Timer = unpack(ElvUI_KnightFrame)
local M = E:GetModule("Misc")
--GLOBALS: SLE_ArmoryDB, AceGUIWidgetLSMlists, PaperDollFrame_UpdateStats
local _G = _G
-- local PaperDollFrame_UpdateStats = PaperDollFrame_UpdateStats
local UnitPowerType = UnitPowerType

local MAX_NUM_SOCKETS = MAX_NUM_SOCKETS
local ALTERNATE_RESOURCE_TEXT, DAMAGE, ATTACK_POWER, ATTACK_SPEED, STAT_SPELLPOWER, STAT_ENERGY_REGEN, STAT_RUNE_REGEN, STAT_FOCUS_REGEN, STAT_SPEED, DURABILITY, HIDE, MANA_REGEN = ALTERNATE_RESOURCE_TEXT, DAMAGE, ATTACK_POWER, ATTACK_SPEED, STAT_SPELLPOWER, STAT_ENERGY_REGEN, STAT_RUNE_REGEN, STAT_FOCUS_REGEN, STAT_SPEED, DURABILITY, HIDE, MANA_REGEN
local FACTION_ALLIANCE, FACTION_HORDE, ARENA, NONE, STAT_CATEGORY_ATTRIBUTES, STAT_CATEGORY_ATTRIBUTES = FACTION_ALLIANCE, FACTION_HORDE, ARENA, NONE, STAT_CATEGORY_ATTRIBUTES, STAT_CATEGORY_ATTRIBUTES
local ADD, DELETE, HEALTH = ADD, DELETE, HEALTH
local CUSTOM = CUSTOM
local STAT_AVERAGE_ITEM_LEVEL = STAT_AVERAGE_ITEM_LEVEL
local STAT_CATEGORY_ATTRIBUTES = STAT_CATEGORY_ATTRIBUTES
local STAT_CATEGORY_ATTACK = STAT_CATEGORY_ATTACK
local STAT_CATEGORY_ENHANCEMENTS = STAT_CATEGORY_ENHANCEMENTS
local DEFENSE = DEFENSE
local STAT_CRITICAL_STRIKE,STAT_HASTE,STAT_MASTERY,STAT_VERSATILITY,STAT_LIFESTEAL = STAT_CRITICAL_STRIKE,STAT_HASTE,STAT_MASTERY,STAT_VERSATILITY,STAT_LIFESTEAL
local STAT_ARMOR,STAT_AVOIDANCE,STAT_DODGE,STAT_PARRY,STAT_BLOCK = STAT_ARMOR,STAT_AVOIDANCE,STAT_DODGE,STAT_PARRY,STAT_BLOCK

if not (KF and KF.Modules and (KF.Modules.CharacterArmory or KF.Modules.InspectArmory)) then return end

local function Color(TrueColor, FalseColor)
	return (E.db.sle.Armory.Character.Enable ~= false or E.db.sle.Armory.Inspect.Enable ~= false) and (TrueColor == '' and '' or TrueColor and '|c'..TrueColor or KF:Color_Value()) or FalseColor and '|c'..FalseColor or ''
end

local EnchantStringName, EnchantString_Old, EnchantString_New = '', '', ''
local SelectedEnchantString

local function LoadArmoryConfigTable()
	E.Options.args.sle.args.modules.args.Armory = {
		type = 'group',
		name = L["Armory Mode"],
		order = 1,
		childGroups = 'tab',
		args = {
			Credit = {
				type = 'header',
				name = KF.Credit,
				order = 1
			},
			EnchantString = {
				type = 'group',
				name = L["Enchant String"],
				order = 700,
				args = {
					Space = {
						type = 'description',
						name = ' ',
						order = 1
					},
					ConfigSpace = {
						type = 'group',
						name = L["String Replacement"],
						order = 2,
						guiInline = true,
						args = {
							CreateString = {
								order = 1,
								name = L["Create Filter"],
								type = 'input',
								width = "full",
								get = function() return EnchantStringName end,
								set = function(_, value)
									EnchantStringName = value
								end,
								disabled = function() return E.db.sle.Armory.Character.Enable == false and E.db.sle.Armory.Inspect.Enable == false end
							},
							AddButton = {
								type = 'execute',
								name = ADD,
								order = 3,
								desc = '',
								func = function()
									if EnchantStringName ~= '' and not SLE_ArmoryDB.EnchantString[EnchantStringName] then
										SLE_ArmoryDB.EnchantString[EnchantStringName] = {}
										SelectedEnchantString = EnchantStringName
										EnchantStringName = ""
									end
								end,
								disabled = function()
									return (E.db.sle.Armory.Character.Enable == false and E.db.sle.Armory.Inspect.Enable == false) or EnchantStringName == ''
								end
							},
							List = {
								type = 'select',
								name = L["List of Strings"],
								order = 4,
								get = function() return SelectedEnchantString end,
								set = function(_, value)
									SelectedEnchantString = value
									E.Options.args.sle.args.modules.args.Armory.args.EnchantString.args.ConfigSpace.args.StringGroup.name = L["List of Strings"]..":  "..value
								end,
								values = function()
									local List = {}
									List[""] = NONE
									for Name, _ in T.pairs(SLE_ArmoryDB.EnchantString) do
										List[Name] = Name
									end
									if not SelectedEnchantString then
											SelectedEnchantString = ''
										end
									return List
								end,
								disabled = function() return E.db.sle.Armory.Character.Enable == false and E.db.sle.Armory.Inspect.Enable == false end
							},
							Space2 = {
								type = 'description',
								name = ' ',
								order = 5,
								width = 'half'
							},
							StringGroup = {
								type = 'group',
								name = "",
								order = 8,
								guiInline = true,
								hidden = function()
									return SelectedEnchantString == ''
								end,
								args = {
									TargetString = {
										type = 'input',
										name = L["Original String"],
										order = 1,
										desc = '',
										width = "full",
										get = function() return SLE_ArmoryDB.EnchantString[SelectedEnchantString]["original"] end,
										set = function(_, value)
											SLE_ArmoryDB.EnchantString[SelectedEnchantString]["original"] = value
											
											if _G["CharacterArmory"] then
												_G["CharacterArmory"]:Update_Gear()
											end
											
											if _G["InspectArmory"] and _G["InspectArmory"].LastDataSetting then
												_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
											end
										end,
										disabled = function() return E.db.sle.Armory.Character.Enable == false and E.db.sle.Armory.Inspect.Enable == false end
									},
									NewString = {
										type = 'input',
										name = L["New String"],
										order = 2,
										desc = '',
										width = "full",
										get = function() return SLE_ArmoryDB.EnchantString[SelectedEnchantString]["new"] end,
										set = function(_, value)
											SLE_ArmoryDB.EnchantString[SelectedEnchantString]["new"] = value
											
											if _G["CharacterArmory"] then
												_G["CharacterArmory"]:Update_Gear()
											end
											
											if _G["InspectArmory"] and _G["InspectArmory"].LastDataSetting then
												_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
											end
										end,
										disabled = function() return E.db.sle.Armory.Character.Enable == false and E.db.sle.Armory.Inspect.Enable == false end
									},
									DeleteButton = {
										type = 'execute',
										name = DELETE,
										order = 8,
										desc = '',
										func = function()
											if SLE_ArmoryDB.EnchantString[SelectedEnchantString] then
												SLE_ArmoryDB.EnchantString[SelectedEnchantString] = nil
												SelectedEnchantString = ''
												
												if _G["CharacterArmory"] then
													_G["CharacterArmory"]:Update_Gear()
												end
												
												if _G["InspectArmory"] and _G["InspectArmory"].LastDataSetting then
													_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
												end
											end
										end,
										disabled = function() return E.db.sle.Armory.Character.Enable == false and E.db.sle.Armory.Inspect.Enable == false end,	
									},
								},
							},
						},
					},
					Space2 = {
						type = 'description',
						name = ' ',
						order = 3
					},
					CreditSpace = {
						type = 'description',
						name = ' ',
						order = 998
					},
					Credit = {
						type = 'header',
						name = KF.Credit,
						order = 999
					}
				}
			}
		}
	}

	local DisplayMethodList = {
		Always = L["Always Display"],
		MouseoverOnly = L["Mouseover"],
		Hide = HIDE
	}

	local FontStyleList = {
		NONE = NONE,
		OUTLINE = 'OUTLINE',
		
		MONOCHROMEOUTLINE = 'MONOCROMEOUTLINE',
		THICKOUTLINE = 'THICKOUTLINE'
	}

	if KF.Modules.CharacterArmory then
		local function CA_Color(TrueColor, FalseColor)
			return E.db.sle.Armory.Character.Enable ~= false and (TrueColor == '' and '' or TrueColor and '|c'..TrueColor or KF:Color_Value()) or FalseColor and '|c'..FalseColor or ''
		end
		
		E.Options.args.sle.args.modules.args.Armory.args.CAEnable = {
			type = 'toggle',
			name = L["Character Armory"],
			order = 2,
			desc = '',
			get = function() return E.db.sle.Armory.Character.Enable end,
			set = function(_, value) E.db.sle.Armory.Character.Enable = value; KF.Modules.CharacterArmory() M:ToggleItemLevelInfo(); PaperDollFrame_UpdateStats() end
		}
		
		local SelectedCABG
		E.Options.args.sle.args.modules.args.Armory.args.Character = {
			type = 'group',
			name = L["Character Armory"],
			order = 400,
			args = {
				NoticeMissing = {
					type = 'toggle',
					name = L["Show Missing Enchants or Gems"],
					order = 1,
					get = function() return E.db.sle.Armory.Character.NoticeMissing end,
					set = function(_, value) E.db.sle.Armory.Character.NoticeMissing = value; _G["CharacterArmory"]:UpdateSettings("gear") end,
					disabled = function() return not E.db.sle.Armory.Character.Enable end,
				},
				MissingIcon = {
					type = 'toggle',
					name = L["Show Warning Icon"],
					order = 2,
					get = function() return E.db.sle.Armory.Character.MissingIcon end,
					set = function(_, value) E.db.sle.Armory.Character.MissingIcon = value; _G["CharacterArmory"]:UpdateSettings("gear") end,
					disabled = function() return not E.db.sle.Armory.Character.Enable or not E.db.sle.Armory.Character.NoticeMissing end,
				},
				Stats = {
					type = 'group',
					name = STAT_CATEGORY_ATTRIBUTES,
					order = 3,
					disabled = function() return SLE._Compatibility["DejaCharacterStats"] end,
					get = function(info) return E.db.sle.Armory.Character.Stats[ info[#info] ] end,
					set = function(info, value) E.db.sle.Armory.Character.Stats[ info[#info] ] = value; PaperDollFrame_UpdateStats() end,
					args = {
						OnlyPrimary = {
							order = 1,
							type = "toggle",
							name = L["Only Relevant Stats"],
							desc = L["Show only those primary stats relevant to your spec."],
						},
						ItemLevel = {
							order = 2,
							type = "group",
							name = STAT_AVERAGE_ITEM_LEVEL,
							guiInline = true,
							args = {
								IlvlFull = {
									order = 1,
									type = "toggle",
									name = L["Full Item Level"],
									desc = L["Show both equipped and average item levels."],
								},
								IlvlColor = {
									order = 2,
									type = "toggle",
									name = L["Item Level Coloring"],
									desc = L["Color code item levels values. Equipped will be gradient, average - selected color."],
									disabled = function() return SLE._Compatibility["DejaCharacterStats"] or not E.db.sle.Armory.Character.Stats.IlvlFull end,
								},
								AverageColor = {
									type = 'color',
									order = 3,
									name = L["Color of Average"],
									desc = L["Sets the color of average item level."],
									hasAlpha = false,
									disabled = function() return SLE._Compatibility["DejaCharacterStats"] or not E.db.sle.Armory.Character.Stats.IlvlFull end,
									get = function(info)
										local t = E.db.sle.Armory.Character.Stats[ info[#info] ]
										local d = P.sle.Armory.Character.Stats[info[#info]]
										return t.r, t.g, t.b, t.a, d.r, d.g, d.b, d.a
									end,
									set = function(info, r, g, b, a)
										E.db.sle.Armory.Character.Stats[ info[#info] ] = {}
										local t = E.db.sle.Armory.Character.Stats[ info[#info] ]
										t.r, t.g, t.b, t.a = r, g, b, a
										PaperDollFrame_UpdateStats()
									end,
								},
							},
						},
						Attributes = {
							order = 10,
							type = "group",
							name = STAT_CATEGORY_ATTRIBUTES,
							guiInline = true,
							get = function(info) return E.db.sle.Armory.Character.Stats.List[ info[#info] ] end,
							set = function(info, value) E.db.sle.Armory.Character.Stats.List[ info[#info] ] = value; _G["CharacterArmory"]:ToggleStats() end,
							args = {
								HEALTH = { order = 1,type = "toggle",name = HEALTH,},
								POWER = { order = 2,type = "toggle",name = _G[T.select(2, UnitPowerType("player"))],},
								ALTERNATEMANA = { order = 3,type = "toggle",name = ALTERNATE_RESOURCE_TEXT,},
								MOVESPEED = { order = 4,type = "toggle",name = STAT_SPEED,},
							},
						},
						Attack = {
							order = 11,
							type = "group",
							name = STAT_CATEGORY_ATTACK,
							guiInline = true,
							get = function(info) return E.db.sle.Armory.Character.Stats.List[ info[#info] ] end,
							set = function(info, value) E.db.sle.Armory.Character.Stats.List[ info[#info] ] = value; _G["CharacterArmory"]:ToggleStats() end,
							args = {
								ATTACK_DAMAGE = { order = 1,type = "toggle",name = DAMAGE,},
								ATTACK_AP = { order = 2,type = "toggle",name = ATTACK_POWER,},
								ATTACK_ATTACKSPEED = { order = 3,type = "toggle",name = ATTACK_SPEED,},
								SPELLPOWER = { order = 4,type = "toggle",name = STAT_SPELLPOWER,},
								MANAREGEN = { order = 5,type = "toggle",name = MANA_REGEN,},
								ENERGY_REGEN = { order = 6,type = "toggle",name = STAT_ENERGY_REGEN,},
								RUNE_REGEN = { order = 7,type = "toggle",name = STAT_RUNE_REGEN,},
								FOCUS_REGEN = { order = 8,type = "toggle",name = STAT_FOCUS_REGEN,},
							},
						},
						Enhancements = {
							order = 12,
							type = "group",
							name = STAT_CATEGORY_ENHANCEMENTS,
							guiInline = true,
							get = function(info) return E.db.sle.Armory.Character.Stats.List[ info[#info] ] end,
							set = function(info, value) E.db.sle.Armory.Character.Stats.List[ info[#info] ] = value; _G["CharacterArmory"]:ToggleStats() end,
							args = {
								CRITCHANCE = { order = 1,type = "toggle",name = STAT_CRITICAL_STRIKE,},
								HASTE = { order = 2,type = "toggle",name = STAT_HASTE,},
								MASTERY = { order = 3,type = "toggle",name = STAT_MASTERY,},
								VERSATILITY = { order = 4,type = "toggle",name = STAT_VERSATILITY,},
								LIFESTEAL = { order = 5,type = "toggle",name = STAT_LIFESTEAL,},
							},
						},
						Defence = {
							order = 13,
							type = "group",
							name = DEFENSE,
							guiInline = true,
							get = function(info) return E.db.sle.Armory.Character.Stats.List[ info[#info] ] end,
							set = function(info, value) E.db.sle.Armory.Character.Stats.List[ info[#info] ] = value; _G["CharacterArmory"]:ToggleStats() end,
							args = {
								ARMOR = { order = 1,type = "toggle",name = STAT_ARMOR,},
								AVOIDANCE = { order = 2,type = "toggle",name = STAT_AVOIDANCE,},
								DODGE = { order = 3,type = "toggle",name = STAT_DODGE,},
								PARRY = { order = 4,type = "toggle",name = STAT_PARRY,},
								BLOCK = { order = 5,type = "toggle",name = STAT_BLOCK,},
								-- STAGGER = { order = 6,type = "toggle",name = STAT_STAGGER,},
							},
						},
					},
				},
				Fonts = {
					type = "group",
					name = STAT_CATEGORY_ATTRIBUTES..": "..L["Fonts"],
					-- guiInline = true,
					order = 3,
					args = {
						IlvlFont = {
							type = 'group',
							name = STAT_AVERAGE_ITEM_LEVEL,
							order = 1,
							guiInline = true,
							get = function(info) return E.db.sle.Armory.Character.Stats.ItemLevel[ info[#info] ] end,
							set = function(info, value) E.db.sle.Armory.Character.Stats.ItemLevel[ info[#info] ] = value; _G["CharacterArmory"]:UpdateIlvlFont() end,
							args = {
								font = {
									type = 'select', dialogControl = 'LSM30_Font',
									name = L["Font"],
									order = 1,
									values = function()
										return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {}
									end,
								},
								size = {
									type = 'range',
									name = L["Font Size"],
									order = 2,
									min = 10,max = 22,step = 1,
								},
								outline = {
									type = 'select',
									name = L["Font Outline"],
									order = 3,
									values = FontStyleList,
								},
							},
						},
						statFonts = {
							type = 'group',
							name = STAT_CATEGORY_ATTRIBUTES,
							order = 2,
							guiInline = true,
							get = function(info) return E.db.sle.Armory.Character.Stats.statFonts[ info[#info] ] end,
							set = function(info, value) E.db.sle.Armory.Character.Stats.statFonts[ info[#info] ] = value; _G["CharacterArmory"]:PaperDollFrame_UpdateStats() end,
							args = {
								font = {
									type = 'select', dialogControl = 'LSM30_Font',
									name = L["Font"],
									order = 1,
									values = function()
										return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {}
									end,
								},
								size = {
									type = 'range',
									name = L["Font Size"],
									order = 2,
									min = 10,max = 22,step = 1,
								},
								outline = {
									type = 'select',
									name = L["Font Outline"],
									order = 3,
									values = FontStyleList,
								},
							},
						},
						catFonts = {
							type = 'group',
							name = L["Categories"],
							order = 3,
							guiInline = true,
							get = function(info) return E.db.sle.Armory.Character.Stats.catFonts[ info[#info] ] end,
							set = function(info, value) E.db.sle.Armory.Character.Stats.catFonts[ info[#info] ] = value; _G["CharacterArmory"]:PaperDollFrame_UpdateStats() end,
							args = {
								font = {
									type = 'select', dialogControl = 'LSM30_Font',
									name = L["Font"],
									order = 1,
									values = function()
										return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {}
									end,
								},
								size = {
									type = 'range',
									name = L["Font Size"],
									order = 2,
									min = 10,max = 22,step = 1,
								},
								outline = {
									type = 'select',
									name = L["Font Outline"],
									order = 3,
									values = FontStyleList,
								},
							},
						},
					},
				},
				Backdrop = {
					type = 'group',
					name = L["Backdrop"],
					order = 4,
					args = {
						SelectedBG = {
							type = 'select',
							name = L["Select Image"],
							order = 1,
							get = function()
								for Index, Key in T.pairs(Info.BackgroundsTextures.Keys) do
									if Key == E.db.sle.Armory.Character.Backdrop.SelectedBG then
										return Index
									end
								end
								return '1'
							end,
							set = function(_, value) E.db.sle.Armory.Character.Backdrop.SelectedBG = Info.BackgroundsTextures.Keys[value]; _G["CharacterArmory"]:UpdateSettings("bg") end,
							values = function() return Info.BackgroundsTextures.Config end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						CustomAddress = {
							type = 'input',
							name = L["Custom Image Path"],
							order = 2,
							get = function() return E.db.sle.Armory.Character.Backdrop.CustomAddress end,
							set = function(_, value) E.db.sle.Armory.Character.Backdrop.CustomAddress = value; _G["CharacterArmory"]:UpdateSettings("bg") end,
							width = 'double',
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							hidden = function() return E.db.sle.Armory.Character.Backdrop.SelectedBG ~= 'CUSTOM' end
						},
						Overlay = {
							type = "toggle",
							order = 3,
							name = L["Overlay"],
							desc = L["Show ElvUI skin's backdrop overlay"],
							get = function() return E.db.sle.Armory.Character.Backdrop.Overlay end,
							set = function(_, value) E.db.sle.Armory.Character.Backdrop.Overlay = value; _G["CharacterArmory"]:ElvOverlayToggle() end
						},
					}
				},
				Gradation = {
					type = 'group',
					name = L["Gradient"],
					order = 5,
					args = {
						Display = {
							type = 'toggle',
							name = L["Enable"],
							order = 1,
							get = function() return E.db.sle.Armory.Character.Gradation.Display end,
							set = function(_, value) E.db.sle.Armory.Character.Gradation.Display = value; _G["CharacterArmory"]:Update_Gear() end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						Color = {
							type = 'color',
							name = L["Gradient Texture Color"],
							order = 2,
							get = function() 
								return E.db.sle.Armory.Character.Gradation.Color[1],
									   E.db.sle.Armory.Character.Gradation.Color[2],
									   E.db.sle.Armory.Character.Gradation.Color[3],
									   E.db.sle.Armory.Character.Gradation.Color[4]
							end,
							set = function(Info, r, g, b, a) E.db.sle.Armory.Character.Gradation.Color = { r, g, b, a }; _G["CharacterArmory"]:Update_Gear() end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false or E.db.sle.Armory.Character.Gradation.Display == false end
						},
						ItemQuality = {
							type = 'toggle',
							name = COLORBLIND_ITEM_QUALITY,
							order = 1,
							get = function() return E.db.sle.Armory.Character.Gradation.ItemQuality end,
							set = function(_, value) E.db.sle.Armory.Character.Gradation.ItemQuality = value; _G["CharacterArmory"]:Update_Gear() end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						}
					}
				},
				Level = {
					type = 'group',
					name = L["Item Level"],
					order = 7,
					get = function(info) return E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] = value; _G["CharacterArmory"]:UpdateSettings("ilvl") end,
					args = {
						Display = {
							type = 'select',
							name = L["Visibility"],
							order = 1,
							set = function(info, value) E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] = value;  _G["CharacterArmory"]:UpdateSettings("gear") end,
							values = DisplayMethodList,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						ShowUpgradeLevel = {
							type = 'toggle',
							name = L["Upgrade Level"],
							order = 2,
							set = function(_, value) E.db.sle.Armory.Character.Level.ShowUpgradeLevel = value; _G["CharacterArmory"]:Update_Gear() end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						Space = {
							type = 'description',
							name = '',
							order = 3
						},
						Font = {
							type = 'select', dialogControl = 'LSM30_Font',
							name = L["Font"],
							order = 4,
							values = function() return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {} end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						FontSize = {
							type = 'range',
							name = L["Font Size"],
							order = 5,
							min = 6, max = 22, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						FontStyle = {
							type = 'select',
							name = L["Font Outline"],
							order = 6,
							values = FontStyleList,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						ItemColor = {
							type = 'select',
							name = L["Item Level Coloring"],
							order = 7,
							set = function(_, value) E.db.sle.Armory.Character.Level.ItemColor = value; _G["CharacterArmory"]:Update_Gear() end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							values = {
								["NONE"] = NONE,
								["QUALITY"] = COLORBLIND_ITEM_QUALITY,
								["GRADIENT"] = L["Gradient"],
							},
						},
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 8,
							min = -40, max = 150, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Level.xOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 8,
							min = -22, max = 3, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Level.yOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
					}
				},
				AzeritePosition = {
					order = 8,
					type = 'group',
					name = L["Azerite Level Position"],
					get = function(info) return E.db.sle.Armory.Character.AzeritePosition[(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Character.AzeritePosition[(info[#info])] = value; _G["CharacterArmory"]:UpdateSettings("gear") end,
					disabled = function() return not E.db.sle.Armory.Character.Enable end,
					args = {
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 1,
							min = -6,max = 30,step = 1,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 2,
							min = -6,max = 30,step = 1,
						},
					},
				},
				Transmog = {
					order = 9,
					type = 'group',
					name = L["Transmog"],
					get = function(info) return E.db.sle.Armory.Character.Transmog[(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Character.Transmog[(info[#info])] = value; _G["CharacterArmory"]:UpdateSettings("gear") end,
					disabled = function() return not E.db.sle.Armory.Character.Enable end,
					args = {
						enableGlow = {
							order = 1,
							type = "toggle",
							name = L["Enable Glow"],
						},
						enableArrow = {
							order = 2,
							type = "toggle",
							name = L["Enable Arrow"],
							desc = L["Enables a small arrow-like indicator on the item slot. Howering over this arrow will show the item this slot is transmogged into."],
						},
						glowNumber = {
							type = 'range',
							name = L["Glow Number"],
							order = 3,
							min = 2,max = 8,step = 1,
							disabled = function() return not E.db.sle.Armory.Character.Transmog.enableGlow end,
						},
						glowOffset = {
							type = 'range',
							name = L["Glow Offset"],
							order = 4,
							min = -2,max = 4,step = 1,
							disabled = function() return not E.db.sle.Armory.Character.Transmog.enableGlow end,
						},
					},
				},
				Enchant = {
					type = 'group',
					name = L["Enchant String"],
					order = 10,
					get = function(info) return E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] = value;  _G["CharacterArmory"]:UpdateSettings("ench") end,
					args = {
						Display = {
							type = 'select',
							name = L["Visibility"],
							order = 1,
							values = DisplayMethodList,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						WarningSize = {
							type = 'range',
							name = L["Warning Size"],
							order = 2,
							min = 6, max = 50, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						WarningIconOnly = {
							type = 'toggle',
							name = L["Warning Only As Icons"],
							order = 3,
							set = function(_, value) E.db.sle.Armory.Character.Enchant.WarningIconOnly = value; _G["CharacterArmory"]:Update_Gear() end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
						},
						Space = {
							type = 'description',
							name = '',
							order = 4
						},
						Font = {
							type = 'select', dialogControl = 'LSM30_Font',
							name = L["Font"],
							order = 5,
							values = function() return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {} end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						FontSize = {
							type = 'range',
							name = L["Font Size"],
							order = 6,
							min = 6, max = 22, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						FontStyle = {
							type = 'select',
							name = L["Font Outline"],
							order = 7,
							values = FontStyleList,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 8,
							min = -2, max = 40, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Enchant.xOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 8,
							min = -13, max = 13, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Enchant.yOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
					}
				},
				Durability = {
					type = 'group',
					name = DURABILITY,
					order = 11,
					get = function(info) return E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] = value; _G["CharacterArmory"]:UpdateSettings("dur") end,
					args = {
						Display = {
							type = 'select',
							name = L["Visibility"],
							order = 1,
							set = function(info, value) E.db.sle.Armory.Character[(info[#info - 1])][(info[#info])] = value; _G["CharacterArmory"]:UpdateSettings("gear") end,
							values = {
								Always = L["Always Display"],
								DamagedOnly = L["Only Damaged"],
								MouseoverOnly = L["Mouseover"],
								Hide = HIDE
							},
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						Space = {
							type = 'description',
							name = '',
							order = 2
						},
						Font = {
							type = 'select', dialogControl = 'LSM30_Font',
							name = L["Font"],
							order = 3,
							values = function() return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {} end,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						FontSize = {
							type = 'range',
							name = L["Font Size"],
							order = 4,
							min = 6, max = 22, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						FontStyle = {
							type = 'select',
							name = L["Font Outline"],
							order = 5,
							values = FontStyleList,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 8,
							min = -2, max = 150, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Durability.xOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 8,
							min = -22, max = 3, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Durability.yOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
					}
				},
				Gem = {
					type = 'group',
					name = L["Gem Sockets"],
					order = 13,
					get = function(Info) return E.db.sle.Armory.Character[(Info[#Info - 1])][(Info[#Info])] end,
					args = {
						Display = {
							type = 'select',
							name = L["Visibility"],
							order = 1,
							set = function(Info, value) E.db.sle.Armory.Character[(Info[#Info - 1])][(Info[#Info])] = value; _G["CharacterArmory"]:UpdateSettings("gem") end,
							values = DisplayMethodList,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						SocketSize = {
							type = 'range',
							name = L["Socket Size"],
							order = 2,
							set = function(_, value) E.db.sle.Armory.Character.Gem.SocketSize = value; _G["CharacterArmory"]:UpdateSettings("gem") end,
							min = 6, max = 50, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						WarningSize = {
							type = 'range',
							name = L["Warning Size"],
							order = 3,
							min = 6,max = 50,step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end
						},
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 8,
							min = -40, max = 150, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Gem.xOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 8,
							min = -3, max = 22, step = 1,
							disabled = function() return E.db.sle.Armory.Character.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Character.Gem.yOffset = value; _G["CharacterArmory"]:Update_Display(true) end,
						},
					},
				},
			},
		}
	end


	if KF.Modules.InspectArmory then
		local function IA_Color(TrueColor, FalseColor)
			return E.db.sle.Armory.Inspect.Enable ~= false and (TrueColor == '' and '' or TrueColor and '|c'..TrueColor or KF:Color_Value()) or FalseColor and '|c'..FalseColor or ''
		end
		
		local function CreateFontsOptions(index, Name, Arg, maxSize)
			local config = {
				order = index,
				name = Name,
				type = "group",
				guiInline = true,
				disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
				get = function(info) return E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] end,
				set = function(info, value) E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] = value; _G["InspectArmory"]:UpdateSettings(Arg) end,
				args = {
					Font = {
						type = 'select', dialogControl = 'LSM30_Font',
						name = L["Font"],
						order = 1,
						values = function()
							return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {}
						end,
					},
					FontSize = {
						type = 'range',
						name = L["Font Size"],
						order = 2,
						min = 6,max = maxSize,step = 1,
					},
					FontStyle = {
						type = 'select',
						name = L["Font Outline"],
						order = 3,
						values = FontStyleList,
					},
				},
			}
			return config
		end
		
		E.Options.args.sle.args.modules.args.Armory.args.IAEnable = {
			type = 'toggle',
			name = L["Inspect Armory"],
			order = 3,
			get = function() return E.db.sle.Armory.Inspect.Enable end,
			set = function(_, value) E.db.sle.Armory.Inspect.Enable = value; KF.Modules.InspectArmory() M:ToggleItemLevelInfo() end
		}
		
		E.Options.args.sle.args.modules.args.Armory.args.Inspect = {
			type = 'group',
			name = L["Inspect Armory"],
			order = 500,
			args = {
				NoticeMissing = {
					type = 'toggle',
					name = L["Show Missing Enchants or Gems"],
					order = 1,
					get = function() return E.db.sle.Armory.Inspect.NoticeMissing end,
					set = function(_, value)
						E.db.sle.Armory.Inspect.NoticeMissing = value
						
						if _G["InspectArmory"].LastDataSetting then
							_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
						end
						_G["InspectArmory"]:Update_Display(true)
					end,
					disabled = function() return not E.db.sle.Armory.Inspect.Enable end,
				},
				MissingIcon = {
					type = 'toggle',
					name = L["Show Warning Icon"],
					order = 2,
					get = function() return E.db.sle.Armory.Inspect.MissingIcon end,
					set = function(_, value)
						E.db.sle.Armory.Inspect.MissingIcon = value
						
						if _G["InspectArmory"].LastDataSetting then
							_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
						end
						_G["InspectArmory"]:Update_Display(true)
					end,
					disabled = function() return not E.db.sle.Armory.Inspect.Enable or not E.db.sle.Armory.Inspect.NoticeMissing end,
				},
				InspectMessage = {
					type = 'toggle',
					name = L["Show Inspection message in chat"],
					order = 3,
					disabled = function() return not E.db.sle.Armory.Inspect.Enable end,
					get = function() return E.db.sle.Armory.Inspect.InspectMessage end,
					set = function(_, value) E.db.sle.Armory.Inspect.InspectMessage = value end,
				},
				Backdrop = {
					type = 'group',
					name = L["Backdrop"],
					order = 4,
					args = {
						SelectedBG = {
							type = 'select',
							name = L["Select Image"],
							order = 1,
							get = function()
								for Index, Key in T.pairs(Info.BackgroundsTextures.Keys) do
									if Key == E.db.sle.Armory.Inspect.Backdrop.SelectedBG then
										return Index
									end
								end
								return '1'
							end,
							set = function(_, value)
								E.db.sle.Armory.Inspect.Backdrop.SelectedBG = Info.BackgroundsTextures.Keys[value]
								
								_G["InspectArmory"]:Update_BG()
							end,
							values = function() return Info.BackgroundsTextures.Config end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						CustomAddress = {
							type = 'input',
							name = L["Custom Image Path"],
							order = 2,
							get = function() return E.db.sle.Armory.Inspect.Backdrop.CustomAddress end,
							set = function(_, value)
								E.db.sle.Armory.Inspect.Backdrop.CustomAddress = value
								
								_G["InspectArmory"]:Update_BG()
							end,
							width = 'double',
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							hidden = function() return E.db.sle.Armory.Inspect.Backdrop.SelectedBG ~= 'CUSTOM' end
						},
						Overlay = {
							type = 'toggle',
							name = L["Overlay"],
							order = 3,
							disabled = function() return not E.db.sle.Armory.Inspect.Enable end,
							get = function() return E.db.sle.Armory.Inspect.Backdrop.Overlay end,
							set = function(_, value) E.db.sle.Armory.Inspect.Backdrop.Overlay = value; _G["InspectArmory"]:ToggleOverlay() end,
						},
						OverlayAlpha = {
							type = 'range',
							name = L["Alpha"],
							order = 4,
							isPercent = true,
							min = 0,max = 1,step = 0.01,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							get = function() return E.db.sle.Armory.Inspect.Backdrop.OverlayAlpha end,
							set = function(_, value) E.db.sle.Armory.Inspect.Backdrop.OverlayAlpha = value; _G["InspectArmory"]:UpdateSettings("overlay") end
						},
					}
				},
				Gradation = {
					type = 'group',
					name = L["Gradient"],
					order = 5,
					args = {
						Display = {
							type = 'toggle',
							name = L["Enable"],
							order = 1,
							get = function() return E.db.sle.Armory.Inspect.Gradation.Display end,
							set = function(_, value)
								E.db.sle.Armory.Inspect.Gradation.Display = value
								
								if _G["InspectArmory"] and _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
							end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						CurrentClassColor = {
							type = 'toggle',
							name = L["Use Inspected Unit Class Color"],
							order = 2,
							get = function() return E.db.sle.Armory.Inspect.Gradation.CurrentClassColor end,
							set = function(_, value)
								E.db.sle.Armory.Inspect.Gradation.CurrentClassColor = value
								
								if _G["InspectArmory"] and _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
							end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						Color = {
							type = 'color',
							name = L["Gradient Texture Color"],
							order = 3,
							get = function() 
								return E.db.sle.Armory.Inspect.Gradation.Color[1],
									   E.db.sle.Armory.Inspect.Gradation.Color[2],
									   E.db.sle.Armory.Inspect.Gradation.Color[3],
									   E.db.sle.Armory.Inspect.Gradation.Color[4]
							end,
							set = function(Info, r, g, b, a)
								E.db.sle.Armory.Inspect.Gradation.Color = { r, g, b, a }
								
								if _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
							end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false or E.db.sle.Armory.Inspect.Gradation.Display == false or E.db.sle.Armory.Inspect.Gradation.CurrentClassColor == true end
						},
						ItemQuality = {
							type = 'toggle',
							name = COLORBLIND_ITEM_QUALITY,
							order = 4,
							get = function() return E.db.sle.Armory.Inspect.Gradation.ItemQuality end,
							set = function(_, value) E.db.sle.Armory.Inspect.Gradation.ItemQuality = value; end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						}

					}
				},
				Level = {
					type = 'group',
					name = L["Item Level"],
					order = 7,
					get = function(info) return E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] = value; _G["InspectArmory"]:UpdateSettings("ilvl") end,
					args = {
						Display = {
							type = 'select',
							name = L["Visibility"],
							order = 1,
							set = function(info, value)
								E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] = value
								
								if _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
								_G["InspectArmory"]:Update_Display(true)
							end,
							values = DisplayMethodList,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						ShowUpgradeLevel = {
							type = 'toggle',
							name = L["Upgrade Level"],
							order = 2,
							set = function(_, value)
								E.db.sle.Armory.Inspect.Level.ShowUpgradeLevel = value
								
								if _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
							end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						Space = {
							type = 'description',
							name = '',
							order = 3
						},
						Font = {
							type = 'select', dialogControl = 'LSM30_Font',
							name = L["Font"],
							order = 4,
							values = function()
								return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {}
							end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						FontSize = {
							type = 'range',
							name = L["Font Size"],
							order = 5,
							min = 6,max = 22,step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						FontStyle = {
							type = 'select',
							name = L["Font Outline"],
							order = 6,
							values = FontStyleList,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						ItemColor = {
							type = 'toggle',
							name = L["Item Level Coloring"],
							order = 7,
							get = function(info) return E.db.sle.Armory.Inspect.Level.ItemColor end,
							set = function(_, value) E.db.sle.Armory.Inspect.Level.ItemColor = value; end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 8,
							min = -40, max = 150, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Inspect.Level.xOffset = value; _G["InspectArmory"]:Update_Display(true) end,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 8,
							min = -22, max = 3, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Inspect.Level.yOffset = value; _G["InspectArmory"]:Update_Display(true) end,
						},
					}
				},
				Enchant = {
					type = 'group',
					name = L["Enchant String"],
					order = 9,
					get = function(info) return E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] = value; _G["InspectArmory"]:UpdateSettings("ench") end,
					args = {
						Display = {
							type = 'select',
							name = L["Visibility"],
							order = 1,
							set = function(info, value)
								E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] = value
								
								if _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
								_G["InspectArmory"]:Update_Display(true)
							end,
							values = DisplayMethodList,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						WarningSize = {
							type = 'range',
							name = L["Warning Size"],
							order = 2,
							min = 6, max = 50, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						WarningIconOnly = {
							type = 'toggle',
							name = L["Warning Only As Icons"],
							order = 3,
							set = function(_, value)
								E.db.sle.Armory.Inspect.Enchant.WarningIconOnly = value
								if _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
							end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
						},
						Space = {
							type = 'description',
							name = '',
							order = 4
						},
						Font = {
							type = 'select', dialogControl = 'LSM30_Font',
							name = L["Font"],
							order = 5,
							values = function()
								return AceGUIWidgetLSMlists and AceGUIWidgetLSMlists.font or {}
							end,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						FontSize = {
							type = 'range',
							name = L["Font Size"],
							order = 6,
							min = 6, max = 22, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						FontStyle = {
							type = 'select',
							name = L["Font Outline"],
							order = 7,
							values = FontStyleList,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 8,
							min = -2, max = 40, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Inspect.Enchant.xOffset = value; _G["InspectArmory"]:Update_Display(true) end,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 8,
							min = -13, max = 13, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Inspect.Enchant.yOffset = value; _G["InspectArmory"]:Update_Display(true) end,
						},
					}
				},
				Gem = {
					type = 'group',
					name = L["Gem Sockets"],
					order = 11,
					get = function(Info) return E.db.sle.Armory.Inspect[(Info[#Info - 1])][(Info[#Info])] end,
					set = function(info, value) E.db.sle.Armory.Inspect[(info[#info - 1])][(info[#info])] = value; _G["InspectArmory"]:UpdateSettings("gem") end,
					args = {
						Display = {
							type = 'select',
							name = L["Visibility"],
							order = 1,
							set = function(Info, value)
								E.db.sle.Armory.Inspect[(Info[#Info - 1])][(Info[#Info])] = value
								if _G["InspectArmory"].LastDataSetting then
									_G["InspectArmory"]:InspectFrame_DataSetting(_G["InspectArmory"].CurrentInspectData)
								end
								_G["InspectArmory"]:Update_Display(true)
							end,
							values = DisplayMethodList,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						SocketSize = {
							type = 'range',
							name = L["Socket Size"],
							order = 2,
							min = 6,max = 50,step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						WarningSize = {
							type = 'range',
							name = L["Warning Size"],
							order = 3,
							min = 6,max = 50,step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end
						},
						xOffset = {
							type = 'range',
							name = L["X-Offset"],
							order = 8,
							min = -40, max = 150, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Inspect.Gem.xOffset = value; _G["InspectArmory"]:Update_Display(true) end,
						},
						yOffset = {
							type = 'range',
							name = L["Y-Offset"],
							order = 8,
							min = -3, max = 22, step = 1,
							disabled = function() return E.db.sle.Armory.Inspect.Enable == false end,
							set = function(_, value) E.db.sle.Armory.Inspect.Gem.yOffset = value; _G["InspectArmory"]:Update_Display(true) end,
						},
					}
				},
				Transmog = {
					order = 12,
					type = 'group',
					name = L["Transmog"],
					get = function(info) return E.db.sle.Armory.Inspect.Transmog[(info[#info])] end,
					set = function(info, value) E.db.sle.Armory.Inspect.Transmog[(info[#info])] = value; _G["InspectArmory"]:UpdateSettings("transmog") end,
					disabled = function() return not E.db.sle.Armory.Inspect.Enable end,
					args = {
						enableGlow = {
							order = 1,
							type = "toggle",
							name = L["Enable Glow"],
						},
						enableArrow = {
							order = 2,
							type = "toggle",
							name = L["Enable Arrow"],
							desc = L["Enables a small arrow-like indicator on the item slot. Howering over this arrow will show the item this slot is transmogged into."],
						},
						glowNumber = {
							type = 'range',
							name = L["Glow Number"],
							order = 3,
							min = 2,max = 8,step = 1,
							disabled = function() return not E.db.sle.Armory.Inspect.Transmog.enableGlow end,
						},
						glowOffset = {
							type = 'range',
							name = L["Glow Offset"],
							order = 4,
							min = -2,max = 4,step = 1,
							disabled = function() return not E.db.sle.Armory.Inspect.Transmog.enableGlow end,
						},
					},
				},
				GeneralFonts = {
					order = 20,
					name = L["General Fonts"],
					type = "group",
					args = {
						Name = CreateFontsOptions(1, NAME, "nameText", 40),
						Title = CreateFontsOptions(2, L["Title"], "titleText", 30),
						LevelRace = CreateFontsOptions(3, L["Level and race"], "levelText", 30),
						Guild = CreateFontsOptions(4, GUILD, "guildText", 30),
						tabsText = CreateFontsOptions(5, L["Tabs"], "tabs", 20),
					},
				},
				InfoFonts = {
					order = 21,
					name = L["Info Fonts"],
					type = "group",
					args = {
						infoTabs = CreateFontsOptions(1, L["Block names"], "infoTabs", 30),
						pvpText = CreateFontsOptions(2, HONOR, "pvp", 18),
						pvpType = CreateFontsOptions(3, L["PvP Type"], "pvp", 30),
						pvpRating = CreateFontsOptions(4, RATING, "pvp", 40),
						pvpRecord = CreateFontsOptions(5, BEST, "pvp", 30),
						guildName = CreateFontsOptions(6, GUILD, "guild", 22),
						guildMembers = CreateFontsOptions(7, MEMBERS, "guild", 20),
					},
				},
				SpecFonts = {
					order = 22,
					name = L["Spec Fonts"],
					type = "group",
					args = {
						Spec = CreateFontsOptions(1, SPECIALIZATION, "spec", 20),
					},
				},
			}
		}
	end
end

T.tinsert(SLE.Configs, 9, LoadArmoryConfigTable)
