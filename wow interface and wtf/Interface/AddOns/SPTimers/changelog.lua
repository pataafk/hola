local addon, C = ...
local changelog = 
[[3.14.1
fix various "New achor system error"

3.14.0
fix various "New achor system error"
fix text flickering on bars
[WIP] Rewrite cooldown line.

3.13.2
fix CoP bug

3.13.1
fix lags

3.13.0
temporary disable stat weight module for 8.1.5

3.12.1
fix profiler

3.12.0
Update for BFA

3.11.4
cooldownline - some changes with charges and splashes

3.11.3
cooldownline - fix cooldowns with 1 charge spells

3.11.2
bugfixes

3.11.1
lib update for 7.3

v3.10.7
fix colldownline.lua error

v3.10.6
7.2.5 update

v3.10.5
Lib update

v3.10.4
bugfixes

v3.10.3
Lib update

v3.10.2
stat parser pattern fix

v3.10.1
update for 7.2

v3.10.0
add relic weight

v3.9.7
bugfix

v3.9.6
real cooldowns for death knight spells
improve gcd detection

v3.9.5
Lib update

v3.9.4
revert 3.9.1 fixes

v3.9.3
bugfix for cooldowns

v3.9.2
bugfix for cooldowns

v3.9.1
bugfixes

v3.9.0
bugfixes

v3.8.7
bugfix

v3.8.6
change cooldown detection

v3.8.5
add gcd detection

v3.8.4
fix fps drop from BAG_UPDATE_COOLDOWN event

v3.8.3
bugfixes

v3.8.2
reduce minimum cooldown duration for cooldown line

v3.8.1
statweight lua error fix

v3.8.0
gui pruning

v3.7.3
bugfixes

v3.7.2
Cooldown line:
   change block list logic
   
   Warlock:
       Show only latest used spell from Grimoire of Service
       Show only latest used Summon Infernal or Summon Doomguard

v3.7.1
increase sensitivity of massive spell detector 
  -> from 4 target to 6 target and time difference from 2 sec to 1 sec
    -> set 'Target Type' to 'single' or 'multi' to disable detector for class spell

v3.7.0
add legion trinkets
demon hunter class spells

v3.6.10
fix error if tick time set to 0

v3.6.9
offtargets sorting behavior improvements

v3.6.8
change offtargets sorting behavior

v3.6.7
siphon life pandemia enabled
Swiftmend cooldown fix

v3.6.6
update fix for death knight cooldowns

v3.6.5
fix cast bars settings update on profile change

v3.6.4
fix bug with settings update
change spell text and raid icon position logic

v3.6.3
fix shaman error

v3.6.2
Update for Legion
fix latency for castbars
stats weight - removed

v3.5.1
fix error with wrong pattern
add glow on apply aura

v3.5
stats weight - add gems value select and stat select
stats weight - add support custom name colors code like ||cFF00FF00
itemID fix

v3.4.5
cooldowns - warrior Colossus Smash cooldown spellID fix
stats weight - add gems to item weight
stats weight - fix error for disabled classes

v3.4
legendary ring buffs fix
add target affiliation to proc and other lists 

v3.3
priest stats weight module

v3.2.3
mage fire dots stuff
add 6.2 trinkets

v3.2.0
add custom icon texture support

v3.1.9
add nil custom text check

v3.1.8
fix number pattern
cache for number values

v3.1.7
fix bug with deleting anchors
rewrite custom text.

v3.1.5
remove spam

v3.1.4
bars spellText position corretions. May require to abjust text position manually
fix shaman's Ascendance cooldown for Cooldown Line
add "Ignore custom colors" to "Bars"

v3.1.3
gui wrap text disabled
fix bar size change

v3.1.1
fix shaman's Riptide and Unleash Life cooldowns
fix deleting bar anchor
fix cooldown bar selecting anchor

v3.1.0
gui update 
mm killshot cooldown 
fix separate group for class specific options
hunters traps update - Bars - Traps 
fix talent cooldown parse 
add gcd for player castbar

v2.10.0
add quest ring procs
add anchors sorting group on/off
add new custom text tags %newval1 %newval2 %newval3

v2.9.12
bugfixes

v2.9.9
bugfixes

v2.9.8
bars fadeout animation improvements
mouseover unit buffs for friendly units
talents's cooldown scan update

v2.9.3
dispell fix

v2.9.2
update about info
add holy paladin spell 31842
alpha verion of cop assist

v2.9.1
fix wrong cast bar interrupt state

v2.9.0
add some pandemia spells
bugfixes

v2.8.7
custom text error
cooldown line aura glitches

v2.8.6
fix unlimited auras

v2.8.5
fix shaman primal strike taint
atept to fix cooldown line texture anchoring
atept to fix bars fadeout animation glitches
player auras on cooldown line ( |cff00ff00Cooldown Line - Auras|r )


v2.8.0
add target name for player cast bar

v2.7.10
fix error bars fading

v2.7.9
import/export removed from profile

v2.7.7
fix spell options gui

v2.7.6
move bars settings form |cff00ff00General|r to |cff00ff00Bars|r
add addon version check

v.2.7.5
fix talent cooldown time

v2.7.3

pandemia (30% dot time ) breakpoint ( |cff00ff00Generals|r )
pandemia style ( |cff00ff00General|r )
pandemia color ( |cff00ff00Bars - Style|r )
Add druid rake and Savager Roar ids
some changes with source/target spell affiliation ( bars spell filters )
add group header position ( bottom/top ) - ( |cff00ff00Bars - Style - Group Settings - Grow up|r)
group backgrounds transparent by default
Add warlock Immolate missing spell
Big Cooldown splash moved to global option tree
fix auras without duration
add group background on/off
group background changes
adapt to max improvements
bar smooth improvements
fix adapt to max, maximum time
add header text customization
add bar overlay customization
add B64 export/import profile
add SpellCache
improve bar overlay autocolor
add turn on/off latency text for cast bars
bugfixes

v2.5.3

bugfixes

v2.5.2

update for wod

v1.74.6

bugfixes

v1.74.5

add font shadow setup

v1.74.3

fix big/small splash hide

v1.74.2

add 2 stages for big splash. To show only forced spells/hide only forced spells

v1.74.1

add option to hide big splash for cooldown

v1.74

reupload v1.73

v1.73

add import/export feature

v1.71

add select sorting timer. "Bars - Style - Sorting"

v1.70

sound for show/hide timers or cooldowns

v1.69

fix target name option update
fix hero/bl/tw "Source". May require manually update to "Source - Any"

v1.68

update for test bars
add raid icon settings
fix buff ticks

v1.66

fix error with filters

v1.65

add "hide dot ticks" option

v1.57

add check for custom spell duration
right click now hide cd

v1.55

cooldownline icon animation and mouse events updated
bar fade out animation updated

v1.50

add global style settings
unit filter, anchor per unit, dot swap improvements

fix solo target type with dot swap disabled
add unit filter

fix tick shine position

v1.46

separate background color for splashes
fix channeling fading
add cooldown line show/hide

v1.45

hide during petbattle
new dk runes icon
cooldown icon background color setup

v1.43

bugfixes

v1.40

add tick count as stack text
add custom text tag %tickcount
add experimental feature to set anchors per unit
add copy settings between anchors
add anchor custom name
add gap for cooldown line tooltip
add cooldownline icon background inset

v1.39

add bar reverse filling
rebuild blacklist for cooldowns
added cooldown report on left click

v1.34

fix totem/shroom hide/show button
minor bugfixes

v1.33

fade out bar animation update
add timer background glow effect
minor bugfixes

v1.29

minor bugfixes

v1.27

rebuild spelltext position
add spelltext offset x
add missing translation

v1.25

fix groups alpha setup

v1.24

fix weapon enchants and totems

v1.23

add icon border setup
fix cleu on/off settings

v1.22

add hide cooldown line time text
add hide cooldown texture
add custom sorting for anchor groups
max cooldown line and bars width set to max resolution

v1.19

fix ticks show

v1.18

add "Adapt to one maximum" and "Maximum time"

v1.17

move back bar border texture setup
offtarget anchor
fading delay option

v1.13

fix channeling spell hide/show
add tick overlap
add text alpha

v1.10b

MA and Skull Banner source fix
add 4p16 shadow buff

]]
C.changeLog = changelog