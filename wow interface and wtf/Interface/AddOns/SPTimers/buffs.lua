local addon, C = ...
local colors = C.CustomColors
local L = AleaUI_GUI.GetLocale("SPTimers")

local find = string.find
local floor = math.floor
local select = select
local GetTime = GetTime
local GetSpellInfo = GetSpellInfo
local UnitIsUnit = UnitIsUnit
local pairs = pairs
local ipairs = ipairs
local type = type
local UnitBuff = UnitBuff
local PlaySoundFile = PlaySoundFile
local UnitInRaid = UnitInRaid
local UnitInParty = UnitInParty
local UnitGUID = UnitGUID
local GetSpellLink = GetSpellLink

local CASTER = "CASTER"
local CASTER_HEAL = "CASTER_HEAL"
local CASTER_DPS = "CASTER_DPS"

local MELEE = "MELEE"
local MELEE_STR = "MELEE_STR"
local MELEE_AGI = "MELEE_AGI"

local TANK = "TANK"

local ALL = "ALL"

local COOLDOWN_SPELL = "COOLDOWN_SPELL"

local PATCH_BC  = 'PATCH_BC'
local PATCH_WLK = 'PATCH_WLK'
local PATCH_CAT = 'PATCH_CATA'
local PATCH_MOP = 'PATCH_MOP'
local PATCH_WOD = 'PATCH_WOD'
local PATCH_LEG = 'PATCH_LEG'

local old_print = print
local print = function(...)
	if C.dodebugging then	
		old_print(GetTime(), "SPTimers_buffs.lua, ", ...)
	end
end

local procs = { -- short timed buffs, trinkets etc

	-- caster trinckets 
	[125487] = { patch = PATCH_MOP, role = CASTER, target_affil = 2}, -- LIGHTWELL
	[125488] = { patch = PATCH_MOP, role = CASTER_HEAL, target_affil = 2}, -- Darkglow

	[104993] = { patch = PATCH_MOP, role = CASTER, target_affil = 2, source = 1, several = true }, -- JADE SPIRIT
	[120032] = { patch = PATCH_MOP, role = MELEE_AGI, target_affil = 2, source = 1, several = true }, -- 
	[118335] = { patch = PATCH_MOP, role = MELEE_STR, target_affil = 2, source = 1, several = true },
	
	[138898] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2, }, -- MEGAERA
	[138963] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2, }, -- UVLS
	[139133] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2, }, -- CHAE
	[138786] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2, checkstaucks = 138788 }, -- WYSHU
	[137590] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2,  }, -- LMG
	[128985] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2, }, -- Relic of Yu'lon
	
	[138703] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2,  }, -- 5.2 Spell Valor trinket
	[138699] = { patch = PATCH_MOP, role = MELEE_AGI,target_affil = 2,  },
	
	[146046] = { patch = PATCH_MOP, role = CASTER_DPS,target_affil = 2,  }, -- immerseus Trincket	
	[146184] = { patch = PATCH_MOP, role = CASTER_DPS, target_affil = 2, checkstaucks = 146202 }, -- Garrosh trinket
	[146218] = { patch = PATCH_MOP, role = CASTER_DPS,target_affil = 2,  }, -- Celestial trinket +crit
	[148906] = { patch = PATCH_MOP, role = CASTER_DPS,target_affil = 2,  }, -- KorKronShaman
	[148897] = { patch = PATCH_MOP, role = CASTER_DPS,target_affil = 2,  }, -- Malkorok

	[33702] = { patch = PATCH_MOP, role = CASTER,target_affil = 2,  },
	[33697] = { patch = PATCH_MOP, role = ALL,target_affil = 2,  },
	[20572] = { patch = PATCH_MOP, role = MELEE,target_affil = 2,  },
	
	-- Potions
	[105702] = { patch = PATCH_MOP, role = CASTER, target_affil = 2,  }, -- Potion of the Jade Serpent
	
	----- Hero --------
	[90355] = { role = ALL,target_affil = 2,  source = 1 },
	[2825] = {  role = ALL,target_affil = 2,  source = 1 },
	[32182] = { role = ALL,target_affil = 2,  source = 1 },
	[80353] = { role = ALL,target_affil = 2,  source = 1 },
	[146555] = { role = ALL,target_affil = 2,  source = 1},
	[178207] = { role = ALL,target_affil = 2,  source = 1},
	-------------------
	
	-- Melee trinkets 
	
	[146308] = { patch = PATCH_MOP, role = MELEE_AGI,target_affil = 2, },
	[148903] = { patch = PATCH_MOP, role = MELEE_AGI,target_affil = 2, },
	[146310] = { patch = PATCH_MOP, role = MELEE_AGI,target_affil = 2, },
	[148896] = { patch = PATCH_MOP, role = MELEE_AGI,target_affil = 2, },
	
	[148899] = { patch = PATCH_MOP, role = MELEE_STR,target_affil = 2, },
	[146245] = { patch = PATCH_MOP, role = MELEE_STR,target_affil = 2, },
	[146285] = { patch = PATCH_MOP, role = MELEE_STR,target_affil = 2, },
	[146250] = { patch = PATCH_MOP, role = MELEE_STR,target_affil = 2, },
	
	[146312] = { patch = PATCH_MOP, role = MELEE_AGI,target_affil = 2, },
	[126649] = { patch = PATCH_MOP, role = MELEE_AGI,target_affil = 2, },
	
	[146296] = { patch = PATCH_MOP, role = MELEE_STR,target_affil = 2, },
	-- Tanks trinkers
	
	[105645] = { patch = PATCH_MOP, role = TANK,target_affil = 2, },
	[146343] = { patch = PATCH_MOP, role = TANK,target_affil = 2, },
	[146344] = { patch = PATCH_MOP, role = TANK,target_affil = 2, },
	
	-- Healers
	
	[146317] = { patch = PATCH_MOP, role = CASTER_HEAL,target_affil = 2, },
	[146314] = { patch = PATCH_MOP, role = CASTER_HEAL,target_affil = 2, },
	[148911] = { patch = PATCH_MOP, role = CASTER_HEAL,target_affil = 2, },
	[148908] = { patch = PATCH_MOP, role = CASTER_HEAL,target_affil = 2, },

	------------------------------
	
	-- WOD
	
	-- enchants
	[159676] = { patch = PATCH_WOD, role = ALL, target_affil = 2, source = 1, several = true },
	[159679] = { patch = PATCH_WOD, role = TANK, target_affil = 2, source = 1, several = true },
	[159678] = { patch = PATCH_WOD, role = CASTER_HEAL, target_affil = 2, source = 1, several = true },
	[159234] = { patch = PATCH_WOD, role = ALL, target_affil = 2, source = 1, several = true },
	[159675] = { patch = PATCH_WOD, role = ALL, target_affil = 2, source = 1, several = true },
	[156055] = { patch = PATCH_WOD, role = ALL, target_affil = 2,source = 1, several = true },
	[156060] = { patch = PATCH_WOD, role = ALL, target_affil = 2,source = 1, several = true },
	[173322] = { patch = PATCH_WOD, role = ALL, target_affil = 2, source = 1, several = true },
	
	-- potions
	[156426] = { patch = PATCH_WOD, role = CASTER, target_affil = 2, },
	[156430] = { patch = PATCH_WOD, role = TANK, target_affil = 2, },
	[156428] = { patch = PATCH_WOD, role = MELEE_STR, target_affil = 2, },
	[156423] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2, },
	
	-- legendary ring 
	[177159] = { patch = PATCH_WOD, role = CASTER, target_affil = 2 },
	[177160] = { patch = PATCH_WOD, role = MELEE_STR, target_affil = 2},
	[177161] = { patch = PATCH_WOD, role = MELEE_AGI, target_affil = 2},
	
	[177176] = { patch = PATCH_WOD, role = CASTER, target_affil = 2},
	[177175] = { patch = PATCH_WOD, role = MELEE_STR, target_affil = 2},
	[177172] = { patch = PATCH_WOD, role = MELEE_AGI, target_affil = 2},
	
	[187620] = { patch = PATCH_WOD, role = MELEE_AGI, source = 1, target_affil = 2, color = colors.GOLD},
	[187616] = { patch = PATCH_WOD, role = CASTER, source = 1, target_affil = 2, color = colors.GOLD},
	[187619] = { patch = PATCH_WOD, role = MELEE_STR, source = 1, target_affil = 2, color = colors.GOLD},
	[187613] = { patch = PATCH_WOD, role = TANK, source = 1, target_affil = 2, color = colors.GOLD}, 
	[187618] = { patch = PATCH_WOD, role = CASTER_HEAL, source = 1, target_affil = 2, color = colors.GOLD}, -- Darkglow
	
	-- int
	
	[126705] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_misc_token_argentdawn3', custom_texture_on = true },
	[126683] = { patch = PATCH_WOD, role = CASTER_DPS,target_affil = 2, },
	[165531] = { patch = PATCH_WOD, role = CASTER_DPS,target_affil = 2, },
	[176882] = { patch = PATCH_WOD, role = CASTER_DPS,target_affil = 2, },
	[165832] = { patch = PATCH_WOD, role = CASTER_DPS,target_affil = 2, },
	[162919] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_inscription_trinket_mage', custom_texture_on = true },
	[176980] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_ragnaros_heart', custom_texture_on = true },
	[176875] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_misc_trinket6oog_isoceles1', custom_texture_on = true},
	[176941] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_misc_trinket6oih_orb2', custom_texture_on = true },
	[177051] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_misc_trinket6oih_orb2', custom_texture_on = true },
	[177594] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2,  },	
	[177046] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_misc_trinket6oih_lanterna2', custom_texture_on = true },
	[177081] = { patch = PATCH_WOD, role = CASTER_DPS, target_affil = 2, custom_texture = 'inv_misc_trinket6oih_orb1', custom_texture_on = true },

	-- healer
	
	[177063] = { patch = PATCH_WOD, role = CASTER_HEAL,target_affil = 2,  },
	[176884] = { patch = PATCH_WOD, role = CASTER_HEAL,target_affil = 2,  },
	[176978] = { patch = PATCH_WOD, role = CASTER_HEAL,target_affil = 2,  },
	[176943] = { patch = PATCH_WOD, role = CASTER_HEAL,target_affil = 2,  custom_texture = 'inv_misc_cat_trinket06', custom_texture_on = true },
	[177060] = { patch = PATCH_WOD, role = CASTER_HEAL ,target_affil = 2, },
	[162913] = { patch = PATCH_WOD, role = CASTER_HEAL, target_affil = 2, custom_texture = 'inv_inscription_trinket_healer', custom_texture_on = true },

	-- agi
	
	[126707] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_misc_token_argentdawn3', custom_texture_on = true},
--	[126696] = { role = MELEE_AGI, custom_texture = 'inv_inscription_trinket_healer', custom_texture_on = true},
	[165830] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  },
	[176883] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  },
	[165485] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  },
	[165542] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  },
	[176984] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_misc_trinket6oog_talisman2', custom_texture_on = true},
	[177038] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_misc_trinket6oog_talisman1', custom_texture_on = true},
	[176939] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_potione_5', custom_texture_on = true},
	[176878] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_misc_trinket6oih_lanternb3', custom_texture_on = true},
	[177035] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_misc_bone_03', custom_texture_on = true},
	[177067] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_misc_trinket6oih_clefthoof2', custom_texture_on = true},
	
	-- str 
	
	[126700] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_misc_token_argentdawn3', custom_texture_on = true},
	[126679] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2, },	
	[176881] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2, },
	[165532] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2, },
	[176974] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_misc_trinket6oog_tablet3', custom_texture_on = true},
	[162915] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_inscription_trinket_melee', custom_texture_on = true},
	[177040] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_misc_trinket6oog_stonefist3', custom_texture_on = true},
	[176935] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_misc_redsaberonfang', custom_texture_on = true},
	[176874] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_misc_trinket6oih_horn1', custom_texture_on = true},
	[177042] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_misc_trinket6oih_horn1', custom_texture_on = true},
	[177096] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'inv_hammer_07', custom_texture_on = true},
	
	-- tanks
	[176885] = { patch = PATCH_WOD, role = TANK,target_affil = 2, },
	[165535] = { patch = PATCH_WOD, role = TANK,target_affil = 2, },
	[165534] = { patch = PATCH_WOD, role = TANK,target_affil = 2, },
	[162917] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_inscription_trinket_tank', custom_texture_on = true},
	[176982] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_relics_runestone', custom_texture_on = true},
	[176937] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_jewelry_orgrimmarraid_trinket_19', custom_texture_on = true},
	[177053] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_misc_trinket6oog_handeye', custom_texture_on = true},
	[176876] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_misc_trinket6oog_2heads3', custom_texture_on = true},
	[177056] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_misc_trinket6oih_ironskull1', custom_texture_on = true},
	[176460] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_stone_weightstone_07', custom_texture_on = true},
	[177102] = { patch = PATCH_WOD, role = TANK,target_affil = 2, },
	[176873] = { patch = PATCH_WOD, role = TANK,target_affil = 2,  custom_texture = 'inv_misc_trinket6oih_orb4', custom_texture_on = true},
	
	-- all

	[165543] = { patch = PATCH_WOD, role = ALL,target_affil = 2, },	 
	[162916] = { patch = PATCH_WOD, role = MELEE,target_affil = 2,  custom_texture = 'inv_inscription_trinket_melee', custom_texture_on = true},
	[165822] = { patch = PATCH_WOD, role = MELEE,target_affil = 2, },
	[165833] = { patch = PATCH_WOD, role = ALL,target_affil = 2, },
	[165824] = { patch = PATCH_WOD, role = ALL,target_affil = 2, },
	
	-- 6.2 trinkets
	
	[183926] = { patch = PATCH_WOD, role = MELEE_AGI,target_affil = 2,  custom_texture = 'inv_guild_cauldron_b', custom_texture_on = true},	
	[184767] = { patch = PATCH_WOD, role = TANK, target_affil = 2, custom_texture = 'inv_holiday_tow_spicebandage', custom_texture_on = true},
	[183929] = { patch = PATCH_WOD, role = CASTER_HEALER,target_affil = 2,  custom_texture = 'spell_mage_presenceofmind', custom_texture_on = true },	
	[183941] = { patch = PATCH_WOD, role = MELEE_STR,target_affil = 2,  custom_texture = 'spell_deathknight_gnaw_ghoul', custom_texture_on = true},	
	[184293] = { patch = PATCH_WOD, role = MELEE ,target_affil = 2,  custom_texture = 'inv_6_2raid_trinket_3b', custom_texture_on = true},	
	[183931] = { patch = PATCH_WOD, role = TANK, target_affil = 2, custom_texture = 'ability_mount_pandarenkitemount_blue', custom_texture_on = true},	
	[183924] = { patch = PATCH_WOD, role = CASTER, target_affil = 2, custom_texture = 'achievement_dungeon_shadowmoonhideout', custom_texture_on = true },
	
	-- Legion

	[201410] = { patch = PATCH_LEG, role = CASTER, target_affil = 2, color = colors.WOO },
	[201405] = { patch = PATCH_LEG, role = MELEE_STR, target_affil = 2, color = colors.WOO },
	[202052] = { patch = PATCH_LEG, role = TANK, target_affil = 2, color = colors.WOO },
	[201408] = { patch = PATCH_LEG, role = MELEE_AGI, target_affil = 2, color = colors.WOO },
	
	-- Blues
	[191611] = { patch = PATCH_LEG, role = CASTER, target_affil = 2, color = colors.DGREEN, custom_texture = '70_inscription_deck_hellfire', custom_texture_on = true },
	[191563] = { patch = PATCH_LEG, role = MELEE, target_affil = 2, color = colors.DBLUE, custom_texture = '70_inscription_deck_dominion', custom_texture_on = true },	
	[188026] = { patch = PATCH_LEG, role = ALL, target_affil = 2, color = colors.DPURPLE, custom_texture = 'inv_alchemy_70_trinket', custom_texture_on = true },	
	[214622] = { patch = PATCH_LEG, role = TANK, target_affil = 2, color = colors.JADEENCANT, custom_texture = 'inv_7_0raid_trinket_010a', custom_texture_on = true },	
	[215247] = { patch = PATCH_LEG, role = CASTER_HEAL, target_affil = 2, color = colors.JADEENCANT },	
	-- http://www.wowhead.com/item=133644
	--[214798] = { patch = PATCH_LEG, role = MELEE, target_affil = 2, color = colors.DBLUE, custom_texture = 'inv_jewelry_trinket_05', custom_texture_on = true },	
	[224059] = { patch = PATCH_LEG, role = MELEE, target_affil = 2, color = colors.JADEENCANT,  custom_texture = 'inv_misc_foot_kodo', custom_texture_on = true  },
	[215648] = { patch = PATCH_LEG, role = ALL, target_affil = 2, color = colors.JADEENCANT,  custom_texture = 'inv_misc_cutgemsuperior2', custom_texture_on = true  },
	[214962] = { patch = PATCH_LEG, role = ALL, target_affil = 2, color = colors.LBLUE,  custom_texture = 'inv_spiritshard_02', custom_texture_on = true  },
	[215658] = { patch = PATCH_LEG, role = ALL, target_affil = 2, color = colors.LBLUE,  custom_texture = 'inv_7_0raid_trinket_02c', custom_texture_on = true  },
	[215813] = { patch = PATCH_LEG, role = CASTER, target_affil = 2, color = colors.ELV_LGREEN,  custom_texture = 'inv_scroll_09', custom_texture_on = true  },
	[215224] = { patch = PATCH_LEG, role = CASTER, target_affil = 2, color = colors.ELV_DBLUE,  custom_texture = 'inv_alchemy_crystalvial', custom_texture_on = true  },
	[214829] = { patch = PATCH_LEG, role = MELEE, target_affil = 2, color = colors.ELV_LGREEN,  custom_texture = 'inv_7_0raid_trinket_02d', custom_texture_on = true  },
	[215196] = { patch = PATCH_LEG, role = CASTER_HEAL, target_affil = 2, color = colors.ELV_DBLUE },
	
	-- Raid
	[221837] = { patch = PATCH_LEG, role = CASTER_HEAL, target_affil = 2, color = colors.LBLUE },
	[221873] = { patch = PATCH_LEG, role = CASTER_HEAL, target_affil = 2, color = colors.LBLUE,  custom_texture = 'inv_alchemy_enchantedvial', custom_texture_on = true }, 
	[222512] = { patch = PATCH_LEG, role = ALL, target_affil = 2, color = colors.ELV_LGREEN,  custom_texture = 'ability_druid_earthandsky', custom_texture_on = true  },
	[221748] = { patch = PATCH_LEG, role = CASTER_HEAL, target_affil = 2, color = colors.ELV_LGREEN,  custom_texture = 'ability_hunter_aspectoftheviper', custom_texture_on = true  },
	[221786] = { patch = PATCH_LEG, role = MELEE_AGI, target_affil = 2, color = colors.ELV_PURPLE,  custom_texture = 'ability_druid_primaltenacity', custom_texture_on = true  },
	[221767] = { patch = PATCH_LEG, role = MELEE_STR, target_affil = 2, color = colors.ELV_RAGE,  custom_texture = 'ability_druid_swipe', custom_texture_on = true  },
	[222015] = { patch = PATCH_LEG, role = MELEE, target_affil = 2, color = colors.ELV_PINK,  custom_texture = 'inv_drink_02', custom_texture_on = true  },
	[222478] = { patch = PATCH_LEG, role = TANK, target_affil = 2, color = colors.ELV_PINK,  custom_texture = 'spell_magic_lesserinvisibilty', custom_texture_on = true  },
	
	[225774] = { patch = PATCH_LEG, role = CASTER_DPS, target_affil = 2, color = colors.ELV_PINK,  custom_texture = 'inv_7_0raid_trinket_08c', custom_texture_on = true  },
	[225140] = { patch = PATCH_LEG, role = TANK, target_affil = 2, color = colors.ELV_LGREEN,  custom_texture = 'inv_7_0raid_trinket_08a', custom_texture_on = true  },
	[225136] = { patch = PATCH_LEG, role = CASTER_HEAL, target_affil = 2, color = colors.ELV_LBLUE,  custom_texture = 'inv_fabric_celestial_cloth', custom_texture_on = true  },
	
	[225129] = { patch = PATCH_LEG, role = ALL, target_affil = 2, custom_texture = 'spell_nature_elementalabsorption', custom_texture_on = true  },
	[225125] = { patch = PATCH_LEG, role = CASTER, target_affil = 2, color = colors.GOLD, custom_texture = 'inv_misc_pocketwatch_01', custom_texture_on = true  },
	
	[225033] = { patch = PATCH_LEG, role = TANK, target_affil = 2, custom_texture = 'inv_qiraj_carapaceoldgod', custom_texture_on = true  },
	
	
	-- Concordance of the Legionfall
	
	[242583] = { patch = PATCH_LEG, role = MELEE_STR, target_affil = 2, }, -- Str
	[242584] = { patch = PATCH_LEG, role = MELEE_AGI, target_affil = 2, }, -- Agi
	[242586] = { patch = PATCH_LEG, role = CASTER, target_affil = 2, }, -- Int
	[243096] = { patch = PATCH_LEG, role = TANK, target_affil = 2, }, -- Tank
}

 local IsGroupUpSpell

do
	
	local wordLen = L['SPELL_GROUPED']:len()
	
	local header = "|cFF00FF00"..L['SPELL_GROUPED']
	
	local function GroupedSpellString(...)
		local spellstr = header
		local numSpells = select("#", ...)
		for i=1, numSpells do
			local spellID = select(i, ...)
		
			local name, _, icon = GetSpellInfo(spellID)
			
			icon = icon or "Interface\\ICONS\\Inv_misc_questionmark"
			name = name or 'Invalide SpellID:'..spellID
			
			if i == 1 then
				spellstr = "\124T"..icon..":0\124t "..spellstr
			end
			
			if numSpells > i then
				spellstr = spellstr..name..', '
			else
				spellstr = spellstr..name
			end
		end
		
		return spellstr
	end
	
	local groupName = {

		[90355] = GroupedSpellString(80353), -- "Hero:group",
		[111859] = GroupedSpellString(108501), -- "Warlock:Grom:group"
		[113858] = GroupedSpellString(77801), -- "Warlock:Soul:group",
		[1122] = GroupedSpellString(1122,18540), --"Warlock:Guardian:group",
		[122355] = GroupedSpellString(122355), --"Warlock:Demo:MC:group",
		[5782] = GroupedSpellString(5782), --"Warlock:Fear:group",
		[27243] = GroupedSpellString(27243), --"Warlock:SoC:group",
		[348] = GroupedSpellString(157736), --"Warlock:Immolate:group",
	
		[20572] = GroupedSpellString(20572), --"Ork:Racial:group",
		
		[114866] = GroupedSpellString(114866), -- "DeathKnight:SoulReaper:group",
		
		[8921] = GroupedSpellString(8921), -- "Druid:Moonfire:group",
		[93402] = GroupedSpellString(93402), -- "Druid:Sunfire:group",
		[77758] = GroupedSpellString(77758), --"Druid:Thrash:group",
		[117679] = GroupedSpellString(117679), --"Druid:Incarnation:group",
		[145162] = GroupedSpellString(145162), --"Druid:DoC:group",
		
		[118] = GroupedSpellString(118), --"Mage:Polymorph:group",
		
		[114050] = GroupedSpellString(114050), --"Shaman:Ascendance:group",
		[1822] = GroupedSpellString(1822), --"Shaman:Ascendance:group",
		
		[52610] = GroupedSpellString(52610),
		
		[30108] = GroupedSpellString(30108),
	}
	
	local groupSpellDB = {

		-- Hero Group ----
		[90355] = 90355,
		[2825] = 90355,
		[32182] = 90355,
		[80353] = 90355,
		[146555] = 90355,
		[178207] = 90355,
		
		------------------
		
		-- Ork Racial
		
		[20572] = 20572,
		[33697] = 20572,
		[33702] = 20572,
		
		
		-- warlock ------
		
		[111859] = 111859,
		[111895] = 111859,
		[111896] = 111859,
		[111897] = 111859,
		[111898] = 111859,
		
		--[113858] = 113858,
		--[113860] = 113858,
		--[113861] = 113858,
		
		[1122] = 1122,
		[18540] = 1122,
		[112921] = 1122,
		[112927] = 1122,
		
		[122355] = 122355,
		[140074] = 122355,
		
		[5782] = 5782,
		[118699] = 5782,
		
		[27243] = 27243,
		[114790] = 27243,
		
		[348] = 348,
		[157736] = 348,
		
		[30108] = 30108,
		[233496] = 30108,
		[233497] = 30108,
		[233498] = 30108,
		[233499] = 30108,
		[233490] = 30108,
	
		-----------------
		
 		-- DK
			
		[114866] = 114866,
		[130735] = 114866,
		[130736] = 114866,
		
		
		---------------
		
		-- Druid
		[52610] = 52610,
		[174544] = 52610,
		
		[8921] = 8921,
		[155625] = 8921,
		[164812] = 8921,
		
		[164815] = 93402,
		[93402] = 93402,
		
		[77758] = 77758,
		[106830] = 77758,
		
		[117679] = 117679,
		[102558] = 117679,
		[102560] = 117679,
		[102543] = 117679,
		
		[145162] = 145162,
		[145152] = 145162,
		
		[1822] = 1822,
		[155722] = 1822,
	
		----------------------
		
		--- Mage
		
		[118]   = 118,
		[61305] = 118,
		[28271] = 118,
		[28272] = 118,
		[61721] = 118,
		[61780] = 118,
		
		
		---------------
		
		-- Shaman
		
		[114050] = 114050,
		[114051] = 114050,
		[114052] = 114050,

		
		-- Warrior 
		
		[94009] = 94009,
		[772]	= 772,
	
		----------------
	}
	
	function IsGroupUpSpell(spellid)


		if ( not C.db.profile.spell_list_grouping ) then return end
	
	
		if groupSpellDB[spellid] then return groupSpellDB[spellid], groupName[groupSpellDB[spellid]] end
		
		return nil
	end

	C.IsGroupUpSpell = IsGroupUpSpell
end

local function GetSpell(spellid)
	local name = GetSpellInfo(spellid)
	
	if not name or name == "" then
		print("Spellid is wrong ", C.myCLASS,"#",spellid)
	end
	
	return name or ""
end

C.GetSpell = GetSpell

local internal_cooldowns = {
	[GetSpell(125487)] = { spellid = 125487, icd = 60, },
	[GetSpell(125488)] = { spellid = 125488, icd = 60, },
--	[GetSpellInfo(125489)] = { spellid = 125489, icd = 60, },

	[GetSpell(146046)] = { spellid = 146046, icd = 115, },
	[GetSpell(146308)] = { spellid = 146308, icd = 115, },
	[GetSpell(148896)] = { spellid = 148896, icd = 85,  },
	[GetSpell(148897)] = { spellid = 148897, icd = 85,  },
	
	[GetSpell(146312)] = { spellid = 146312, icd = 115,  },
	[GetSpell(126649)] = { spellid = 126649, icd = 115,  },
	[GetSpell(146218)] = { spellid = 146218, icd = 115,  },
	[GetSpell(146296)] = { spellid = 146296, icd = 115,  },

	[GetSpell(148899)] = { spellid = 148899, checkID = true, icd = 85,  },
	[GetSpell(146245)] = { spellid = 146245, icd = 55,  },
	[GetSpell(146250)] = { spellid = 146250, icd = 55,  },
	
	[GetSpell(146314)] = { spellid = 146314, icd = 115,  },
	[GetSpell(148911)] = { spellid = 148911, icd = 115,  },

	[GetSpell(162915)] = { spellid = 162915, icd = 115,  },
	[GetSpell(162919)] = { spellid = 162919, icd = 115,  },
	[GetSpell(162913)] = { spellid = 162913, icd = 115,  },
	[GetSpell(162917)] = { spellid = 162917, icd = 115,  },
	
	[GetSpell(214622)] = { spellid = 214622, icd = 90,	 },
	[GetSpell(215648)] = { spellid = 215648, icd = 90,	 },
	[GetSpell(215658)] = { spellid = 215658, icd = 90,   },
	
	[GetSpell(222478)] = { spellid = 222478, icd = 120,  },
	
--	[GetSpellInfo(96230)] = { spellid = 96230, icd = 60, },
--	[GetSpellInfo(96229)] = { spellid = 96229, icd = 60, },
--	[GetSpellInfo(96228)] = { spellid = 96228, icd = 60, },

}


local others = {
	--[95223] = { blacklist = 4, blacklist_cleu = 4 },
	--[1490] =	{ target = 1, priority = -21 },
	--[119653] =  { target = 1, priority = -21 },
	--[81328] =	{ target = 1, priority = -21 },
	--[113746] =	{ target = 1, priority = -21 },
	--[115798] =	{ target = 1, priority = -21 },
	--[93068] = 	{ target = 1, priority = -21 },
	
	--[114206] = { source = 1, color = colors.GOLD, group = "player", },
	[31821] = { source = 1, duration = 6, color = colors.GOLD, target_affil = 2, group = "procs"},
}

local traptypes = {
	
	[82939] = "fire",
	[13813] = "fire",
	[13812] = "fire", -- debuff
	
	[60192] = "frost",
	[1499] 	= "frost",
	[3355]  = "frost", -- debuff
	
	[34600] = "slow", -- snake
	[82948] = "slow", -- snake
	[25809] = "slow", -- debuff snakes
	[45145] = "slow", -- snake SPELL_CAST_SUCCESS
	
	[13810] = "slow", -- slow SPELL_CAST_SUCCESS
	[135299] = "slow", -- slow normal debuff
	[82941] = "slow",-- slow normal		
	[13809] = "slow",-- slow normal	

	[196277] = 'slow',
	
	[162488] = "frost",
	[162487] = 'frost', -- debuff on target
	
	[187650] = "frost",
	[191433] = "fire",

	[194279] = 'slow',
	[194277] = "slow",
	[187698] = "slow",
}

function C:GetTrapType(spellID)
	return traptypes[spellID]
end

function C:GetTrapEnable(spellID)
	return self.db.profile.hunterTraps[traptypes[spellID]].active or false , self.db.profile.hunterTraps[traptypes[spellID]].nonactive or false
end

local customGroups = {}

do
	local anchor_unit = { "focus",  "boss1",  "boss2", "boss3", "boss4", "boss5", "arena1", "arena2", "arena3", "arena4", "arena5", "mouseover"}
	local unit_list   = { "target", "focus",  "player", "boss1", "boss2", "boss3", "boss4", "boss5",  "arena1", "arena2", "arena3", "arena4", "arena5" }
	local unit_list2  = { "target", "focus",  "boss1", "boss2", "boss3", "boss4", "boss5",  "arena1", "arena2", "arena3", "arena4", "arena5", "mouseover"}
	local unit_list3  = { "player", "target", "focus", "boss1", "boss2", "boss3", "boss4",  "boss5",  "arena1", "arena2", "arena3", "arena4", "arena5", "mouseover"}
	
	local unit_list4  = { "boss1","boss2","boss3","boss4","boss5", "arena1","arena2","arena3","arena4","arena5" }
	
	
	local UnitGUID = UnitGUID
	function C:FindUnitGUID(destGUID)
		for i=1, #anchor_unit do
			if UnitGUID(anchor_unit[i]) == destGUID then return anchor_unit[i] end
		end
		return nil
	end
	
	function C:FindUnitGUIDAnother(destGUID)
		for i=1, #unit_list4 do
			if UnitGUID(unit_list4[i]) == destGUID then return unit_list4[i] end
		end
		return nil
	end
	
	function C:FindUnitGUID_SMO(destGUID)
		for i=1, #unit_list do
			if UnitGUID(unit_list[i]) == destGUID then return unit_list[i] end
		end
		return nil
	end
	
	function C:FindUnitUnit(unit)
		for i=1, #unit_list2 do
			if UnitIsUnit(unit_list2[i], unit) and unit ~= unit_list2[i] then return unit_list2[i] end
		end		
		return nil
	end
	
	function C:FindUnitByGUID(guid)
	
		if guid and C.RaidRoster[guid] then			
			return C.RaidRoster[guid]
		end
		
		for i=1, #unit_list3 do
			if UnitGUID(unit_list3[i]) == guid then return unit_list3[i] end
		end

		return nil
	end
end


function C:GetUnitAnchor(spellID, destGUID)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit_enabled and destGUID then
			local unit = self:FindUnitGUID(destGUID)
			
			if unit == "target" and self.db.profile.classSpells[self.myCLASS][spellID].set_anchor then
				return self.db.profile.bars_anchors[self.db.profile.classSpells[self.myCLASS][spellID].set_anchor] and self.db.profile.classSpells[self.myCLASS][spellID].set_anchor or 1			
			end
			
			if unit and 
				self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit and
				self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit] and 
				self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit] ~= 0 and
				self.db.profile.bars_anchors[self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit]] then

				return self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit]
			end
		end
	return nil
end

function C:GetAnchorPerUnit1(spellID, unit)
	if unit == "target" and self.db.profile.classSpells[self.myCLASS][spellID].set_anchor then
		return self.db.profile.bars_anchors[self.db.profile.classSpells[self.myCLASS][spellID].set_anchor] and self.db.profile.classSpells[self.myCLASS][spellID].set_anchor or 1			
	end
			
	if unit and	
		self.db.profile.classSpells[self.myCLASS][spellID].unit_force_show and 
		self.db.profile.classSpells[self.myCLASS][spellID].unit_force_show[unit] and
		self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit] and 
		self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit] ~= 0 and
		self.db.profile.bars_anchors[self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit]] then
				
		return self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit[unit]		
	end
end

function C:GetUnitAlwaysShowAnchor(spellID, destGUID)
		
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if destGUID and self.db.profile.classSpells[self.myCLASS][spellID] and
		self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit_enabled then
		local unit2 = self:FindUnitGUIDAnother(destGUID) 		-- юнит не таргет и фокус
		
		return ( destGUID == self.CurrentTarget and self:GetAnchorPerUnit1(spellID, "target") or nil ), 
			( destGUID == self.FocusTarget and self:GetAnchorPerUnit1(spellID, "focus") or nil ), 
			( unit2 and self:GetAnchorPerUnit1(spellID,unit2) or nil)
		
	end
	return nil
end

function C:GetAnchor(spellID, destGUID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if traptypes[spellID] then
		return self.db.profile.hunterTraps[traptypes[spellID]].anchor or 1
	end
	
	if destGUID == COOLDOWN_SPELL then
		if self.db.profile.bars_cooldowns[self.myCLASS][spellID] and self.db.profile.bars_cooldowns[self.myCLASS][spellID].set_anchor then
		
			return self.db.profile.bars_anchors[self.db.profile.bars_cooldowns[self.myCLASS][spellID].set_anchor] and self.db.profile.bars_cooldowns[self.myCLASS][spellID].set_anchor or 1	
		end
	end
	
	if self.db.profile.classSpells[self.myCLASS][spellID] then
			
		if not self.db.profile.doswap then
			
			local unit_a = C:GetUnitAnchor(spellID, destGUID)
			
			if unit_a then 
				return unit_a 
			else
				if self.db.profile.classSpells[self.myCLASS][spellID].set_anchor then			
					return self.db.profile.bars_anchors[self.db.profile.classSpells[self.myCLASS][spellID].set_anchor] and self.db.profile.classSpells[self.myCLASS][spellID].set_anchor or 1 
				end
			end
				
		elseif self.db.profile.classSpells[self.myCLASS][spellID].set_anchor then 		
			return self.db.profile.bars_anchors[self.db.profile.classSpells[self.myCLASS][spellID].set_anchor] and self.db.profile.classSpells[self.myCLASS][spellID].set_anchor or 1 
		end
	end
		
	if self.db.profile.procSpells[spellID]
		and self.db.profile.procSpells[spellID].set_anchor then
	return self.db.profile.bars_anchors[self.db.profile.procSpells[spellID].set_anchor] and self.db.profile.procSpells[spellID].set_anchor or 1 end
	
	if self.db.profile.othersSpells[spellID] 
		and self.db.profile.othersSpells[spellID].set_anchor then 
	return self.db.profile.bars_anchors[self.db.profile.othersSpells[spellID].set_anchor] and self.db.profile.othersSpells[spellID].set_anchor or 1 end
	
	if self.db.profile.totems[spellID] and self.db.profile.totems[spellID].anchor then
		return self.db.profile.totems[spellID].anchor
	end
	
	if self.db.profile.enchants[spellID] and self.db.profile.enchants[spellID].anchor then
		return self.db.profile.enchants[spellID].anchor
	end
	
	return 1
end

function C:DoUnitAnchor(spellID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if self.db.profile.classSpells[self.myCLASS][spellID] then
		return self.db.profile.classSpells[self.myCLASS][spellID].anchor_per_unit_enabled
	end
end

function C:GetOffAnchor(spellID, destGUID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
--	if self.db.profile.doswap then

	if self.db.profile.classSpells[self.myCLASS][spellID] then
		
		local unit_a = C:GetUnitAnchor(spellID, destGUID)
		
		if unit_a then
			return unit_a
		elseif self.db.profile.classSpells[self.myCLASS][spellID].offtarge then 		
			return self.db.profile.bars_anchors[self.db.profile.classSpells[self.myCLASS][spellID].offtarge] and self.db.profile.classSpells[self.myCLASS][spellID].offtarge or 1
		end
	
	end
	
	if self.db.profile.procSpells[spellID]
		and self.db.profile.procSpells[spellID].offtarge then
	return self.db.profile.bars_anchors[self.db.profile.procSpells[spellID].offtarge] and self.db.profile.procSpells[spellID].offtarge or 1 end
	
	if self.db.profile.othersSpells[spellID] 
		and self.db.profile.othersSpells[spellID].offtarge then 
	return self.db.profile.bars_anchors[self.db.profile.othersSpells[spellID].offtarge] and self.db.profile.othersSpells[spellID].offtarge or 1 end
--	end
	
	return self:GetAnchor(spellID, destGUID) or 1
end

function C:GetGroup(spellID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if traptypes[spellID] then
		if self.db.profile.hunterTraps[traptypes[spellID]].group ~= "auto" then
			return self.db.profile.hunterTraps[traptypes[spellID]].group
		end
		
		return nil
	end
	
	if self.db.profile.classSpells[self.myCLASS][spellID] and self.db.profile.classSpells[self.myCLASS][spellID].group ~= "auto" then
		return self.db.profile.classSpells[self.myCLASS][spellID].group 
	end
	if self.db.profile.procSpells[spellID] and self.db.profile.procSpells[spellID].group ~= "auto" then 
		return self.db.profile.procSpells[spellID].group 
	end
	if self.db.profile.othersSpells[spellID] and self.db.profile.othersSpells[spellID].group ~= "auto" then
		return self.db.profile.othersSpells[spellID].group 
	end
	
	if self.db.profile.totems[spellID] and self.db.profile.totems[spellID].group ~= "auto" then
		return self.db.profile.totems[spellID].group
	end
	
	if self.db.profile.enchants[spellID] and self.db.profile.enchants[spellID].group ~= "auto" then
		return self.db.profile.enchants[spellID].group
	end
	
	return nil
end


function C:GetCheckStacks(spellID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if self.db.profile.procSpells[spellID] and 
	   self.db.profile.procSpells[spellID].checkstaucks_on then
	   local spellname = GetSpellInfo(self.db.profile.procSpells[spellID].checkstaucks)
	   
		if spellname then
			local name, _, count, _, _, _, _, _, _, ua_spellid = AuraUtil.FindAuraByName(spellname, 'player', 'HELPFUL')

			if name and name == spellname then				
				return count 
			end
		end
	end
	return nil
end

function C:GetPriority(spellID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if traptypes[spellID] then	
		return self.db.profile.hunterTraps[traptypes[spellID]].priority
	end

	if self.db.profile.classSpells[self.myCLASS][spellID] then
		if self.db.profile.classSpells[self.myCLASS][spellID].priority and type(self.db.profile.classSpells[self.myCLASS][spellID].priority) == "number" then
			return self.db.profile.classSpells[self.myCLASS][spellID].priority
		end
	end
	if self.db.profile.procSpells[spellID] then
		if self.db.profile.procSpells[spellID].priority and type(self.db.profile.procSpells[spellID].priority) == "number" then
			return self.db.profile.procSpells[spellID].priority 
		end
	end
	if self.db.profile.othersSpells[spellID] then
		if self.db.profile.othersSpells[spellID].priority and type(self.db.profile.othersSpells[spellID].priority) == "number" then
			return self.db.profile.othersSpells[spellID].priority 
		end
	end
	
	if self.db.profile.totems[spellID] then
		if self.db.profile.totems[spellID].priority and type(self.db.profile.totems[spellID].priority) == "number" then
			return self.db.profile.totems[spellID].priority
		end
	end
	
	if self.db.profile.enchants[spellID] then
		if self.db.profile.enchants[spellID].priority and type(self.db.profile.enchants[spellID].priority) == "number" then
			return self.db.profile.enchants[spellID].priority
		end
	end
	
	return 0
end

function C:GetTargetType(spellID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if self.db.profile.classSpells[self.myCLASS][spellID] then
		if self.db.profile.classSpells[self.myCLASS][spellID].target then
			return self.db.profile.classSpells[self.myCLASS][spellID].target
		end
	end
	if self.db.profile.procSpells[spellID] then
		if self.db.profile.procSpells[spellID].target then
			return self.db.profile.procSpells[spellID].target 
		end
	end
	if self.db.profile.othersSpells[spellID] then
		if self.db.profile.othersSpells[spellID].target then
			return self.db.profile.othersSpells[spellID].target 
		end
	end

	return 3
end

do
	local list = {
		-- Shaman
		[8050] = true, -- Fire shock
		
		--Warlock
		[30283] = true, -- Aoe Stun
		[157736] = true, -- Aoe Immolate
	}
	
	function C:IsMassiveTargetSpell(spellID)

	--	spellID = IsGroupUpSpell(spellID) or spellID
		
		if list[spellID] then
			return true, spellID
		end
		--[==[
		if self.db.profile.classSpells[self.myCLASS][spellID] then
			if self.db.profile.classSpells[self.myCLASS][spellID].massive then
				return self.db.profile.classSpells[self.myCLASS][spellID].massive
			end
		end
		]==]
		
		return false, spellID
	end
end

function C:GetColor(spellID, func)

	spellID = IsGroupUpSpell(spellID) or spellID
	
	if traptypes[spellID] then
		return self.db.profile.hunterTraps[traptypes[spellID]].color
	end
	
	if self.db.profile.ignore_custom_color then return nil end
	
	if func == COOLDOWN_SPELL then
		if self.db.profile.bars_cooldowns[self.myCLASS][spellID] then
			if self.db.profile.bars_cooldowns[self.myCLASS][spellID].color_on or self.db.profile.bars_cooldowns[self.myCLASS][spellID].color_on == nil then			
				return self.db.profile.bars_cooldowns[self.myCLASS][spellID].color 
			end
		end
	end
	
	if self.db.profile.classSpells[self.myCLASS][spellID] then
		if self.db.profile.classSpells[self.myCLASS][spellID].color_on or self.db.profile.classSpells[self.myCLASS][spellID].color_on == nil then
			return self.db.profile.classSpells[self.myCLASS][spellID].color
		end
	end
	if self.db.profile.procSpells[spellID] then
		if self.db.profile.procSpells[spellID].color_on or self.db.profile.procSpells[spellID].color_on == nil then
			return self.db.profile.procSpells[spellID].color 
		end
	end
	if self.db.profile.othersSpells[spellID] then
		if self.db.profile.othersSpells[spellID].color_on or self.db.profile.othersSpells[spellID].color_on == nil then
			return self.db.profile.othersSpells[spellID].color 
		end
	end
	
	if self.db.profile.totems[spellID] then
		return self.db.profile.totems[spellID].color
	end
	
	if self.db.profile.enchants[spellID] then
		return self.db.profile.enchants[spellID].color
	end
	
	return nil
end

function C:ShowTotems(totem)
	if self.db.profile.totems[totem] then
		return self.db.profile.totems[totem].show
	end
end

local SingleDest = {	
	[974] = true,
}

function C:IsSingleDest(spellID)	
	return SingleDest[spellID]
end

function C:IsSeveralAuras(spellID)

	if self.db.profile.classSpells[self.myCLASS][spellID] then
		if self.db.profile.classSpells[self.myCLASS][spellID].several then
			return true
		end
	end
	if self.db.profile.procSpells[spellID] then
		if self.db.profile.procSpells[spellID].several then
			return true
		end
	end
	if self.db.profile.othersSpells[spellID] then
		if self.db.profile.othersSpells[spellID].several then
			return true
		end
	end

	return false
end

function C:GetCooldown(spellName)
	if self.db.profile.classCooldowns[self.myCLASS][spellName] then	
		return self.db.profile.classCooldowns[self.myCLASS][spellName].hide
	end
	if self.db.profile.internal_cooldowns[spellName] then	
		return self.db.profile.internal_cooldowns[spellName].hide
	end
	
	--local isInBlockList = C:GetCooldownBlockName(spellName)
	
	if spellName and 
		self.db.profile.cooldownline.blockList[spellName] and 
		not self.db.profile.cooldownline.blockList[spellName].deleted and 
		not self.db.profile.cooldownline.blockList[spellName].fulldel then 

		return self.db.profile.cooldownline.blockList[spellName].hide
	end
	
	return nil
end

function C:DoBigSplashCooldown(spellName)

	local force = self.db.profile.cooldownline.show_only_force  -- if you show only forced spells if no then hide spell
	
	if self.db.profile.classCooldowns[self.myCLASS][spellName] then	
		if force then
			if self.db.profile.classCooldowns[self.myCLASS][spellName].hide_splash then 
				return false
			else
				return true
			end
		else
			return self.db.profile.classCooldowns[self.myCLASS][spellName].hide_splash
		end
	end
	if self.db.profile.internal_cooldowns[spellName] then	
		if force then
			if self.db.profile.internal_cooldowns[spellName].hide_splash then 
				return false
			else
				return true
			end
		else
			return self.db.profile.internal_cooldowns[spellName].hide_splash
		end
	end
	
	--local isInBlockList = C:GetCooldownBlockName(spellName)
	
	if self.db.profile.cooldownline.blockList[spellName] and 
		not self.db.profile.cooldownline.blockList[spellName].deleted and 
		not self.db.profile.cooldownline.blockList[spellName].fulldel then 
		if force then
			if self.db.profile.cooldownline.blockList[spellName].hide_splash then 
				return false
			else
				return true
			end
		else
			return self.db.profile.cooldownline.blockList[spellName].hide_splash
		end
	end
	
	return force
end
function C:GetCooldownColor(spellName)
	if self.db.profile.classCooldowns[self.myCLASS][spellName] and 
		( self.db.profile.classCooldowns[self.myCLASS][spellName].color_on or self.db.profile.classCooldowns[self.myCLASS][spellName].color_on == nil ) then		
		return self.db.profile.classCooldowns[self.myCLASS][spellName].color		
	end
	
	if self.db.profile.internal_cooldowns[spellName] and 
		( self.db.profile.internal_cooldowns[spellName].color_on or self.db.profile.internal_cooldowns[spellName].color_on == nil ) then		
		return self.db.profile.internal_cooldowns[spellName].color		
	end
	
	return nil
end

function C:GetInternalCD(spellName, spellID)
	if self.db.profile.hideinternal then return false end
	if self.db.profile.internal_cooldowns[spellName] and not self.db.profile.internal_cooldowns[spellName].hide then 
		if self.db.profile.internal_cooldowns[spellName].checkID then		
			if self.db.profile.internal_cooldowns[spellName].spellID == spellID then
				return true
			end
			return false
		else
			return true
		end
	end
	return false
end

function C:GetAuraCD(spellName, spellID, types)
	if self.db.profile.hideauracd then return false end
	if self.db.profile.auras_cooldowns[self.myCLASS][spellName] and 
	not self.db.profile.auras_cooldowns[self.myCLASS][spellName].hide then
		
		if self.db.profile.auras_cooldowns[self.myCLASS][spellName].auraType == 2 and types ~= "HELPFUL" then return false end
		if self.db.profile.auras_cooldowns[self.myCLASS][spellName].auraType == 3 and types ~= "HARMFUL" then return false end
		
		if self.db.profile.auras_cooldowns[self.myCLASS][spellName].checkID then		
			if self.db.profile.auras_cooldowns[self.myCLASS][spellName].spellID == spellID then
				return true
			end
			return false
		else
			return true
		end
	end
	return false
end

function C:GetPlayerCooldownList()
	return self.db.profile.classCooldowns[self.myCLASS]
end

function C:GetICD(spellName, spellID)

	if self.db.profile.internal_cooldowns[spellName].icd then
		return self.db.profile.internal_cooldowns[spellName].icd
	end
	
	return 0
end

do
	local cd_type = {
		["PLAYER_ITEMS"]	= "inv_color",
		["BAG_SLOTS"]		= "bag_color",
		["PET_CD"]			= "pet_color",
		["VEHICLE_CD"]		= "veh_color",
		["PLAYER_CD"]		= "pla_color",
		["INTERNAL_CD"]		= "inter_color",
		["RuneBlood"]		= "blood_runes_color",
		["RuneUnholy"]		= "unholy_runes_color",
		["RuneFrost"]		= "frost_runes_color",
		["AURA_CD_BUFF"]	= "aura_cd_buff_color",
		["AURA_CD_DEBUFF"]	= "aura_cd_debuff_color",
	}
		--[[
			pla_color = {1,0.5,0,1},
						veh_color = {1,0.5,0,1},
						pet_color = {1,0,.95,1},
						bag_color = {1,1,0,1},
						inv_color = {1,1,0,1},
						inter_color = {0, 0.6, 0.85, 1},
		
		]]
	function C:GetCooldownTypeColor(types)
		if cd_type[types] then
			return self.db.profile.cooldownline[cd_type[types]]	
		end
		
		return self.db.profile.cooldownline.pla_color
	end
end

do
	-- inv_reporting
	-- bag_reporting
	
	-- veh_reporting
	-- icd_reporting
	-- pet_reporting
	-- player_reporting
		
		local cd_type = {
			["PLAYER_ITEMS"]	= "inv_reporting",
			["BAG_SLOTS"]		= "bag_reporting",
			["PET_CD"]			= "pet_reporting",
			["VEHICLE_CD"]		= "veh_reporting",
			["PLAYER_CD"]		= "player_reporting",
			["INTERNAL_CD"]		= "icd_reporting",
			["RuneBlood"]		= "br_reporting",
			["RuneUnholy"]		= "uh_reporting",
			["RuneFrost"]		= "fr_reporting",
			["AURA_CD_BUFF"]	= "aura_cd_buff_reporting",
			["AURA_CD_DEBUFF"]	= "aura_cd_debuff_reporting",
		}
		
	function C:GetAnonce(name, tip)

		if cd_type[tip] then
			
			if self.db.profile.classCooldowns[self.myCLASS][name] then					
				if self.db.profile.classCooldowns[self.myCLASS][name].reporting == false then return false end
				if self.db.profile.classCooldowns[self.myCLASS][name].reporting == true then return true end
			end
			
			if self.db.profile.auras_cooldowns[self.myCLASS][name] then					
				if self.db.profile.auras_cooldowns[self.myCLASS][name].reporting == false then return false end
				if self.db.profile.auras_cooldowns[self.myCLASS][name].reporting == true then return true end
			end
			
			if self.db.profile.internal_cooldowns[name] then				
				if self.db.profile.internal_cooldowns[name].reporting == false then return false end
				if self.db.profile.internal_cooldowns[name].reporting == true then return true end
			end
			
			--local isInBlockList = C:GetCooldownBlockName(name)
			
			if self.db.profile.cooldownline.blockList[name] and 
				not self.db.profile.cooldownline.blockList[name].deleted and 
				not self.db.profile.cooldownline.blockList[name].fulldel then

				if self.db.profile.cooldownline.blockList[name].reporting == false then return false end
				if self.db.profile.cooldownline.blockList[name].reporting == true then return true end
			end

			if self.db.profile.cooldownline[cd_type[tip]] == false then return false end
			if self.db.profile.cooldownline[cd_type[tip]] == true then return true end

		end
			
		return false
	end
end

function C:RebuildBanCD()
	for k,v in pairs(self.db.profile.cooldownline.block) do
	
		if k and type(v) == "boolean" then
			self.db.profile.cooldownline.block[k] = { hide = v }	
		end
	end
end

------------------------------------------------------ check only @player auras
--[[
function C:GetRaidBuffsFilter(spellID)
	if raidBuffs[spellID] then return raidBuffs[spellID] end
	return false
end

local filters = {
	L["None"],
	L["Only buff"],
	L["Only debuff"],
	L["All"],
}


]]


-------------------------------------------------------- Unit Aura checking

-- true пропускает ауру через фильтр false запрещает
do
	function C:GetBlackListFilter(spellID, filter, skip)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] then
			
			if self.db.profile.classlistFiltersoff then return false end			
			if self.db.profile.classSpells[self.myCLASS][spellID].hide then return false end
			
			if self.db.profile.classSpells[self.myCLASS][spellID].blacklist == 4 then skip = false end			
			if self.db.profile.classSpells[self.myCLASS][spellID].blacklist == filter then skip = false end
			if self.db.profile.classSpells[self.myCLASS][spellID].hide then skip = false end
			if self.db.profile.classSpells[self.myCLASS][spellID].deleted then skip = false end
			if self.db.profile.classSpells[self.myCLASS][spellID].fulldel then skip = false end
			
		end
		return skip
	end
end

do
	function C:GetWhiteListFilter(spellID, filter, skip)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] then
			
			if self.db.profile.classlistFiltersoff then return false end			
			if self.db.profile.classSpells[self.myCLASS][spellID].hide then return false end
			if self.db.profile.classSpells[self.myCLASS][spellID].deleted then return false end
			if self.db.profile.classSpells[self.myCLASS][spellID].fulldel then return false end
			
			if not self.db.profile.classSpells[self.myCLASS][spellID].whitelist or 
				self.db.profile.classSpells[self.myCLASS][spellID].whitelist == 1 then skip = true end
				
			if self.db.profile.classSpells[self.myCLASS][spellID].whitelist == 4 then skip = true end
			if self.db.profile.classSpells[self.myCLASS][spellID].whitelist == filter then skip = true end
		end
		return skip
	end
end

do
	function C:UnitFilter_UNIT(unit)
		local filter_type
		if self.db.profile.unit_filter_enabled then			
			if self.db.profile.unit_filters then
				
				filter_type = C:FindUnitUnit(unit) or "unknown"
				
				if filter_type and ( self.db.profile.unit_filters[filter_type] ) then				
					return true
				end
				return false
			end
		end
		return true
	end
	--[[
	function C:UnitFilter_TIMER(timer)
		local filter_type
		if self.db.profile.unit_filter_enabled then			
			if self.db.profile.unit_filters then
				
				self:FindUnitGUID_SMO(timer.targetGUID)
				
				if timer.targetGUID then					
					filter_type = self:FindUnitGUID_SMO(timer.targetGUID) or "unknown"
				end
	
				if filter_type and self.db.profile.unit_filters[filter_type] then				
					return true
				end
				return false
			end
		end
		return true
	end
	
	]]
	
	function C:UnitFilter_TIMER(timer)
		local filter_type
		if self.db.profile.unit_filter_enabled then			
			if self.db.profile.unit_filters then
				
				self:FindUnitGUID_SMO(timer.data[3])
				
				if timer.data[3] then					
					filter_type = self:FindUnitGUID_SMO(timer.data[3]) or "unknown"
				end
	
				if filter_type and self.db.profile.unit_filters[filter_type] then				
					return true
				end
				return false
			end
		end
		return true
	end
	
	function C:UnitFilter_GUID(guid)
		local filter_type
		if self.db.profile.unit_filter_enabled then			
			if guid then 
				filter_type = self:FindUnitGUID_SMO(guid) or "unknown"
			end
				
			if filter_type and self.db.profile.unit_filters[filter_type] then
				
--				print("C:UnitFilter_GUID", guid, filter_type, "true")
				return true
			end
--			print("C:UnitFilter_GUID", guid, filter_type, "false")
			return false
		end
--		print("C:UnitFilter_GUID", guid, filter_type, "SKIP")
		return true
	end
end


do
	function C:GetProcsFilter(spellID, types, skip) -- если true то пропустить заклинание
	
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.procSpells[spellID] then
			
			if self.db.profile.procsFiltersoff then return false end			
			if self.db.profile.procSpells[spellID].hide then return false end
			if self.db.profile.procSpells[spellID].deleted then return false end
			if self.db.profile.procSpells[spellID].fulldel then return false end
			
			if ( self.db.profile.procSpells[spellID].whitelist == nil ) or 
			   ( self.db.profile.procSpells[spellID].whitelist == 1   ) then skip = true end
				
			if self.db.profile.procSpells[spellID].whitelist == 4 then skip = true end
			if self.db.profile.procSpells[spellID].whitelist == types then skip = true end
			if self.db.profile.procSpells[spellID].blacklist == 4 then skip = false end			
			if self.db.profile.procSpells[spellID].blacklist == types then skip = false end
		end
		return skip
	end
end

do
	local none = "None"
	local none1 = "Interface\Quiet.ogg"
	
	function C:GetSound(spell, event, func)
		
		spell = IsGroupUpSpell(spell) or spell
		
		if not spell then return none end
		if event ~= "sound_onshow" and event ~= "sound_onhide" then return none end
		
		if func == COOLDOWN_SPELL then
			if self.db.profile.bars_cooldowns[spell] then
				return self.db.profile.bars_cooldowns[spell][event] or none	
			end		
		end
		
		if self.db.profile.classSpells[self.myCLASS][spell] then
			return self.db.profile.classSpells[self.myCLASS][spell][event] or none
		end
		
		if self.db.profile.othersSpells[spell] then
			return self.db.profile.othersSpells[spell][event] or none	
		end
		
		if self.db.profile.procSpells[spell] then	
			return self.db.profile.procSpells[spell][event] or none
		end
		
		if self.db.profile.classCooldowns[self.myCLASS][spell] then	
			return self.db.profile.classCooldowns[self.myCLASS][spell][event] or none	
		end
		
		if self.db.profile.internal_cooldowns[spell] then	
			return self.db.profile.internal_cooldowns[spell][event] or none	
		end
	
		--local isInBlockList = C:GetCooldownBlockName(spell)
		
		if self.db.profile.cooldownline.blockList[spell] and 
			not self.db.profile.cooldownline.blockList[spell].deleted and 
			not self.db.profile.cooldownline.blockList[spell].fulldel then 

			return self.db.profile.cooldownline.blockList[spell][event] or none	
		end

		return none
	end
	
	--  Either "Master" (this will play the sound also with disabled sounds like before 4.0.1), "SFX", "Ambience", "Music
	
	function C:PlaySound(spell, event, func)
		
		spell = IsGroupUpSpell(spell) or spell
		
		local sound = self:GetSound(spell, event, func)
		if sound == none then return end
		
		local sound2 = self.LSM:Fetch("sound", sound)
		
		if event == "sound_onshow" then		
			local willplay, handler = PlaySoundFile(sound2, self.db.profile.sound_channel)	
		elseif event == "sound_onhide" then
			local willplay, handler = PlaySoundFile(sound2, self.db.profile.sound_channel)				
		end
	end
	
	function C:PlaySoundCooldown(spell, event)
	
		spell = IsGroupUpSpell(spell) or spell
		
		local sound = self:GetSound(spell, event)		
		if sound == none then return end
		
		local sound2 = self.LSM:Fetch("sound", sound)
		
		if event == "sound_onshow" then			
			local willplay, handler = PlaySoundFile(sound2, self.db.profile.sound_channel)
		elseif event == "sound_onhide" then	
			local willplay, handler = PlaySoundFile(sound2, self.db.profile.sound_channel)
		end
	end
end


do
	function C:GetOthersFilter(spellID, types, skip)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.othersSpells[spellID] then
		
			if self.db.profile.othersFiltersoff then return false end			
			if self.db.profile.othersSpells[spellID].hide then return false end
			if self.db.profile.othersSpells[spellID].deleted then return false end
			if self.db.profile.othersSpells[spellID].fulldel then return false end
			
			if ( self.db.profile.othersSpells[spellID].whitelist == nil ) or 
			   ( self.db.profile.othersSpells[spellID].whitelist == 1   ) then skip = true end
			   
			if self.db.profile.othersSpells[spellID].whitelist == 4 then skip = true end
			if self.db.profile.othersSpells[spellID].whitelist == types then skip = true end
			if self.db.profile.othersSpells[spellID].blacklist == 4 then skip = false end			
			if self.db.profile.othersSpells[spellID].blacklist == types then skip = false end
		end
		return skip
	end
end

do

	local casterAuras = {
		[1490] 		= { 1490, 119653, 58410, 93068 },
		[119653] 	= { 1490, 119653, 58410, 93068 },
		[93068] 	= { 1490, 119653, 58410, 93068 },
	}
	
	local meleeAuras = {
		[81328] = { 81328, 113746 },
		[113746] = { 81328, 113746 },
	}
	
	local tankAuras = {
		[115798] = { 115798 },
	}
	
	function C:GetRaidDebuffListFilter(spellID, skip)
		
		if casterAuras[spellID] then skip = self.db.profile.casterTargetAura end
		if meleeAuras[spellID] then skip = self.db.profile.meleeTargetAura end	
		if tankAuras[spellID] then skip = self.db.profile.tankTargetAura end	
		
		return skip
	end
	
	function C:GetRaidDebuffList(spellID)

		if casterAuras[spellID] then return casterAuras[spellID] end
		if meleeAuras[spellID] then return meleeAuras[spellID] end	
		if tankAuras[spellID] then return tankAuras[spellID] end	
		
		return {}
	end
end

---------------------CLEU FILTER -------------------------

do
	local UnitSpellHaste = UnitSpellHaste
	
	local typesFilter = {
		["BUFF"] = 2,
		["DEBUFF"] = 3,
		["SPELL_CAST"] = 5,
		["SPELL_SUMMON"] = 6,
		["SPELL_ENERGIZE"] = 7,
	}
	
	function C:GetCLEUFilter(spellID, types)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		local skip = false
		if self.db.profile.classSpells[self.myCLASS][spellID] and self.db.profile.classSpells[self.myCLASS][spellID].cleu then
			
			if self.db.profile.classlistFiltersoff then return false end
			
			if self.db.profile.classSpells[self.myCLASS][spellID].hide then return false end
			if self.db.profile.classSpells[self.myCLASS][spellID].deleted then return false end
			if self.db.profile.classSpells[self.myCLASS][spellID].fulldel then return false end
			
			if types ~= "SPELL_CAST" and not self.db.profile.classSpells[self.myCLASS][spellID].whitelist_cleu then skip = true end
			if self.db.profile.classSpells[self.myCLASS][spellID].whitelist_cleu == 4 then skip = true end
			if types == C.SPELL_ENERGIZE and self.db.profile.classSpells[self.myCLASS][spellID].whitelist_cleu ~= typesFilter[types] then return false end
			
			if types and self.db.profile.classSpells[self.myCLASS][spellID].whitelist_cleu == typesFilter[types] then skip = true end
			
			if self.db.profile.classSpells[self.myCLASS][spellID].blacklist_cleu == 4 then skip = false end			
			if types and self.db.profile.classSpells[self.myCLASS][spellID].blacklist_cleu == typesFilter[types] then skip = false end
			
		end
		return skip
	end
	
	function C:GetShowTicks(spellID)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] and self.db.profile.classSpells[self.myCLASS][spellID].showTicks then
			if self.db.profile.classSpells[self.myCLASS][spellID].tick and 
				self.db.profile.classSpells[self.myCLASS][spellID].tick > 0 then 
				return true 
			end			
		end
		
		return false
	end
	
	function C:GetTicksEvery(spellID)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] and self.db.profile.classSpells[self.myCLASS][spellID].showTicks then
			local data = self.db.profile.classSpells[self.myCLASS][spellID]
			if data.tick and 
				data.tick > 0 then 
				
				if data.haste then
					return data.tick/(1+(UnitSpellHaste("player")/100))
				end
				
				return data.tick 
			end			
		end
	
		return 0
	end
	
	function C:IsPandemiaSpell(spellID)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		return self.db.profile.classSpells[self.myCLASS][spellID] and self.db.profile.classSpells[self.myCLASS][spellID].pandemia
	end
	
	--[==[
	function C:GetCLEUSpellInfo(spellID)
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] and
			self.db.profile.classSpells[self.myCLASS][spellID].tick and
			self.db.profile.classSpells[self.myCLASS][spellID].tick > 0 then
			
			local haste		= self.db.profile.classSpells[self.myCLASS][spellID].haste
			local tick		= self.db.profile.classSpells[self.myCLASS][spellID].tick
			local pandemia	= self.db.profile.classSpells[self.myCLASS][spellID].pandemia
	
			return tick, haste, pandemia
		end
		
		return false
	end
	]==]
	
	function C:IsChanneling(spellID)
	
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] then
			return self.db.profile.classSpells[self.myCLASS][spellID].spellType == 2
		end
		
		return false
	end
	
	
	function C:GetCastTime(spellID)
	
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] and self.db.profile.classSpells[self.myCLASS][spellID].showOverlay then	

		   if self.db.profile.classSpells[self.myCLASS][spellID].cast and
				self.db.profile.classSpells[self.myCLASS][spellID].cast > 0 then
		   
				local cast = self.db.profile.classSpells[self.myCLASS][spellID].cast+0.2

				return cast/(1+(UnitSpellHaste("player")/100))
			elseif self.db.profile.classSpells[self.myCLASS][spellID].withgcd then
			
				return 1.5/(1+(UnitSpellHaste("player")/100))
			end
		end
		
		return 0
	end
	
	function C:TickOverlap(spellID)
	
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] and
			self.db.profile.classSpells[self.myCLASS][spellID].tickoverlap and
			self.db.profile.classSpells[self.myCLASS][spellID].tick and 
			self.db.profile.classSpells[self.myCLASS][spellID].tick > 0 then
			
			return true
		end	
		return nil
	end
	
end

do
	
	--[[
	
		local affiliation = {
			L["Any"],
			L["player"],
			L["raid"],
			L["party"],
			L["pet"],
		}
	
	]]
	-- http://wowprogramming.com/docs/api/CombatLog_Object_IsA
	
	local  CombatLog_Object_IsA =  CombatLog_Object_IsA

	local COMBATLOG_OBJECT_TYPE_PLAYER = COMBATLOG_OBJECT_TYPE_PLAYER
	local COMBATLOG_OBJECT_AFFILIATION_RAID = COMBATLOG_OBJECT_AFFILIATION_RAID
	local COMBATLOG_OBJECT_AFFILIATION_PARTY = COMBATLOG_OBJECT_AFFILIATION_PARTY
	local COMBATLOG_OBJECT_AFFILIATION_MINE = COMBATLOG_OBJECT_AFFILIATION_MINE
	local COMBATLOG_OBJECT_TYPE_NPC = COMBATLOG_OBJECT_TYPE_NPC

	local COMBATLOG_FILTER_MY_PET = COMBATLOG_FILTER_MY_PET
	local COMBATLOG_FILTER_MINE = COMBATLOG_FILTER_MINE
	local COMBATLOG_FILTER_ME = COMBATLOG_FILTER_ME
	
	local bit_band = bit.band
	local match = string.match

	local function IsRaidMember(flags)
		return ( bit_band(flags, COMBATLOG_OBJECT_AFFILIATION_RAID) == COMBATLOG_OBJECT_AFFILIATION_RAID )
	end
	
	local function IsPartyMember(flags)
		return ( bit_band(flags, COMBATLOG_OBJECT_AFFILIATION_PARTY) == COMBATLOG_OBJECT_AFFILIATION_PARTY )
	end
	
	local function IsMyFlags(flags)
		return  CombatLog_Object_IsA(flags, COMBATLOG_FILTER_MINE  )
	end
	
	local function IsMyPetFlags(flags)
		return  CombatLog_Object_IsA(flags, COMBATLOG_FILTER_MY_PET )
	end
	
	local function IsPlayer(flag)
		if flag then return ( bit_band(flag, COMBATLOG_OBJECT_TYPE_PLAYER) > 0 ) end
		return false
	end
	
	C.IsPlayer = IsPlayer
	
	local function IsNPC(flag)
		if flag then return ( bit_band(flag, COMBATLOG_OBJECT_TYPE_NPC) > 0 ) end
		return false
	end
	
	C.IsNPC = IsNPC
	
	
	function C:GetAffiliation(spellid)
	
		
		spellid = IsGroupUpSpell(spellid) or spellid
		
		if self.db.profile.classSpells[self.myCLASS][spellid] and
			self.db.profile.classSpells[self.myCLASS][spellid].source then 
			return self.db.profile.classSpells[self.myCLASS][spellid].source end
			
		if self.db.profile.procSpells[spellid] and
			self.db.profile.procSpells[spellid].source then 
			return self.db.profile.procSpells[spellid].source end
			
		if self.db.profile.othersSpells[spellid] and
			self.db.profile.othersSpells[spellid].source then 
			return self.db.profile.othersSpells[spellid].source end
		
		return 2
	end
	
	function C:GetTargetAffiliation(spellid)
	
		
		spellid = IsGroupUpSpell(spellid) or spellid
		
		if self.db.profile.classSpells[self.myCLASS][spellid] and
			self.db.profile.classSpells[self.myCLASS][spellid].target_affil then 
			return self.db.profile.classSpells[self.myCLASS][spellid].target_affil end
		
		if self.db.profile.procSpells[spellid] and
			self.db.profile.procSpells[spellid].target_affil then 
			return self.db.profile.procSpells[spellid].target_affil end
			
		if self.db.profile.othersSpells[spellid] and
			self.db.profile.othersSpells[spellid].target_affil then 
			return self.db.profile.othersSpells[spellid].target_affil end
			
		return 1
	end

	function C:CheckUnitSource(unit1, atype)	
		if unit1 then
			if atype == 2 then
				return UnitIsUnit(unit1, 'player') or false
			elseif atype == 3 then
				return UnitInRaid(unit1) or UnitInParty(unit1) or false --( unit1 == match(unit1, "raid%d") or unit1 == match(unit1, "party%d") or UnitInRaid(unit1) or UnitInParty(unit1))
			elseif atype == 4 then
				return UnitInParty(unit1) or false --( unit1 == match(unit1, "party%d") or UnitInParty(unit1) )
			elseif atype == 5 then
				return UnitIsUnit(unit1, 'pet') or false --( unit1 == "playerpet" ) or ( unit1 == "pet" )
			elseif atype == 1 then
				return true
			end
		end		
		return false		
	end
	
	function C:CLEU_AffilationCheck(flags, spellid)
		if not flags and spellid then return false end
		
		local affilation = self:GetAffiliation(spellid)

		if affilation == 2 then
			return ( IsMyFlags(flags) )
		elseif affilation == 3 then
			return ( IsRaidMember(flags) )
		elseif affilation == 4 then
			return ( IsPartyMember(flags) )
		elseif affilation == 5 then
			return ( IsMyPetFlags(flags) )
		elseif affilation == 1 then
			return true
		end
		return false
	end
	
	function C:CLEU_AffilationCheckTarget(flags, spellid)
		if not flags and spellid then return false end
		
		local affilation = self:GetTargetAffiliation(spellid)

		if affilation == 2 then
			return ( IsMyFlags(flags) )
		elseif affilation == 3 then
			return ( IsRaidMember(flags) )
		elseif affilation == 4 then
			return ( IsPartyMember(flags) )
		elseif affilation == 5 then
			return ( IsMyPetFlags(flags) )
		elseif affilation == 1 then
			return true
		end
		return false
	end
	
	--[[
	function C:CLEU_TEST(flags, name, spellName)
		
		print("T", name, spellName, IsPlayer(flags), IsMyFlags(flags), IsMyPetFlags(flags), IsRaidMember(flags), IsPartyMember(flags))
	end
	
	]]
	--[==[
	function C:CLEU_TypeSource(flags, atype)
		if atype == 2 then
			return ( unit1 == "player" )
		elseif atype == 3 then
			return ( unit1 == match(unit1, "raid%d") or unit1 == match(unit1, "party%d") )
		elseif atype == 4 then
			return ( unit1 == match(unit1, "party%d") )
		elseif atype == 5 then
			return ( unit1 == match(unit1, "playerpet") or unit1 == match(unit1, "pet") )
		elseif atype == 1 then
			return true
		end
		return false
	end
	]==]
end
-------------- aura duration --------------------------------
do
	C.pandemia_cache = {}
	
	local pandemia_cache = C.pandemia_cache
	
	local duration, tick, tick_count, tick_every
	
	local Round = C.Round

	local function fullDuration(spellID, dstGUID, pandemia_t) -- pandemia_t 1 - refresh 2 - applied
		
		spellID = IsGroupUpSpell(spellID) or spellID
		
		tick_every 	= C.db.profile.classSpells[C.myCLASS][spellID].tick
		tick_count 	= Round(C.db.profile.classSpells[C.myCLASS][spellID].duration/tick_every)
		duration 	= tick_count * tick_every
		
		if C.ignorePandemicForCorruption and spellID == 146739 then			
			return 0
		end
		
		if C.db.profile.classSpells[C.myCLASS][spellID].pandemia then
			if pandemia_t == 2 then				
				if pandemia_cache[dstGUID] and pandemia_cache[dstGUID][spellID] and ( pandemia_cache[dstGUID][spellID] - GetTime() > 0 ) then					
					if (pandemia_cache[dstGUID][spellID] - GetTime()) > duration*0.3 then					
						duration = duration + duration*0.3
					else
						duration = duration + (pandemia_cache[dstGUID][spellID] - GetTime())
					end					
					pandemia_cache[dstGUID][spellID] = GetTime()+duration		
				end
			elseif pandemia_t == 1 then		
				pandemia_cache[dstGUID] = pandemia_cache[dstGUID] or {}				
				pandemia_cache[dstGUID][spellID] = GetTime()+duration
			end
		end
		return duration
	end
	
	function C:RemovePandemia(spellID, dstGUID)	
		if spellID then
			spellID = IsGroupUpSpell(spellID) or spellID

			if pandemia_cache[dstGUID] and pandemia_cache[dstGUID][spellID] then pandemia_cache[dstGUID][spellID] = nil end
		else
			if pandemia_cache[dstGUID] then pandemia_cache[dstGUID] = nil end
		end
	end
	
	function C:GetDefaultDuraton(spellID)
	
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] and self.db.profile.classSpells[self.myCLASS][spellID].duration then
			return self.db.profile.classSpells[self.myCLASS][spellID].duration, self.db.profile.classSpells[self.myCLASS][spellID].duration*1.3
		end
		return 0, 0
	end
	
	local traptypes_duration = {
		-- 1: normal nonactive 2:pvp nonactive 3:normal active 4:pvp active
		[82939] = { 60 },
		[13813] = { 60 },
		[13812] = { 10 }, -- debuff
		
		[60192] = { 60 },
		[1499] 	= { 60 },
		[3355]  = { 60, 8 }, -- debuff
			
		[34600] = { 60 }, -- snake
		[82948] = { 60 }, -- snake
		[25809] = { 10 }, -- debuff snakes
		[45145] = { 15 }, -- snake SPELL_CAST_SUCCESS
		
		[13810] = { 30 }, -- slow SPELL_CAST_SUCCESS
		[82941] = { 60 },-- slow normal		
		[135299] = { 30 }, -- slow normal debuff
		[13809] = { 60 },-- slow normal	
		
		[162488] = { 60, 60, 30, 10},
		[187650] = { 60, 60, 60, 8 },
		[191433] = { 60, 60, 10, 10},
		[194277] = { 15, 15, 6, 6},
		[187698] = { 60, 60, 30, 10 },		
		[162487] = { 60, 60, 30, 10 },
		[194279] = { 15, 15, 6, 6},	
	}
	
	local normalTrapDur = 1
	
	
	function C:GetTrapDuration(spellID, isplayer, active)
		local num = active and normalTrapDur+2 or normalTrapDur
		
		if traptypes_duration[spellID] then		
			return ( isplayer and traptypes_duration[spellID][num+1] ) or traptypes_duration[spellID][num] or traptypes_duration[spellID][normalTrapDur]
		end		
		
		return 0
	end
	
	function C:GetDuration(spellID, dstGUID, pandemia_t, isplayer)
	
		spellID = IsGroupUpSpell(spellID) or spellID
	
		if self.db.profile.classSpells[self.myCLASS][spellID].haste then
			if C.db.profile.classSpells[self.myCLASS][spellID].tick and
				C.db.profile.classSpells[self.myCLASS][spellID].tick > 0 and
				C.db.profile.classSpells[self.myCLASS][spellID].duration then
				return fullDuration(spellID, dstGUID, pandemia_t)
			end
		end
		
		if isplayer and self.db.profile.classSpells[self.myCLASS][spellID].pvpduration then
			return self.db.profile.classSpells[self.myCLASS][spellID].pvpduration or self.db.profile.classSpells[self.myCLASS][spellID].duration
		end
		
		return self.db.profile.classSpells[self.myCLASS][spellID].duration
	end
	
	function C:FillDuration(spellID, isplayer, duration)
		spellID = IsGroupUpSpell(spellID) or spellID
		
		if self.db.profile.classSpells[self.myCLASS][spellID] then
			if not self.db.profile.classSpells[self.myCLASS][spellID].duration then
				self.db.profile.classSpells[self.myCLASS][spellID].duration = duration
			end
			
			if isplayer then
				if not self.db.profile.classSpells[self.myCLASS][spellID].pvpduration then
					self.db.profile.classSpells[self.myCLASS][spellID].pvpduration = duration
				end
			end		
		end
	end
end
----------------------------------------------------------

function C:GetCustomTextureBars(spellID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	local texture = nil
	
	if self.db.profile.classSpells[self.myCLASS][spellID] and
		self.db.profile.classSpells[self.myCLASS][spellID].custom_texture_on then
		
		texture = self.db.profile.classSpells[self.myCLASS][spellID].custom_texture
	end
	if self.db.profile.procSpells[spellID] and
		self.db.profile.procSpells[spellID].custom_texture_on then
		
		texture = self.db.profile.procSpells[spellID].custom_texture
	end
	if self.db.profile.othersSpells[spellID] and
		self.db.profile.othersSpells[spellID].custom_texture_on then
		
		texture = self.db.profile.othersSpells[spellID].custom_texture
	end
	if texture and tonumber(texture) ~= nil then
		return tonumber(texture)
	elseif texture and texture ~= ''then
		local prefolder = ''
		texture = texture:lower()
		
		if not find(texture, '\\') then		
			if not find(texture, '\\icons\\') then	
				prefolder = 'Interface\\Icons\\'
			end
		end
		
		return prefolder..texture
	end
	
	return false
end


function C:GetCustomCooldownTexture(spellName)

	local texture = nil
	
	if self.db.profile.classCooldowns[self.myCLASS][spellName] and 
		( self.db.profile.classCooldowns[self.myCLASS][spellName].custom_texture_on or self.db.profile.classCooldowns[self.myCLASS][spellName].custom_texture_on == nil ) then		
		texture = self.db.profile.classCooldowns[self.myCLASS][spellName].custom_texture		
	end
	
	if self.db.profile.internal_cooldowns[spellName] and 
		( self.db.profile.internal_cooldowns[spellName].custom_texture_on or self.db.profile.internal_cooldowns[spellName].custom_texture_on == nil ) then		
		texture = self.db.profile.internal_cooldowns[spellName].custom_texture		
	end
	
	if texture and tonumber(texture) ~= nil then
		return tonumber(texture)
	elseif texture and texture ~= '' then
		local prefolder = ''
		texture = texture:lower()
		
		if not find(texture, '\\') then		
			if not find(texture, '\\icons\\') then	
				prefolder = 'Interface\\Icons\\'
			end
		end
		
		return prefolder..texture
	end
	
	return false
end

function C:GetCustomText(spellID)
	
	spellID = IsGroupUpSpell(spellID) or spellID
	
	if self.db.profile.classSpells[self.myCLASS][spellID] and
		self.db.profile.classSpells[self.myCLASS][spellID].custom_text_on then
		
		return self.db.profile.classSpells[self.myCLASS][spellID].custom_text
	end
	if self.db.profile.procSpells[spellID] and
		self.db.profile.procSpells[spellID].custom_text_on then
		
		return self.db.profile.procSpells[spellID].custom_text
	end
	if self.db.profile.othersSpells[spellID] and
		self.db.profile.othersSpells[spellID].custom_text_on then
		
		return self.db.profile.othersSpells[spellID].custom_text
	end
	
	return false
end
do
	local GetTalentInfo = GetTalentInfo
	local MAX_TALENT_TIERS = MAX_TALENT_TIERS
	local GetActiveSpecGroup = GetActiveSpecGroup
	
	local function IsTalentKnown(spellID)
		for i=1, MAX_TALENT_TIERS do
			for a=1, 3 do
				local talentID, name, texture, selected, availible, spellID_talent = GetTalentInfo(i, a, GetActiveSpecGroup())

				if selected then
					if spellID == spellID_talent then
						return true
					end
				end
			end
		end
		
		return false
	end

	C.IsTalentKnown = IsTalentKnown
end	
	
local SpellsToRemove = {	
	["HUNTER"] = { 82939, 13813, 13812, 60192,1499, 3355, 34600, 82948, 25809, 45145, 13810, 82941, 135299, 13809},
	["PRIEST"] = { 2944 },
}

local GlobalSpellsToRemove = {
	187614,
	187611,
	187615,
}

local SpellOneTimeRemove = {
	{
		mark = 'clear3.4',
		spells = {
			['CLASS']  = { 187620, 187616, 187619, 187613, 187618 },
			['PROCS']  = { 184073 },
			['OTHERS'] = { 184073 },
		},
	},
}

function C:SetupAuras(C)
	
	self.myGUID = UnitGUID("player")

	if not C.SpellOneTimeRemove then
		C.SpellOneTimeRemove = {}
	end
	
	for k,v in pairs(procs) do
		if GetSpellInfo(k) == nil or GetSpellInfo(k) == "" then
			print("Wrong procSpells spellID in default list", k)		
			procs[k] = nil
		end
	end
	
	for k,v in pairs(others) do
		if GetSpellInfo(k) == nil or GetSpellInfo(k) == "" then
			print("Wrong othersSpells spellID in default list", k)		
			others[k] = nil
		end
	end
	
	for k,v in pairs(internal_cooldowns) do
		if k == "" then
			print("Wrong internal_cooldowns spellID in defaul list", v.spellid)			
			internal_cooldowns[k] = nil
		end
	end
	
	C.procSpells = procs
	C.othersSpells = others
	C.internal_cooldowns = internal_cooldowns
	
	
	for k,v in pairs(C.procSpells) do
		if GetSpellInfo(k) == nil or GetSpellInfo(k) == "" then
			print("Wrong procSpells spellID", k)		
			v = nil
		end
	end
	
	for k,v in pairs(C.othersSpells) do
		if GetSpellInfo(k) == nil or GetSpellInfo(k) == "" then
			print("Wrong othersSpells spellID", k)			
			v = nil
		end
	end
	
	for k,v in pairs(C.internal_cooldowns) do
		if k == "" then
			print("Wrong internal_cooldowns spellID", v.spellid)			
			v = nil
		end
	end

	if self.SetupClassSpells then	
		for id,data in pairs(self:SetupClassSpells()) do			
			if GetSpellInfo(id) == nil or GetSpellInfo(id) == "" then
				print("Wrong classSpells spellID in default "..self.myCLASS.." DB #", id)
			else
				C.classSpells[self.myCLASS][id] = data
			end
		end
	end
	
	for k,v in pairs(C.classSpells[self.myCLASS]) do
		if GetSpellInfo(k) == nil or GetSpellInfo(k) == "" then
			print("Wrong classSpells spellID in profile"..self.myCLASS.." DB #", k)			
			C.classSpells[self.myCLASS][k] = nil
		end
	end

	for i=1, #( SpellsToRemove[self.myCLASS] or {} ) do
		if C.classSpells[self.myCLASS][SpellsToRemove[self.myCLASS][i]] then		
			print("Wrong classSpells spellID in profile"..self.myCLASS.." DB #", SpellsToRemove[self.myCLASS][i], "due of removed spells")
			C.classSpells[self.myCLASS][SpellsToRemove[self.myCLASS][i]] = nil			
		end
	end

	for i=1, #GlobalSpellsToRemove do
		if C.classSpells[self.myCLASS][GlobalSpellsToRemove[i]] then		
			print("Wrong classSpells spellID in profile"..self.myCLASS.." DB #", GlobalSpellsToRemove[i], "due of removed spells")
			C.classSpells[self.myCLASS][GlobalSpellsToRemove[i]] = nil			
		end
	end
	
	for i=1, #GlobalSpellsToRemove do
		if C.procSpells[GlobalSpellsToRemove[i]] then		
			print("Wrong procSpells spellID in profile DB #", GlobalSpellsToRemove[i], "due of removed spells")
			C.procSpells[GlobalSpellsToRemove[i]] = nil	
		end
	end
	
	for i=1, #GlobalSpellsToRemove do
		if C.othersSpells[GlobalSpellsToRemove[i]] then		
			print("Wrong othersSpells spellID in profile DB #", GlobalSpellsToRemove[i], "due of removed spells")
			C.othersSpells[GlobalSpellsToRemove[i]] = nil	
		end
	end
	
	if self.SetupClassCooldowns then
		C.classCooldowns[self.myCLASS] = self:SetupClassCooldowns()
		
	end
	
	for k,v in pairs(C.classCooldowns[self.myCLASS]) do
		if k == "" then
			print("Wrong classCooldowns spellID id DB #", v.spellid)
			C.classCooldowns[self.myCLASS][k] = nil
		end
	end
	
	
	return C
end

function C:RemoveSpellExists(C)
	
	self.myGUID = UnitGUID("player")

	if not C.SpellOneTimeRemove then
		C.SpellOneTimeRemove = {}
	end
	
	for i=1, #( SpellsToRemove[self.myCLASS] or {} ) do
		if C.classSpells[self.myCLASS][SpellsToRemove[self.myCLASS][i]] then		
			print("Wrong classSpells spellID in profile"..self.myCLASS.." DB #", SpellsToRemove[self.myCLASS][i], "due of removed spells")
			C.classSpells[self.myCLASS][SpellsToRemove[self.myCLASS][i]] = nil			
		end
	end

	for i=1, #GlobalSpellsToRemove do
		if C.classSpells[self.myCLASS][GlobalSpellsToRemove[i]] then		
			print("Wrong classSpells spellID in profile"..self.myCLASS.." DB #", GlobalSpellsToRemove[i], "due of removed spells")
			C.classSpells[self.myCLASS][GlobalSpellsToRemove[i]] = nil			
		end
	end
	
	for i=1, #GlobalSpellsToRemove do
		if C.procSpells[GlobalSpellsToRemove[i]] then		
			print("Wrong procSpells spellID in profile DB #", GlobalSpellsToRemove[i], "due of removed spells")
			C.procSpells[GlobalSpellsToRemove[i]] = nil	
		end
	end
	
	for i=1, #GlobalSpellsToRemove do
		if C.othersSpells[GlobalSpellsToRemove[i]] then		
			print("Wrong othersSpells spellID in profile DB #", GlobalSpellsToRemove[i], "due of removed spells")
			C.othersSpells[GlobalSpellsToRemove[i]] = nil	
		end
	end

	for i=1, #SpellOneTimeRemove do
		local mark, spells = SpellOneTimeRemove[i].mark, SpellOneTimeRemove[i].spells
			
		if not C.SpellOneTimeRemove[mark] then
			C.SpellOneTimeRemove[mark] = true
			
			for class, list in pairs(spells) do		
				if class == 'ALL' then
					for index=1, #list do 
						local spellIDtoRemove = list[index]
						for class2, classdata in pairs(C.classSpells) do						
							if C.classSpells[class2][spellIDtoRemove] then
								C.classSpells[class2][spellIDtoRemove] = nil						
								old_print('T', 'Remove', GetSpellLink(spellIDtoRemove),'in classList', class2)
							end							
						end						
						if C.procSpells[spellIDtoRemove] then	
							C.procSpells[spellIDtoRemove] = nil
							old_print('T', 'Remove', GetSpellLink(spellIDtoRemove),'in procList')
						end					
						if C.othersSpells[spellIDtoRemove] then	
							C.othersSpells[spellIDtoRemove] = nil
							old_print('T', 'Remove', GetSpellLink(spellIDtoRemove),'in othersSpells')
						end
					end
				elseif class == 'CLASS' then
					for index=1, #list do 
						local spellIDtoRemove = list[index]
						for class2, classdata in pairs(C.classSpells) do						
							if C.classSpells[class2][spellIDtoRemove] then
								C.classSpells[class2][spellIDtoRemove] = nil						
								old_print('T', 'Remove', GetSpellLink(spellIDtoRemove),'in classList', class2)
							end							
						end	
					end				
				elseif class == 'PROCS' then
					for index=1, #list do 
						local spellIDtoRemove = list[index]				
						if C.procSpells[spellIDtoRemove] then	
							C.procSpells[spellIDtoRemove] = nil
							old_print('T', 'Remove', GetSpellLink(spellIDtoRemove),'in procList')
						end					
					end
				elseif class == 'OTHERS' then
					for index=1, #list do 
						local spellIDtoRemove = list[index]				
						if C.othersSpells[spellIDtoRemove] then	
							C.othersSpells[spellIDtoRemove] = nil
							old_print('T', 'Remove', GetSpellLink(spellIDtoRemove),'in othersSpells')
						end					
					end
				elseif C.classSpells[class] then
					for index=1, #list do 
						local spellIDtoRemove = list[index]					
						if C.classSpells[class][spellIDtoRemove] then
							C.classSpells[class][spellIDtoRemove] = nil						
							old_print('T', 'Remove', GetSpellLink(spellIDtoRemove),'in classList', class)
						end							
					end
				end
			end
		end
	end
end