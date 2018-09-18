--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Taranis X9D+ and QX7+ radios
--
-- Copyright (C) 2018. Alessandro Apostoli
--   https://github.com/yaapu
--
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY, without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, see <http://www.gnu.org/licenses>.
--
-- Passthrough protocol reference:
--   https://cdn.rawgit.com/ArduPilot/ardupilot_wiki/33cd0c2c/images/FrSky_Passthrough_protocol.xlsx
--
-- Borrowed some code from the LI-xx BATTCHECK v3.30 script
--  http://frskytaranis.forumactif.org/t2800-lua-download-un-testeur-de-batterie-sur-la-radio

--[[
	MAV_TYPE_GENERIC=0,               /* Generic micro air vehicle. | */
	MAV_TYPE_FIXED_WING=1,            /* Fixed wing aircraft. | */
	MAV_TYPE_QUADROTOR=2,             /* Quadrotor | */
	MAV_TYPE_COAXIAL=3,               /* Coaxial helicopter | */
	MAV_TYPE_HELICOPTER=4,            /* Normal helicopter with tail rotor. | */
	MAV_TYPE_ANTENNA_TRACKER=5,       /* Ground installation | */
	MAV_TYPE_GCS=6,                   /* Operator control unit / ground control station | */
	MAV_TYPE_AIRSHIP=7,               /* Airship, controlled | */
	MAV_TYPE_FREE_BALLOON=8,          /* Free balloon, uncontrolled | */
	MAV_TYPE_ROCKET=9,                /* Rocket | */
	MAV_TYPE_GROUND_ROVER=10,         /* Ground rover | */
	MAV_TYPE_SURFACE_BOAT=11,         /* Surface vessel, boat, ship | */
	MAV_TYPE_SUBMARINE=12,            /* Submarine | */
  MAV_TYPE_HEXAROTOR=13,            /* Hexarotor | */
	MAV_TYPE_OCTOROTOR=14,            /* Octorotor | */
	MAV_TYPE_TRICOPTER=15,            /* Tricopter | */
	MAV_TYPE_FLAPPING_WING=16,        /* Flapping wing | */
	MAV_TYPE_KITE=17,                 /* Kite | */
	MAV_TYPE_ONBOARD_CONTROLLER=18,   /* Onboard companion controller | */
	MAV_TYPE_VTOL_DUOROTOR=19,        /* Two-rotor VTOL using control surfaces in vertical operation in addition. Tailsitter. | */
	MAV_TYPE_VTOL_QUADROTOR=20,       /* Quad-rotor VTOL using a V-shaped quad config in vertical operation. Tailsitter. | */
	MAV_TYPE_VTOL_TILTROTOR=21,       /* Tiltrotor VTOL | */
	MAV_TYPE_VTOL_RESERVED2=22,       /* VTOL reserved 2 | */
	MAV_TYPE_VTOL_RESERVED3=23,       /* VTOL reserved 3 | */
	MAV_TYPE_VTOL_RESERVED4=24,       /* VTOL reserved 4 | */
	MAV_TYPE_VTOL_RESERVED5=25,       /* VTOL reserved 5 | */
	MAV_TYPE_GIMBAL=26,               /* Onboard gimbal | */
	MAV_TYPE_ADSB=27,                 /* Onboard ADSB peripheral | */
	MAV_TYPE_PARAFOIL=28,             /* Steerable, nonrigid airfoil | */
	MAV_TYPE_DODECAROTOR=29,          /* Dodecarotor | */
]]
------------------------------------------------------------------------------------
-- X9D+ OpenTX 2.2.2 memory increase +4Kb https://github.com/opentx/opentx/pull/5579
------------------------------------------------------------------------------------

---------------------
-- radio model
---------------------
--#define X7
-- to compile lua in luac files
--#define COMPILE
-- force loading of .lua files even after compilation
-- usefull if you rename .luac in .lua
--#define LOAD_LUA

---------------------
-- script version 
---------------------

---------------------
-- features
---------------------
--#define FRAMETYPE
---------------------
-- dev features
---------------------
--#define LOGTELEMETRY
--#define MEMDEBUG
--#define DEBUG
--#define TESTMODE
--#define BATT2TEST
--#define FLVSS2TEST
--#define DEMO
--#define DEV
--#define DEBUGEVT

-- calc and show background function rate
--#define BGRATE
-- calc and show run function rate
--#define FGRATE
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
--#define BGTELERATE
-- calc and show actual incoming telemetry rate
--#define TELERATE

-------------------------------------
-- UNITS Scales from Ardupilot OSD code /ardupilot/libraries/AP_OSD/AP_OSD_Screen.cpp
-------------------------------------
--[[
    static const float scale_metric[UNIT_TYPE_LAST] = {
        1.0,       //ALTITUDE m
        3.6,       //SPEED km/hr
        1.0,       //VSPEED m/s
        1.0,       //DISTANCE m
        1.0/1000,  //DISTANCE_LONG km
        1.0,       //TEMPERATURE C
    };
    static const float scale_imperial[UNIT_TYPE_LAST] = {
        3.28084,     //ALTITUDE ft
        2.23694,     //SPEED mph
        3.28084,     //VSPEED ft/s
        3.28084,     //DISTANCE ft
        1.0/1609.34, //DISTANCE_LONG miles
        1.8,         //TEMPERATURE F
    };
    static const float scale_SI[UNIT_TYPE_LAST] = {
        1.0,       //ALTITUDE m
        1.0,       //SPEED m/s
        1.0,       //VSPEED m/s
        1.0,       //DISTANCE m
        1.0/1000,  //DISTANCE_LONG km
        1.0,       //TEMPERATURE C
    };
    static const float scale_aviation[UNIT_TYPE_LAST] = {
        3.28084,   //ALTITUDE Ft
        1.94384,   //SPEED Knots
        196.85,    //VSPEED ft/min
        3.28084,   //DISTANCE ft
        0.000539957,  //DISTANCE_LONG Nm
        1.0,       //TEMPERATURE C
    };
--]]--











local frameTypes = {}
-- copter
frameTypes[0]   = "c"
frameTypes[2]   = "c"
frameTypes[3]   = "c"
frameTypes[4]   = "c"
frameTypes[13]  = "c"
frameTypes[14]  = "c"
frameTypes[15]  = "c"
frameTypes[29]  = "c"
-- plane
frameTypes[1]   = "p"
frameTypes[16]  = "p"
frameTypes[19]  = "p"
frameTypes[20]  = "p"
frameTypes[21]  = "p"
frameTypes[22]  = "p"
frameTypes[23]  = "p"
frameTypes[24]  = "p"
frameTypes[25]  = "p"
frameTypes[28]  = "p"
-- rover
frameTypes[10]  = "r"
-- boat
frameTypes[11]  = "b"

--
local frame = {}
--
local soundFileBasePath = "/SOUNDS/yaapu0"
local gpsStatuses = {}
--
gpsStatuses[0]="NoGPS"
gpsStatuses[1]="NoLock"
gpsStatuses[2]="2D"
gpsStatuses[3]="3D"
gpsStatuses[4]="DGPS"
gpsStatuses[5]="RTK"
gpsStatuses[6]="RTK"

-- EMR,ALR,CRT,ERR,WRN,NOT,INF,DBG
--
--------------------------------
-- FLVSS 1
local cell1min = 0
local cell1sum = 0
-- FLVSS 2
local cell2min = 0
local cell2sum = 0
-- FC 1
local cell1sumFC = 0
-- used to calculate cellcount
local cell1maxFC = 0
-- FC 2
local cell2sumFC = 0
-- A2
local cellsumA2 = 0
-- used to calculate cellcount
local cellmaxA2 = 0
--------------------------------
-- STATUS
local flightMode = 0
local simpleMode = 0
local landComplete = 0
local statusArmed = 0
local battFailsafe = 0
local ekfFailsafe = 0
local imuTemp = 0
-- GPS
local numSats = 0
local gpsStatus = 0
local gpsHdopC = 100
local gpsAlt = 0
-- BATT
local cellcount = 0
local battsource = "na"
-- BATT 1
local batt1volt = 0
local batt1current = 0
local batt1mah = 0
local batt1sources = {
  a2 = false,
  vs = false,
  fc = false
}
-- BATT 2
local batt2volt = 0
local batt2current = 0
local batt2mah = 0
local batt2sources = {
  a2 = false,
  vs = false,
  fc = false
}
-- TELEMETRY
local noTelemetryData = 1
-- HOME
local homeDist = 0
local homeAlt = 0
local homeAngle = -1
-- MESSAGES
local msgBuffer = ""
local lastMsgValue = 0
local lastMsgTime = 0
-- VELANDYAW
local vSpeed = 0
local hSpeed = 0
local yaw = 0
-- SYNTH VSPEED SUPPORT
local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0
-- ROLLPITCH
local roll = 0
local pitch = 0
local range = 0 
-- PARAMS
local frameType = -1
local batt1Capacity = 0
local batt2Capacity = 0
-- FLIGHT TIME
--[[ migrated to model.timer(2)
local seconds = 0
--]]local lastTimerStart = 0
local timerRunning = 0
local flightTime = 0
-- EVENTS
local lastStatusArmed = 0
local lastGpsStatus = 0
local lastFlightMode = 0
local lastSimpleMode = 0
-- battery levels
local batLevel = 99
local battLevel1 = false
local battLevel2 = false
--
local lastBattLevel = 13
--
-- 00 05 10 15 20 25 30 40 50 60 70 80 90
-- dual battery
local showDualBattery = false
--


--
local minmaxValues = {}
-- min
minmaxValues[1] = 0
minmaxValues[2] = 0
minmaxValues[3] = 0
minmaxValues[4] = 0
minmaxValues[5] = 0
minmaxValues[6] = 0
minmaxValues[7] = 0
-- max
minmaxValues[8] = 0
minmaxValues[9] = 0
minmaxValues[10] = 0
minmaxValues[11] = 0
minmaxValues[12] = 0
minmaxValues[13] = 0
minmaxValues[14] = 0
minmaxValues[15] = 0
minmaxValues[16] = 0
minmaxValues[17] = 0

local showMinMaxValues = false
-- messages
local lastMessage
local lastMessageSeverity = 0
local lastMessageCount = 1
local messageCount = 0
local messages = {}
--
--
--

  

























--------------------------------------------------------------------------------
-- ALARMS
--------------------------------------------------------------------------------
--[[
 ALARM_TYPE_MIN needs arming (min has to be reached first), value below level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_MAX no arming, value above level for grace, once armed is periodic, reset on landing
 ALARM_TYPE_TIMER no arming, fired periodically, spoken time, reset on landing
 ALARM_TYPE_BATT needs arming (min has to be reached first), value below level for grace, no reset on landing
{ 
  1 = notified, 
  2 = alarm start, 
  3 = armed, 
  4 = type(0=min,1=max,2=timer,3=batt), 
  5 = grace duration
  6 = ready
  7 = last alarm
}  
--]]--
--
--
--
local alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}  
    { false, 0 , false, 0, 0, false, 0}, --MIN_ALT
    { false, 0 , true, 1 , 0, false, 0 }, --MAX_ALT
    { false, 0 , true, 1 , 0, false, 0 }, --16
    { false, 0 , true, 1 , 0, false, 0 }, --FS_EKF
    { false, 0 , true, 1 , 0, false, 0 }, --FS_BAT
    { false, 0 , true, 2, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, 3, 4, false, 0 }, --BATT L1
    { false, 0 , false, 3, 4, false, 0 } --BATT L2
}

--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------
-- X-Lite Support


  


local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0
}

local menuItems = {
  {"voice language:", 1, "L1", 1, { "english", "italian", "french", "german" } , {"en","it","fr","de"} },
  {"batt alert level 1:", 0, "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", 0, "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] capacity override:", 0, "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] capacity override:", 0, "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"disable all sounds:", 1, "S1", 1, { "no", "yes" }, { false, true } },
  {"disable msg beep:", 1, "S2", 1, { "no", "yes" }, { false, true } },
  {"disable msg blink:", 1, "S3", 1, { "no", "yes" }, { false, true } },
  {"default voltage source:", 1, "VS", 1, { "auto", "FLVSS", "A2", "fc" }, { nil, "vs", "a2", "fc" } },
  {"timer alert every:", 0, "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", 0, "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", 0, "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", 0, "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", 0, "T2", 10, 5,600,"sec",0,5 },
  {"cell count override:", 0, "CC", 0, 0,12," cells",0,1 },
  {"rangefinder max:", 0, "RM", 0, 0,10000," cm",0,10 },
  {"enable synthetic vspeed:", 1, "SVS", 1, { "no", "yes" }, { false, true } },
  {"air/groundspeed unit:", 1, "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vert speed unit:", 1, "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
}


local modelInfo = model.getInfo()
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084


local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"

local function getConfigFilename()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(modelInfo.name, "[%c%p%s%z]", "")..".cfg")
end

local function applyConfigValues()
  if menuItems[9][6][menuItems[9][4]] ~= nil then
    battsource = menuItems[9][6][menuItems[9][4]]
  end
  collectgarbage()
end

local function loadConfig()
  local cfg = io.open(getConfigFilename(),"r")
  if cfg == nil then
    return
  end
  local str = io.read(cfg,200)
  if string.len(str) > 0 then
    for i=1,#menuItems
    do
		local value = string.match(str, menuItems[i][3]..":(%d+)")
		if value ~= nil then
		  menuItems[i][4] = tonumber(value)
		end
    end
  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function saveConfig()
  local cfg = assert(io.open(getConfigFilename(),"w"))
  if cfg == nil then
    return
  end
  for i=1,#menuItems
  do
    io.write(cfg,menuItems[i][3],":",menuItems[i][4])
    if i < #menuItems then
      io.write(cfg,",")
    end
  end
  if cfg 	~= nil then
    io.close(cfg)
  end
  applyConfigValues()
end

local function drawConfigMenuBars()
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
  lcd.drawFilledRectangle(0,0, 212, 7, SOLID)
  lcd.drawRectangle(0, 0, 212, 7, SOLID)
  lcd.drawText(0,0,"Yaapu X9 telemetry script 1.7.1",SMLSIZE+INVERS)
  lcd.drawFilledRectangle(0,56, 212, 8, SOLID)
  lcd.drawRectangle(0, 56, 212, 8, SOLID)
  lcd.drawText(0,56+1,getConfigFilename(),SMLSIZE+INVERS)
  lcd.drawText(212,56+1,itemIdx,SMLSIZE+INVERS+RIGHT)
end

local function incMenuItem(idx)
  if menuItems[idx][2] == 0 then
    menuItems[idx][4] = menuItems[idx][4] + menuItems[idx][9]
    if menuItems[idx][4] > menuItems[idx][6] then
      menuItems[idx][4] = menuItems[idx][6]
    end
  else
    menuItems[idx][4] = menuItems[idx][4] + 1
    if menuItems[idx][4] > #menuItems[idx][5] then
      menuItems[idx][4] = 1
    end
  end
end

local function decMenuItem(idx)
  if menuItems[idx][2] == 0 then
    menuItems[idx][4] = menuItems[idx][4] - menuItems[idx][9]
    if menuItems[idx][4] < menuItems[idx][5] then
      menuItems[idx][4] = menuItems[idx][5]
    end
  else
    menuItems[idx][4] = menuItems[idx][4] - 1
    if menuItems[idx][4] < 1 then
      menuItems[idx][4] = #menuItems[idx][5]
    end
  end
end

local function drawItem(idx,flags)
  if menuItems[idx][2] == 0 then
    if menuItems[idx][4] == 0 then
      lcd.drawText(150,7 + (idx-menu.offset-1)*7, "---",0+SMLSIZE+flags+menuItems[idx][8])
    else
      lcd.drawNumber(150,7 + (idx-menu.offset-1)*7, menuItems[idx][4],0+SMLSIZE+flags+menuItems[idx][8])
      lcd.drawText(lcd.getLastRightPos(),7 + (idx-menu.offset-1)*7, menuItems[idx][7],SMLSIZE+flags)
    end
  else
    lcd.drawText(150,7 + (idx-menu.offset-1)*7, menuItems[idx][5][menuItems[idx][4]],SMLSIZE+flags)
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  if event == EVT_ENTER_BREAK or event == 34 then
	menu.editSelected = not menu.editSelected
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == EVT_PLUS_REPT or event == 36 or event == 68) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_MINUS_REPT or event == 35 or event == 67) then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == 36) then
    menu.selectedItem = (menu.selectedItem - 1)
    if menu.offset >=  menu.selectedItem then
      menu.offset = menu.offset - 1
    end
  elseif not menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == 35) then
    menu.selectedItem = (menu.selectedItem + 1)
    if menu.selectedItem - 7 > menu.offset then
      menu.offset = menu.offset + 1
    end
  end
  --wrap
  if menu.selectedItem > #menuItems then
    menu.selectedItem = 1 
    menu.offset = 0
  elseif menu.selectedItem  < 1 then
    menu.selectedItem = #menuItems
    -- 
    menu.offset = 12
  end
  --
  for m=1+menu.offset,math.min(#menuItems,7+menu.offset) do
    lcd.drawText(2,7 + (m-menu.offset-1)*7, menuItems[m][1],0+SMLSIZE)
    if m == menu.selectedItem then
      if menu.editSelected then
        drawItem(m,INVERS+BLINK)
      else
        drawItem(m,INVERS)
      end
    else
      drawItem(m,0)
    end
  end
end
-----------------------
-- SOUNDS
-----------------------
local function playSound(soundFile)
  if menuItems[6][6][menuItems[6][4]] then
    return
  end
  playFile(soundFileBasePath .."/"..menuItems[1][6][menuItems[1][4]].."/".. soundFile..".wav")
end
----------------------------------------------
-- NOTE: sound file has same name as flightmode all lowercase with .wav extension
----------------------------------------------
local function playSoundByFrameTypeAndFlightMode(frameType,flightMode)
  if menuItems[6][6][menuItems[6][4]] then
    return
  end
  if frame.flightModes then
    if frame.flightModes[flightMode] ~= nil then
      playFile(soundFileBasePath.."/"..menuItems[1][6][menuItems[1][4]].."/".. string.lower(frame.flightModes[flightMode])..".wav")
    end
  end
end

local function drawHArrow(x,y,width,left,right)
  lcd.drawLine(x, y, x + width,y, SOLID, 0)
  if left == true then
    lcd.drawLine(x + 1,y  - 1,x + 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + 1,x + 2,y  + 2, SOLID, 0)
  end
  if right == true then
    lcd.drawLine(x + width - 1,y  - 1,x + width - 2,y  - 2, SOLID, 0)
    lcd.drawLine(x + width - 1,y  + 1,x + width - 2,y  + 2, SOLID, 0)
  end
end

local function drawVArrow(x,y,h,top,bottom)
  lcd.drawLine(x,y,x,y + h, SOLID, 0)
  if top == true then
    lcd.drawLine(x - 1,y + 1,x - 2,y  + 2, SOLID, 0)
    lcd.drawLine(x + 1,y + 1,x + 2,y  + 2, SOLID, 0)
  end
  if bottom == true then
    lcd.drawLine(x - 1,y  + h - 1,x - 2,y + h - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + h - 1,x + 2,y + h - 2, SOLID, 0)
  end
end
--
local function drawHomeIcon(x,y)
  lcd.drawRectangle(x,y,5,5,SOLID)
  lcd.drawLine(x+2,y+3,x+2,y+4,SOLID,FORCE)
  lcd.drawPoint(x+2,y-1,FORCE)
  lcd.drawLine(x,y+1,x+5,y+1,SOLID,FORCE)
  lcd.drawLine(x-1,y+1,x+2,y-2,SOLID, FORCE)
  lcd.drawLine(x+5,y+1,x+3,y-1,SOLID, FORCE)
end


local function computeOutCode(x,y,xmin,ymin,xmax,ymax)
    local code = 0; --initialised as being inside of hud
    --
    if x < xmin then --to the left of hud
        code = bit32.bor(code,1);
    elseif x > xmax then --to the right of hud
        code = bit32.bor(code,2);
    end
    if y < ymin then --below the hud
        code = bit32.bor(code,4);
    elseif y > ymax then --above the hud
        code = bit32.bor(code,8);
    end
    --
    return code;
end

-- Cohen–Sutherland clipping algorithm
-- https://en.wikipedia.org/wiki/Cohen%E2%80%93Sutherland_algorithm
local function drawLineWithClipping(ox,oy,angle,len,style,xmin,xmax,ymin,ymax)
  --
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  --
  local x0 = ox - xx
  local x1 = ox + xx
  local y0 = oy - yy
  local y1 = oy + yy    
  -- compute outcodes for P0, P1, and whatever point lies outside the clip rectangle
  local outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax);
  local outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax);
  local accept = false;

  while (true) do
    if ( bit32.bor(outcode0,outcode1) == 0) then
      -- bitwise OR is 0: both points inside window; trivially accept and exit loop
      accept = true;
      break;
    elseif (bit32.band(outcode0,outcode1) ~= 0) then
      -- bitwise AND is not 0: both points share an outside zone (LEFT, RIGHT, TOP, BOTTOM)
      -- both must be outside window; exit loop (accept is false)
      break;
    else
      -- failed both tests, so calculate the line segment to clip
      -- from an outside point to an intersection with clip edge
      local x = 0
      local y = 0
      -- At least one endpoint is outside the clip rectangle; pick it.
      local outcodeOut = outcode0 ~= 0 and outcode0 or outcode1
      -- No need to worry about divide-by-zero because, in each case, the
      -- outcode bit being tested guarantees the denominator is non-zero
      if bit32.band(outcodeOut,8) ~= 0 then --point is above the clip window
        x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
        y = ymax
      elseif bit32.band(outcodeOut,4) ~= 0 then --point is below the clip window
        x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
        y = ymin
      elseif bit32.band(outcodeOut,2) ~= 0 then --point is to the right of clip window
        y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
        x = xmax
      elseif bit32.band(outcodeOut,1) ~= 0 then --point is to the left of clip window
        y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
        x = xmin
      end
      -- Now we move outside point to intersection point to clip
      -- and get ready for next pass.
      if outcodeOut == outcode0 then
        x0 = x
        y0 = y
        outcode0 = computeOutCode(x0, y0, xmin, ymin, xmax, ymax)
      else
        x1 = x
        y1 = y
        outcode1 = computeOutCode(x1, y1, xmin, ymin, xmax, ymax)
      end
    end
  end
  if accept then
    lcd.drawLine(x0,y0,x1,y1, style,0)
  end
end


local function drawNumberWithTwoDims(x,y,yTop,yBottom,number,topDim,bottomDim,flags,topFlags,bottomFlags)
  -- +0.5 because PREC2 does a math.floor() and not a math.round()
  lcd.drawNumber(x, y, number + 0.5, flags)
  local lx = lcd.getLastRightPos()
  lcd.drawText(lx, yTop, topDim, topFlags)
  lcd.drawText(lx, yBottom, bottomDim, bottomFlags)
end

local function drawNumberWithDim(x,y,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(lcd.getLastRightPos(), yDim, dim, dimFlags)
end



local function formatMessage(severity,msg)
  if lastMessageCount > 1 then
    if #msg > 36 then
      msg = string.sub(msg,1,36)
    end
    return string.format("%02d:%s %s (x%d)", messageCount, string.sub("EMRALRCRTERRWRNNOTINFDBG",severity*3+1,severity*3+3), msg, lastMessageCount)
  else
    if #msg > 40 then
      msg = string.sub(msg,1,40)
    end
    return string.format("%02d:%s %s", messageCount, string.sub("EMRALRCRTERRWRNNOTINFDBG",severity*3+1,severity*3+3), msg)
  end
end


local function pushMessage(severity, msg)
  if  menuItems[7][6][menuItems[7][4]] == false and menuItems[6][6][menuItems[6][4]] == false then
    if ( severity < 5) then
      playSound("../err")
    else
      playSound("../inf")
    end
  end
  -- check if wrapping is needed
  if #messages == 9 and msg ~= lastMessage then
    for i=1,9-1 do
      messages[i]=messages[i+1]
    end
    -- trunc at 9
    messages[9] = nil
  end
  -- is it a duplicate?
  if msg == lastMessage then
    lastMessageCount = lastMessageCount + 1
    messages[#messages] = formatMessage(severity,msg)
  else  
    lastMessageCount = 1
    messageCount = messageCount + 1
    messages[#messages+1] = formatMessage(severity,msg)
  end
  lastMessage = msg
  lastMessageSeverity = severity
  collectgarbage()
  maxmem = 0
end
--
local function startTimer()
  lastTimerStart = getTime()/100
  model.setTimer(2,{mode=1})
end

local function stopTimer()
  model.setTimer(2,{mode=0})
  lastTimerStart = 0
end


-----------------------------------------------------------------
-- TELEMETRY
-----------------------------------------------------------------
--
local function processTelemetry()
  local SENSOR_ID,FRAME_ID,DATA_ID,VALUE
  SENSOR_ID,FRAME_ID,DATA_ID,VALUE = sportTelemetryPop()
  if ( FRAME_ID == 0x10) then
    noTelemetryData = 0
    if ( DATA_ID == 0x5006) then -- ROLLPITCH
      -- roll [0,1800] ==> [-180,180]
      roll = (math.min(bit32.extract(VALUE,0,11),1800) - 900) * 0.2
      -- pitch [0,900] ==> [-90,90]
      pitch = (math.min(bit32.extract(VALUE,11,10),900) - 450) * 0.2
      -- number encoded on 11 bits: 10 bits for digits + 1 for 10^power
      range = bit32.extract(VALUE,22,10) * (10^bit32.extract(VALUE,21,1)) -- cm
    elseif ( DATA_ID == 0x5005) then -- VELANDYAW
      vSpeed = bit32.extract(VALUE,1,7) * (10^bit32.extract(VALUE,0,1)) * (bit32.extract(VALUE,8,1) == 1 and -1 or 1)
      hSpeed = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      yaw = bit32.extract(VALUE,17,11) * 0.2
    elseif ( DATA_ID == 0x5001) then -- AP STATUS
      flightMode = bit32.extract(VALUE,0,5)
      simpleMode = bit32.extract(VALUE,5,2)
      landComplete = bit32.extract(VALUE,7,1)
      statusArmed = bit32.extract(VALUE,8,1)
      battFailsafe = bit32.extract(VALUE,9,1)
      ekfFailsafe = bit32.extract(VALUE,10,2)
      -- IMU temperature: 0 means temp =< 19°, 63 means temp => 82°
      imuTemp = bit32.extract(VALUE,26,6) + 19 -- C°
    elseif ( DATA_ID == 0x5002) then -- GPS STATUS
      numSats = bit32.extract(VALUE,0,4)
      -- offset  4: NO_GPS = 0, NO_FIX = 1, GPS_OK_FIX_2D = 2, GPS_OK_FIX_3D or GPS_OK_FIX_3D_DGPS or GPS_OK_FIX_3D_RTK_FLOAT or GPS_OK_FIX_3D_RTK_FIXED = 3
      -- offset 14: 0: no advanced fix, 1: GPS_OK_FIX_3D_DGPS, 2: GPS_OK_FIX_3D_RTK_FLOAT, 3: GPS_OK_FIX_3D_RTK_FIXED
      gpsStatus = bit32.extract(VALUE,4,2) + bit32.extract(VALUE,14,2)
      gpsHdopC = bit32.extract(VALUE,7,7) * (10^bit32.extract(VALUE,6,1)) -- dm
      gpsAlt = bit32.extract(VALUE,24,7) * (10^bit32.extract(VALUE,22,2)) * (bit32.extract(VALUE,31,1) == 1 and -1 or 1) -- dm
    elseif ( DATA_ID == 0x5003) then -- BATT
      batt1volt = bit32.extract(VALUE,0,9)
      batt1current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt1mah = bit32.extract(VALUE,17,15)
    elseif ( DATA_ID == 0x5008) then -- BATT2
      batt2volt = bit32.extract(VALUE,0,9)
      batt2current = bit32.extract(VALUE,10,7) * (10^bit32.extract(VALUE,9,1))
      batt2mah = bit32.extract(VALUE,17,15)
    elseif ( DATA_ID == 0x5004) then -- HOME
      homeDist = bit32.extract(VALUE,2,10) * (10^bit32.extract(VALUE,0,2))
      homeAlt = bit32.extract(VALUE,14,10) * (10^bit32.extract(VALUE,12,2)) * 0.1 * (bit32.extract(VALUE,24,1) == 1 and -1 or 1) --m
      homeAngle = bit32.extract(VALUE, 25,  7) * 3
    elseif ( DATA_ID == 0x5000) then -- MESSAGES
      if (VALUE ~= lastMsgValue) then
        lastMsgValue = VALUE
        local c1 = bit32.extract(VALUE,0,7)
        local c2 = bit32.extract(VALUE,8,7)
        local c3 = bit32.extract(VALUE,16,7)
        local c4 = bit32.extract(VALUE,24,7)
        --
        local msgEnd = false
        if (c4 ~= 0) then
          msgBuffer = msgBuffer .. string.char(c4)
        else
          msgEnd = true;
        end
        if (c3 ~= 0 and not msgEnd) then
          msgBuffer = msgBuffer .. string.char(c3)
        else
          msgEnd = true;
        end
        if (c2 ~= 0 and not msgEnd) then
          msgBuffer = msgBuffer .. string.char(c2)
        else
          msgEnd = true;
        end
        if (c1 ~= 0 and not msgEnd) then
          msgBuffer = msgBuffer .. string.char(c1)
        else
          msgEnd = true;
        end
        --[[
        _msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x4)<<21;
        _msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x2)<<14;
        _msg_chunk.chunk |= (_statustext_queue[0]->severity & 0x1)<<7;
        --]]        if (msgEnd) then
          local severity = (bit32.extract(VALUE,7,1) * 1) + (bit32.extract(VALUE,15,1) * 2) + (bit32.extract(VALUE,23,1) * 4)
          pushMessage( severity, msgBuffer)
          msgBuffer = ""
        end
    end
    elseif ( DATA_ID == 0x5007) then -- PARAMS
      paramId = bit32.extract(VALUE,24,4)
      paramValue = bit32.extract(VALUE,0,24)
      if paramId == 1 then
        frameType = paramValue
      elseif paramId == 4 then
        batt1Capacity = paramValue
      elseif paramId == 5 then
        batt2Capacity = paramValue
      end
    end
  end
end

local function telemetryEnabled()
  if getRSSI() == 0 then
    noTelemetryData = 1
  end
  return noTelemetryData == 0
end

local function getMaxValue(value,idx)
  minmaxValues[idx] = math.max(value,minmaxValues[idx])
  return showMinMaxValues == true and minmaxValues[idx] or value
end

local function calcMinValue(value,min)
  return min == 0 and value or math.min(value,min)
end

-- returns the actual minimun only if both are > 0
local function getNonZeroMin(v1,v2)
  return v1 == 0 and v2 or ( v2 == 0 and v1 or math.min(v1,v2))
end

local function calcCellCount()
  -- cellcount override from menu
  if menuItems[15][4] ~= nil and menuItems[15][4] > 0 then
    return menuItems[15][4]
  end
  -- cellcount is cached only for FLVSS
  if batt1sources.vs == true and cellcount > 1 then
    return cellcount
  end
  -- round in excess and return
  -- Note: cellcount is not cached because max voltage can rise during initialization)
  return math.floor( (( math.max(cell1maxFC,cellmaxA2)*0.1 ) / 4.36) + 1)
end

local function calcBattery()
  ------------
  -- FLVSS 1
  ------------
  local cellResult = getValue("Cels")
  if type(cellResult) == "table" then
    cell1min = 4.36
    cell1sum = 0
    -- cellcount is global and shared
    cellcount = #cellResult
    for i, v in pairs(cellResult) do
      cell1sum = cell1sum + v
      if cell1min > v then
        cell1min = v
      end
    end
    -- if connected after scritp started
    if batt1sources.vs == false then
      battsource = "na"
    end
    if battsource == "na" then
      battsource = "vs"
    end
    batt1sources.vs = true
  else
    batt1sources.vs = false
    cell1min = 0
    cell1sum = 0
  end
  ------------
  -- FLVSS 2
  ------------
  cellResult = getValue("Cel2")
  if type(cellResult) == "table" then
    cell2min = 4.36
    cell2sum = 0
    -- cellcount is global and shared
    cellcount = #cellResult
    for i, v in pairs(cellResult) do
      cell2sum = cell2sum + v
      if cell2min > v then
        cell2min = v
      end
    end
    -- if connected after scritp started
    if batt2sources.vs == false then
      battsource = "na"
    end
    if battsource == "na" then
      battsource = "vs"
    end
    batt2sources.vs = true
  else
    batt2sources.vs = false
    cell2min = 0
    cell2sum = 0
  end
  --------------------------------
  -- flight controller battery 1
  --------------------------------
  if batt1volt > 0 then
    cell1sumFC = batt1volt*0.1
    cell1maxFC = math.max(batt1volt,cell1maxFC)
    if battsource == "na" then
      battsource = "fc"
    end
    batt1sources.fc = true
  else
    batt1sources.fc = false
    cell1sumFC = 0
  end
  --------------------------------
  -- flight controller battery 2
  --------------------------------
  if batt2volt > 0 then
    cell2sumFC = batt2volt*0.1
    if battsource == "na" then
      battsource = "fc"
    end
    batt2sources.fc = true
  else
    batt2sources.fc = false
    cell2sumFC = 0
  end
  ----------------------------------
  -- 12 analog voltage only 1 supported
  ----------------------------------
  local battA2 = getValue("A2")
  --
  if battA2 > 0 then
    cellsumA2 = battA2
    cellmaxA2 = math.max(battA2*10,cellmaxA2)
    -- don't force a2, only way to display it
    -- is by user selection from menu
    --[[
    if battsource == "na" then
      battsource = "a2"
    end
    --]]    batt1sources.a2 = true
  else
    batt1sources.a2 = false
    cellsumA2 = 0
  end
  -- batt fc
  minmaxValues[1] = calcMinValue(cell1sumFC,minmaxValues[1])
  minmaxValues[2] = calcMinValue(cell2sumFC,minmaxValues[2])
  -- cell flvss
  minmaxValues[3] = calcMinValue(cell1min,minmaxValues[3])
  minmaxValues[4] = calcMinValue(cell2min,minmaxValues[4])
  -- batt flvss
  minmaxValues[5] = calcMinValue(cell1sum,minmaxValues[5])
  minmaxValues[6] = calcMinValue(cell2sum,minmaxValues[6])
  -- batt 12
  minmaxValues[7] = calcMinValue(cellsumA2,minmaxValues[7])
end

local function checkLandingStatus()
  if ( timerRunning == 0 and landComplete == 1 and lastTimerStart == 0) then
    startTimer()
  end
  if (timerRunning == 1 and landComplete == 0 and lastTimerStart ~= 0) then
    stopTimer()
    -- play landing complete only if motorts are armed
    if statusArmed == 1 then
      playSound("landing")
    end
  end
  timerRunning = landComplete
end

local function calcFlightTime() 
  -- update local variable with timer 3 value
  flightTime = model.getTimer(2).value
end

local function getBatt1Capacity()
  return menuItems[4][4]*0.1 > 0 and menuItems[4][4]*0.1*100 or batt1Capacity  
end

local function getBatt2Capacity()
  return menuItems[5][4]*0.1 > 0 and menuItems[5][4]*0.1*100 or batt2Capacity  
end

-- gets the voltage based on source and min value, battId = [1|2]
local function getMinVoltageBySource(source,cell,cellFC,cellA2,battId,count)
  -- offset 0 for cell voltage, 2 for pack voltage
  local offset = 0
  --
  if cell > 4.36*2 or cellFC > 4.36*2 or cellA2 > 4.36*2 then
    offset = 2
  end
  --
  if source == "vs" then
    return showMinMaxValues == true and minmaxValues[2+offset+battId] or cell
  elseif source == "fc" then
      -- FC only tracks batt1 and batt2 no cell voltage tracking
      local minmax = (offset == 2 and minmaxValues[battId] or minmaxValues[battId]/count)
      return showMinMaxValues == true and minmax or cellFC
  elseif source == "a2" then
      -- 12 does not depend on battery id
      local minmax = (offset == 2 and minmaxValues[7] or minmaxValues[7]/count)
      return showMinMaxValues == true and minmax or cellA2
  end
  --
  return 0
end

local function setSensorValues()
  if (not telemetryEnabled()) then
    return
  end
  local battmah = batt1mah
  local battcapacity = getBatt1Capacity()
  if batt2mah > 0 then
    battcapacity =  getBatt1Capacity() + getBatt2Capacity()
    battmah = batt1mah + batt2mah
  end
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    end  
  end
  setTelemetryValue(0x060F, 0, 0, perc, 13 , 0 , "Fuel")
  setTelemetryValue(0x021F, 0, 0, getNonZeroMin(batt1volt,batt2volt)*10, 1 , 2 , "VFAS")
  setTelemetryValue(0x020F, 0, 0, batt1current+batt2current, 2 , 1 , "CURR")
  setTelemetryValue(0x011F, 0, 0, vSpeed, 5 , 1 , "VSpd")
  setTelemetryValue(0x083F, 0, 0, hSpeed*0.1, 4 , 0 , "GSpd")
  setTelemetryValue(0x010F, 0, 0, homeAlt*10, 9 , 1 , "Alt")
  setTelemetryValue(0x082F, 0, 0, math.floor(gpsAlt*0.1), 9 , 0 , "GAlt")
  setTelemetryValue(0x084F, 0, 0, math.floor(yaw), 20 , 0 , "Hdg")
  setTelemetryValue(0x041F, 0, 0, imuTemp, 11 , 0 , "IMUt")
  setTelemetryValue(0x060F, 0, 1, statusArmed*100, 0 , 0 , "ARM")
end
--------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawX9BatteryPane(x,battVolt,cellVolt,current,battmah,battcapacity)
  local perc = 0
  if (battcapacity > 0) then
    perc = (1 - (battmah/battcapacity))*100
    if perc > 99 then
      perc = 99
    end
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if showMinMaxValues == false then
    if battLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif battLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  drawNumberWithTwoDims(x+27, 11, 12, 21,cellVolt,"V",battsource,DBLSIZE+PREC2+flags,dimFlags,SMLSIZE)
  -- battery voltage
  drawNumberWithDim(x+2,43,43, battVolt,"V",MIDSIZE+PREC1,SMLSIZE)
  -- battery current
  drawNumberWithDim(x+37,43,43,current,"A",MIDSIZE+PREC1,SMLSIZE)
  -- battery percentage
  lcd.drawNumber(x+4, 15, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos(), 20, "%", SMLSIZE)
  -- display capacity bar %
  lcd.drawFilledRectangle(x+5, 28, 2 + math.floor(perc * 0.01 * (59 - 3)), 5, SOLID)
  lcd.drawRectangle(x+5, 28, 2 + math.floor(perc * 0.01 * (59 - 3)), 5, SOLID)
  local step = 59/10
  for s=1,10 - 1 do
    lcd.drawLine(x+5 + s*step - 1,28, x+5 + s*step - 1, 28 + 5 - 1,SOLID,0)
  end
  -- battery mah
  lcd.drawNumber(x+10, 35, battmah/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 35, "/", SMLSIZE)
  lcd.drawNumber(lcd.getLastRightPos(), 35, battcapacity/100, SMLSIZE+PREC1)
  lcd.drawText(lcd.getLastRightPos(), 35, "Ah", SMLSIZE)
  if showMinMaxValues == true then
    drawVArrow(x+2+29,43 + 6, 5,false,true)
    drawVArrow(x+37+27,43 + 6,5,true,false)
    drawVArrow(x+27+37, 11 + 3,6,false,true)
  end
end



local function drawNoTelemetryData()
  -- no telemetry data
  if (not telemetryEnabled()) then
    lcd.drawFilledRectangle((212-130)/2,18, 130, 30, SOLID)
    lcd.drawRectangle((212-130)/2,18, 130, 30, ERASE)
    lcd.drawText(60, 29, "no telemetry data", INVERS)
    return
  end
end

local function drawTopBar()
  -- black bar
  lcd.drawFilledRectangle(0,0, 212, 7, SOLID)
  lcd.drawRectangle(0, 0, 212, 7, SOLID)
  -- flight mode
  if frame.flightModes then
    local strMode = frame.flightModes[flightMode]
    if strMode ~= nil then
      lcd.drawText(1, 0, strMode, SMLSIZE+INVERS)
      if ( simpleMode > 0 ) then
        local strSimpleMode = simpleMode == 1 and "(S)" or "(SS)"
        lcd.drawText(lcd.getLastRightPos(), 0, strSimpleMode, SMLSIZE+INVERS)
      end
    end  
  end
  -- flight time
  lcd.drawText(179, 0, "T:", SMLSIZE+INVERS)
  lcd.drawTimer(lcd.getLastRightPos(), 0, flightTime, SMLSIZE+INVERS)
  -- RSSI
  lcd.drawText(69, 0, "RS:", SMLSIZE+INVERS )
  lcd.drawText(lcd.getLastRightPos(), 0, getRSSI(), SMLSIZE+INVERS )  
  -- tx voltage
  local vTx = string.format("Tx%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(116, 0, vTx, SMLSIZE+INVERS)
end

local function drawBottomBar()
  -- black bar
  lcd.drawFilledRectangle(0,56, 212, 8, SOLID)
  lcd.drawRectangle(0, 56, 212, 8, SOLID)
  -- message text
  local now = getTime()
  local msg = messages[#messages]
  if (now - lastMsgTime ) > 150 or menuItems[8][6][menuItems[8][4]] then
    lcd.drawText(0, 56+1, msg,SMLSIZE+INVERS)
  else
    lcd.drawText(0, 56+1, msg,SMLSIZE+INVERS+BLINK)
  end
end

local function drawAllMessages()
  for i=1,#messages do
    lcd.drawText(1, 1 + 7*(i-1), messages[i],SMLSIZE)
  end
end

local function drawX9LeftPane(battcurrent,cellsumFC)
  -- gps status
  local strStatus = gpsStatuses[gpsStatus]
  local strNumSats = ""
  local flags = BLINK
  local mult = 1
  if gpsStatus  > 2 then
    if homeAngle ~= -1 then
      flags = PREC1
    end
    if gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(0,6 + 2, strStatus, SMLSIZE)
    lcd.drawText(0,6 + 8, "fix", SMLSIZE)
    if numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",numSats)
    end
    lcd.drawText(0 + 40, 6 + 2, strNumSats, MIDSIZE+RIGHT)
    lcd.drawText(0 + 42, 6 + 2 , "H", SMLSIZE)
    lcd.drawNumber(0 + 66, 6 + 2, gpsHdopC*mult , MIDSIZE+flags+RIGHT)
    lcd.drawLine(0 + 40,6+1,0+40,6 + 14,SOLID,FORCE)
  else
    lcd.drawText(0 + 10, 6 + 2, strStatus, MIDSIZE+INVERS+BLINK)
  end  
  lcd.drawLine(0 ,6 + 15,0+66,6 + 15,SOLID,FORCE)
  if showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
  drawVArrow(4,25 - 1,7,true,true)
  if menuItems[16][4] > 0 then
    -- rng finder
    flags = 0
    local rng = range
    -- rng is centimeters, RANGE_MAX is feet
    if rng > menuItems[16][4] then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,17)
    lcd.drawText(4 + 4, 25, "Rng", SMLSIZE)
    lcd.drawText(65, 26 , unitLabel, SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos()-1, 26-1 , string.format("%.2f",rng*0.01*unitScale), RIGHT+flags)
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = gpsAlt/10 -- meters
    flags = BLINK
    if gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,13)
    end
    lcd.drawText(4 + 4, 25, "Asl", SMLSIZE)
    lcd.drawText(65, 26, unitLabel, SMLSIZE+RIGHT)
    lcd.drawText(lcd.getLastLeftPos()-1, 26-1 , string.format("%d",alt*unitScale), RIGHT+flags)
  end
  -- home distance
  drawHomeIcon(2 + 1,36,7)
  drawHArrow(2 + 10,36 + 2,8,true,true)
  flags = 0
  if homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(homeDist,16)
  if showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(65, 36-1, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 36-1, dist*unitScale, RIGHT+flags)
  -- efficiency
  local eff = hSpeed*0.1 > 2 and 1000*battcurrent*0.1/(hSpeed*0.1*menuItems[18][6][menuItems[18][4]]) or 0
  lcd.drawText(2, 45, "Eff", SMLSIZE)
  lcd.drawText(65,45,string.format("%d mAh",eff),SMLSIZE+RIGHT)
  if showMinMaxValues == true then
    drawVArrow(2 + 23, 36 - 2,6,true,false)
    drawVArrow(4 + 21, 26 - 2,6,true,false)
  end
end

local function drawFailsafe()
  local xoffset = 0
  local yoffset = 0
  if ekfFailsafe > 0 then
    lcd.drawText(xoffset + 68 + 76/2 - 31, 22 + yoffset, " EKF FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
  if battFailsafe > 0 then
    lcd.drawText(xoffset + 68 + 76/2 - 33, 22 + yoffset, " BATT FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
end


local yawRibbonPoints = {}
--
yawRibbonPoints[0]={"N",0}
yawRibbonPoints[1]={"NE",-3}
yawRibbonPoints[2]={"E",0}
yawRibbonPoints[3]={"SE",-3}
yawRibbonPoints[4]={"S",0}
yawRibbonPoints[5]={"SW",-3}
yawRibbonPoints[6]={"W",0}
yawRibbonPoints[7]={"NW",-3}

-- optimized yaw ribbon drawing
local function drawCompassRibbon()
  -- ribbon centered +/- 90 on yaw
  local centerYaw = (yaw+270)%360
  -- this is the first point left to be drawn on the compass ribbon
  local nextPoint = math.floor(centerYaw/45) * 45 --roundTo(centerYaw,45)
  -- distance in degrees between leftmost ribbon point and first 45° multiple normalized to YAW_WIDTH/8
  local yawMinX = (LCD_W - 76)/2 + 2
  local yawMaxX = (LCD_W + 76)/2 - 3
  -- x coord of first ribbon letter
  local nextPointX = yawMinX + (nextPoint - centerYaw)/45 * 17
  local yawY = 0 + 7
  --
  local i = (nextPoint / 45) % 8
  for idx=1,6
  do
      if nextPointX >= yawMinX and nextPointX < yawMaxX then
        lcd.drawText(nextPointX+yawRibbonPoints[i][2],yawY,yawRibbonPoints[i][1],SMLSIZE)
      end
      i = (i + 1) % 8
      nextPointX = nextPointX + 17
  end
  -- home icon
  local leftYaw = (yaw + 180)%360
  local rightYaw = yaw%360
  local centerHome = (homeAngle+270)%360
  --
  local homeIconX = yawMinX
  local homeIconY = yawY + 10
  if rightYaw >= leftYaw then
    if centerHome > leftYaw and centerHome < rightYaw then
      drawHomeIcon(math.min(yawMinX + ((centerHome - leftYaw)/180)*76,yawMaxX - 2),homeIconY)
    end
  else
    if centerHome < rightYaw then
      drawHomeIcon(yawMinX + (((360-leftYaw) + centerHome)/180)*76,homeIconY)
    elseif centerHome >= leftYaw then
      drawHomeIcon(math.min(yawMinX + ((centerHome-leftYaw)/180)*76,yawMaxX-2),homeIconY)
    end
  end
  -- when abs(home angle) > 90 draw home icon close to left/right border
  local angle = homeAngle - yaw
  local cos = math.cos(math.rad(angle - 90))    
  local sin = math.sin(math.rad(angle - 90))    
  if sin > 0 then
    drawHomeIcon(( cos > 0 and yawMaxX or yawMinX ) - 2, yawY + 10)
  end
  --
  lcd.drawLine(yawMinX - 2, yawY + 7, yawMaxX + 2, yawY + 7, SOLID, 0)
  local xx = yaw < 10 and 1 or ( yaw < 100 and -2 or -5 )
  lcd.drawNumber(LCD_W/2 + xx - 4, yawY, yaw, MIDSIZE+INVERS)
end

-- vertical distance between roll horiz segments
--
local function drawHud()
  local r = -roll
  local cx,cy,dx,dy,ccx,ccy,cccx,cccy
  local yPos = 0 + 7 + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 6
  if ( roll == 0) then
    dx=0
    dy=pitch
    cx=0
    cy=6
    ccx=0
    ccy=2*6
    cccx=0
    cccy=3*6
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -pitch
    dy = math.sin(math.rad(90 - r)) * pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 6
    cy = math.sin(math.rad(90 - r)) * 6
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * 6
    ccy = math.sin(math.rad(90 - r)) * 2 * 6
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * 6
    cccy = math.sin(math.rad(90 - r)) * 3 * 6
  end
  local rollX = math.floor(68 + 76/2)
  -- parallel lines above and below horizon of increasing length 5,7,16,16,7,5
  drawLineWithClipping(rollX + dx - cccx,dy + 35 + cccy,r,16,DOTTED,68,68 + 76,yPos,56 - 1)
  drawLineWithClipping(rollX + dx - ccx,dy + 35 + ccy,r,7,DOTTED,68,68 + 76,yPos,56 - 1)
  drawLineWithClipping(rollX + dx - cx,dy + 35 + cy,r,16,DOTTED,68,68 + 76,yPos,56 - 1)
  drawLineWithClipping(rollX + dx + cx,dy + 35 - cy,r,16,DOTTED,68,68 + 76,yPos,56 - 1)
  drawLineWithClipping(rollX + dx + ccx,dy + 35 - ccy,r,7,DOTTED,68,68 + 76,yPos,56 - 1)
  drawLineWithClipping(rollX + dx + cccx,dy + 35 - cccy,r,16,DOTTED,68,68 + 76,yPos,56 - 1)
  -----------------------
  -- dark color for "ground"
  -----------------------
  local minY = 16
  local maxY = 54
  local minX = 68 + 1
  local maxX = 68 + 76 - 2
  --
  local ox = 106 + dx
  --
  local oy = 35 + dy
  local yy = 0
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-roll))
  -- for each pixel of the hud base/top draw vertical black 
  -- lines from hud border to horizon line
  -- horizon line moves with pitch/roll
  for xx= minX,maxX
  do
    if roll > 90 or roll < -90 then
      yy = (oy - ox*angle) + math.floor(xx*angle)
      if yy <= minY then
      elseif yy > minY + 1 and yy < maxY then
        lcd.drawLine(0 + xx, 0 + minY, 0 + xx, 0 + yy,SOLID,0)
      elseif yy >= maxY then
        lcd.drawLine(0 + xx, 0 + minY, 0 + xx, 0 + maxY,SOLID,0)
      end
    else
      yy = (oy - ox*angle) + math.floor(xx*angle)
      if yy <= minY then
        lcd.drawLine(0 + xx, 0 + minY, 0 + xx, 0 + maxY,SOLID,0)
      elseif yy >= maxY then
      else
        lcd.drawLine(0 + xx, 0 + yy, 0 + xx, 0 + maxY,SOLID,0)
      end
    end
  end
  ------------------------------------
  -- synthetic vSpeed based on 
  -- home altitude when EKF is disabled
  -- updated at 1Hz (i.e every 1000ms)
  -------------------------------------
  if menuItems[17][6][menuItems[17][4]] == true then
    if (synthVSpeedTime == 0) then
      -- first time do nothing
      synthVSpeedTime = getTime()
      prevHomeAlt = homeAlt -- dm
    elseif (getTime() - synthVSpeedTime > 100) then
      -- calc vspeed
      vspd = 1000*(homeAlt-prevHomeAlt)/(getTime()-synthVSpeedTime) -- m/s
      -- update counters
      synthVSpeedTime = getTime()
      prevHomeAlt = homeAlt -- m
    end
  else
    vspd = vSpeed
  end
  -------------------------------------
  -- vario indicator on left
  -------------------------------------
  lcd.drawFilledRectangle(68, yPos, 7, 50, ERASE, 0)
  lcd.drawLine(68 + 5, yPos, 68 + 5, yPos + 40, SOLID, FORCE)
  local varioMax = math.log(10)
  local varioSpeed = math.log(1+math.min(math.abs(0.1*vspd),10))
  local varioY = 0
  if vspd > 0 then
    varioY = 35 - 4 - varioSpeed/varioMax*15
  else
    varioY = 35 + 6
  end
  lcd.drawFilledRectangle(68, varioY, 5, varioSpeed/varioMax*15, FORCE, 0)
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- lets erase to hide the artificial horizon lines
  -- black borders
  lcd.drawRectangle(68, 35 - 5,   20, 11, FORCE, 0)
  lcd.drawRectangle(68 + 76 -  17 - 1, 35 - 5,  17+1, 11, FORCE, 0)
  -- erase area
  lcd.drawFilledRectangle(68, 35 - 4,   20, 9, ERASE, 0)
  lcd.drawFilledRectangle(68 + 76 -  17 - 1, 35 - 4,  17+2, 9, ERASE, 0)
  -- erase tips
  lcd.drawLine(68 +   20,35 - 3,68 +   20,35 + 3, SOLID, ERASE)
  lcd.drawLine(68 +   20+1,35 - 2,68 +   20+1,35 + 2, SOLID, ERASE)
  lcd.drawLine(68 + 76 -  17 - 2,35 - 3,68 + 76 -  17 - 2,35 + 3, SOLID, ERASE)
  lcd.drawLine(68 + 76 -  17 - 3,35 - 2,68 + 76 -  17 - 3,35 + 2, SOLID, ERASE)
  -- left tip
  lcd.drawLine(68 +   20+2,35 - 2,68 +   20+2,35 + 2, SOLID, FORCE)
  lcd.drawLine(68 +   20-1,35 - 5,68 +   20+1,35 - 3, SOLID, FORCE)
  lcd.drawLine(68 +   20-1,35 + 5,68 +   20+1,35 + 3, SOLID, FORCE)
  -- right tip
  lcd.drawLine(68 + 76 -  17 - 4,35 - 2,68 + 76 -  17 - 4,35 + 2, SOLID, FORCE)
  lcd.drawLine(68 + 76 -  17 - 3,35 - 3,68 + 76 -  17 - 1,35 - 5, SOLID, FORCE)
  lcd.drawLine(68 + 76 -  17 - 3,35 + 3,68 + 76 -  17 - 1,35 + 5, SOLID, FORCE)
    -- altitude
  local alt = getMaxValue(homeAlt,12) * unitScale -- homeAlt is meters*3.28 = feet
  --
  if math.abs(alt) < 10 then
      lcd.drawNumber(68 + 76,35 - 3,alt * 10,SMLSIZE+PREC1+RIGHT)
  else
      lcd.drawNumber(68 + 76,35 - 3,alt,SMLSIZE+RIGHT)
  end
  -- vertical speed
  if math.abs(vspd*3.28*60) > 99 then
    lcd.drawNumber(68+1,35 - 3,vspd*0.1*menuItems[19][6][menuItems[19][4]],SMLSIZE)
  else
    lcd.drawNumber(68+1,35 - 3,vspd*menuItems[19][6][menuItems[19][4]],SMLSIZE+PREC1)
  end
  -- center arrow
  local arrowX = math.floor(68 + 76/2)
  lcd.drawLine(arrowX - 4,35 + 4,arrowX ,35 ,SOLID,0)
  lcd.drawLine(arrowX + 1,35 + 1,arrowX + 4, 35 + 4,SOLID,0)
  lcd.drawLine(68 + 25,35,68 + 30,35 ,SOLID,0)
  lcd.drawLine(68 + 76 - 24,35,68 + 76 - 31,35 ,SOLID,0)
  -- hspeed
  local speed = getMaxValue(hSpeed,15) * menuItems[18][6][menuItems[18][4]]
--
  lcd.drawFilledRectangle((LCD_W)/2 - 10, LCD_H - 17, 20, 10, ERASE, 0)
  if math.abs(speed) > 99 then -- 
    lcd.drawNumber((LCD_W)/2 + 9, LCD_H - 15, speed*0.1, SMLSIZE+RIGHT)
  else
    lcd.drawNumber((LCD_W)/2 + 9, LCD_H - 15, speed, SMLSIZE+RIGHT+PREC1)
  end
  -- hspeed box
  lcd.drawRectangle((LCD_W)/2 - 10, LCD_H - 17, 20, 10, SOLID, FORCE)
  if showMinMaxValues == true then
    drawVArrow((LCD_W)/2 + 12,LCD_H - 16,6,true,false)
  end
  -- min/max arrows
  if showMinMaxValues == true then
    drawVArrow(68 + 76 - 24, 35 - 4,6,true,false)
  end
  -- arming status, show only if timer is not running, hide otherwise
  if ekfFailsafe == 0 and battFailsafe == 0 and timerRunning == 0 then
    if (statusArmed == 1) then
      lcd.drawText(68 + 76/2 - 15, 22, " ARMED ", SMLSIZE+INVERS)
    else
      lcd.drawText(68 + 76/2 - 21, 22, " DISARMED ", SMLSIZE+INVERS+BLINK)
    end
  end
end

local function drawGrid()
  lcd.drawLine(68 - 1, 7 ,68 - 1, 57, SOLID, 0)
  lcd.drawLine(68 + 76, 7, 68 + 76, 57, SOLID, 0)
end

local function drawHomeDirection()
  local angle = math.floor(homeAngle - yaw)
  local x1 = 82 + 7 * math.cos(math.rad(angle - 90))
  local y1 = 48 + 7 * math.sin(math.rad(angle - 90))
  local x2 = 82 + 7 * math.cos(math.rad(angle - 90 + 150))
  local y2 = 48 + 7 * math.sin(math.rad(angle - 90 + 150))
  local x3 = 82 + 7 * math.cos(math.rad(angle - 90 - 150))
  local y3 = 48 + 7 * math.sin(math.rad(angle - 90 - 150))
  local x4 = 82 + 7 * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = 48 + 7 * 0.5 *math.sin(math.rad(angle - 270))
  --
  lcd.drawLine(x1,y1,x2,y2,SOLID,1)
  lcd.drawLine(x1,y1,x3,y3,SOLID,1)
  lcd.drawLine(x2,y2,x4,y4,SOLID,1)
  lcd.drawLine(x3,y3,x4,y4,SOLID,1)
end


---------------------------------
-- This function checks alarm condition and as long as the condition persists it plays
-- a warning sound.
---------------------------------
local function checkAlarm(level,value,idx,sign,sound,delay)
  -- once landed reset all alarms except battery alerts
  if timerRunning == 0 then
    if alarms[idx][4] == 0 then
      alarms[idx] = { false, 0, false, 0, 0, false, 0} 
    elseif alarms[idx][4] == 1  then
      alarms[idx] = { false, 0, true, 1 , 0, false, 0}
    elseif  alarms[idx][4] == 2 then
      alarms[idx] = { false, 0, true, 2, 0, false, 0}
    elseif  alarms[idx][4] == 3 then
      alarms[idx] = { false, 0 , false, 3, 4, false, 0}
    end
    -- reset done
    return
  end
  -- if needed arm the alarm only after value has reached level  
  if alarms[idx][3] == false and level > 0 and -1 * sign*value > -1 * sign*level then
    alarms[idx][3] = true
  end
  --
  if alarms[idx][4] == 2 then
    if flightTime > 0 and math.floor(flightTime) %  delay == 0 then
      if alarms[idx][1] == false then 
        alarms[idx][1] = true
        playSound(sound)
         -- flightime is a multiple of 1 minute
        if (flightTime % 60 == 0 ) then
          -- minutes
          playNumber(flightTime / 60,25) --25=minutes,26=seconds
        else
          -- minutes
          if (flightTime > 60) then playNumber(flightTime / 60,25) end
          -- seconds
          playNumber(flightTime % 60,26)
        end
      end
    else
        alarms[idx][1] = false
    end
  else
    if alarms[idx][3] == true then
      if level > 0 and sign*value > sign*level then
        -- value is outside level 
        if alarms[idx][2] == 0 then
          -- first time outside level after last reset
          alarms[idx][2] = flightTime
          -- status: START
        end
      else
        -- value back to normal ==> reset
        alarms[idx][2] = 0
        alarms[idx][1] = false
        alarms[idx][6] = false
        -- status: RESET
      end
      if alarms[idx][2] > 0 and (flightTime ~= alarms[idx][2]) and (flightTime - alarms[idx][2]) >= alarms[idx][5] then
        -- enough time has passed after START
        alarms[idx][6] = true
        -- status: READY
      end
      --
      if alarms[idx][6] == true and alarms[idx][1] == false then 
        playSound(sound)
        alarms[idx][1] = true
        alarms[idx][7] = flightTime
        -- status: BEEP
      end
      -- all but battery alarms
      if alarms[idx][4] ~= 3 then
        if alarms[idx][6] == true and flightTime ~= alarms[idx][7] and (flightTime - alarms[idx][7]) %  delay == 0 then
          alarms[idx][1] = false
          -- status: REPEAT
        end
      end
    end
  end
end

local function loadFlightModes()
  if frame.flightModes then
    return
  end
  if frameType ~= -1 then
    if frameTypes[frameType] == "c" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/copter.luac")
    elseif frameTypes[frameType] == "p" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/plane.luac")
    elseif frameTypes[frameType] == "r" then
      frame = dofile("/SCRIPTS/TELEMETRY/yaapu/rover.luac")
    end
    if frame.flightModes then
      for i,v in pairs(frameTypes) do
        frameTypes[i] = nil
      end
      frameTypes = nil
    end
    collectgarbage()
    maxmem=0
  end
end

local function checkEvents()
  loadFlightModes()
  checkAlarm(menuItems[11][4]*0.1,homeAlt,1,-1,"minalt",menuItems[14][4])
  checkAlarm(menuItems[12][4],homeAlt,2,1,"maxalt",menuItems[14][4])  
  checkAlarm(menuItems[13][4],homeDist,3,1,"maxdist",menuItems[14][4])
  checkAlarm(1,2*ekfFailsafe,4,1,"ekf",menuItems[14][4])  
  checkAlarm(1,2*battFailsafe,5,1,"lowbat",menuItems[14][4])  
  checkAlarm(math.floor(menuItems[10][4]*0.1*60),flightTime,6,1,"timealert",math.floor(menuItems[10][4]*0.1*60))
  --
  local capacity = getBatt1Capacity()
  local mah = batt1mah
  -- only if dual battery has been detected
  if batt2sources.fc or batt2sources.vs then
      capacity = capacity + getBatt2Capacity()
      mah = mah  + batt2mah
  end
  if (capacity > 0) then
    batLevel = (1 - (mah/capacity))*100
  else
    batLevel = 99
  end

  for l=0,12 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    local level = tonumber(string.sub("00051015202530405060708090",l*2+1,l*2+2))
    if batLevel <= level + 1 and l < lastBattLevel then
      lastBattLevel = l
      playSound("bat"..level)
      break
    end
  end
  --
  if statusArmed ~= lastStatusArmed then
    if statusArmed == 1 then playSound("armed") else playSound("disarmed") end
    lastStatusArmed = statusArmed
  end
  --
  if gpsStatus > 2 and lastGpsStatus <= 2 then
    lastGpsStatus = gpsStatus
    playSound("gpsfix")
  elseif gpsStatus <= 2 and lastGpsStatus > 2 then
    lastGpsStatus = gpsStatus
    playSound("gpsnofix")
  end
  --
  if frame.flightModes ~= nil and flightMode ~= lastFlightMode then
    lastFlightMode = flightMode
    playSoundByFrameTypeAndFlightMode(frameType,flightMode)
  end
  --
  if simpleMode ~= lastSimpleMode then
    if simpleMode == 0 then
      playSound( lastSimpleMode == 1 and "simpleoff" or "ssimpleoff" )
    else
      playSound( simpleMode == 1 and "simpleon" or "ssimpleon" )
    end
    lastSimpleMode = simpleMode
  end
end

local function checkCellVoltage(celm)
  -- check alarms
  checkAlarm(menuItems[2][4],celm,7,-1,"batalert1",menuItems[14][4])
  checkAlarm(menuItems[3][4],celm,8,-1,"batalert2",menuItems[14][4])
  -- cell bgcolor is sticky but gets triggered with alarms
  if battLevel1 == false then battLevel1 = alarms[7][1] end
  if battLevel2 == false then battLevel2 = alarms[8][1] end
end

local function cycleBatteryInfo()
  if showDualBattery == false and (batt2sources.fc or batt2sources.vs) then
    showDualBattery = true
    return
  end
  if battsource == "vs" then
    battsource = "fc"
  elseif battsource == "fc" then
    battsource = "a2"
  elseif battsource == "a2" then
    battsource = "vs"
  end
end
--------------------------------------------------------------------------------
-- MAIN LOOP
--------------------------------------------------------------------------------
local showMessages = false
local showConfigMenu = false
local bgclock = 0

-------------------------------
-- running at 20Hz (every 50ms)
-------------------------------
local function background()
  -- FAST: this runs at 60Hz (every 16ms)
  for i=1,3
  do
    processTelemetry()
end
  --[[
  -- NORMAL: this runs at 10Hz (every 100ms)
  if telemetryEnabled() and (bgclock % 2 == 0) then
    setTelemetryValue(VSpd_ID, VSpd_SUBID, VSpd_INSTANCE, vSpeed, 5 , VSpd_PRECISION , VSpd_NAME)
  end
  --]]  -- SLOW: this runs at 4Hz (every 250ms)
  if (bgclock % 4 == 0) then
    setSensorValues()
  end
  -- SLOWER: this runs at 2Hz (every 500ms)
  if (bgclock % 8 == 0) then
    calcBattery()
    calcFlightTime()
    -- prepare celm based on battsource
    local count = calcCellCount()
    local cellVoltage = 0
    --
    if battsource == "vs" then
      cellVoltage = getNonZeroMin(cell1min,cell2min)*100 --FLVSS
    elseif battsource == "fc" then
      cellVoltage = getNonZeroMin(cell1sumFC/count,cell2sumFC/count)*100 --FC
    elseif battsource == "a2" then
      cellVoltage = (cellsumA2/count)*100 --12
    end
    --
    checkEvents()
    checkLandingStatus()
    -- no need for alarms if reported voltage is 0
    if cellVoltage > 0 then
      checkCellVoltage(cellVoltage)
    end
    -- aggregate value
    minmaxValues[8] = math.max(batt1current+batt2current,minmaxValues[8])
    -- indipendent values
    minmaxValues[9] = math.max(batt1current,minmaxValues[9])
    minmaxValues[10] = math.max(batt2current,minmaxValues[10])
    bgclock=0
  end
  bgclock = bgclock+1
end

local function run(event)
  lcd.clear()
  ---------------------
  -- SHOW MESSAGES
  ---------------------
  if showConfigMenu == false and (event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == 36) then
    showMessages = true
    collectgarbage()
  end
  ---------------------
  -- SHOW CONFIG MENU
  ---------------------
  if showMessages == false and (event == EVT_MENU_LONG or event == 128) then
    showConfigMenu = true
    collectgarbage()
  end
  if showMessages then
    ---------------------
    -- MESSAGES
    ---------------------
    if event == EVT_EXIT_BREAK or event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT  or event == 35 or event == 33 then
      showMessages = false
    end
    drawAllMessages()
  elseif showConfigMenu then
    ---------------------
    -- CONFIG MENU
    ---------------------
    drawConfigMenu(event)
    --
    if event == EVT_EXIT_BREAK or event == 33 then
      menu.editSelected = false
      showConfigMenu = false
      saveConfig()
    end
  else
    ---------------------
    -- MAIN VIEW
    ---------------------
    if event == EVT_ENTER_BREAK or event == 34 then
      cycleBatteryInfo()
    end
    if event == EVT_MENU_BREAK or event == 32 then
      showMinMaxValues = not showMinMaxValues
    end
    if showDualBattery == true and event == EVT_EXIT_BREAK or event == 33 then
      showDualBattery = false
    end
    drawHud()
    drawCompassRibbon()
    drawGrid()
    --
    -- Note: these can be calculated. not necessary to track them as min/max 
    -- cell1minFC = cell1sumFC/calcCellCount()
    -- cell2minFC = cell2sumFC/calcCellCount()
    -- cell1minA2 = cell1sumA2/calcCellCount()
    local count = calcCellCount()
    local cel1m = getMinVoltageBySource(battsource,cell1min,cell1sumFC/count,cellsumA2/count,1,count)*100
    local cel2m = getMinVoltageBySource(battsource,cell2min,cell2sumFC/count,cellsumA2/count,2,count)*100
    local batt1 = getMinVoltageBySource(battsource,cell1sum,cell1sumFC,cellsumA2,1,count)*10
    local batt2 = getMinVoltageBySource(battsource,cell2sum,cell2sumFC,cellsumA2,2,count)*10
    local curr  = getMaxValue(batt1current+batt2current,8)
    local curr1 = getMaxValue(batt1current,9)
    local curr2 = getMaxValue(batt2current,10)
    local mah1 = batt1mah
    local mah2 = batt2mah
    local cap1 = getBatt1Capacity()
    local cap2 = getBatt2Capacity()
    -- with dual battery default is to show aggregate view
    if batt2sources.fc or batt2sources.vs then
      if showDualBattery == false then
        -- dual battery: aggregate view
        lcd.drawText(68+76+1,7,"B1+B2",SMLSIZE+INVERS)
        drawX9BatteryPane(68+76+1,getNonZeroMin(batt1,batt2),getNonZeroMin(cel1m,cel2m),curr,mah1+mah2,cap1+cap2)
      else
        -- dual battery: do I have also dual current monitor?
        if curr1 > 0 and curr2 == 0 then
          -- special case: assume 1 power brick is monitoring batt1+batt2 in parallel
          curr1 = curr1/2
          curr2 = curr1
          --
          mah1 = mah1/2
          mah2 = mah1
          --
          cap1 = cap1/2
          cap2 = cap1
        end
        -- dual battery:battery 1 right pane
        lcd.drawText(68+76+1,7,"B1",SMLSIZE+INVERS)
        drawX9BatteryPane(68+76+1,batt1,cel1m,curr1,mah1,cap1)
        -- dual battery:battery 2 left pane
        lcd.drawText(0,7,"B2",SMLSIZE+INVERS)
        drawX9BatteryPane(0,batt2,cel2m,curr2,mah2,cap2)
      end
    else
      -- battery 1 right pane in single battery mode
        drawX9BatteryPane(68+76+1,batt1,cel1m,curr1,mah1,cap1)
    end
    -- left pane info when not in dual battery mode
    if showDualBattery == false then
      -- power is always based on FC current+voltage
      drawX9LeftPane(curr1+curr2,getNonZeroMin(cell1sumFC,cell2sumFC))
    end
    drawHomeDirection()
    drawTopBar()
    drawBottomBar()
    drawFailsafe()
    drawNoTelemetryData()
  end
end

local function init()
-- initialize flight timer
  model.setTimer(2,{mode=0})
  model.setTimer(2,{value=0})
  loadConfig()
  pushMessage(6,"Yaapu X9 telemetry script 1.7.1")
  playSound("yaapu")
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run,  background=background, init=init}

