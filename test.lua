MachoIsolatedInject([=[
-- ===== Keys =====
local KEY_TOGGLE_PRIMARY = 166 -- F5
local KEY_TOGGLE_SECONDARY = 0x14 -- CapsLock
local KEY_PANIC = 167 -- F6
local KEY_UP = 172
local KEY_DOWN = 173
local KEY_LEFT = 174
local KEY_RIGHT = 175
local KEY_ENTER = 176
local KEY_BACK = 177
local KEY_F10 = 57
local WHEEL_UP = 241
local WHEEL_DOWN = 242

-- ===== Panel geometry & position =====
local PANEL_W, PANEL_H = 380, 540 -- Slimmed down width
local posMode = 2 -- 1=CENTER, 2=TOP-LEFT, 3=BOTTOM-RIGHT

-- ===== Handles/state =====
local menuDui, snowDui = nil, nil
local uiReady, snowReady = false, false
local visible = false

local inSelf, inMisc, inVehicle, inCombat, inOnlineList, inOnlineAct, inVisual, inThemes, inDestructive, inTriggers =
false,false,false,false,false,false,false,false,false,false

local listIdx, selfIdx, miscIdx, vehIdx, cmbIdx, visIdx, thmIdx, dstIdx, trgIdx = 0,0,0,0,0,0,0,0,0
local onlListIdx, onlActIdx = 0,0
local TOTAL = 9 -- Main category count is now 9

local spectate = { active = false, target = nil, cam = nil }
local liftPlayerState = { active = false, target = nil }
local freecam = {
active = false,
cam = nil,
currentFeature = 1,
selectedVehicleIndex = 1,
features = { "Look-Around", "Teleportation", "Door Unlocker", "Delete Entity", "Spikestrip Spawner", "Shooting (Pistol)", "Explode", "Fire Spawner", "Car Shooter", "Spawn Car", "Spawn Angry Ped" },
allowedVehicles = { "bmx", "cruiser", "fixter", "scorcher", "tribike", "tribike2", "tribike3", "alkonost", "alphaz1", "avenger", "avenger2", "besra", "blimp", "blimp2", "blimp3", "bombushka", "cargoplane", "cargoplane2", "cuban800", "dodo", "duster", "howard", "hydra", "jet", "lazer", "luxor", "luxor2", "mammatus", "miljet", "molotok", "molotok2", "mogul", "nimbus", "pyro", "rogue", "seabreeze", "shamal", "starling", "strikeforce", "stunt", "titan", "tula", "velum", "velum2", "vestra", "volatol", "blade", "buccaneer", "buccaneer2", "chino", "chino2", "clique", "coquette3", "deviant", "dominator", "dominator2", "dominator3", "dominator4", "dominator5", "dominator6", "dukes", "dukes2", "ellie", "faction", "faction2", "faction3", "gauntlet", "gauntlet2", "gauntlet3", "gauntlet4", "gauntlet5", "hermes", "hotknife", "hustler", "impaler", "impaler2", "impaler3", "impaler4", "imperator", "imperator2", "imperator3", "lurcher", "moonbeam", "moonbeam2", "nightshade", "peyote2", "phoenix", "picador", "ratloader", "ratloader2", "ruiner", "ruiner2", "ruiner3", "sabregt", "sabregt2", "slamvan", "slamvan2", "slamvan3", "slamvan4", "slamvan5", "slamvan6", "tampa", "tampa2", "tampa3", "tulip", "tulip2", "vamos", "vigero", "vigero2", "voodoo", "voodoo2", "yosemite", "yosemite2", "yosemite3", "apc", "barracks", "barracks2", "barracks3", "barrage", "chernobog", "crusader", "firetruk", "khanjali", "minitank", "rhino", "riot", "riot2", "ripley", "terbyte", "airtug", "bulldozer", "cutter", "docktug", "docktrailer", "dump", "flatbed", "guardian", "handler", "mixer", "mixer2", "mule", "mule2", "mule3", "mule4", "packer", "phantom", "phantom2", "phantom3", "phantom4", "pounder", "pounder2", "stockade", "stockade3", "tiptruck", "tiptruck2", "towtruck", "towtruck2", "tractor", "tractor2", "tractor3", "trash", "trash2", "utillitruck", "utillitruck2", "utillitruck3", "wastelander", "tr2", "tr3", "tr4", "trflat", "tvtrail", "trailers", "trailers2", "trailers3", "trailers4", "akuma", "avarus", "bati", "bati2", "bf400", "carbonrs", "chimera", "cliffhanger", "defiler", "diablous", "diablous2", "double", "enduro", "esskey", "faggio", "faggio2", "faggio3", "fcr", "fcr2", "gargoyle", "hakuchou", "hakuchou2", "hexer", "innovation", "lectro", "manchez", "manchez2", "nemesis", "pcj", "rrocket", "ruffian", "sanchez", "sanchez2", "shinobi", "shotaro", "sovereign", "stryder", "thrust", "vader", "vindicator", "vortex", "wolfsbane", "zombiea", "zombieb", "asbo", "asterope", "brioso", "brioso2", "brioso3", "cog55", "cog552", "cognoscenti", "cognoscenti2", "emperor", "fugitive", "glendale", "glendale2", "intruder", "issi2", "issi3", "issi4", "issi5", "issi6", "kanjo", "oracle", "oracle2", "prairie", "premier", "regina", "rhinehart", "schafter2", "schafter3", "schafter4", "schafter5", "schafter6", "stafford", "stretch", "superd", "surge", "tailgater", "tailgater2", "warrener", "warrener2", "washington", "alpha", "banshee", "bestiagts", "buffalo", "buffalo2", "buffalo3", "calico", "carbonizzare", "comet2", "comet3", "comet4", "comet5", "comet6", "comet7", "coquette", "coquette4", "cypher", "drafter", "elegy", "elegy2", "euros", "fusilade", "futo", "futo2", "gauntletrs", "growler", "hotring", "imorgon", "issi7", "italirsx", "jester", "jester2", "jester3", "jester4", "jugular", "khamelion", "komoda", "kuruma", "kuruma2", "locust", "lynx", "massacro", "massacro2", "neo", "neon", "ninef", "ninef2", "omnis", "omniseggt", "paragon", "paragon2", "pariah", "penumbra", "penumbra2", "raiden", "rapidgt", "rapidgt2", "remus", "revolter", "rt3000", "ruston", "schafter2", "schlagen", "schwarzer", "sentinel3", "sentinel4", "seven70", "specter", "specter2", "streiter", "sugoi", "sultan", "sultan2", "sultanrs", "tampa2", "tropos", "verlierer2", "vectre", "veto", "veto2", "vstr", "zr350", "adder", "autarch", "banshee2", "bullet", "cheetah", "champion", "deveste", "entityxf", "entity2", "entity3", "emerus", "endurant", "fmj", "furia", "gp1", "ignus", "ignus2", "infernus", "italigtb", "italigtb2", "krieger", "le7b", "nero", "nero2", "osiris", "penetrator", "pfister811", "prototipo", "reaper", "s80", "sc1", "sheava", "shotaro", "t20", "taipan", "tempesta", "tezeract", "thrax", "tigon", "turismor", "tyrus", "tyrant", "vacca", "vagner", "visione", "voltic", "voltic2", "xa21", "zentorno", "zeno", "baller", "baller2", "baller3", "baller4", "baller5", "baller6", "baller7", "baller8", "bfinjection", "bifta", "bison", "bison2", "bison3", "bodhi2", "brawler", "bruiser", "bruiser2", "bruiser3", "caracara", "caracara2", "contender", "dubsta3", "dune", "dune2", "dune3", "dune4", "dune5", "everon", "freecrawler", "granger", "granger2", "guardian", "hellion", "habanero", "insurgent", "insurgent2", "insurgent3", "journey", "journey2", "kamacho", "landstalker", "landstalker2", "mesa", "mesa2", "mesa3", "nightshark", "novak", "outlaw", "patriot", "patriot2", "patriot3", "rancherxl", "rebel", "rebel2", "riata", "sandking", "sandking2", "serrano", "seminole", "seminole2", "squaddie", "toros", "trophytruck", "trophytruck2", "wastelander", "youga", "youga2", "youga3", "youga4", "dinghy", "dinghy2", "dinghy3", "dinghy4", "jetmax", "marquis", "patrolboat", "seashark", "seashark2", "seashark3", "speeder", "speeder2", "squalo", "submersible", "submersible2", "suntrap", "toro", "toro2", "tropic", "tropic2", "akula", "annihilator", "annihilator2", "buzzard", "buzzard2", "cargobob", "cargobob2", "cargobob3", "cargobob4", "frogger", "frogger2", "havok", "hunter", "maverick", "polmav", "seasparrow", "seasparrow2", "seasparrow3", "skylift", "supervolito", "supervolito2", "swift", "swift2", "valkyrie", "valkyrie2", "volatus" }
}
local trollState = { attach = false }

-- ===== Data =====
local SELF_IDS = { "god", "sjump", "beast_jump", "freecam", "noclip", "invisible", "noragdoll", "nostun", "infstam",
"fastrun_toggle", "superrun", "anti_tp", "anti_handcuff", "heal", "armor", "revive", "suicide", "force_ragdoll", "clear_task", "clear_vision",
"unfreeze", "end_jail", "randfit", "pos" }

local VEH_IDS = { "repair", "autofix", "veh_god", "unlimited_fuel", "maxupgrade", "downgrade_vehicle", "clean_vehicle", "delete_vehicle", "flip_vehicle", "force_engine", "unlock",
"poptires", "rainbow", "carhop", "car_lift", "boost", "drift", "horn_boost", "infinite_boost", "vehicle_weapons", "warp", "teleport_into_vehicle" }

local CMB_IDS = { "giveall", "maxammo", "unlimammo", "explosive_ammo", "super_punch", "explosive_punch" }
local VIS_IDS = { "esp", "crosshair", "fov", "nametags" }
local MISC_IDS = { "clear_area", "cycle_weather", "spawn_ped", "force_rob", "panelpos" }
local DST_IDS = { "lift_objects", "meteors", "tpobjects", "surprise_party" }
local TRG_IDS = { "item_spawner", "money_spawner", "common_exploits", "event_payloads" } -- Dummy IDs for structure

local THEMES = { "HuM1n", "Transparent Blur", "Blue","Xmas","Halloween","Gangster","Neon","Midnight","Ocean","Sunset","Matrix","Disconnect","Gamerware", "LEAN SIPPA", "JAY PROMETHAZINE", "Trump V1", "Trump V2" }

local ONL_ACT_IDS = {
"goto_player", "tptoplayer", "spec", "kill", "explode_player", "taze", "ragdoll", "cage", "crush", "attachcone", "stealoutfit", "force_blame", "force_twerk", "force_sit", "fake_escort", "detach"
}

local FONTS = {"System","Compact","Wide","Mono"}

local visual = { theme=8 } -- Default to Midnight theme
local STATE = {
god=false, sjump=false, freecam=false, noclip=false, invisible=false, noragdoll=false, nostun=false,
infstam=false, superrun=false, boost=false, drift=false, unlimammo=false, nametags=false,
autofix=false, rainbow=false, unlimited_fuel=false, esp=false, crosshair=false,
kill_aura=false, fastrun_toggle=false, veh_god=false, horn_boost=false, explosive_ammo=false, infinite_boost=false,
super_punch=false, explosive_punch=false, anti_tp=false, anti_handcuff=false, vehicle_weapons=false
}
local OPT = { fov=60.0 }
local BIND = {}
local trgInput = {
    item_name = "...", item_amount = "...", money_amount = "...",
    event_payload = "...", event_type = "...", event_resource = "..."
}


-- Weather Cycle state
local weathers = {"EXTRASUNNY", "CLEAR", "CLOUDS", "SMOG", "FOGGY", "OVERCAST", "RAIN", "THUNDER", "CLEARING", "NEUTRAL", "SNOW", "BLIZZARD", "SNOWLIGHT", "XMAS", "HALLOWEEN"}
local current_weather_idx = 1

local onlPlayers = {}
local onlSel = nil
local notifications = {}

-- ===== Key helpers =====
local function key_name(k)
local map = {[8]="BACKSPACE",[9]="TAB",[13]="ENTER",[20]="CAPSLOCK",[27]="ESC",[32]="SPACE",[33]="PAGEUP",[34]="PAGEDOWN",[35]="END",[36]="HOME",[45]="INSERT",[46]="DELETE",[71]="G",[112]="F1",[113]="F2",[114]="F3",[115]="F4",[116]="F5",[117]="F6",[118]="F7",[119]="F8",[120]="F9",[121]="F10",[122]="F11",[123]="F12",[144]="NUMLOCK",[186]=";",[187]="=",[188]=",",[189]="-",[190]=".",[191]="/",[192]="`",[219]="[",[220]="\\",[221]="]",[222]="'",[172]="↑",[173]="↓",[174]="←",[175]="→",[176]="ENTER",[177]="BACKSPACE"}
if map[k] then return map[k] end; if k>=65 and k<=90 then return string.char(k) end; if k>=48 and k<=57 then return tostring(k-48) end; return ("K%d"):format(k)
end
local function is_banned_key(k)
local banned={[239]=true,[240]=true,[241]=true,[242]=true,[237]=true,[238]=true,[56]=true,[166]=true,[167]=true,[57]=true,[9]=true}
return banned[k] or false
end
local function Pressed(code) return IsDisabledControlJustPressed(0, code) or IsControlJustPressed(0, code) end
local function Held(code) return IsDisabledControlPressed(0, code) or IsControlPressed(0, code) end
local function DPressed(code) return IsDisabledControlJustPressed(0, code) end

-- ========================= HTML (MENU) - FULLY THEMED AND RESTYLED =========================
local HTML_MENU = [===[(function(){try{
document.open(); document.write(`<!doctype html>
<html><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>HuM1n MENU</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Creepster&family=Lobster&family=Monoton&family=Orbitron&family=Pacifico&family=Playfair+Display&family=Press+Start+2P&family=VT323&display=swap" rel="stylesheet">
<style>
:root {
	--text-primary: #f5f5f5;
	--text-secondary: #a0a0a0;
	--edge: rgba(120, 160, 200, .22);
    /* Default (Blue) Theme Variables */
	--blue:#2b6df7; --blue2:#2256d6;
    --highlight-start: #2b6df7;
    --highlight-end: #2256d6;
    --scrollbar-color: #2b6df7;
    --main-bg: rgba(20, 22, 28, 0.94);
    --footer-bg: rgba(18, 18, 18, 0.96);
}
*{box-sizing:border-box}
html,body{height:100%;margin:0;background:transparent!important;font-family:'Inter',sans-serif;color:var(--text-primary);overflow:hidden;}

/* NEW ESP STYLES */
#esp-container { position:fixed; inset:0; pointer-events:none; overflow:hidden; z-index: 1; }
.esp-box {
    border: 1px solid rgba(255, 255, 255, 0.7);
    background: rgba(0, 0, 0, 0.3);
    transition: all 0.1s linear;
    position: absolute;
}
.esp-info-container {
    position: absolute;
    bottom: 100%;
    left: 50%;
    transform: translateX(-50%);
    padding-bottom: 5px;
    width: 150px;
    display: flex;
    flex-direction: column;
    align-items: center;
}
.esp-info {
    color: #fff;
    font-size: 12px;
    font-weight: 600;
    text-shadow: 1px 1px 2px #000;
    white-space: nowrap;
    background: rgba(0,0,0,0.5);
    padding: 2px 5px;
    border-radius: 3px;
}
.esp-bar {
    height: 5px;
    width: 100%;
    background-color: rgba(0,0,0,0.7);
    border-radius: 2px;
    margin-top: 3px;
    border: 1px solid rgba(0,0,0,0.5);
}
.esp-health-bar {
    background-color: #4CAF50;
    height: 100%;
    border-radius: 2px;
}
.esp-armor-bar {
    background-color: #2196F3;
    height: 100%;
    border-radius: 2px;
}
.corner { display: none; } /* Hide old corners */

/* --- Main Layout & Structure --- */
.wrap{position:fixed;inset:0;display:flex;pointer-events:none; z-index: 50;}
.wrap.pos-center{align-items:center;justify-content:center}
.wrap.pos-tl{align-items:flex-start;justify-content:flex-start;padding:60px 0 0 30px}
.wrap.pos-br{align-items:flex-end;justify-content:flex-end;padding:0 30px 60px 0}
.menu-wrapper {position:relative;display:flex;align-items:flex-start;pointer-events:auto;}
.menu-container {width:380px;background:var(--main-bg); border-radius:8px;overflow:hidden;box-shadow:0 5px 25px rgba(0,0,0,0.7);display:flex;flex-direction:column; border: 1px solid rgba(255,255,255,0.08);}
.menu-tabs {padding: 6px 8px 0 8px; display: flex; gap: 4px; background: rgba(0,0,0,0.2);}
.tab-item {padding:8px 12px;font-size:14px;font-weight:600;color:var(--highlight-start);border-top-left-radius:4px;border-top-right-radius:4px; border-bottom: 2px solid var(--highlight-start); transition: color .2s ease, border-color .2s ease;}

/* --- Content & Scrollbar --- */
.menu-content {position:relative;height:342px;display:flex;flex-direction:column; background: rgba(0,0,0,0.15);}
.view-container {position:relative;width:100%;height:100%;overflow:hidden;}
.view, .page {position:absolute;inset:0;overflow-y:auto;scrollbar-width:none;}
.view::-webkit-scrollbar, .page::-webkit-scrollbar { display: none; }
.custom-scrollbar {width:8px;height:342px;background-color:rgba(18,18,18,0.2);border-radius:4px;position:relative;margin-left:2px;margin-right:6px;margin-top:145px;display:none;}
.custom-scrollbar-thumb {width:100%;background-color:var(--scrollbar-color);border-radius:4px;position:absolute;left:0;top:0;transition: background-color .2s ease;}

/* --- List & Item Styling --- */
.list {padding: 0;margin: 0;}
.row, .item {display:flex;justify-content:space-between;align-items:center;padding:0 15px;font-size:14px;color:var(--text-primary);height:38px;box-sizing:border-box;margin:0 4px; transition: background .2s ease;}
.row.sel, .item.sel {background:linear-gradient(90deg, var(--highlight-start), var(--highlight-end));font-weight:600;border-radius:4px;}
.row:not(.sel), .item:not(.sel) {margin-top: 2px;} .item.sel {margin-top: 2px;}
.arrow-icon {width:0;height:0;border-top:5px solid transparent;border-bottom:5px solid transparent;border-left:5px solid var(--text-primary);opacity:0.6;}
.item .status {display: flex; align-items: center; justify-content: flex-end; gap: 8px;}
.toggle-container {position: relative; width: 34px; height: 18px;}
.toggle-input {display: none;}
.toggle-label {cursor: pointer; display: block; overflow: hidden; position: absolute; top: 0; left: 0; right: 0; bottom: 0; border-radius: 99px; background: rgba(255,255,255,.1); transition: background-color .2s ease;}
.toggle-label:after {content: ''; position: absolute; top: 2px; left: 2px; width: 14px; height: 14px; background-color: #f5f5f5; border-radius: 50%; transition: transform .2s ease-in-out;}
.toggle-input:checked + .toggle-label {background: var(--highlight-start);}
.toggle-input:checked + .toggle-label:after {transform: translateX(16px);}
.item .opt {display:flex;align-items:center;gap:8px;font-size:13px;font-weight:600;}
.item .opt span {min-width: 30px; text-align: right;}
.item input[type="range"] { -webkit-appearance: none; width: 100px; height: 2px; background: rgba(255,255,255,.1); border-radius: 4px; outline: none; transition: opacity .2s; }
.item input[type="range"]::-webkit-slider-thumb { -webkit-appearance: none; appearance: none; width: 12px; height: 12px; background: var(--highlight-start); cursor: pointer; border-radius: 50%; }

/* --- Footer & Sub-pages --- */
.menu-footer {background-color:var(--footer-bg);display:flex;justify-content:space-between;align-items:center;padding:10px 15px;font-size:13px;font-weight:500;color:var(--text-secondary);margin-top:2px;}
.page{display:none;opacity:0;transform: translateX(15px);transition:opacity .2s ease, transform .2s ease;flex-direction:column;}
.page.show{display:flex;opacity:1;transform: translateX(0);}
.page .hdr{height:44px;display:flex;align-items:center;gap:8px;padding:0 15px;background:rgba(0,0,0,.2); flex-shrink: 0;}
.page .hdr .back{cursor:pointer; padding: 4px; border-radius: 4px;}
.page .content{position:relative;flex-grow:1;overflow-y:auto; scrollbar-width:none;}
.page .content::-webkit-scrollbar{display:none}

/* --- Misc UI Elements --- */
.ov{position:absolute;inset:0;background:rgba(0,0,0,.85);display:none;align-items:center;justify-content:center;z-index:100;backdrop-filter: blur(5px);}
.modal{background:var(--main-bg);border:1px solid var(--edge);border-radius:12px;padding:24px;text-align:center;min-width:240px}
.kbd{font-family:monospace;font-size:18px;font-weight:800;margin:12px 0;padding:8px 16px;background:rgba(255,255,255,.1);border-radius:6px;display:inline-block}
.blink{animation:blink 1.5s infinite} @keyframes blink{0%,50%{opacity:1}51%,100%{opacity:.3}}
.trigger-form .exec-btn {background:linear-gradient(90deg, var(--highlight-start), var(--highlight-end)); border:none; color:#fff; font-weight:800; padding:10px; border-radius:8px; cursor:pointer; margin-top:8px; transition:transform .1s ease, background .2s ease;}
.trigger-form .exec-btn:hover {transform:scale(1.02)} .trigger-form .exec-btn:active {transform:scale(.98)}

/* ===== FULLY DYNAMIC THEME SYSTEM ===== */
.banner{height:112px;border-bottom:1px solid var(--edge);position:relative;display:flex;align-items:center;justify-content:center;padding:0 16px;overflow:hidden;transition: background .3s ease;}
.HuM1n-logo{font-weight:900;font-size:32px;letter-spacing:2px;color:#fff;animation:HuM1n-glow 3s ease-in-out infinite;text-shadow:0 0 5px #fff, 0 0 10px var(--blue), 0 0 20px var(--blue2);}
@keyframes HuM1n-glow{0%,100%{opacity:.8}50%{opacity:1;transform:scale(1.02)}}

body.th-HuM1n {--blue:#ff3c3c;--blue2:#ff6969;--edge:rgba(255,60,60,0.2);--highlight-start:#ff3c3c;--highlight-end:#d42a2a;--scrollbar-color:#ff3c3c;}
body.th-HuM1n .banner { background: url('https://c.tenor.com/Ae_eyMkMi8IAAAAd/tenor.gif') center/cover; animation: none; }
body.th-transparentblur {--blue:#A0C4FF;--blue2:#B4E7CE;--highlight-start:#A0C4FF;--highlight-end:#8aa9e3;--scrollbar-color:#A0C4FF; --main-bg: rgba(20, 22, 28, 0.88);}
body.th-transparentblur .menu-container {backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);}
body.th-transparentblur .banner{background:transparent}
body.th-blue .banner{background:radial-gradient(circle at 10% 20%,rgba(43,109,247,.2),transparent 50%),linear-gradient(135deg,#121a2a,#0f1521);animation:blue-shift 10s ease-in-out infinite alternate;}@keyframes blue-shift{from{background-position:0% 0%}to{background-position:20% 0%}}
body.th-xmas {--blue:#1db954;--blue2:#d61339;--highlight-start:#1db954;--highlight-end:#d61339;--scrollbar-color:#1db954;}
body.th-xmas .banner{background:radial-gradient(circle at 20% 80%,rgba(29,185,84,.2),transparent 50%),radial-gradient(circle at 80% 20%,rgba(214,19,57,.15),transparent 60%),linear-gradient(45deg,#0f1b1b,#1a2820);overflow:hidden}
body.th-xmas .banner::before{content:'';position:absolute;inset:0;background-image:radial-gradient(white 1px,transparent 0);background-size:20px 20px;opacity:0.2;animation:snowfall 10s linear infinite}@keyframes snowfall{100%{transform:translateY(200px)}}
body.th-halloween {--blue:#ff7a1a;--blue2:#8b2bd6;--highlight-start:#ff7a1a;--highlight-end:#8b2bd6;--scrollbar-color:#ff7a1a;}
body.th-halloween .banner{background:radial-gradient(ellipse at top,rgba(255,122,26,.2),transparent 70%),radial-gradient(ellipse at bottom right,rgba(139,43,214,.15),transparent 60%),linear-gradient(135deg,#1b1117,#2a1820);animation:spooky-flicker 1.5s infinite}@keyframes spooky-flicker{0%,100%{filter:brightness(1)}95%{filter:brightness(1)}96%{filter:brightness(.8)}98%{filter:brightness(1.2)}99%{filter:brightness(1)}}
body.th-gangster {--blue:#f2c34e;--blue2:#b99114;--highlight-start:#f2c34e;--highlight-end:#b99114;--scrollbar-color:#f2c34e;}
body.th-gangster .banner{background:linear-gradient(45deg,rgba(242,195,78,.1) 0%,rgba(185,145,20,.2) 100%),linear-gradient(180deg,#1f1f1f,#0f0f0f);background-size:40px 40px;background-image:linear-gradient(45deg,rgba(255,255,255,0.03) 25%,transparent 25%,transparent 50%,rgba(255,255,255,0.03) 50%,rgba(255,255,255,0.03) 75%,transparent 75%,transparent);}
body.th-neon {--blue:#00e5ff;--blue2:#ff00d4;--highlight-start:#00e5ff;--highlight-end:#ff00d4;--scrollbar-color:#00e5ff;}
body.th-neon .banner{background:radial-gradient(circle at 30% 70%,rgba(0,229,255,.18),transparent 60%),radial-gradient(circle at 80% 20%,rgba(255,0,212,.12),transparent 50%),linear-gradient(135deg,#0b0f1b,#1a1b2f);animation:neon-flicker 10s linear infinite}@keyframes neon-flicker{0%,100%{filter:brightness(1)}50%{filter:brightness(1.1)}}
body.th-midnight {--blue:#8aa4ff;--blue2:#4860d4;--highlight-start:#8aa4ff;--highlight-end:#4860d4;--scrollbar-color:#8aa4ff;}
body.th-midnight .banner{background:radial-gradient(ellipse at center top,rgba(138,164,255,.15),transparent 70%),linear-gradient(180deg,rgba(72,96,212,.08),transparent),linear-gradient(180deg,#0e1422,#1a2035);overflow:hidden;}
body.th-midnight .banner::after{content:'';position:absolute;top:10%;left:0;width:100%;height:1px;background:linear-gradient(90deg,transparent,rgba(138,164,255,.5),transparent);animation:shooting-star 8s linear infinite}@keyframes shooting-star{0%{transform:translateX(-100%)}100%{transform:translateX(100%)}}
body.th-ocean {--blue:#36d1dc;--blue2:#5b86e5;--highlight-start:#36d1dc;--highlight-end:#5b86e5;--scrollbar-color:#36d1dc;}
body.th-ocean .banner{background:linear-gradient(160deg,#36d1dc20,#5b86e520),linear-gradient(135deg,#0a121a,#1a2a35);background-size:200% 200%;animation:ocean-wave 12s ease infinite}@keyframes ocean-wave{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
body.th-sunset {--blue:#ff9966;--blue2:#ff5e62;--highlight-start:#ff9966;--highlight-end:#ff5e62;--scrollbar-color:#ff9966;}
body.th-sunset .banner{background:linear-gradient(45deg,#ff9966,#ff5e62);background-size:200% 200%;animation:sunset-shift 10s ease infinite}@keyframes sunset-shift{0%{background-position:0% 50%}50%{background-position:100% 50%}100%{background-position:0% 50%}}
body.th-matrix {--blue:#39ff14;--blue2:#22aa11;--highlight-start:#39ff14;--highlight-end:#22aa11;--scrollbar-color:#39ff14;}
body.th-matrix .banner{background:#071109;overflow:hidden;}
body.th-matrix .banner::before{content:'';position:absolute;inset:0;background-image:linear-gradient(var(--blue) 1px,transparent 1px);background-size:1px 20px;animation:matrix-rain .5s linear infinite;opacity:0.5}@keyframes matrix-rain{0%{background-position:0 0}100%{background-position:0 -20px}}
body.th-disconnect {--blue:#b16cff;--blue2:#6a5cff;--highlight-start:#b16cff;--highlight-end:#6a5cff;--scrollbar-color:#b16cff;}
body.th-disconnect .banner{background:radial-gradient(circle at 50% 0%,rgba(177,108,255,.2),transparent 70%),radial-gradient(circle at 100% 100%,rgba(106,92,255,.15),transparent 60%),linear-gradient(180deg,#2a0c3f,#1a1030);}
body.th-gamerware {--blue:#c018c0; --blue2:#8b1297; --highlight-start:#c018c0;--highlight-end:#8b1297;--scrollbar-color:#c018c0;}
body.th-gamerware .banner{background:url('https://i.postimg.cc/L8Y3RjNL/sdfsdfsdfsfd.png') center/cover;}
body.th-gamerware .banner::after{content:"";position:absolute;inset:0;background:linear-gradient(180deg,rgba(0,0,0,.20),rgba(0,0,0,.35));}
body.th-leansippa {--blue:#9b59b6;--blue2:#8e44ad;--edge:rgba(155,89,182,0.3);--highlight-start:#9b59b6;--highlight-end:#8e44ad;--scrollbar-color:#9b59b6;}
body.th-leansippa .banner {background:url('https://c.tenor.com/AfEysfVhY5IAAAAd/tenor.gif') center 20%/cover;}
body.th-jaypromethazine {--blue:#bf00ff;--blue2:#8a2be2;--edge:rgba(191,0,255,.25);--highlight-start:#bf00ff;--highlight-end:#8a2be2;--scrollbar-color:#bf00ff;}
body.th-jaypromethazine .banner {background:url('https://i.postimg.cc/DWHP1n3j/asdasdasd.png') center/cover;}
body.th-jaypromethazine .banner::after {content:"";position:absolute;inset:0;background:linear-gradient(180deg,rgba(0,0,0,.3),rgba(0,0,0,.5));}
body.th-trumpv1 {--blue:#B61E2B;--blue2:#202F5A;--edge:rgba(182,30,43,0.3);--highlight-start:#B61E2B;--highlight-end:#202F5A;--scrollbar-color:#B61E2B;}
body.th-trumpv1 .banner {background:url('https://i.postimg.cc/FKF84xyk/TRUMPV1.png') center/cover;}
body.th-trumpv2 {--blue:#B61E2B;--blue2:#202F5A;--edge:rgba(32,47,90,0.3);--highlight-start:#B61E2B;--highlight-end:#202F5A;--scrollbar-color:#202F5A;}
body.th-trumpv2 .banner {background:url('https://i.postimg.cc/3RdqyJbK/TRUMPV2.png') center/cover;}
</style>
</head>
<body>
<div id="esp-container"></div>
<div class="wrap pos-tl" id="wrap">
	<div class="menu-wrapper">
		<div class="custom-scrollbar" id="panel-scrollbar"><div class="custom-scrollbar-thumb"></div></div>
		<div class="menu-container" id="panel">
			<header class="banner" id="banner"><div id="banner-content"></div></header>
			<nav class="menu-tabs">
                <div class="tab-item active" id="tab-main">Main Menu</div>
            </nav>
			<main class="menu-content">
				<div class="view-container">
					<div class="view" id="view-list"><div class="list" id="list"></div></div>
					<div class="page" id="page-self"><div class="hdr"><div class="back" id="back-self"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Self</div></div><div class="content" id="self-content"></div></div>
					<div class="page" id="page-veh"><div class="hdr"><div class="back" id="back-veh"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Vehicle</div></div><div class="content" id="veh-content"></div></div>
					<div class="page" id="page-cmb"><div class="hdr"><div class="back" id="back-cmb"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Combat/Weapons</div></div><div class="content" id="cmb-content"></div></div>
					<div class="page" id="page-vis"><div class="hdr"><div class="back" id="back-vis"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Visual</div></div><div class="content" id="vis-content"></div></div>
					<div class="page" id="page-thm"><div class="hdr"><div class="back" id="back-thm"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Themes</div></div><div class="content" id="thm-content"></div></div>
					<div class="page" id="page-misc"><div class="hdr"><div class="back" id="back-misc"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Miscellaneous</div></div><div class="content" id="misc-content"></div></div>
                    <div class="page" id="page-dst"><div class="hdr"><div class="back" id="back-dst"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Destructive</div></div><div class="content" id="dst-content"></div></div>
                    <div class="page" id="page-trg"><div class="hdr"><div class="back" id="back-trg"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Triggers</div></div><div class="content" id="trg-content"></div></div>
					<div class="page" id="page-onllist"><div class="hdr"><div class="back" id="back-onllist"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800">Online Players</div></div><div class="content" id="onllist-content"></div></div>
					<div class="page" id="page-onlact"><div class="hdr"><div class="back" id="back-onlact"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M15 6l-6 6 6 6" stroke="currentColor" stroke-width="2" fill="none"/></svg></div><div style="font-weight:800" id="onlact-title">Troll Actions</div></div><div class="content" id="onlact-content"></div></div>
				</div>
				<div class="ov" id="bind-ov"><div class="modal"><div id="bind-title" style="font-weight:800;margin-bottom:6px">Bind Feature</div><div id="bind-desc">Press any key…</div><div class="kbd blink" id="bind-key">—</div><div style="margin-top:8px;color:var(--muted);font-size:12px">Backspace to cancel</div></div></div>
			</main>
			<footer class="menu-footer">
                <span id="foot-text">HuM1n.wtf - release</span>
                <span id="foot-counter">0/9</span>
            </footer>
		</div>
	</div>
</div>
<script>
// ================= SCRIPT =================
const CHEVRON = \`<div class="arrow-icon"></div>\`;
const STATUS_TOGGLE = (id) => \`<div class="status" id="status-\${id}"><div class="toggle-container"><input type="checkbox" id="toggle-\${id}" class="toggle-input"><label for="toggle-\${id}" class="toggle-label"></label></div></div>\`;

const pageContent = {
self: [{id:'god',label:'God Mode',type:'toggle'},{id:'sjump',label:'Super Jump',type:'toggle'},{id:'beast_jump',label:'Beast Jump',type:'action'},{id:'freecam',label:'Freecam',type:'toggle'},{id:'noclip',label:'Noclip',type:'toggle'},{id:'invisible',label:'Invisible',type:'toggle'},{id:'noragdoll',label:'No Ragdoll',type:'toggle'},{id:'nostun',label:'No Stun',type:'toggle'},{id:'infstam',label:'Infinite Stamina',type:'toggle'},{id:'fastrun_toggle',label:'Fast Run',type:'toggle'},{id:'superrun',label:'Super Run',type:'toggle'},{id:'anti_tp',label:'Anti-Teleport',type:'toggle'},{id:'anti_handcuff',label:'Anti-Handcuff',type:'toggle'},{id:'heal',label:'Heal',type:'action'},{id:'armor',label:'Armor',type:'action'},{id:'revive',label:'Revive',type:'action'},{id:'suicide',label:'Suicide',type:'action'},{id:'force_ragdoll',label:'Force Ragdoll',type:'action'},{id:'clear_task',label:'Clear Task',type:'action'},{id:'clear_vision',label:'Clear Vision',type:'action'},{id:'unfreeze',label:'Unfreeze Self',type:'action'},{id:'end_jail',label:'End Jail Time',type:'action'},{id:'randfit',label:'Randomize Outfit',type:'action'},{id:'pos',label:'Panel Position',type:'action'}],
veh: [{id:"repair",label:"Repair Vehicle",type:"action"},{id:"autofix",label:"Auto Fix",type:"toggle"},{id:"veh_god",label:"Vehicle God Mode",type:"toggle"},{id:"unlimited_fuel",label:"Unlimited Fuel",type:"toggle"},{id:"maxupgrade",label:"Max Upgrades",type:"action"},{id:"downgrade_vehicle",label:"Downgrade Vehicle",type:"action"},{id:"clean_vehicle",label:"Clean Vehicle",type:"action"},{id:"delete_vehicle",label:"Delete Vehicle",type:"action"},{id:"flip_vehicle",label:"Flip Vehicle",type:"action"},{id:"force_engine",label:"Force Engine On",type:"action"},{id:"unlock",label:"Unlock Doors",type:"action"},{id:"poptires",label:"Pop Tires",type:"action"},{id:"rainbow",label:"Rainbow Vehicle",type:'toggle'},{id:"carhop",label:"Car Hop",type:"action"},{id:"car_lift",label:"Car Lift",type:"action"},{id:"boost",label:"Vehicle Boost",type:'toggle'},{id:"drift",label:"Drift Mode",type:"toggle"},{id:"horn_boost",label:"Horn Boost",type:'toggle'},{id:"infinite_boost",label:"Infinite Boost",type:'toggle'},{id:"vehicle_weapons",label:"Vehicle Weapons",type:'toggle'},{id:"warp",label:"Warp into Vehicle",type:"action"},{id:"teleport_into_vehicle",label:"Teleport to Closest Vehicle",type:"action"}],
cmb: [{id:"giveall",label:"Give All Weapons",type:"action"},{id:"maxammo",label:"Max Ammo",type:"action"},{id:"unlimammo",label:"Unlimited Ammo",type:'toggle'},{id:"explosive_ammo",label:"Explosive Ammo",type:'toggle'},{id:"super_punch",label:"Super Punch",type:'toggle'},{id:"explosive_punch",label:"Explosive Punch",type:'toggle'}],
vis: [{id:"esp",label:"Player ESP",type:'toggle'},{id:"crosshair",label:"Enable Crosshair",type:'toggle'},{id:"fov",label:"Field of View",type:'slider',min:30,max:120,step:1,value:60},{id:"nametags",label:"Show Player Nametags",type:"toggle"}],
misc: [{id:"clear_area",label:"Clear Area",type:"action"},{id:"cycle_weather",label:"Cycle Weather",type:"action"},{id:"spawn_ped",label:"Spawn Ped",type:"action"},{id:"force_rob",label:"Force Rob Nearby Ped",type:"action"},{id:"panelpos",label:"Panel Position",type:"action"}],
dst: [{id:"lift_objects",label:"Lift Nearby Objects",type:"action"},{id:"meteors",label:"Meteor Shower",type:"action"},{id:"tpobjects",label:"Teleport Objects to Me",type:"action"},{id:"surprise_party",label:"Surprise Party (TP All)",type:"action"}],
trg: [{id:'item_spawner',label:'Item Spawner',type:'action'}, {id:'money_spawner',label:'Money Spawner',type:'action'}, {id:'common_exploits',label:'Common Exploits',type:'action'}, {id:'event_payloads',label:'Event Payloads',type:'action'}],
thm: [{id:"HuM1n",label:"HuM1n",type:"action"},{id:"Transparent Blur",label:"Transparent Blur",type:"action"},{id:"Blue",label:"Blue",type:"action"},{id:"Xmas",label:"Xmas",type:"action"},{id:"Halloween",label:"Halloween",type:"action"},{id:"Gangster",label:"Gangster",type:"action"},{id:"Neon",label:"Neon",type:"action"},{id:"Midnight",label:"Midnight",type:"action"},{id:"Ocean",label:"Ocean",type:"action"},{id:"Sunset",label:"Sunset",type:"action"},{id:"Matrix",label:"Matrix",type:"action"},{id:"Disconnect",label:"Disconnect",type:"action"},{id:"Gamerware",label:"Gamerware",type:"action"},{id:"LEAN SIPPA",label:"LEAN SIPPA",type:"action"},{id:"JAY PROMETHAZINE",label:"JAY PROMETHAZINE",type:"action"},{id:"Trump V1",label:"Trump V1",type:"action"},{id:"Trump V2",label:"Trump V2",type:"action"}],
onlact: [{id:"goto_player",label:"Go To Player",type:"action"},{id:"tptoplayer",label:"Teleport Player To Me",type:"action"},{id:"spec",label:"Spectate Player",type:"action"},{id:"kill",label:"Kill Player",type:"action"},{id:"explode_player",label:"Explode Player",type:"action"},{id:"taze",label:"Taze Player",type:"action"},{id:"ragdoll",label:"Force Fall",type:"action"},{id:"cage",label:"Cage Player",type:"action"},{id:"crush",label:"Crush (Drop Car)",type:"action"},{id:"attachcone",label:"Attach Cone",type:"action"},{id:"stealoutfit",label:"Steal Outfit",type:"action"},{id:"force_blame",label:"Force Blame Anim",type:"action"},{id:"force_twerk",label:"Force Twerk Anim",type:"action"},{id:"force_sit",label:"Force Sit Anim",type:"action"},{id:"fake_escort",label:"Fake Escort",type:"action"},{id:"detach",label:"Detach From Player",type:"action"}]
};

function buildItem(item) {
    const d = document.createElement('div');
    d.className = 'item';
    d.dataset.id = item.id;
    let rightEl = '';
    if (item.type === 'action') {
        rightEl = CHEVRON;
    } else if (item.type === 'toggle') {
        rightEl = STATUS_TOGGLE(item.id);
    } else if (item.type === 'slider') {
        rightEl = \`<div class="opt"><span></span><input id="s-\${item.id}" type="range" min="\${item.min}" max="\${item.max}" step="\${item.step}" value="\${item.value}"/><span class="val" id="v-\${item.id}">\${item.value}</span></div>\`;
    }
    d.innerHTML = \`<span>\${item.label}</span>\${rightEl}\`;
    return d;
}

function populatePages() {
    for (const pageKey in pageContent) {
        const contentEl = document.getElementById(\`\${pageKey}-content\`);
        if (contentEl) {
            contentEl.innerHTML = '';
            pageContent[pageKey].forEach(item => {
                contentEl.appendChild(buildItem(item));
            });
        }
    }
    const fovVal = document.getElementById('v-fov');
    if (fovVal) fovVal.textContent = parseFloat(document.getElementById('s-fov').value).toFixed(0);
}

populatePages();

const P = {};
Array.from(document.querySelectorAll('.page')).forEach(p => P[p.id.replace('page-', '')] = p);
P['view-list'] = document.getElementById('view-list');
const vList = document.getElementById('view-list');

function open(which) {
    vList.style.display = 'none';
    for (const key in P) {
        if (P[key]) P[key].classList.remove('show');
    }
    if (P[which]) {
        P[which].classList.add('show');
        updateScrollbar(P[which].querySelector('.content') || vList);
    }
}

function hideAll() {
    for (const k in P) {
        if (P[k]) P[k].classList.remove('show');
    }
    vList.style.display = 'block';
    updateScrollbar(vList);
}

const names = ["Self", "Online", "Combat/Weapons", "Vehicle", "Miscellaneous", "Triggers", "Destructive", "Visual", "Themes"];
const list = document.getElementById('list');
list.innerHTML = '';
names.forEach((t, i) => {
    const r = document.createElement('div');
    r.className = 'row' + (i === 0 ? ' sel' : '');
    r.innerHTML = '<span>' + t + '</span><div class="arrow-icon"></div>';
    list.appendChild(r);
});

const rows = [...document.querySelectorAll('.row')];
const footCounter = document.getElementById('foot-counter');

function selIntoView(listEl, idx) {
    if (!listEl) return;
    const items = [...listEl.querySelectorAll('.item,.row')];
    if (!items[idx]) return;
    items[idx].scrollIntoView({ block: 'nearest', behavior: 'smooth' });
}

window.HuM1nSetInput = (k, c) => {};
window.HuM1nSelect = (n) => { if (window.HuM1nLastListIdx !== n) { n = Math.max(0, Math.min(rows.length - 1, n | 0)); setListSel(n); window.HuM1nLastListIdx = n; } };
function setListSel(i) { rows.forEach((r, n) => r.classList.toggle('sel', n === i)); selIntoView(vList, i); if (footCounter) footCounter.textContent = \`\${i + 1}/\${rows.length}\`; }
window.HuM1nOpenTab = (t) => { if(t==="Self")open('self');else if(t==="Vehicle")open('veh');else if(t==="Combat/Weapons")open('cmb');else if(t==="Visual")open('vis');else if(t==="Themes")open('thm');else if(t==="Miscellaneous")open('misc');else if(t==="Destructive")open('dst');else if(t==="Triggers")open('trg');else if(t==="Online")open('onllist'); };
window.HuM1nClose = () => { hideAll(); };
window.HuM1nSel = {};
for (const pageKey in P) { window.HuM1nSel[pageKey] = (n) => { const c = P[pageKey].querySelector('.content') || vList; if (c) { const items = [...c.querySelectorAll('.item,.row')]; items.forEach((e, i) => e.classList.toggle('sel', i === n)); selIntoView(c, n); if (footCounter && items.length > 0) footCounter.textContent = \`\${n + 1}/\${items.length}\`; } } }

Object.keys(P).forEach(pgKey => {
    const backButton = document.getElementById('back-' + pgKey);
    if (backButton) {
        // Clicks are disabled for stability, handled by Lua's backspace key.
    }
});

window.HuM1nRenderPlayers=(arr)=>{const root=document.getElementById('onllist-content');root.innerHTML='';arr.forEach((p,i)=>{const d=document.createElement('div');d.className='item';d.dataset.id=p.sid;d.dataset.idx=i;d.innerHTML=\`<span>\${p.name} <span style="opacity:.7">ID:\${p.id}</span></span><div class="arrow-icon"></div>\`;root.appendChild(d);});updateScrollbar(root);};
window.HuM1nOpenActions = (title) => { document.getElementById('onlact-title').textContent = 'Troll Actions — ' + title; open('onlact'); };
window.HuM1nSetSwitch = (id, isOn) => { 
    const el = document.getElementById('status-' + id);
    if (!el) return;
    el.classList.toggle('on', isOn);
    const input = el.querySelector('.toggle-input');
    if (input) input.checked = isOn;
};

const body = document.body, bannerContent = document.getElementById('banner-content'), footText = document.getElementById('foot-text');
const tcls = ["HuM1n", "transparentblur", "blue", "xmas", "halloween", "gangster", "neon", "midnight", "ocean", "sunset", "matrix", "disconnect", "gamerware", "leansippa", "jaypromethazine", "trumpv1", "trumpv2"].map(n => 'th-' + n);
function swap(l, cls) { l.forEach(c => body.classList.remove(c)); if (cls) body.classList.add(cls); }

const bannerFont = "'Orbitron', sans-serif";
const HuM1nLogo = (style) => \`<div class="HuM1n-logo" style="font-family:\${bannerFont}; \${style || ''}">HuM1n</div>\`;
window.HuM1nApplyTheme = (name) => {
    const themeMap = { 
		"HuM1n": { class: "HuM1n", logo: HuM1nLogo("text-shadow: 0 0 8px #fff, 0 0 12px var(--blue);") },
		"Transparent Blur": { class: "transparentblur", logo: HuM1nLogo("color: #eee; text-shadow: 0 0 5px #000; font-weight: 700; animation: none;") },
		"Blue": { class: "blue", logo: HuM1nLogo("animation:HuM1n-glow 3s ease-in-out infinite;text-shadow:0 0 5px #fff, 0 0 10px var(--blue), 0 0 20px var(--blue2);") },
		"Xmas": { class: "xmas", logo: HuM1nLogo("color: #fff; text-shadow: 0 0 8px #d61339; animation: none;") },
		"Halloween": { class: "halloween", logo: HuM1nLogo("color: #ff7a1a; text-shadow: 0 0 8px #000; animation: none;") },
		"Gangster": { class: "gangster", logo: HuM1nLogo("color: #f2c34e; text-shadow: 1px 1px 5px #000; animation: none;") },
		"Neon": { class: "neon", logo: HuM1nLogo("text-shadow: 0 0 5px #fff, 0 0 10px #00e5ff, 0 0 20px #ff00d4;") },
		"Midnight": { class: "midnight", logo: HuM1nLogo("letter-spacing: 4px; color: #8aa4ff; text-shadow: 0 0 10px #000; animation: none;") },
		"Ocean": { class: "ocean", logo: HuM1nLogo("color: #fff; text-shadow: 0 0 8px #1a2a35; animation: none;") },
		"Sunset": { class: "sunset", logo: HuM1nLogo("color: #fff; text-shadow: 0 0 8px #a13333; animation: none;") },
		"Matrix": { class: "matrix", logo: HuM1nLogo("color: #39ff14; text-shadow: 0 0 10px #22aa11; animation: none;") },
		"Disconnect": { class: "disconnect", logo: HuM1nLogo("color: #b16cff; text-shadow: 0 0 10px #1a1030; animation: none;") },
		"Gamerware": { class: "gamerware", logo: HuM1nLogo("color: #fff; text-shadow: 2px 2px 0 #c018c0, -2px -2px 0 #8b1297; animation: none;") },
		"LEAN SIPPA": { class: "leansippa", logo: HuM1nLogo("color: #fff; text-shadow: 0 0 10px #000, 0 0 20px #9b59b6;") },
		"JAY PROMETHAZINE": { class: "jaypromethazine", logo: HuM1nLogo("position:relative; z-index:1; color: #fff; text-shadow: 0 0 10px #000, 0 0 20px #bf00ff;") },
		"Trump V1": { class: "trumpv1", logo: HuM1nLogo("font-weight: bold; color: #fff; text-shadow: 0 0 3px #202F5A, 0 0 8px #202F5A, 0 0 12px #B61E2B; animation: none;") },
		"Trump V2": { class: "trumpv2", logo: HuM1nLogo("letter-spacing: 3px; color: #fff; text-shadow: 1px 1px 2px #000, -1px -1px 2px #000; animation: none;") }
    };

    const themeData = themeMap[name] || themeMap["Blue"];
    swap(tcls, 'th-' + themeData.class);
    bannerContent.innerHTML = themeData.logo;
    footText.textContent = 'HuM1n.wtf - release';
};

window.HuM1nUpdateEsp = (players, active) => {
    const container = document.getElementById('esp-container');
    if (!container) return;
    container.innerHTML = '';
    if (!active) return;
    
    for (const p of players) {
        const box = document.createElement('div');
        box.className = 'esp-box';
        box.style.left = \`\${p.x - p.w / 2}px\`;
        box.style.top = \`\${p.y}px\`;
        box.style.width = \`\${p.w}px\`;
        box.style.height = \`\${p.h}px\`;

        const healthPercentage = (p.health / p.max_health) * 100;

        box.innerHTML = \`
            <div class="esp-info-container">
                <div class="esp-info">\${p.name} [\${p.dist}m]</div>
                <div class="esp-bar">
                    <div class="esp-health-bar" style="width: \${healthPercentage}%;"></div>
                </div>
                \${p.armor > 0 ? \`
                <div class="esp-bar">
                    <div class="esp-armor-bar" style="width: \${p.armor}%;"></div>
                </div>
                \` : ''}
            </div>
        \`;
        container.appendChild(box);
    }
};

const scrollbar = document.getElementById('panel-scrollbar');
const thumb = scrollbar.querySelector('.custom-scrollbar-thumb');
let currentScroller = vList;
function updateScrollbar(contentElement) { currentScroller = contentElement || currentScroller; if (!currentScroller) return; const scrollableHeight = currentScroller.scrollHeight - currentScroller.clientHeight; if (scrollableHeight <= 0) { scrollbar.style.display = 'none'; return; } scrollbar.style.display = 'block'; const scrollbarHeight = scrollbar.clientHeight; const thumbHeight = Math.max(20, (currentScroller.clientHeight / currentScroller.scrollHeight) * scrollbarHeight); const thumbTop = (currentScroller.scrollTop / scrollableHeight) * (scrollbarHeight - thumbHeight); thumb.style.height = thumbHeight + 'px'; thumb.style.transform = 'translateY(' + thumbTop + 'px)'; }
[vList, ...document.querySelectorAll('.content')].forEach(el => { if (el) { el.onscroll = () => updateScrollbar(el); new MutationObserver(() => updateScrollbar(el)).observe(el, { childList: true, subtree: true, attributes: true, characterData: true }); new ResizeObserver(() => updateScrollbar(el)).observe(el); } });
updateScrollbar(vList);
</script>
</body></html>`); document.close();
}catch(e){console.error(e)}})();]===]

-- ========================= HTML (SNOW) =========================
local HTML_SNOW = [===[(function(){try{
document.open(); document.write('<!doctype html><meta charset="utf-8">\
<style>html,body{margin:0;height:100%;background:transparent}canvas{position:fixed;inset:0;pointer-events:none}</style>\
<canvas id="s"></canvas><script>\
var c=document.getElementById("s"),x=c.getContext("2d"),W=0,H=0;function R(){W=c.width=innerWidth;H=c.height=innerHeight}R();addEventListener("resize",R,{passive:true});\
var F=[],N=160;for(var i=0;i<N;i++)F.push({x:Math.random()*W,y:Math.random()*H,r:0.9+Math.random()*2.4,vy:0.35+Math.random()*1.0,vx:-0.3+Math.random()*0.6,d:Math.random()*6.28});\
(function t(){x.clearRect(0,0,W,H);for(var j=0;j<F.length;j++){var f=F[j];f.d+=0.003+(f.r*0.0006);f.x+=f.vx+Math.cos(f.d)*0.12;f.y+=f.vy+(f.r*0.02);if(f.x<-10)f.x=W+10;if(f.x>W+10)f.x=-10;if(f.y>H+10){f.y=-10;f.x=Math.random()*W;}x.beginPath();x.arc(f.x,f.y,f.r,0,Math.PI*2);x.fillStyle="rgba(255,255,255,.9)";x.fill();}requestAnimationFrame(t);} )();\
<\/script>'); document.close();
}catch(e){console.error(e)}})();]===]

-- ========================= Helpers / JS bridge =========================
local function JS(code) if menuDui then MachoExecuteDuiScript(menuDui, code) end end
local function js_io(k,c) JS(("window.HuM1nSetInput(%s,%s);"):format(k and "true" or "false", c and "true" or "false")) end
local function js_list_sel(n) JS(("window.HuM1nSelect(%d);"):format(n)) end
local function js_sel(pg,n) JS(("window.HuM1nSel['%s'](%d);"):format(pg,n)) end
local function js_open(tab) JS(("window.HuM1nOpenTab(%q);"):format(tab)) end
local function js_close() JS("window.HuM1nClose();") end
local function js_set_switch(id, on) JS(("window.HuM1nSetSwitch && window.HuM1nSetSwitch('%s', %s);"):format(id, on and "true" or "false")) end
local function js_set_pos(mode) JS(("document.getElementById('wrap').classList.remove('pos-center','pos-tl','pos-br');document.getElementById('wrap').classList.add(%q);"):format(mode==1 and "pos-center" or mode==2 and "pos-tl" or "pos-br")) end
local function js_bind_open(lbl,cur) JS(("document.getElementById('bind-ov').style.display='flex';document.getElementById('bind-title').textContent=%q;document.getElementById('bind-key').textContent=%q;"):format("Bind: "..lbl, cur or "—")) end
local function js_bind_close() JS("document.getElementById('bind-ov').style.display='none';") end
local function js_theme(nm) JS(("window.HuM1nApplyTheme(%q);"):format(nm)) end
local function js_render_players(json) JS(("window.HuM1nRenderPlayers(%s);"):format(json)) end
local function js_open_actions(name) JS(("window.HuM1nOpenActions(%q);"):format(name)) end

local function add_notification(text)
    table.insert(notifications, { text = text, creation = GetGameTimer() })
end

local function draw_notifications()
    if #notifications == 0 then return end
    local x = 0.98 * GetSafeZoneSize()
    local y = 0.75
    local i = #notifications
    while i >= 1 do
        local notif = notifications[i]
        if GetGameTimer() - notif.creation > 5000 then
            table.remove(notifications, i)
        else
            SetTextFont(4); SetTextScale(0.35, 0.35); SetTextColour(255, 255, 255, 255); SetTextWrap(0.0, x); SetTextRightJustify(true); SetTextEntry("STRING"); AddTextComponentSubstringPlayerName(notif.text); DrawText(0, y)
            y = y - 0.04
        end
        i = i - 1
    end
end

local function refresh_pills()
for _,id in ipairs({
"god","sjump","freecam","noclip","invisible","noragdoll","nostun","infstam",
"superrun","boost","drift","unlimammo","nametags","autofix","rainbow",
"unlimited_fuel", "esp", "crosshair", "fastrun_toggle", "veh_god", "horn_boost",
"explosive_ammo", "super_punch", "explosive_punch", "anti_tp", "anti_handcuff", "vehicle_weapons"
}) do
    if STATE[id] ~= nil then
        js_set_switch(id, STATE[id])
    end
end
end

-- ========================= Gameplay helpers =========================
local function safe_ped(p) return p and p ~= 0 and DoesEntityExist(p) end
local function me() return PlayerPedId() end
local function requestCtrl(ent,ms)
if ent==0 or not DoesEntityExist(ent) then return false end
local untilT = GetGameTimer() + (ms or 900)
while not NetworkHasControlOfEntity(ent) and GetGameTimer()<untilT do NetworkRequestControlOfEntity(ent); Wait(0) end
return NetworkHasControlOfEntity(ent)
end

local function do_heal()
local myPed = me()
if safe_ped(myPed) then
SetEntityHealth(myPed, GetEntityMaxHealth(myPed))
ClearPedBloodDamage(myPed)
end
end
local function do_armor()
local myPed = me()
if safe_ped(myPed) then
SetPedArmour(myPed, 100)
end
end

local function do_revive()
    local injected_code = [[
        local function AcjU5NQzKw()
            if GetResourceState('prp-injuries') == 'started' then
                TriggerEvent('prp-injuries:hospitalBedHeal', false)
                return
            end
            if GetResourceState('es_extended') == 'started' then
                TriggerEvent("esx_ambulancejob:revive")
                return
            end
            if GetResourceState('qb-core') == 'started' then
                TriggerEvent("hospital:client:Revive")
                return
            end
            if GetResourceState('wasabi_ambulance') == 'started' then
                TriggerEvent("wasabi_ambulance:revive")
                return
            end
            if GetResourceState('ak47_ambulancejob') == 'started' then
                TriggerEvent("ak47_ambulancejob:revive")
                return
            end
            local NcVbXzQwErTyUiO = GetEntityHeading(PlayerPedId())
            local BvCxZlKjHgFdSaP = GetEntityCoords(PlayerPedId())
            NetworkResurrectLocalPlayer(BvCxZlKjHgFdSaP.x, BvCxZlKjHgFdSaP.y, BvCxZlKjHgFdSaP.z, NcVbXzQwErTyUiO, false, false)
        end
        AcjU5NQzKw()
    ]]
    local res = "any"
    if GetResourceState("ox_inventory") == "started" then res = "ox_inventory"
    elseif GetResourceState("es_extended") == "started" then res = "es_extended"
    elseif GetResourceState("qb-core") == "started" then res = "qb-core" end
    MachoInjectResource(res, injected_code)
end
local function do_suicide()
    MachoInjectResource("any", [[SetEntityHealth(PlayerPedId(), 0)]])
end
local function do_force_ragdoll()
    MachoInjectResource("any", [[SetPedToRagdoll(PlayerPedId(), 3000, 3000, 0, false, false, false)]])
end

local function do_clear_task()
ClearPedTasksImmediately(me())
end
local function do_clear_vision()
ClearTimecycleModifier()
ClearExtraTimecycleModifier()
end

local function unfreeze_self()
FreezeEntityPosition(me(), false)
end

local function do_end_jail()
    local code = [[
        if GetResourceState("tk_jail") == "started" then
            StopResource("tk_jail")
        end
    ]]
    MachoInjectResource("any", code)
    add_notification("Attempted to stop jail resource (tk_jail).")
end

local function do_randfit()
local ped = me()
local function getRandomDrawable(component, exclude)
local total = GetNumberOfPedDrawableVariations(ped, component)
if total <= 1 then return 0 end
local choice = exclude
while choice == exclude do
choice = math.random(0, total - 1)
end
return choice
end
SetPedComponentVariation(ped, 11, getRandomDrawable(11, 15), 0, 2)
SetPedComponentVariation(ped, 6, getRandomDrawable(6, 15), 0, 2)
SetPedComponentVariation(ped, 8, 15, 0, 2)
SetPedComponentVariation(ped, 3, 0, 0, 2)
SetPedComponentVariation(ped, 4, getRandomDrawable(4), 0, 2)
local face, skin = math.random(0, 45), math.random(0, 45)
SetPedHeadBlendData(ped, face, skin, 0, face, skin, 0, 1.0, 1.0, 0.0, false)
local hairMax = GetNumberOfPedDrawableVariations(ped, 2)
local hair = hairMax > 1 and math.random(0, hairMax - 1) or 0
SetPedComponentVariation(ped, 2, hair, 0, 2)
SetPedHairColor(ped, 0, 0)
local browsMax = GetNumHeadOverlayValues(2)
SetPedHeadOverlay(ped, 2, browsMax > 1 and math.random(0, browsMax - 1) or 0, 1.0)
SetPedHeadOverlayColor(ped, 2, 1, 0, 0)
ClearPedProp(ped, 0)
ClearPedProp(ped, 1)
end

local function do_beast_jump()
    CreateThread(function()
        local ped = me()
        local animDict = "missheistfbi3b_ig8_2"
        local animName = "fall_over_back_on_floor"
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Wait(0)
        end
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, 500, 0, 0, false, false, false)
        Wait(250)
        SetEntityVelocity(ped, 0.0, 0.0, 30.0)
    end)
end

local function loop_god()
CreateThread(function()
while STATE.god do
local p = me()
if p and DoesEntityExist(p) then
SetEntityHealth(p, GetEntityMaxHealth(p))
SetPedArmour(p, 100)
ClearPedBloodDamage(p)
end
Wait(0)
end
end)
end

local function loop_sjump()
CreateThread(function()
while STATE.sjump do
SetSuperJumpThisFrame(PlayerId())
Wait(0)
end
end)
end

local function loop_invisible()
CreateThread(function()
    local ply = PlayerPedId()
    local entity = SetEntityVisible
    entity(ply, false, false)
    while STATE.invisible do
        Wait(500)
    end
    if DoesEntityExist(ply) then
        entity(ply, true, false)
    end
end)
end

local function loop_noragdoll()
CreateThread(function()
while STATE.noragdoll do
local p = me()
if safe_ped(p) then
SetPedConfigFlag(p, 32, true)
end
Wait(0)
end
local p=me()
if safe_ped(p) then
SetPedConfigFlag(p, 32, false)
end
end)
end

local function loop_nostun()
CreateThread(function()
while STATE.nostun do
local p = me()
if safe_ped(p) then
SetPedConfigFlag(p, 17, true)
end
Wait(0)
end
local p=me()
if safe_ped(p) then
SetPedConfigFlag(p, 17, false)
end
end)
end

local function loop_infstam()
CreateThread(function()
while STATE.infstam do
StatSetInt(GetHashKey("MP" .. PlayerId() .. "_STAMINA"), 100, true)
Wait(5000)
end
end)
end

local function loop_fastrun()
CreateThread(function()
while STATE.fastrun_toggle do
SetRunSprintMultiplierForPlayer(PlayerId(), 1.5)
Wait(0)
end
SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
end)
end

local function loop_superrun()
CreateThread(function()
while STATE.superrun do
local p = me()
if IsPedOnFoot(p) then
SetPedMoveRateOverride(p, 1.15)
end
Wait(0)
end
end)
end

local function loop_anti_teleport()
    CreateThread(function()
        local lastPos = GetEntityCoords(me())
        while STATE.anti_tp do
            Wait(50) -- Check less frequently to avoid performance issues
            local myPed = me()
            local currentPos = GetEntityCoords(myPed)

            if #(currentPos - lastPos) > 25.0 and not IsPedInAnyVehicle(myPed, false) and not IsPedFalling(myPed) and not IsPedJumping(myPed) then
                add_notification("Teleport detected! Reverting position.")
                SetEntityCoords(myPed, lastPos.x, lastPos.y, lastPos.z, false, false, false, true)
            else
                lastPos = currentPos
            end
        end
    end)
end

local function loop_anti_handcuff()
    CreateThread(function()
        while STATE.anti_handcuff do
            Wait(0)
            local myPed = me()
            if IsPedBeingCuffed(myPed) or IsEntityPlayingAnim(myPed, "mp_arresting", "idle", 3) then
               ClearPedTasksImmediately(myPed)
            end
        end
    end)
end

local function do_noclip_on()
local res = "any"
if GetResourceState("monitor") == "started" then res = "monitor"
elseif GetResourceState("oxmysql") == "started" then res = "oxmysql" end

MachoInjectResource(res, [[
if NpYgTbUcXsRoVm == nil then NpYgTbUcXsRoVm = false end
NpYgTbUcXsRoVm = true

local function KUQpH7owdz()
local RvBcNxMzKgUiLo=PlayerPedId;local EkLpOiUhYtGrFe=GetVehiclePedIsIn;local CtVbXnMzQaWsEd=GetEntityCoords;local DrTgYhUjIkOlPm=GetEntityHeading;local QiWzExRdCtVbNm=GetGameplayCamRelativeHeading;local AoSdFgHjKlZxCv=GetGameplayCamRelativePitch;local JkLzXcVbNmAsDf=IsDisabledControlJustPressed;local TyUiOpAsDfGhJk=IsDisabledControlPressed;local WqErTyUiOpAsDf=SetEntityCoordsNoOffset;local PlMnBvCxZaSdFg=SetEntityHeading;local HnJmKlPoIuYtRe=CreateThread;local ZxCVbNmQwErTyU=SetEntityCollision;local YtReWqAzXsEdCv=true
HnJmKlPoIuYtRe(function()
while NpYgTbUcXsRoVm and not Unloaded do Wait(0)
local p_main=RvBcNxMzKgUiLo();local v_main=EkLpOiUhYtGrFe(p_main,false);local ent_main=(v_main~=0 and v_main~=nil) and v_main or p_main
if YtReWqAzXsEdCv then
local speed=2.0;ZxCVbNmQwErTyU(ent_main,false,false)
local pos=CtVbXnMzQaWsEd(ent_main,true);local head=QiWzExRdCtVbNm()+DrTgYhUjIkOlPm(ent_main);local pitch=AoSdFgHjKlZxCv()
local dx=-math.sin(math.rad(head));local dy=math.cos(math.rad(head));local dz=math.sin(math.rad(pitch));local len=math.sqrt(dx*dx+dy*dy+dz*dz)
if len~=0 then dx,dy,dz=dx/len,dy/len,dz / len end
if TyUiOpAsDfGhJk(0,21) then speed=speed+2.5 end;if TyUiOpAsDfGhJk(0,19) then speed=0.25 end
if TyUiOpAsDfGhJk(0,32) then pos=pos+vector3(dx,dy,dz)*speed end;if TyUiOpAsDfGhJk(0,269) then pos=pos-vector3(dx,dy,dz)*speed end;if TyUiOpAsDfGhJk(0,34) then pos=pos+vector3(-dy,dx,0.0)*speed end;if TyUiOpAsDfGhJk(0,9) then pos=pos+vector3(dy,-dx,0.0)*speed end;if TyUiOpAsDfGhJk(0,22) then pos=pos+vector3(0.0,0.0,speed) end;if TyUiOpAsDfGhJk(0,36) then pos=pos-vector3(0.0,0.0,speed) end
WqErTyUiOpAsDf(ent_main,pos.x,pos.y,pos.z,true,true,true);PlMnBvCxZaSdFg(ent_main,head)
else ZxCVbNmQwErTyU(ent_main,true,true) end end
local p_final=RvBcNxMzKgUiLo();if p_final then local v_final=EkLpOiUhYtGrFe(p_final,false);local ent_final=(v_final~=0 and v_final~=nil) and v_final or p_final;if DoesEntityExist(ent_final) then ZxCVbNmQwErTyU(ent_final,true,true) end end
YtReWqAzXsEdCv=false end) end
KUQpH7owdz()
]])
end

local function do_noclip_off()
local res = "any"
if GetResourceState("monitor") == "started" then res = "monitor"
elseif GetResourceState("oxmysql") == "started" then res = "oxmysql" end
MachoInjectResource(res, [[ NpYgTbUcXsRoVm = false ]])
end

local function loop_freecam()
CreateThread(function()
local playerPed=PlayerPedId();local CreateCam,SetCamActive,RenderScriptCams,DestroyCam,DoesCamExist=CreateCamWithParams,SetCamActive,RenderScriptCams,DestroyCam,DoesEntityExist;local GetCamCoord,GetCamRot,SetCamCoord,SetCamRot=GetCamCoord,GetCamRot,SetCamCoord,SetCamRot;local GetFinalCamCoord,GetFinalCamRot=GetFinalRenderedCamCoord,GetFinalRenderedCamRot;local IsControlPressed,IsControlJustPressed,GetControlNormal=IsDisabledControlPressed,IsDisabledControlJustPressed,GetControlNormal;local StartRaycast,GetRaycastResult=StartExpensiveSynchronousShapeTestLosProbe,GetShapeTestResult;local targetCoords,targetEntity=nil,nil
local function draw_text(text,x,y,scale,center,font,isSelected,r,g,b,a,glow)
SetTextScale(0.0,scale);SetTextFont(font);SetTextProportional(true);if glow then SetTextColour(52,137,235,a or 255)else SetTextColour(r or 255,g or 255,b or 255,a or 255)end;if center then SetTextCentre(true)end;if isSelected then SetTextDropShadow(2,0,0,0,255)else SetTextDropShadow(0,0,0,0,0)end;BeginTextCommandDisplayText("STRING");AddTextComponentSubstringPlayerName(text);EndTextCommandDisplayText(x,y)
end
local function get_vehicle_name(modelName)
local hash=GetHashKey(modelName);local label=GetDisplayNameFromVehicleModel(hash);if not label then return modelName end;local text=GetLabelText(label);if not text or text=="NULL"then return modelName end;return text
end
local function draw_ui()
DrawRect(0.5,0.5,0.002,0.003,255,255,255,200);local total,baseY,lineHeight,baseScale,font=#freecam.features,0.79,0.031,0.30,4
for i,featureName in ipairs(freecam.features)do
local offset=(i-(total/2+0.5))*lineHeight;local y=baseY+offset;local isSelected=(i==freecam.currentFeature);local scale=isSelected and(baseScale+0.04)or baseScale;local text=featureName
if isSelected then if featureName=="Car Shooter"or featureName=="Spawn Car"then local spawncode=freecam.allowedVehicles[freecam.selectedVehicleIndex]or"n/a";text=("%s: ~w~%s"):format(featureName,get_vehicle_name(spawncode))end end
draw_text(text,0.5,y,scale,true,font,isSelected,255,255,255,255,isSelected)end
end
local initialPos,initialRot=GetFinalCamCoord(),GetFinalCamRot(2);freecam.cam=CreateCam("DEFAULT_SCRIPTED_CAMERA",initialPos.x,initialPos.y,initialPos.z,initialRot.x,initialRot.y,initialRot.z,50.0,true,2);SetCamActive(freecam.cam,true);RenderScriptCams(true,false,0,false,true)
while STATE.freecam do Wait(0);draw_ui();TaskStandStill(playerPed,10)
if DPressed(WHEEL_UP)then freecam.currentFeature=(freecam.currentFeature-2+#freecam.features)% #freecam.features+1 elseif DPressed(WHEEL_DOWN)then freecam.currentFeature=(freecam.currentFeature % #freecam.features)+1 end
local pos,rotRaw=GetCamCoord(freecam.cam),GetCamRot(freecam.cam,2);local rot={x=rotRaw.x,y=rotRaw.y,z=rotRaw.z};local dir=vector3(-math.sin(math.rad(rot.z))*math.cos(math.rad(rot.x)),math.cos(math.rad(rot.z))*math.cos(math.rad(rot.x)),math.sin(math.rad(rot.x)));local right=vector3(dir.y,-dir.x,0);local speed=1.0
if IsControlPressed(0,21)then speed=9.0 end;if IsControlPressed(0,19)then speed=0.1 end;if IsControlPressed(0,32)then pos=pos+dir*speed end;if IsControlPressed(0,33)then pos=pos-dir*speed end;if IsControlPressed(0,34)then pos=pos-right*speed end;if IsControlPressed(0,35)then pos=pos+right*speed end;if IsControlPressed(0,22)then pos=pos+vector3(0,0,1.0)*speed end;if IsControlPressed(0,36)then pos=pos-vector3(0,0,1.0)*speed end
local h,v=GetControlNormal(0,1)*7.5,GetControlNormal(0,2)*7.5;rot.x=math.max(-89.0,math.min(89.0,rot.x-v));rot.z=rot.z-h;SetCamCoord(freecam.cam,pos.x,pos.y,pos.z);SetCamRot(freecam.cam,rot.x,rot.y,rot.z,2)
local rayHandle=StartRaycast(pos.x,pos.y,pos.z,pos.x+dir.x*500.0,pos.y+dir.y*500.0,pos.z+dir.z*500.0,-1,playerPed,7);local _,hit,hitCoords,_,entityHit=GetRaycastResult(rayHandle);targetCoords,targetEntity=hit and hitCoords or nil,hit and entityHit or nil
local currentFeatureName=freecam.features[freecam.currentFeature]
if IsControlJustPressed(0,24)and targetCoords then if currentFeatureName=="Teleportation"then local p=PlayerPedId();SetEntityCoords(p,targetCoords.x,targetCoords.y,targetCoords.z,false,false,false,true)elseif currentFeatureName=="Delete Entity"and targetEntity and DoesEntityExist(targetEntity)then SetEntityAsMissionEntity(targetEntity,true,true);DeleteEntity(targetEntity)elseif currentFeatureName=="Explode"then AddExplosion(targetCoords.x,targetCoords.y,targetCoords.z,6,10.0,true,false,0.0)elseif currentFeatureName=="Spikestrip Spawner"then local model=GetHashKey("p_ld_stinger_s");RequestModel(model);while not HasModelLoaded(model)do Wait(0)end;local _,z=GetGroundZFor_3dCoord(targetCoords.x,targetCoords.y,targetCoords.z+10.0,false);CreateObject(model,targetCoords.x,targetCoords.y,z+0.2,true,true,false);SetModelAsNoLongerNeeded(model)elseif currentFeatureName=="Fire Spawner"then StartNetworkedParticleFxNonLoopedAtCoord("ent_sht_petrol_fire",targetCoords.x,targetCoords.y,targetCoords.z,0.0,0.0,0.0,9.5,false,false,false)elseif currentFeatureName=="Car Shooter"or currentFeatureName=="Spawn Car"then local model=freecam.allowedVehicles[freecam.selectedVehicleIndex];local spawnPos=targetCoords or(pos+dir*10.0);local veh=spawn_vehicle(model,spawnPos,rot.z);if currentFeatureName=="Car Shooter"and veh then local force=dir*150.0;ApplyForceToEntityCenterOfMass(veh,1,force.x,force.y,force.z,true,false,true,false)end elseif currentFeatureName=="Spawn Angry Ped"then local model=GetHashKey("mp_m_freemode_01");RequestModel(model);while not HasModelLoaded(model)do Wait(0)end;local _,z=GetGroundZFor_3dCoord(targetCoords.x,targetCoords.y,targetCoords.z+1.0,false);local ped=CreatePed(28,model,targetCoords.x,targetCoords.y,z,rot.z,true,false);GiveWeaponToPed(ped,GetHashKey("WEAPON_BAT"),1,false,true);TaskCombatPed(ped,playerPed,0,16);SetModelAsNoLongerNeeded(model)end elseif(currentFeatureName=="Car Shooter"or currentFeatureName=="Spawn Car")then if IsControlJustPressed(0,44)then freecam.selectedVehicleIndex=(freecam.selectedVehicleIndex-2+#freecam.allowedVehicles)%#freecam.allowedVehicles+1 elseif IsControlJustPressed(0,45)then freecam.selectedVehicleIndex=(freecam.selectedVehicleIndex % #freecam.allowedVehicles)+1 end end end
RenderScriptCams(false,false,0,true,true);if DoesCamExist(freecam.cam)then DestroyCam(freecam.cam,false)end;freecam.cam=nil;ClearFocus()end)
end

local function loop_html_esp()
    CreateThread(function()
        local function toJson(tbl)
            local s = "{"
            for k, v in pairs(tbl) do
                if type(v) == "table" then
                    s = s .. string.format("\"%s\":%s,", k, toJson(v))
                elseif type(v) == "string" then
                    s = s .. string.format("\"%s\":\"%s\",", k, v:gsub("\"", "\\\""))
                else
                    s = s .. string.format("\"%s\":%s,", k, tostring(v))
                end
            end
            if s:sub(-1) == "," then s = s:sub(1, -2) end
            return s .. "}"
        end

        while STATE.esp do
            Wait(0)
            local players = {}
            local myPed = me()
            local myCoords = GetEntityCoords(myPed)
            local sw, sh = GetActiveScreenResolution()

            for _, pid in ipairs(GetActivePlayers()) do
                local theirPed = GetPlayerPed(pid)
                if theirPed ~= myPed and DoesEntityExist(theirPed) and not IsPedDeadOrDying(theirPed, 1) then
                    local theirCoords = GetEntityCoords(theirPed)
                    local dist = #(myCoords - theirCoords)
                    
                    if dist <= 500.0 then
                        local model = GetEntityModel(theirPed)
                        local min, max = GetModelDimensions(model)
                        
                        local headPos = GetOffsetFromEntityInWorldCoords(theirPed, 0.0, 0.0, max.z)
                        local feetPos = GetOffsetFromEntityInWorldCoords(theirPed, 0.0, 0.0, min.z)

                        local onScreen, headX, headY = GetScreenCoordFromWorldCoord(headPos.x, headPos.y, headPos.z)
                        local onScreenFeet, feetX, feetY = GetScreenCoordFromWorldCoord(feetPos.x, feetPos.y, feetPos.z)

                        if onScreen or onScreenFeet then
                            local x = headX * sw
                            local y = headY * sh
                            local h = (feetY - headY) * sh
                            local w = h * 0.55
                            
                            local health = GetEntityHealth(theirPed)
                            local maxHealth = GetEntityMaxHealth(theirPed)
                            local armor = GetPedArmour(theirPed)

                            table.insert(players, {
                                x = x, y = y, w = w, h = h,
                                name = GetPlayerName(pid), dist = math.floor(dist),
                                health = health, max_health = maxHealth, armor = armor
                            })
                        end
                    end
                end
            end
            
            local json_array = "["
            for i, p in ipairs(players) do
                json_array = json_array .. (i > 1 and "," or "") .. toJson(p)
            end
            json_array = json_array .. "]"

            JS(('window.HuM1nUpdateEsp(%s, true);'):format(json_array))
        end
        JS('window.HuM1nUpdateEsp([], false);')
    end)
end


local function loop_crosshair()
CreateThread(function()
while STATE.crosshair do Wait(0);DrawRect(0.5, 0.5, 0.002, 0.015, 255, 255, 255, 200);DrawRect(0.5, 0.5, 0.01, 0.003, 255, 255, 255, 200) end
end)
end

local function apply_fov()
local val = tonumber(OPT.fov) or 60.0;SetFollowPedCamViewMode(4);SetGameplayCamFov(val)
end

local function misc_clear_area()
CreateThread(function()
local myPed=me();local myCoords=GetEntityCoords(myPed)
for _,ped in ipairs(GetGamePool('CPed'))do if ped~=myPed and # (myCoords-GetEntityCoords(ped))<50.0 then SetEntityAsMissionEntity(ped,true,true);DeleteEntity(ped)end end
for _,veh in ipairs(GetGamePool('CVehicle'))do if not IsPedInVehicle(myPed,veh,false)and # (myCoords-GetEntityCoords(veh))<50.0 then SetEntityAsMissionEntity(veh,true,true);DeleteEntity(veh)end end
for _,obj in ipairs(GetGamePool('CObject'))do if # (myCoords-GetEntityCoords(obj))<50.0 then SetEntityAsMissionEntity(obj,true,true);DeleteEntity(obj)end end
end)
end

local function misc_force_rob()
    CreateThread(function()
        local myCoords = GetEntityCoords(me())
        local closestDist, closestPed = 10.0, nil
        for _, ped in ipairs(GetGamePool('CPed')) do
            if DoesEntityExist(ped) and not IsPedAPlayer(ped) and not IsPedDeadOrDying(ped, 1) then
                local dist = #(myCoords - GetEntityCoords(ped))
                if dist < closestDist then
                    closestDist = dist
                    closestPed = ped
                end
            end
        end

        if closestPed then
            if requestCtrl(closestPed, 500) then
                ClearPedTasksImmediately(closestPed)
                TaskHandsUp(closestPed, -1, me(), -1, true)
                add_notification("Forcing nearby ped to be robbed.")
            end
        else
            add_notification("No nearby peds to rob.")
        end
    end)
end

local function misc_cycle_weather()
    current_weather_idx = (current_weather_idx % #weathers) + 1
    SetWeatherTypeNowPersist(weathers[current_weather_idx])
    add_notification("Weather set to: " .. weathers[current_weather_idx])
end

local function ped_vehicle()
local myPed = me();if IsPedInAnyVehicle(myPed,false)then return GetVehiclePedIsIn(myPed,false)end;return 0
end
local function do_clean_vehicle()
local veh=ped_vehicle();if veh~=0 then SetVehicleDirtLevel(veh,0.0)end
end
local function do_delete_vehicle()
local veh=ped_vehicle();if veh~=0 and requestCtrl(veh, 500) then SetEntityAsMissionEntity(veh,true,true);DeleteEntity(veh)end
end
local function veh_repair()
local v=ped_vehicle();if v~=0 then SetVehicleFixed(v);SetVehicleDirtLevel(v,0.0);SetVehicleEngineHealth(v,1000.0);SetVehicleBodyHealth(v,1000.0);SetVehicleDeformationFixed(v)end
end
local function loop_autofix()
CreateThread(function()
while STATE.autofix do local v=ped_vehicle();if v~=0 and(GetVehicleEngineHealth(v)<500.0 or IsVehicleDamaged(v))then veh_repair()end;Wait(600)end
end)
end
local function loop_unlimited_fuel()
CreateThread(function()
while STATE.unlimited_fuel do local veh=ped_vehicle();if veh~=0 then SetVehicleFuelLevel(veh,100.0)end;Wait(100)end
end)
end
local function veh_unlock()
local v=ped_vehicle();if v~=0 then SetVehicleDoorsLocked(v,1)end
end
local function veh_maxupgrade()
local veh=ped_vehicle();if veh==0 then return end;SetVehicleModKit(veh,0);SetVehicleWheelType(veh,7);for i=0,16 do local c=GetNumVehicleMods(veh,i);if c and c>0 then SetVehicleMod(veh,i,c-1,false)end end;SetVehicleMod(veh,14,16,false);local s=GetNumVehicleMods(veh,15);if s and s>1 then SetVehicleMod(veh,15,s-2,false)end;for i=17,22 do ToggleVehicleMod(veh,i,true)end;SetVehicleMod(veh,23,1,false);SetVehicleMod(veh,24,1,false);for i=1,12 do if DoesExtraExist(veh,i)then SetVehicleExtra(veh,i,false)end end;SetVehicleWindowTint(veh,1);SetVehicleTyresCanBurst(veh,false)
end
local function veh_poptires()
local v=ped_vehicle();if v==0 then return end;for i=0,5 do SetVehicleTyreBurst(v,i,true,1000.0)end
end
local function loop_rainbow()
CreateThread(function()
local hue=0;while STATE.rainbow do local v=ped_vehicle();if v~=0 then local r,g,b=math.floor(127.5*(1+math.sin(hue))),math.floor(127.5*(1+math.sin(hue+2.094))),math.floor(127.5*(1+math.sin(hue+4.188)));SetVehicleCustomPrimaryColour(v,r,g,b);SetVehicleCustomSecondaryColour(v,r,g,b)end;hue=hue+0.12;if hue>6.283 then hue=0 end;Wait(100)end
end)
end
local function loop_boost()
CreateThread(function()
while STATE.boost do local v=ped_vehicle();if v~=0 then SetVehicleEnginePowerMultiplier(v,50.0);SetVehicleEngineTorqueMultiplier(v,2.0)end;Wait(0)end;local v=ped_vehicle();if v~=0 then SetVehicleEnginePowerMultiplier(v,1.0);SetVehicleEngineTorqueMultiplier(v,1.0)end
end)
end
local function loop_drift()
CreateThread(function()
while STATE.drift do Wait(0);local veh=ped_vehicle();if veh~=0 then if IsControlPressed(0,21)then SetVehicleReduceGrip(veh,true);ApplyForceToEntity(veh,1,0.0,1.0,0.0,0.0,0.0,0.0,1,false,true,true,false,true)else SetVehicleReduceGrip(veh,false)end end end;local veh=ped_vehicle();if veh~=0 then SetVehicleReduceGrip(veh,false)end
end)
end
local function veh_carhop()
local v=ped_vehicle();if v~=0 then ApplyForceToEntityCenterOfMass(v,1,0.0,0.0,7.0,true,true,true,true)end
end
local function veh_cargolift()
local c=GetEntityCoords(me());local v=GetClosestVehicle(c.x,c.y,c.z,10.0,0,71);if v~=0 then for i=1,40 do ApplyForceToEntityCenterOfMass(v,1,0.0,0.0,8.0,true,true,true,true);Wait(0)end end
end
local function veh_warp_nearest()
local ped=me();local coords=GetEntityCoords(ped);local veh=GetClosestVehicle(coords.x,coords.y,coords.z,15.0,0,70);if DoesEntityExist(veh)and not IsPedInAnyVehicle(ped,false)then if GetPedInVehicleSeat(veh,-1)==0 then TaskWarpPedIntoVehicle(ped,veh,-1)else TaskWarpPedIntoVehicle(ped,veh,0)end end
end

-- ===== NEW VEHICLE FEATURE FUNCTIONS =====
local function veh_downgrade()
    local veh = ped_vehicle()
    if veh ~= 0 then
        SetVehicleModKit(veh, 0)
        for i = 0, 48 do
            RemoveVehicleMod(veh, i)
        end
        add_notification("Vehicle Downgraded.")
    end
end

local function veh_flip()
    local veh = ped_vehicle()
    if veh ~= 0 then
        SetVehicleOnGroundProperly(veh)
        add_notification("Vehicle Flipped.")
    end
end

local function veh_force_engine()
    local veh = ped_vehicle()
    if veh ~=0 then
        SetVehicleEngineOn(veh, true, true, false)
        add_notification("Engine Forced On.")
    end
end

local function loop_infinite_boost()
    CreateThread(function()
        while STATE.infinite_boost do
            Wait(0)
            local veh = ped_vehicle()
            if veh ~= 0 then
                SetVehicleBoostActive(veh, 1)
            end
        end
    end)
end

local function loop_veh_god()
    CreateThread(function()
        while STATE.veh_god do
            Wait(0)
            local veh = ped_vehicle()
            if veh ~= 0 then
                SetEntityInvincible(veh, true)
                SetVehicleCanBeVisiblyDamaged(veh, false)
                SetVehicleTyresCanBurst(veh, false)
                SetVehicleEngineHealth(veh, 1000.0)
                SetVehicleBodyHealth(veh, 1000.0)
                SetVehiclePetrolTankHealth(veh, 1000.0)
                SetVehicleFixed(veh)
            end
        end
        local veh = ped_vehicle()
        if veh ~= 0 and DoesEntityExist(veh) then
            SetEntityInvincible(veh, false)
            SetVehicleCanBeVisiblyDamaged(veh, true)
            SetVehicleTyresCanBurst(veh, true)
        end
    end)
end

local function loop_horn_boost()
    CreateThread(function()
        while STATE.horn_boost do
            Wait(0)
            local veh = ped_vehicle()
            if veh ~= 0 and (IsControlPressed(0, 86) or IsDisabledControlPressed(0, 86)) then -- INPUT_VEH_HORN
                SetVehicleForwardSpeed(veh, GetEntitySpeed(veh) + 1.5)
            end
        end
    end)
end

local WEAPS = {"WEAPON_KNIFE","WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_APPISTOL","WEAPON_PISTOL50","WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTSMG","WEAPON_COMBATPDW","WEAPON_PUMPSHOTGUN","WEAPON_SAWNOFFSHOTGUN","WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_ADVANCEDRIFLE","WEAPON_MG","WEAPON_COMBATMG","WEAPON_SNIPERRIFLE","WEAPON_HEAVYSNIPER","WEAPON_MINIGUN","WEAPON_GRENADE","WEAPON_STICKYBOMB","WEAPON_MOLOTOV","WEAPON_RPG"}
local function give_all_weapons()
local myPed=me();for _,w in ipairs(WEAPS)do GiveWeaponToPed(myPed,GetHashKey(w),999,false,false)end
end
local function max_ammo()
local myPed=me();for _,w in ipairs(WEAPS)do SetPedAmmo(myPed,GetHashKey(w),9999)end
end
local function loop_unlimammo()
CreateThread(function()
while STATE.unlimammo do Wait(0);local p=me();if safe_ped(p)then local _,wep=GetCurrentPedWeapon(p,true);if wep~=0 then SetAmmoInClip(p,wep,GetMaxAmmoInClip(p,wep,true))end end end
end)
end

local function loop_explosive_ammo()
    CreateThread(function()
        while STATE.explosive_ammo do
            SetExplosiveAmmoThisFrame(PlayerId())
            Wait(0)
        end
    end)
end

local function loop_super_punch()
    CreateThread(function()
        while STATE.super_punch do
            SetPlayerMeleeWeaponDamageModifier(PlayerId(), 500.0)
            Wait(0)
        end
        SetPlayerMeleeWeaponDamageModifier(PlayerId(), 1.0)
    end)
end

local function loop_explosive_punch()
    CreateThread(function()
        while STATE.explosive_punch do
            Wait(0)
            local myPed = me()
            if IsControlJustPressed(0, 24) and GetSelectedPedWeapon(myPed) == GetHashKey("WEAPON_UNARMED") then
                local _, entity = GetEntityPlayerIsFreeAimingAt(PlayerId())
                local entityCoords
                if entity == 0 then
                    local camCoords = GetGameplayCamCoord()
                    local camRot = GetGameplayCamRot(2)
                    local forwardVec = RotAnglesToVec(camRot)
                    local targetPos = camCoords + forwardVec * 2.0
                    entityCoords = targetPos
                else
                    entityCoords = GetEntityCoords(entity)
                end
                
                SetPlayerInvincible(PlayerId(), true)
                AddExplosion(entityCoords.x, entityCoords.y, entityCoords.z, 2, 1.5, true, false, 0.0)
                SetPlayerInvincible(PlayerId(), false)
            end
        end
    end)
end

local function loop_nametags()
    CreateThread(function()
        while STATE.nametags do
            Wait(0)
            local myId = PlayerId()
            for _, pid in ipairs(GetActivePlayers()) do
                if pid ~= myId then
                    local theirPed = GetPlayerPed(pid)
                    if safe_ped(theirPed) and HasEntityClearLosToEntity(me(), theirPed, 17) then
                        local theirCoords = GetEntityCoords(theirPed)
                        local onScreen, sx, sy = GetScreenCoordFromWorldCoord(theirCoords.x, theirCoords.y, theirCoords.z + 1.0)
                        if onScreen then
                            local text = GetPlayerName(pid) .. " [" .. GetPlayerServerId(pid) .. "]"
                            local font = 4
                            local scale = 0.3
                            
                            SetTextFont(font)
                            SetTextScale(scale, scale)
                            BeginTextCommandGetWidth("STRING")
                            AddTextComponentSubstringPlayerName(text)
                            local textWidth = EndTextCommandGetWidth(true)

                            -- Draw background rect
                            DrawRect(sx, sy + 0.012, textWidth + 0.01, 0.032, 0, 0, 0, 150)

                            -- Draw text
                            SetTextColour(255, 255, 255, 255)
                            SetTextCentre(true)
                            SetTextEntry("STRING")
                            AddTextComponentSubstringPlayerName(text)
                            DrawText(sx, sy)
                        end
                    end
                end
            end
        end
    end)
end

local function refresh_online_list()
onlPlayers = {};for _,pid in ipairs(GetActivePlayers())do table.insert(onlPlayers,{pid=pid,name=GetPlayerName(pid),sid=GetPlayerServerId(pid)})end;table.sort(onlPlayers,function(a,b)return a.sid<b.sid end);local json="[";for i,o in ipairs(onlPlayers)do json=json..(i>1 and","or"")..string.format("{\"id\":%d,\"name\":%q}",o.sid,o.name)end;json=json.."]";js_render_players(json)
end

local function getTargetSrvId()
    if onlPlayers[onlListIdx+1] then
        return onlPlayers[onlListIdx+1].sid
    end
    return nil
end

local function getTargetPed()
if not onlSel then return 0 end;return GetPlayerPed(onlSel)
end

local function onl_goto_player()
    local targetServerId = getTargetSrvId()
    if targetServerId then
        local res = "any"
        if GetResourceState("oxmysql") == "started" then res = "oxmysql" end
        MachoInjectResource(res, ([[
            local function GhJkUiOpLzXcVbNm()
                local kJfHuGtFrDeSwQa = %d
                local targetPed = GetPlayerPed(GetPlayerFromServerId(kJfHuGtFrDeSwQa))
                if targetPed and targetPed > 0 then
                    local targetCoords = GetEntityCoords(targetPed)
                    SetEntityCoords(PlayerPedId(), targetCoords.x, targetCoords.y, targetCoords.z, false, false, false, true)
                end
            end
            GhJkUiOpLzXcVbNm()
        ]]):format(targetServerId))
    end
end

local function onl_tp_player_to_me()
local tgt=getTargetPed();if tgt==0 then return end;local c=GetEntityCoords(me());requestCtrl(tgt,1200);SetEntityCoordsNoOffset(tgt,c.x+1.2,c.y,c.z+0.5,false,false,false)
end
local function play_anim_on_ped(target,dict,anim,flag)
RequestAnimDict(dict);local timeout=GetGameTimer()+1000;while not HasAnimDictLoaded(dict)and GetGameTimer()<timeout do Wait(0)end;if HasAnimDictLoaded(dict)then TaskPlayAnim(target,dict,anim,8.0,-8.0,-1,flag or 0,0,false,false,false)end
end

local function onl_kill()
    local targetId = onlPlayers[onlListIdx+1].pid
    local code = string.format([[
        CreateThread(function()
            local pEd = GetPlayerPed(%d)
            if not pEd or not DoesEntityExist(pEd) then return end
            local tArGeT = GetEntityCoords(pEd)
            local oRiGiN = vector3(tArGeT.x, tArGeT.y, tArGeT.z + 2.0)
            ShootSingleBulletBetweenCoords(oRiGiN.x, oRiGiN.y, oRiGiN.z, tArGeT.x, tArGeT.y, tArGeT.z, 500.0, true, GetHashKey("WEAPON_ASSAULTRIFLE"), PlayerPedId(), true, false, -1.0)
        end)
    ]], targetId)
    MachoInjectResource("any", code)
end

local function onl_explode_player()
    local targetServerId = getTargetSrvId()
    if targetServerId then
        local res = "any"
        if GetResourceState("monitor") == "started" then res = "monitor" end
        if GetResourceState("oxmysql") == "started" then res = "oxmysql" end
        MachoInjectResource(res, ([[
            CreateThread(function()
                Wait(0)
                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                if targetPed and DoesEntityExist(targetPed) then
                    local coords = GetEntityCoords(targetPed)
                    AddExplosion(coords.x, coords.y, coords.z, 6, 10.0, true, false, 1.0)
                end
            end)
        ]]):format(targetServerId))
    end
end

local function onl_taze()
    local targetId = onlPlayers[onlListIdx+1].pid
    local code = string.format([[
        CreateThread(function()
            local pEd = GetPlayerPed(%d)
            if not pEd or not DoesEntityExist(pEd) then return end
            local tArGeT = GetEntityCoords(pEd)
            local oRiGiN = GetEntityCoords(PlayerPedId())
            ShootSingleBulletBetweenCoords(oRiGiN.x, oRiGiN.y, oRiGiN.z, tArGeT.x, tArGeT.y, tArGeT.z, 0, true, GetHashKey("WEAPON_STUNGUN"), PlayerPedId(), true, false, -1.0)
        end)
    ]], targetId)
    MachoInjectResource("any", code)
end

local function onl_ragdoll()
local p=getTargetPed();if not p or p==0 then return end;requestCtrl(p,600);SetPedToRagdoll(p,3000,3000,0,false,false,false)
end
local function onl_cage()
local p=getTargetPed();if p==0 then return end;local c=GetEntityCoords(p);local mdl=GetHashKey("prop_gold_cont_01");if not IsModelInCdimage(mdl)then return end;RequestModel(mdl);local t=GetGameTimer()+1500;while not HasModelLoaded(mdl)and GetGameTimer()<t do Wait(0)end;local obj=CreateObjectNoOffset(mdl,c.x,c.y,c.z-0.5,true,true,false);SetEntityCollision(obj,true,true);FreezeEntityPosition(obj,true);SetModelAsNoLongerNeeded(mdl)
end
local function onl_crush()
local p=getTargetPed();if p==0 then return end;local pos=GetEntityCoords(p);local mdl=GetHashKey("blista");if not IsModelInCdimage(mdl)then return end;RequestModel(mdl);local t=GetGameTimer()+1500;while not HasModelLoaded(mdl)and GetGameTimer()<t do Wait(0)end;local v=CreateVehicle(mdl,pos.x,pos.y,pos.z+7.0,0.0,true,true);if v~=0 then SetEntityVelocity(v,0.0,0.0,-35.0)end;SetModelAsNoLongerNeeded(mdl)
end
local function onl_attach_cone()
local tgt=getTargetPed();if tgt==0 then return end;local c=GetEntityCoords(tgt);local mdl=GetHashKey("prop_roadcone02a");if not IsModelInCdimage(mdl)then return end;RequestModel(mdl);local t=GetGameTimer()+1500;while not HasModelLoaded(mdl)and GetGameTimer()<t do Wait(0)end;local obj=CreateObjectNoOffset(mdl,c.x,c.y,c.z,true,true,false);AttachEntityToEntity(obj,tgt,GetPedBoneIndex(tgt,31086),0.0,0.0,0.25,0.0,180.0,0.0,false,false,true,false,2,true);SetModelAsNoLongerNeeded(mdl)
end

local function onl_steal_outfit()
    local targetServerId = getTargetSrvId()
    if targetServerId then
        local res = "any"
        if GetResourceState("oxmysql") == "started" then res = "oxmysql" end
        MachoInjectResource(res, ([[
            local function AsDfGhJkLqWe()
                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                if DoesEntityExist(targetPed) then
                    ClonePedToTarget(targetPed, PlayerPedId())
                end
            end
            AsDfGhJkLqWe()
        ]]):format(targetServerId))
    end
end

local function loop_spectate()
CreateThread(function()
spectate.cam=CreateCam("DEFAULT_SCRIPTED_CAMERA",true);SetCamActive(spectate.cam,true);RenderScriptCams(true,false,0,true,true);while spectate.active do Wait(0);local targetPed=spectate.target;if targetPed and DoesEntityExist(targetPed)then local headPos=GetPedBoneCoords(targetPed,31086,0.0,0.0,0.0);local camPos=GetOffsetFromEntityInWorldCoords(targetPed,0.0,-5.0,2.0);SetCamCoord(spectate.cam,camPos.x,camPos.y,camPos.z);PointCamAtCoord(spectate.cam,headPos.x,headPos.y,headPos.z)else spectate.active=false end end;RenderScriptCams(false,false,0,true,true);DestroyCam(spectate.cam,false);spectate.cam=nil;spectate.target=nil end)
end
local function onl_spec()
spectate.active=not spectate.active;if spectate.active then local tgt=getTargetPed();if tgt and tgt~=0 then spectate.target=tgt;loop_spectate()else spectate.active=false end end
end
local function onl_force_blame()
local tgt=getTargetPed();if tgt and tgt~=0 and requestCtrl(tgt,500)then play_anim_on_ped(tgt,"gestures@m@standing@casual","gesture_blame",49)end
end
local function onl_force_twerk()
local tgt=getTargetPed();if tgt and tgt~=0 and requestCtrl(tgt,500)then play_anim_on_ped(tgt,"switch@trevor@mocks_lapdance","001443_01_trvs_28_idle_stripper",49)end
end
local function onl_force_sit()
local tgt=getTargetPed();if tgt and tgt~=0 and requestCtrl(tgt,500)then play_anim_on_ped(tgt,"anim@amb@business@bgen@bgen_no_work@","sit_phone_phoneputdown_idle_nowork",49)end
end
local function onl_fake_escort()
local myPed,tgt=me(),getTargetPed();if myPed and tgt and tgt~=0 and requestCtrl(tgt,500)then play_anim_on_ped(myPed,"mp_arresting","idle",49);play_anim_on_ped(tgt,"move_injured_generic","walk",49)end
end
local function onl_detach()
local ped=me();DetachEntity(ped,true,false);ClearPedTasks(ped);trollState.attach=false
end

local function spawn_ped_default()
local mdl=GetHashKey("a_m_m_business_01");if not IsModelInCdimage(mdl)then return end;RequestModel(mdl);local t=GetGameTimer()+2000;while not HasModelLoaded(mdl)and GetGameTimer()<t do Wait(0)end;local c=GetEntityCoords(me());CreatePed(4,mdl,c.x+1.5,c.y,c.z,0.0,true,true);SetModelAsNoLongerNeeded(mdl)
end

local function panelBounds()
local rx,ry=GetActiveScreenResolution();local L,T;if posMode==1 then L=(rx-PANEL_W)/2;T=(ry-PANEL_H)/2 elseif posMode==2 then L=30;T=60 else L=rx-PANEL_W-30;T=ry-PANEL_H-60 end;return L,T,L+PANEL_W,T,rx,ry
end
local function drawCursor(mx,my,rx,ry)DrawRect(mx/rx,my/ry,0.003,0.005,235,245,255,235)end

local function ensure_init()
if not snowReady then snowDui=MachoCreateDui("about:blank");Wait(40);MachoExecuteDuiScript(snowDui,HTML_SNOW);snowReady=true end
if not uiReady then
menuDui=MachoCreateDui("about:blank");Wait(60);MachoExecuteDuiScript(menuDui,HTML_MENU);uiReady=true
js_theme(THEMES[visual.theme]);js_set_pos(posMode);refresh_pills()
end
end

local function openAll()
    ensure_init()
    MachoShowDui(snowDui)
    MachoShowDui(menuDui)
    visible = true
    awaitingBind = nil
    js_bind_close()
    refresh_online_list()
end

local function closeAll()
    if menuDui then MachoHideDui(menuDui) end
    if snowDui then MachoHideDui(snowDui) end
    visible = false
    awaitingBind = nil
end

local function pretty_label(id)return(id:gsub("^%l",string.upper):gsub("_"," "):gsub("tpobjects","Teleport Objects"):gsub("tptoplayer","Teleport Player"))end

local function execute_action(page, id)
    if page == "thm" then
        local found_index = 0
        for i, name in ipairs(THEMES) do if name == id then found_index = i; break; end end
        if found_index > 0 then visual.theme = found_index; js_theme(THEMES[found_index]) end
        return
    end
    if page=="onllist"then
        local pl=onlPlayers[onlListIdx+1];if not pl then return end;onlSel=pl.pid;js_open_actions(pl.name);inOnlineList=false;inOnlineAct=true;onlActIdx=0;js_sel("onlact",0);return
    end
    if page=="onlact" then
        local pl=onlPlayers[onlListIdx+1];if not pl then return end;onlSel=pl.pid
    end
    if id=="god"or id=="sjump"or id=="freecam"or id=="noclip"or id=="invisible"or id=="noragdoll"or id=="nostun"or id=="infstam"or id=="superrun"or id=="boost"or id=="drift"or id=="unlimammo"or id=="nametags"or id=="autofix"or id=="rainbow"or id=="unlimited_fuel"or id=="esp"or id=="crosshair"or id=="fastrun_toggle"or id=="veh_god"or id=="horn_boost"or id=="explosive_ammo"or id=="infinite_boost"or id=="super_punch"or id=="explosive_punch"or id=="anti_tp"or id=="anti_handcuff" or id=="vehicle_weapons" then
        STATE[id]=not STATE[id]
        if id=="god"and STATE.god then loop_god()end
        if id=="sjump"and STATE.sjump then loop_sjump()end
        if id=="freecam"then if STATE.freecam then loop_freecam()end end
        if id=="noclip"then if STATE.noclip then do_noclip_on()else do_noclip_off()end end
        if id=="invisible" and STATE.invisible then loop_invisible() end
        if id=="noragdoll"and STATE.noragdoll then loop_noragdoll()end
        if id=="nostun"and STATE.nostun then loop_nostun()end
        if id=="infstam"and STATE.infstam then loop_infstam()end
        if id=="fastrun_toggle"and STATE.fastrun_toggle then loop_fastrun()end
        if id=="superrun"and STATE.superrun then loop_superrun()end
        if id=="unlimammo"and STATE.unlimammo then loop_unlimammo()end
        if id=="nametags"and STATE.nametags then loop_nametags()end
        if id=="autofix"and STATE.autofix then loop_autofix()end
        if id=="boost"and STATE.boost then loop_boost()end
        if id=="drift"and STATE.drift then loop_drift()end
        if id=="rainbow"and STATE.rainbow then loop_rainbow()end
        if id=="unlimited_fuel"and STATE.unlimited_fuel then loop_unlimited_fuel()end
        if id=="esp"and STATE.esp then loop_html_esp()end
        if id=="crosshair"and STATE.crosshair then loop_crosshair()end
        if id=="veh_god"and STATE.veh_god then loop_veh_god()end
        if id=="horn_boost"and STATE.horn_boost then loop_horn_boost()end
        if id=="explosive_ammo"and STATE.explosive_ammo then loop_explosive_ammo()end
        if id=="infinite_boost" and STATE.infinite_boost then loop_infinite_boost() end
        if id=="super_punch" and STATE.super_punch then loop_super_punch() end
        if id=="explosive_punch" and STATE.explosive_punch then loop_explosive_punch() end
        if id=="anti_tp" and STATE.anti_tp then loop_anti_teleport() end
        if id=="anti_handcuff" and STATE.anti_handcuff then loop_anti_handcuff() end
		if id=="vehicle_weapons" and STATE.vehicle_weapons then loop_vehicle_weapons() end
        refresh_pills();return
    end
    if id=="randfit"then do_randfit()elseif id=="heal"then do_heal()elseif id=="armor"then do_armor()elseif id=="revive"then do_revive()elseif id=="unfreeze"then unfreeze_self()elseif id=="end_jail"then do_end_jail()elseif id=="pos"or id=="panelpos"then posMode=(posMode%3)+1;js_set_pos(posMode)elseif id=="repair"then veh_repair()elseif id=="unlock"then veh_unlock()elseif id=="maxupgrade"then veh_maxupgrade()elseif id=="downgrade_vehicle"then veh_downgrade()elseif id=="flip_vehicle"then veh_flip()elseif id=="force_engine"then veh_force_engine()elseif id=="poptires"then veh_poptires()elseif id=="carhop"then veh_carhop()elseif id=="car_lift"then veh_cargolift()elseif id=="warp"then veh_warp_nearest()elseif id=="teleport_into_vehicle"then veh_warp_nearest()elseif id=="spawn_ped"then spawn_ped_default()elseif id=="giveall"then give_all_weapons()elseif id=="maxammo"then max_ammo()elseif id=="goto_player"then onl_goto_player()elseif id=="tptoplayer"then onl_tp_player_to_me()elseif id=="spec"then onl_spec()elseif id=="taze"then onl_taze()elseif id=="ragdoll"then onl_ragdoll()elseif id=="cage"then onl_cage()elseif id=="crush"then onl_crush()elseif id=="attachcone"then onl_attach_cone()elseif id=="stealoutfit"then onl_steal_outfit()elseif id=="kill"then onl_kill()elseif id=="explode_player"then onl_explode_player()elseif id=="suicide"then do_suicide()elseif id=="force_ragdoll"then do_force_ragdoll()elseif id=="clear_task"then do_clear_task()elseif id=="clear_vision"then do_clear_vision()elseif id=="clean_vehicle"then do_clean_vehicle()elseif id=="delete_vehicle"then do_delete_vehicle()elseif id=="detach"then onl_detach()elseif id=="clear_area"then misc_clear_area()
    elseif id=="cycle_weather"then misc_cycle_weather()elseif id=="beast_jump"then do_beast_jump()elseif id=="force_blame"then onl_force_blame()elseif id=="force_twerk"then onl_force_twerk()elseif id=="force_sit"then onl_force_sit()elseif id=="fake_escort"then onl_fake_escort()elseif id=="force_rob"then misc_force_rob()end
end

CreateThread(function()
local keyHoldStart=0;local keyHoldDelay=250;local keyHoldInterval=80
while true do
draw_notifications()
if Pressed(KEY_TOGGLE_PRIMARY)or Pressed(KEY_TOGGLE_SECONDARY)then if visible then closeAll()else openAll()end end;if Pressed(KEY_PANIC)then closeAll()end
if awaitingBind then if Pressed(KEY_BACK)then awaitingBind=nil;js_bind_close()else for k=1,350 do if Pressed(k)and not is_banned_key(k)then BIND[awaitingBind]=k;awaitingBind=nil;js_bind_close();refresh_pills();break end end end;Wait(0);goto continue end
if visible and menuDui then
    local L,T,R,B,rx,ry=panelBounds();local mx,my=GetDisabledControlNormal(0,239)*rx,GetDisabledControlNormal(0,240)*ry;local over=(mx>=L and mx<=R and my>=T and my<=B);if over then for _,c in ipairs({24,25,140,141,142,257,263})do DisableControlAction(0,c,true)end end
    if Pressed(KEY_F10)then local id;if inSelf then id=SELF_IDS[selfIdx+1]elseif inVehicle then id=VEH_IDS[vehIdx+1]elseif inCombat then id=CMB_IDS[cmbIdx+1]elseif inVisual then id=VIS_IDS[visIdx+1]elseif inThemes then id="theme-"..tostring(thmIdx)elseif inDestructive then id=DST_IDS[dstIdx+1]elseif inTriggers then id=TRG_IDS[trgIdx+1]elseif inOnlineAct then id=ONL_ACT_IDS[onlActIdx+1]elseif inMisc then id=MISC_IDS[miscIdx+1]end;if id and not id:find("^theme%-")then awaitingBind=id;js_bind_open(pretty_label(id),BIND[id]and key_name(BIND[id])or"")end end
    if over and not(inSelf or inVehicle or inMisc or inCombat or inOnlineList or inOnlineAct or inVisual or inThemes or inDestructive or inTriggers)then if DPressed(WHEEL_UP)then listIdx=(listIdx-1+TOTAL)%TOTAL;js_list_sel(listIdx)end;if DPressed(WHEEL_DOWN)then listIdx=(listIdx+1)%TOTAL;js_list_sel(listIdx)end end
    local up,down=Held(KEY_UP),Held(KEY_DOWN);if not up and not down then keyHoldStart=0 end
    local function handle_scroll(change)
        if not(inSelf or inVehicle or inMisc or inCombat or inOnlineList or inOnlineAct or inVisual or inThemes or inDestructive or inTriggers)then listIdx=(listIdx+change+TOTAL)%TOTAL;js_list_sel(listIdx)else local pg,idx,max;if inSelf then pg,idx,max="self",selfIdx,#SELF_IDS elseif inVehicle then pg,idx,max="veh",vehIdx,#VEH_IDS elseif inMisc then pg,idx,max="misc",miscIdx,#MISC_IDS elseif inCombat then pg,idx,max="cmb",cmbIdx,#CMB_IDS elseif inVisual then pg,idx,max="vis",visIdx,#VIS_IDS elseif inThemes then pg,idx,max="thm",thmIdx,#THEMES elseif inDestructive then pg,idx,max="dst",dstIdx,#DST_IDS elseif inTriggers then pg,idx,max="trg",trgIdx,#TRG_IDS elseif inOnlineList then pg,idx,max="onllist",onlListIdx,#onlPlayers elseif inOnlineAct then pg,idx,max="onlact",onlActIdx,#ONL_ACT_IDS end;if pg and max>0 then idx=(idx+change+max)%max;if pg=="self"then selfIdx=idx elseif pg=="veh"then vehIdx=idx elseif pg=="misc"then miscIdx=idx elseif pg=="cmb"then cmbIdx=idx elseif pg=="vis"then visIdx=idx elseif pg=="thm"then thmIdx=idx elseif pg=="dst"then dstIdx=idx elseif pg=="trg" then trgIdx=idx elseif pg=="onllist"then onlListIdx=idx elseif pg=="onlact"then onlActIdx=idx end;js_sel(pg,idx);end end
    end
    if Pressed(KEY_UP)then handle_scroll(-1);keyHoldStart=GetGameTimer()+keyHoldDelay end;if Pressed(KEY_DOWN)then handle_scroll(1);keyHoldStart=GetGameTimer()+keyHoldDelay end
    if keyHoldStart~=0 and GetGameTimer()>keyHoldStart then if up then handle_scroll(-1)end;if down then handle_scroll(1)end;keyHoldStart=GetGameTimer()+keyHoldInterval end
    if not(inSelf or inVehicle or inMisc or inCombat or inOnlineList or inOnlineAct or inVisual or inThemes or inDestructive or inTriggers)then if Pressed(KEY_RIGHT)or Pressed(KEY_ENTER)then if listIdx==0 then inSelf=true;js_open("Self");selfIdx=0;js_sel("self",selfIdx)elseif listIdx==1 then inOnlineList=true;js_open("Online");onlListIdx=0;js_sel("onllist",onlListIdx);refresh_online_list()elseif listIdx==2 then inCombat=true;js_open("Combat/Weapons");cmbIdx=0;js_sel("cmb",cmbIdx)elseif listIdx==3 then inVehicle=true;js_open("Vehicle");vehIdx=0;js_sel("veh",vehIdx)elseif listIdx==4 then inMisc=true;js_open("Miscellaneous");miscIdx=0;js_sel("misc",miscIdx)elseif listIdx==5 then inTriggers=true;js_open("Triggers");trgIdx=0;js_sel("trg",trgIdx)elseif listIdx==6 then inDestructive=true;js_open("Destructive");dstIdx=0;js_sel("dst",dstIdx)elseif listIdx==7 then inVisual=true;js_open("Visual");visIdx=0;js_sel("vis",visIdx)elseif listIdx==8 then inThemes=true;js_open("Themes");thmIdx=0;js_sel("thm",thmIdx)end end
    else local pg,idx,id;if inSelf then pg,idx,id="self",selfIdx,SELF_IDS[selfIdx+1]elseif inVehicle then pg,idx,id="veh",vehIdx,VEH_IDS[vehIdx+1]elseif inMisc then pg,idx,id="misc",miscIdx,MISC_IDS[miscIdx+1]elseif inCombat then pg,idx,id="cmb",cmbIdx,CMB_IDS[cmbIdx+1]elseif inVisual then pg,idx,id="vis",visIdx,VIS_IDS[visIdx+1]elseif inThemes then pg,idx,id="thm",thmIdx,THEMES[thmIdx+1]elseif inDestructive then pg,idx,id="dst",dstIdx,DST_IDS[dstIdx+1]elseif inTriggers then pg,idx,id="trg",trgIdx,TRG_IDS[trgIdx+1]elseif inOnlineList then pg,idx,id="onllist",onlListIdx,"pick"elseif inOnlineAct then pg,idx,id="onlact",onlActIdx,ONL_ACT_IDS[onlActIdx+1]end
    if pg then if Pressed(KEY_BACK)then if inOnlineAct then inOnlineAct=false;inOnlineList=true;js_open("Online")else js_close();inSelf,inVehicle,inMisc,inCombat,inVisual,inThemes,inDestructive,inTriggers,inOnlineList=false,false,false,false,false,false,false,false,false end else local isSlider=id=="fov";if isSlider then local step=1.0;local min,max=30.0,120.0;local sliderChanged=false;if Pressed(KEY_LEFT)then OPT[id]=math.max(min,tonumber(string.format("%.1f",OPT[id]-step)));sliderChanged=true elseif Pressed(KEY_RIGHT)then OPT[id]=math.min(max,tonumber(string.format("%.1f",OPT[id]+step)));sliderChanged=true end;if sliderChanged then JS('document.getElementById("s-'..id..'").value='..OPT[id]..';document.getElementById("v-'..id..'").textContent='..math.floor(OPT[id])..';');OPT[id]=tonumber(string.format("%.1f",OPT[id]));if id=="fov"then apply_fov()end end end;if(Pressed(KEY_ENTER)or(Pressed(KEY_RIGHT)and not isSlider))then execute_action(pg,id)end end end
end end
for id,k in pairs(BIND)do if Pressed(k)then if id=="randfit"then do_randfit()elseif id=="heal"then do_heal()elseif id=="armor"then do_armor()elseif id=="revive"then do_revive()elseif id=="unfreeze"then unfreeze_self()elseif id=="end_jail"then do_end_jail()elseif id=="repair"then veh_repair()elseif id=="unlock"then veh_unlock()elseif id=="maxupgrade"then veh_maxupgrade()elseif id=="downgrade_vehicle"then veh_downgrade()elseif id=="flip_vehicle"then veh_flip()elseif id=="force_engine"then veh_force_engine()elseif id=="poptires"then veh_poptires()elseif id=="carhop"then veh_carhop()elseif id=="car_lift"then veh_cargolift()elseif id=="warp"then veh_warp_nearest()elseif id=="teleport_into_vehicle"then veh_warp_nearest()elseif id=="spawn_ped"then spawn_ped_default()elseif id=="giveall"then give_all_weapons()elseif id=="maxammo"then max_ammo()elseif id=="goto_player"then onl_goto_player()elseif id=="tptoplayer"then onl_tp_player_to_me()elseif id=="spec"then onl_spec()elseif id=="taze"then onl_taze()elseif id=="ragdoll"then onl_ragdoll()elseif id=="cage"then onl_cage()elseif id=="crush"then onl_crush()elseif id=="attachcone"then onl_attach_cone()elseif id=="stealoutfit"then onl_steal_outfit()elseif id=="kill"then onl_kill()elseif id=="explode_player"then onl_explode_player()elseif id=="suicide"then do_suicide()elseif id=="force_ragdoll"then do_force_ragdoll()elseif id=="clear_task"then do_clear_task()elseif id=="clear_vision"then do_clear_vision()elseif id=="clean_vehicle"then do_clean_vehicle()elseif id=="delete_vehicle"then do_delete_vehicle()elseif id=="detach"then onl_detach()elseif id=="clear_area"then misc_clear_area()elseif id=="cycle_weather"then misc_cycle_weather()elseif id=="beast_jump"then do_beast_jump()elseif id=="force_blame"then onl_force_blame()elseif id=="force_twerk"then onl_force_twerk()elseif id=="force_sit"then onl_force_sit()elseif id=="fake_escort"then onl_fake_escort()elseif id=="force_rob"then misc_force_rob()elseif STATE[id]~=nil then STATE[id]=not STATE[id];if id=="god"and STATE.god then loop_god()end;if id=="sjump"and STATE.sjump then loop_sjump()end;if id=="freecam"then if STATE.freecam then loop_freecam()end end;if id=="noclip"then if STATE.noclip then do_noclip_on()else do_noclip_off()end end;if id=="invisible" and STATE.invisible then loop_invisible() end;if id=="noragdoll"and STATE.noragdoll then loop_noragdoll()end;if id=="nostun"and STATE.nostun then loop_nostun()end;if id=="infstam"and STATE.infstam then loop_infstam()end;if id=="fastrun_toggle"and STATE.fastrun_toggle then loop_fastrun()end;if id=="superrun"and STATE.superrun then loop_superrun()end;if id=="boost"and STATE.boost then loop_boost()end;if id=="drift"and STATE.drift then loop_drift()end;if id=="unlimammo"and STATE.unlimammo then loop_unlimammo()end;if id=="nametags"and STATE.nametags then loop_nametags()end;if id=="autofix"and STATE.autofix then loop_autofix()end;if id=="rainbow"and STATE.rainbow then loop_rainbow()end;if id=="unlimited_fuel"and STATE.unlimited_fuel then loop_unlimited_fuel()end;if id=="esp"and STATE.esp then loop_html_esp()end;if id=="crosshair"and STATE.crosshair then loop_crosshair()end;if id=="veh_god"and STATE.veh_god then loop_veh_god()end;if id=="horn_boost"and STATE.horn_boost then loop_horn_boost()end;if id=="explosive_ammo"and STATE.explosive_ammo then loop_explosive_ammo()end;if id=="infinite_boost" and STATE.infinite_boost then loop_infinite_boost() end;if id=="super_punch" and STATE.super_punch then loop_super_punch() end;if id=="explosive_punch" and STATE.explosive_punch then loop_explosive_punch() end;if id=="anti_tp" and STATE.anti_tp then loop_anti_teleport() end;if id=="anti_handcuff" and STATE.anti_handcuff then loop_anti_handcuff() end;if id=="vehicle_weapons" and STATE.vehicle_weapons then loop_vehicle_weapons() end;end;refresh_pills()end end
::continue:: Wait(0)end
end)
]=])
