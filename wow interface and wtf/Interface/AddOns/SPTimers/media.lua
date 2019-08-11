local addon, C = ...
local LSM = C.LSM

LSM:Register("border", "ElvUI Style2", "Interface\\AddOns\\"..addon.."\\\media\\BorderSquarePerso2.tga")
LSM:Register("border", "Flat", "Interface\\AddOns\\"..addon.."\\\media\\Flat.tga")
LSM:Register("border", "Minimalist", "Interface\\AddOns\\"..addon.."\\\media\\Minimalist.tga")

LSM:Register("statusbar", "Flat", "Interface\\AddOns\\"..addon.."\\\media\\Flat.tga")
LSM:Register("statusbar", "Minimalist", "Interface\\AddOns\\"..addon.."\\\media\\Minimalist.tga")

LSM:Register("border", "WHITE8x8", [[Interface\Buttons\WHITE8x8]])
LSM:Register("statusbar", "WHITE8x8", [[Interface\Buttons\WHITE8x8]])



if not C.CustomColors then C.CustomColors = {} end
local colors = C.CustomColors
-- COLORS
colors["ELV_DBLUE"]			= { 23/255, 131/255, 209/255 }
colors["ELV_LBLUE"]			= { 79/255, 115/255, 161/255 }
colors["ELV_LGREEN"]		= { 75/255, 175/255, 76/255 }
colors["ELV_LYELLOW"]		= { 218/255, 197/255, 92/255 }
colors["ELV_LGREY"]			= { 153/255, 153/255, 153/255 }
colors["ELV_ORANGE"] 		= { 240/255, 154/255, 17/255 }
colors["ELV_PINK"] 			= { 179/255, 118/255, 184/255 }
colors["ELV_RED"] 			= { 204/255, 26/255, 26/255 }
colors["ELV_PURPLE"] 		= { 128/255, 128/255, 255/255 }
colors["ELV_OFFLINE"] 		= { 214/255, 191/255, 166/255 }
colors["ELV_HEALTH"] 		= { 79/255, 79/255, 79/255 }
colors["ELV_HPRED"] 		= { 204/255, 3/255, 3/255 }
colors["ELV_ALIEN"] 		= { 140/255, 145/255, 156/255 }
colors["ELV_MANA"] 			= { 79/255, 115/255, 161/255 }
colors["ELV_RAGE"] 			= { 199/255, 64/255, 64/255 }
colors["ELV_FOCUS"] 		= { 181/255, 110/255, 69/255 }
colors["ELV_ENERGY"] 		= { 166/255, 161/255, 89/255 }
colors["ELV_RUNICPOWER"] 	= { 0, 209/255, 255/255}
colors["ELV_NEUTRAL"] 		= { 218/255, 197/255, 92/255 }
colors["ELV_FRIENDLY"] 		= { 75/255, 175/255, 76/255 }
colors["SPINAL_WOO"] 		= {151/255, 86/255, 168/255}
colors["SPINAL_WOO2"] 		= {80/255, 83/255, 150/255}
colors["SPINAL_WOO2DARK"] 	= {30/255, 30/255, 65/255}
colors["SPINAL_WHITE"]		= { 255/255, 255/255 ,255/255 }
colors["SPINAL_STRAW"]		= { 255/255, 204/255 , 0/255 }

-- BUFFS COLOR 
colors["JADEPOTION"] 		= { 84/255, 106/255, 11/255 }
colors["LIGHTWEAVE"]		= { 129/255, 59/255, 143/255 }
colors["JADEENCANT"]		= {  6/255, 138/255, 88/255}
colors["SYNAPSE"]			= { 90/255, 176/255, 213/255 }
colors["MEGAERA"]			= { 91/255, 85/255, 176/255 }
colors["UVLS"]				= { 225/255, 211/255, 177/255 }
colors["CHAE"]				= { 206/255, 228/255, 244/255 }
colors["WYSHU"]				= { 60/255, 103/255, 95/255 }
colors["LMG"]				= { 195/255, 143/255, 109/255 }
colors["Trink"]				= { 163/255, 166/255, 135/255 } 
colors["RED"]				= { 0.8, 0, 0}
colors["LRED"]				= { 1,0.4,0.4}
colors["DRED"]				= { 0.55,0,0}
colors["CURSE"]				= { 0.6, 0, 1 }
colors["PINK"]				= { 1, 0.3, 0.6 }
colors["PINKIERED"]			= { 206/255, 4/255, 56/255 }
colors["TEAL"]				= { 0.32, 0.52, 0.82 }
colors["TEAL2"]				= {38/255, 221/255, 163/255}
colors["ORANGE"]			= { 1, 124/255, 33/255 }
colors["FIRE"]				= {1,80/255,0}
colors["LBLUE"]				= {149/255, 121/255, 214/255}
colors["DBLUE"]				= { 50/255, 34/255, 151/255 }
colors["GOLD"]				= {1,0.7,0.5}
colors["LGREEN"]			= { 0.63, 0.8, 0.35 }
colors["GREEN"]				= {0.3, 0.9, 0.3}
colors["DGREEN"]			= { 0, 0.35, 0 }
colors["PURPLE"]			= { 187/255, 75/255, 128/255 }
colors["PURPLE2"]			= { 188/255, 37/255, 186/255 }
colors["PURPLE3"]			= { 64/255, 48/255, 109/255 }
colors["DPURPLE"]			= {74/255, 14/255, 85/255}
colors["FROZEN"]			= { 65/255, 110/255, 1 }
colors["CHILL"]				= { 0.6, 0.6, 1}
colors["BLACK"]				= {0.35,0.35,0.35}
colors["WOO"] 				= {151/255, 86/255, 168/255}
colors["WOO2"]				= {80/255, 83/255, 150/255}
colors["WOO2DARK"] 			= {30/255, 30/255, 65/255}
colors["BROWN"] 			= { 192/255, 77/255, 48/255}
colors["DBROWN"] 			= { 118/255, 69/255, 50/255}
colors["MISSED"] 			= { .15, .15, .15}
colors["DEFAULT_DEBUFF"] 	= { 0.8, 0.1, 0.7}
colors["DEFAULT_BUFF"] 		= { 1, 0.4, 0.2}
colors["TAUNT"] 			= { 255/255, 43/255, 0 }
colors["REJUV"]				= { 1, 0.2, 1 }
colors["REGROW"]			= { 198/255, 233/255, 80/255}
colors["INSANITY"]			= { 5/255, 173/255, 202/255 }

if not C.CustomSounds then C.CustomSounds = {} end
local sounds = C.CustomSounds

local weakauras_sounds = {
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BatmanPunch.ogg"] = "Batman Punch",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BikeHorn.ogg"] = "Bike Horn",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BoxingArenaSound.ogg"] = "Boxing Arena Gong",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Bleat.ogg"] = "Bleat",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonHop.ogg"] = "Cartoon Hop",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CatMeow2.ogg"] = "Cat Meow",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\KittenMeow.ogg"] = "Kitten Meow",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RobotBlip.ogg"] = "Robot Blip",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SharpPunch.ogg"] = "Sharp Punch",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\WaterDrop.ogg"] = "Water Drop",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\AirHorn.ogg"] = "Air Horn",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Applause.ogg"] = "Applause",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\BananaPeelSlip.ogg"] = "Banana Peel Slip",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Blast.ogg"] = "Blast",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonVoiceBaritone.ogg"] = "Cartoon Voice Baritone",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CartoonWalking.ogg"] = "Cartoon Walking",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\CowMooing.ogg"] = "Cow Mooing",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RingingPhone.ogg"] = "Ringing Phone",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\RoaringLion.ogg"] = "Roaring Lion",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Shotgun.ogg"] = "Shotgun",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\SquishFart.ogg"] = "Squish Fart",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\TempleBellHuge.ogg"] = "Temple Bell",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\Torch.ogg"] = "Torch",
	  ["Interface\\AddOns\\WeakAuras\\Media\\Sounds\\WarningSiren.ogg"] = "Warning Siren", 
	  
}


local powerauras_sounds = {
	
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\aggro.ogg"] = "Aggro",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\Arrow_swoosh.ogg"] = "Arrow Swoosh",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\bam.ogg"] = "Bam",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\bear_polar.ogg"] = "Polar Bear",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\bigkiss.ogg"] = "Big Kiss",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\BITE.ogg"] = "Bite",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\burp4.ogg"] = "Burp",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\cat2.ogg"] = "Cat",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\chant2.ogg"] = "Chant Major 2nd",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\chant4.ogg"] = "Chant Minor 3rd",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\chimes.ogg"] = "Chimes",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\cookie.ogg"] = "Cookie Monster",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\ESPARK1.ogg"] = "Electrical Spark",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\Fireball.ogg"] = "Fireball",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\Gasp.ogg"] = "Gasp",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\heartbeat.ogg"] = "Heartbeat",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\hic3.ogg"] = "Hiccup",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\huh_1.ogg"] = "Huh?",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\hurricane.ogg"] = "Hurricane",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\hyena.ogg"] = "Hyena",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\kaching.ogg"] = "Kaching",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\moan.ogg"] = "Moan",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\panther1.ogg"] = "Panther",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\phone.ogg"] = "Phone",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\PUNCH.ogg"] = "Punch",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\rainroof.ogg"] = "Rain",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\rocket.ogg"] = "Rocket",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\shipswhistle.ogg"] = "Ship's Whistle",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\shot.ogg"] = "Gunshot",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\snakeatt.ogg"] = "Snake Attack",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\sneeze.ogg"] = "Sneeze",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\sonar.ogg"] = "Sonar",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\splash.ogg"] = "Splash",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\Squeakypig.ogg"] = "Squeaky Toy",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\swordecho.ogg"] = "Sword Ring",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\throwknife.ogg"] = "Throwing Knife",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\thunder.ogg"] = "Thunder",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\wickedmalelaugh1.ogg"] = "Wicked Male Laugh",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\wilhelm.ogg"] = "Wilhelm Scream",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\wlaugh.ogg"] = "Wicked Female Laugh",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\wolf5.ogg"] = "Wolf Howl",
	  ["Interface\\Addons\\WeakAuras\\PowerAurasMedia\\Sounds\\yeehaw.ogg"] = "Yeehaw",

}

local powerauras2 = {

	["Interface\\Addons\\PowerAuras\\Sounds\\Aggro.mp3"] = "Aggro",
	["Interface\\Addons\\PowerAuras\\Sounds\\Arrow Swoosh.mp3"] = "Arrow Swoosh",
	["Interface\\Addons\\PowerAuras\\Sounds\\Bam.mp3"] = "Bam",
	["Interface\\Addons\\PowerAuras\\Sounds\\Bear Polar.mp3"] = "Bear Polar",
	["Interface\\Addons\\PowerAuras\\Sounds\\Big Kiss.mp3"] = "Big Kiss",
	["Interface\\Addons\\PowerAuras\\Sounds\\Bite.mp3"] = "Bite",
	["Interface\\Addons\\PowerAuras\\Sounds\\Bloodbath.mp3"] = "Bloodbath",
	["Interface\\Addons\\PowerAuras\\Sounds\\Burp.mp3"] = "Burp",
	["Interface\\Addons\\PowerAuras\\Sounds\\Cat.mp3"] = "Cat",
	["Interface\\Addons\\PowerAuras\\Sounds\\Chant1.mp3"] = "Chant1",
	["Interface\\Addons\\PowerAuras\\Sounds\\Chant2.mp3"] = "Chant2",
	["Interface\\Addons\\PowerAuras\\Sounds\\Chimes.mp3"] = "Chimes",
	["Interface\\Addons\\PowerAuras\\Sounds\\Cookie.mp3"] = "Cookie",
	["Interface\\Addons\\PowerAuras\\Sounds\\Espark.mp3"] = "Espark",
	["Interface\\Addons\\PowerAuras\\Sounds\\Fireball.mp3"] = "Fireball",
	["Interface\\Addons\\PowerAuras\\Sounds\\Gasp.mp3"] = "Gasp",
	["Interface\\Addons\\PowerAuras\\Sounds\\Heartbeat.mp3"] = "Heartbeat",
	["Interface\\Addons\\PowerAuras\\Sounds\\Hic.mp3"] = "Hic",
	["Interface\\Addons\\PowerAuras\\Sounds\\Huh.mp3"] = "Huh",
	["Interface\\Addons\\PowerAuras\\Sounds\\Hurricane.mp3"] = "Hurricane",
	["Interface\\Addons\\PowerAuras\\Sounds\\Hyena.mp3"] = "Hyena",
	["Interface\\Addons\\PowerAuras\\Sounds\\Kaching.mp3"] = "Kaching",
	["Interface\\Addons\\PowerAuras\\Sounds\\Moan.mp3"] = "Moan",
	["Interface\\Addons\\PowerAuras\\Sounds\\Panther.mp3"] = "Panther",
	["Interface\\Addons\\PowerAuras\\Sounds\\Phone.mp3"] = "Phone",
	["Interface\\Addons\\PowerAuras\\Sounds\\Punch.mp3"] = "Punch",
	["Interface\\Addons\\PowerAuras\\Sounds\\Rainroof.mp3"] = "Rainroof",
	["Interface\\Addons\\PowerAuras\\Sounds\\Rocket.mp3"] = "Rocket",
	["Interface\\Addons\\PowerAuras\\Sounds\\Ship Horn.mp3"] = "Ship Horn",
	["Interface\\Addons\\PowerAuras\\Sounds\\Shot.mp3"] = "Shot",
	["Interface\\Addons\\PowerAuras\\Sounds\\Snake.mp3"] = "Snake",
	["Interface\\Addons\\PowerAuras\\Sounds\\Sneeze.mp3"] = "Sneeze",
	["Interface\\Addons\\PowerAuras\\Sounds\\Sonar.mp3"] = "Sonar",
	["Interface\\Addons\\PowerAuras\\Sounds\\Splash.mp3"] = "Splash",
	["Interface\\Addons\\PowerAuras\\Sounds\\Squeaky.mp3"] = "Squeaky",
	["Interface\\Addons\\PowerAuras\\Sounds\\Sword.mp3"] = "Sword",
	["Interface\\Addons\\PowerAuras\\Sounds\\Throw.mp3"] = "Throw",	
	["Interface\\Addons\\PowerAuras\\Sounds\\Thunder.mp3"] = "Thunder",
	["Interface\\Addons\\PowerAuras\\Sounds\\Vengeance.mp3"] = "Vengeance",
	["Interface\\Addons\\PowerAuras\\Sounds\\Warpath.mp3"] = "Warpath",
	["Interface\\Addons\\PowerAuras\\Sounds\\Wicked Laugh Female.mp3"] = "Wicked Laugh Female",
	["Interface\\Addons\\PowerAuras\\Sounds\\Wicked Laugh Male.mp3"] = "Wicked Laugh Male",
	["Interface\\Addons\\PowerAuras\\Sounds\\Wilhelm.mp3"] = "Wilhelm",
	["Interface\\Addons\\PowerAuras\\Sounds\\Wolf.mp3"] = "Wolf",
	["Interface\\Addons\\PowerAuras\\Sounds\\Yeehaw.mp3"] = "Yeehaw",
}
 
local function IsAddonExists(name)	

	if IsAddOnLoaded(name) then
		return true
	else
		return false
	end
	
	for i=1,GetNumAddOns() do
	   local addonName = GetAddOnInfo(i)	   
	   if addonName == name then return true end
	end
end

local addonloading = CreateFrame("Frame")
addonloading:RegisterEvent("PLAYER_LOGIN")
addonloading:SetScript("OnEvent", function(self, event)
	if IsAddonExists("WeakAuras") then --IsAddOnLoaded("WeakAuras") then	
		for k,v in pairs(weakauras_sounds) do	
		--	LSM:Register("sound", v, k)
		end

		for k,v in pairs(powerauras_sounds) do		
		--	LSM:Register("sound", v, k)
		end
	end
	
	if IsAddonExists("PowerAuras") then -- IsAddOnLoaded("PowerAuras") then
		for k,v in pairs(powerauras2) do		
		--	LSM:Register("sound", v, k)
		end
	end
end)