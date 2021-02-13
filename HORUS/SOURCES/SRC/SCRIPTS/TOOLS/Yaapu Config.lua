--
-- An FRSKY S.Port <passthrough protocol> based Telemetry script for the Horus X10 and X12 radios
--
-- Copyright (C) 2018-2019. Alessandro Apostoli
-- https://github.com/yaapu
-- OlliW MavSDK additions by Risto Kõiva
-- https://github.com/rotorman
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

---------------------
-- MAIN CONFIG
-- 480x272 LCD_W x LCD_H
---------------------

---------------------
-- VERSION
---------------------
-- load and compile of lua files
-- uncomment to force compile of all chunks, comment for release
--#define COMPILE
-- fix for issue OpenTX 2.2.1 on X10/X10S - https://github.com/opentx/opentx/issues/5764

---------------------
-- FEATURE CONFIG
---------------------
-- enable splash screen for no telemetry data
--#define SPLASH
-- enable battery percentage based on voltage
-- enable code to draw a compass rose vs a compass ribbon
--#define COMPASS_ROSE

---------------------
-- DEV FEATURE CONFIG
---------------------
-- enable memory debuging 
--#define MEMDEBUG
-- enable dev code
--#define DEV
-- uncomment haversine calculation routine
--#define HAVERSINE
-- enable telemetry logging to file (experimental)
--#define LOGTELEMETRY
-- use radio channels imputs to generate fake telemetry data
--#define TESTMODE
-- enable debug of generated hash or short hash string
--#define HASHDEBUG
-- enable MESSAGES DEBUG
--#define DEBUG_MESSAGES
---------------------
-- DEBUG REFRESH RATES
---------------------
-- calc and show hud refresh rate
--#define HUDRATE
-- calc and show telemetry process rate
-- #define BGTELERATE

---------------------
-- SENSOR IDS
---------------------
















-- Throttle and RC use RPM sensor IDs

---------------------
-- BATTERY DEFAULTS
---------------------
---------------------------------
-- BACKLIGHT SUPPORT
-- GV is zero based, GV 8 = GV 9 in OpenTX
---------------------------------
---------------------------------
-- CONF REFRESH GV
---------------------------------

--
--
--

--

----------------------
-- COMMON LAYOUT
----------------------
-- enable vertical bars HUD drawing (same as taranis)
--#define HUD_ALGO1
-- enable optimized hor bars HUD drawing
--#define HUD_ALGO2
-- enable hor bars HUD drawing, 2 px resolution
-- enable hor bars HUD drawing, 1 px resolution
--#define HUD_ALGO4






--------------------------------------------------------------------------------
-- MENU VALUE,COMBO
--------------------------------------------------------------------------------

--------------------------
-- UNIT OF MEASURE
--------------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


-----------------------
-- BATTERY 
-----------------------
-- offsets are: 1 celm, 4 batt, 7 curr, 10 mah, 13 cap, indexing starts at 1
-- 


----------------------
--- COLORS
----------------------

--#define COLOR_LABEL 0x7BCF
--#define COLOR_BG 0x0169
--#define COLOR_BARSEX 0x10A3


--#define COLOR_SENSORS 0x0169

-----------------------------------
-- STATE TRANSITION ENGINE SUPPORT
-----------------------------------


--------------------------
-- CLIPPING ALGO DEFINES
--------------------------


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
--]]
--
local menuItems = {
  {"voice language:", "L1", 1, { "english", "italian", "french", "german" } , {"en","it","fr","de"} },
  {"batt alert level 1:", "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] capacity override:", "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] capacity override:", "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[1] cell count override:", "CC", 0, 0,12," cells",0,1 },
  {"batt[2] cell count override:", "CC2", 0, 0,12," cells",0,1 },
  {"dual battery config:", "BC", 1, { "parallel", "series", "dual with alert on B1", "dual with alert on B2", "volts on B1, curr on B2", "volts on B2, curr on B1" }, { 1, 2, 3, 4, 5, 6 } },
  {"enable battery % by voltage:", "BPBV", 1, { "no", "yes" }, { false, true } },
  {"default voltage source:", "VS", 1, { "auto", "FLVSS", "fc" }, { nil, "vs", "fc" } },
  {"disable all sounds:", "S1", 1, { "no", "yes" }, { false, true } },
  {"disable incoming msg beep:", "S2", 1, { "no", "only for INF severity", "always" }, { 1, 2, 3 } },
  {"enable haptic:", "VIBR", 1, { "no", "yes" }, { false, true } },
  {"timer alert every:", "T1", 0, 0,600,"min",PREC1,5 },
  {"min altitude alert:", "A1", 0, 0,500,"m",PREC1,5 },
  {"max altitude alert:", "A2", 0, 0,10000,"m",0,1 },
  {"max distance alert:", "D1", 0, 0,100000,"m",0,10 },
  {"repeat alerts every:", "T2", 10, 5,600,"sec",0,5 },
  {"rangefinder max:", "RM", 0, 0,10000," cm",0,10 },
  {"air/groundspeed unit:", "HSPD", 1, { "m/s", "km/h", "mph", "kn" }, { 1, 3.6, 2.23694, 1.94384} },
  {"vertical speed unit:", "VSPD", 1, { "m/s", "ft/s", "ft/min" }, { 1, 3.28084, 196.85} },
  {"widget layout:", "WL", 1, { "default","legacy"}, { 1, 2 } },
  {"center panel:", "CPANE", 1, { "option 1","option 2","option 3","option 4" }, { 1, 2, 3, 4 } },
  {"right panel:", "RPANE", 1, {  "option 1","option 2","option 3","option 4","option 5","option 6" }, { 1, 2, 3, 4, 5, 6 } },
  {"left panel:", "LPANE", 1, {  "option 1","option 2","option 3","option 4" }, { 1 , 2, 3, 4 } },
  {"enable PX4 flightmodes:", "PX4", 1, { "no", "yes" }, { false, true } },
  {"enable CRSF support:", "CRSF", 1, { "no", "yes" }, { false, true } },
  {"enable OlliW MavSDK support:", "MAVLINK", 1, { "no", "yes" }, { false, true } },
  {"emulated page channel:", "STC", 0, 0, 32,nil,0,1 },
  {"emulated wheel channel:", "SWC", 0, 0, 32,nil,0,1 },
  {"GPS coordinates format:", "GPS", 1, { "DMS", "decimal" }, { 1, 2 } },
  {"map provider:", "MAPP", 1, { "GMapCatcher", "Google" }, { 1, 2 } },
  {"map type:", "MAPT", 1, { "satellite", "map", "terrain" }, { "sat_tiles", "tiles", "ter_tiles" } },
  {"map min zoom level:", "MAPmZ", -2, -2, 17,nil,0,1 },
  {"map max zoom level:", "MAPMZ", 17, -2, 17,nil,0,1 },
  {"map grid lines:", "MAPG", 1, { "yes", "no" }, { true, false } },
  {"use radio GPS for home:", "TXGPS", 1, { "no", "yes" }, { false, true } },  
}

local menuItemsByName = {}

-- map from NEW to OLD settings
local mapNewToOldItemCfg = {
  ["SWC"] = "ZTC" -- ZTC was replaced by SWC
}

local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0,
  updated = true, -- if true menu needs a call to updateMenuItems()
  wrapOffset = 0, -- changes according to enabled/disabled features and panels
}

local basePath = "/SCRIPTS/YAAPU/"
local libBasePath = basePath.."LIB/"

local widgetLayoutFiles = {"layout_1","layout_2"}

local centerPanelFiles = {}
local rightPanelFiles = {}
local leftPanelFiles = {}

------------------------------------------
-- returns item's VALUE,LABEL,IDX
------------------------------------------
local function getMenuItemByName(items,name)
  local itemIdx = menuItemsByName[name]
  local item = items[itemIdx]
  if item == nil then
    return nil
  end
  if type(item[4]) == "table" then
    -- return item's value, label, index
    return item[5][item[3]], item[4][item[3]], itemIdx
  else
    -- return item's value, label, index
    return item[3], name, itemIdx
  end
end

local function updateMenuItems()
  if menu.updated == true then
    local value, name, idx = getMenuItemByName(menuItems,"WL")
    if value == 1 then
      ---------------------
      -- large hud layout
      ---------------------
      
      value, name, idx = getMenuItemByName(menuItems,"CPANE")
      menuItems[idx][4] = { "default" };
      menuItems[idx][5] = { 1 };
      
      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"RPANE")
      menuItems[idx][4] = { "default", "batt% by voltage", "tether", "hybrid"};
      menuItems[idx][5] = { 1, 2, 3, 4 };
      
      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"LPANE")
      menuItems[idx][4] = { "default", "MavSDK/Mav2PT" };
      menuItems[idx][5] = { 1, 2 };
      
      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end
      
      centerPanelFiles =  { "hud_1" }
      rightPanelFiles =   { "right_1", "right_battperc_1", "right_tether_1", "right_hybrid_1" }
      leftPanelFiles =    { "left_1", "left_m2f_1" }
    
    elseif value == 2 then
      ---------------------
      -- legacy layout
      ---------------------
      
      value, name, idx = getMenuItemByName(menuItems,"CPANE")
      menuItems[idx][4] = { "default", "russian hud", "compact hud " };
      menuItems[idx][5] = { 1, 2, 3 };
      
      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"RPANE")
      menuItems[idx][4] = { "default", "custom sensors" };
      menuItems[idx][5] = { 1, 2 };
      
      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end
      
      value, name, idx = getMenuItemByName(menuItems,"LPANE")
      menuItems[idx][4] = { "default", "MavSDK/Mav2PT" };
      menuItems[idx][5] = { 1, 2 };
      
      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end
      
      centerPanelFiles = {"hud_2", "hud_russian_2", "hud_small_2" }
      rightPanelFiles = {"right_2", "right_custom_2" }
      leftPanelFiles = {"left_2", "left_m2f_2" }
    end
    
    value, name, idx = getMenuItemByName(menuItems,"MAPP")
    
    if value == nil then
      return
    end
    
    local value2, name2, idx2 = getMenuItemByName(menuItems,"MAPT")
    
    if value2 ~= nil then
      if value == 1 then --GMapCatcher
        menuItems[idx2][4] = { "satellite", "map", "terrain" }
        menuItems[idx2][5] = { "sat_tiles", "tiles", "ter_tiles" }
      elseif value == 2 then -- Google
        menuItems[idx2][4] = { "GoogleSatelliteMap", "GoogleHybridMap", "GoogleMap", "GoogleTerrainMap" }
        menuItems[idx2][5] = { "GoogleSatelliteMap", "GoogleHybridMap", "GoogleMap", "GoogleTerrainMap" }
      end
    end
    
    value2, name2, idx2 = getMenuItemByName(menuItems,"MAPmZ")
    
    if value2 ~= nil then
      if value == 1 then        -- GMapCatcher
        menuItems[idx2][4] = -2
        menuItems[idx2][5] = 17
      else                      -- Google
        menuItems[idx2][4] = 1
        menuItems[idx2][5] = 20
      end
	  -- check that the selected value is in range of the appropriate map product
      if menuItems[idx2][3] < menuItems[idx2][4] then
        menuItems[idx2][3] = menuItems[idx2][4]
      end
      if menuItems[idx2][3] > menuItems[idx2][5] then
        menuItems[idx2][3] = menuItems[idx2][5]
      end
    end
    
    value2, name2, idx2 = getMenuItemByName(menuItems,"MAPMZ")
    
    if value2 ~= nil then
      if value == 1 then        -- GMapCatcher
        menuItems[idx2][4] = -2
        menuItems[idx2][5] = 17
      else                      -- Google
        menuItems[idx2][4] = 1
        menuItems[idx2][5] = 20
      end
	  -- check that the selected value is in range of the appropriate map product
      if menuItems[idx2][3] < menuItems[idx2][4] then
        menuItems[idx2][3] = menuItems[idx2][4]
      end
      if menuItems[idx2][3] > menuItems[idx2][5] then
        menuItems[idx2][3] = menuItems[idx2][5]
      end
    end
    
    menu.updated = false
  end
end

local function getConfigFilename()
  local info = model.getInfo()
  return "/SCRIPTS/YAAPU/CFG/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

local function applyConfigValues(conf)
  if menu.updated == true then
    updateMenuItems()
    menu.updated = false
  end
  conf.language = getMenuItemByName(menuItems,"L1")
  conf.battAlertLevel1 = getMenuItemByName(menuItems,"V1")
  conf.battAlertLevel2 = getMenuItemByName(menuItems,"V2")
  conf.battCapOverride1 = getMenuItemByName(menuItems,"B1")
  conf.battCapOverride2 = getMenuItemByName(menuItems,"B2")
  conf.disableAllSounds = getMenuItemByName(menuItems,"S1")
  conf.disableMsgBeep = getMenuItemByName(menuItems,"S2")
  conf.enableHaptic = getMenuItemByName(menuItems,"VIBR")
  conf.timerAlert = math.floor(getMenuItemByName(menuItems,"T1")*0.1*60)
  conf.minAltitudeAlert = getMenuItemByName(menuItems,"A1")*0.1
  conf.maxAltitudeAlert = getMenuItemByName(menuItems,"A2")
  conf.maxDistanceAlert = getMenuItemByName(menuItems,"D1")
  conf.repeatAlertsPeriod = getMenuItemByName(menuItems,"T2")
  conf.battConf = getMenuItemByName(menuItems,"BC")
  conf.cell1Count = getMenuItemByName(menuItems,"CC")
  conf.cell2Count = getMenuItemByName(menuItems,"CC2")
  conf.rangeFinderMax = getMenuItemByName(menuItems,"RM")
  conf.horSpeedMultiplier, conf.horSpeedLabel = getMenuItemByName(menuItems,"HSPD")
  conf.vertSpeedMultiplier, conf.vertSpeedLabel = getMenuItemByName(menuItems,"VSPD")
  -- Layout configuration
  conf.widgetLayout = getMenuItemByName(menuItems,"WL")
  conf.widgetLayoutFilename = widgetLayoutFiles[conf.widgetLayout]
  
  conf.centerPanel = getMenuItemByName(menuItems,"CPANE")
  conf.centerPanelFilename = centerPanelFiles[conf.centerPanel]
  
  conf.rightPanel = getMenuItemByName(menuItems,"RPANE")
  conf.rightPanelFilename = rightPanelFiles[conf.rightPanel]
  
  conf.leftPanel = getMenuItemByName(menuItems,"LPANE")
  conf.leftPanelFilename = leftPanelFiles[conf.leftPanel]
  conf.enablePX4Modes = getMenuItemByName(menuItems,"PX4")
  conf.enableCRSF = getMenuItemByName(menuItems,"CRSF")
  conf.enableMAVLink = getMenuItemByName(menuItems,"MAVLINK")

  conf.mapZoomMin = getMenuItemByName(menuItems,"MAPmZ")
  conf.mapZoomMax = getMenuItemByName(menuItems,"MAPMZ")
  
  conf.mapType = getMenuItemByName(menuItems,"MAPT")
  
  local chInfo = getFieldInfo("ch"..getMenuItemByName(menuItems,"STC"))
  conf.screenToggleChannelId = (chInfo == nil and -1 or chInfo['id'])
  
  chInfo = getFieldInfo("ch"..getMenuItemByName(menuItems,"SWC"))
  conf.screenWheelChannelId = (chInfo == nil and -1 or chInfo['id'])
  
  conf.enableMapGrid = getMenuItemByName(menuItems,"MAPG")
  conf.mapProvider = getMenuItemByName(menuItems,"MAPP")
  
  -- set default voltage source
  if getMenuItemByName(menuItems,"VS") ~= nil then
    conf.defaultBattSource = getMenuItemByName(menuItems,"VS")
  end
  conf.gpsFormat = getMenuItemByName(menuItems,"GPS")
  conf.enableBattPercByVoltage = getMenuItemByName(menuItems,"BPBV")
  
  conf.enableTxGPS = getMenuItemByName(menuItems,"TXGPS")
  menu.editSelected = false
end

local function loadConfig(conf)
  local cfg_found = false
  local cfg_string
  local cfg = io.open(getConfigFilename(),"r")
  
  if cfg ~= nil then
    cfg_string = io.read(cfg,500)
    io.close(cfg)
    if string.len(cfg_string) > 0 then
      cfg_found = true
    end
  end
      
  for i=1,#menuItems
  do
    menuItemsByName[tostring(menuItems[i][2])] = i
    if cfg_found then
      local value = string.match(cfg_string, menuItems[i][2]..":([-%d]+)")
      if value == nil then
        -- check if it was replaced by an older settings
        local oldCfg = mapNewToOldItemCfg[menuItems[i][2]]
        if oldCfg ~= nil then
          value = string.match(cfg_string, oldCfg..":([-%d]+)")
        end
      end
      if value ~= nil then
        menuItems[i][3] = tonumber(value)
        -- check if the value read from file is compatible with available options
        if type(menuItems[i][4]) == "table" and tonumber(value) > #menuItems[i][4] then
          --if not force default
          menuItems[i][3] = 1
        end
      end
    end
  end
    
  -- when run standalone there's nothing to update :-)
  if conf ~= nil then
    applyConfigValues(conf)
    -- menu was loaded apply required changes
    menu.updated = true
  end
end

local function saveConfig(conf)
  local myConfig = ""
  for i=1,#menuItems
  do
    myConfig = myConfig..menuItems[i][2]..":"..menuItems[i][3]
    if i < #menuItems then
      myConfig = myConfig..","
    end
  end
  local cfg = assert(io.open(getConfigFilename(),"w"))
  if cfg ~= nil then
    io.write(cfg,myConfig)
    io.close(cfg)
  end
  myConfig = nil
  -- when run standalone there's nothing to update :-)
  if conf ~= nil then
    applyConfigValues(conf)
  end
  model.setGlobalVariable(8,8,1)
end

local function drawConfigMenuBars()
  lcd.setColor(CUSTOM_COLOR,0x0000)
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
  lcd.drawFilledRectangle(0,0, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawRectangle(0, 0, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawFilledRectangle(0,LCD_H-20, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawRectangle(0, LCD_H-20, LCD_W, 20, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)  
  lcd.drawText(2,0,"Yaapu v1.9.3b4 (OlliW MavSDK support by Risto)",CUSTOM_COLOR)
  lcd.drawText(2,LCD_H-20+1,getConfigFilename(),CUSTOM_COLOR)
  lcd.drawText(LCD_W,LCD_H-20+1,itemIdx,CUSTOM_COLOR+RIGHT)
end

local function incMenuItem(idx)
  if type(menuItems[idx][4]) == "table" then
    menuItems[idx][3] = menuItems[idx][3] + 1
    if menuItems[idx][3] > #menuItems[idx][4] then
      menuItems[idx][3] = 1
    end
  else
    menuItems[idx][3] = menuItems[idx][3] + menuItems[idx][8]
    if menuItems[idx][3] > menuItems[idx][5] then
      menuItems[idx][3] = menuItems[idx][5]
    end
  end
end

local function decMenuItem(idx)
  if type(menuItems[idx][4]) == "table" then
    menuItems[idx][3] = menuItems[idx][3] - 1
    if menuItems[idx][3] < 1 then
      menuItems[idx][3] = #menuItems[idx][4]
    end
  else
    menuItems[idx][3] = menuItems[idx][3] - menuItems[idx][8]
    if menuItems[idx][3] < menuItems[idx][4] then
      menuItems[idx][3] = menuItems[idx][4]
    end
  end
end

local function drawItem(idx,flags)
  lcd.setColor(CUSTOM_COLOR,0xFFFF)    
  if type(menuItems[idx][4]) == "table" then
    lcd.drawText(280,25 + (idx-menu.offset-1)*20, menuItems[idx][4][menuItems[idx][3]],flags+CUSTOM_COLOR)
  else
    if menuItems[idx][3] == 0 and menuItems[idx][4] >= 0 then
      lcd.drawText(280,25 + (idx-menu.offset-1)*20, "---",flags+CUSTOM_COLOR)
    else
      lcd.drawNumber(280,25 + (idx-menu.offset-1)*20, menuItems[idx][3],flags+menuItems[idx][7]+CUSTOM_COLOR)
      if menuItems[idx][6] ~= nil then
        lcd.drawText(280 + 50,25 + (idx-menu.offset-1)*20, menuItems[idx][6],flags+CUSTOM_COLOR)
      end
    end
  end
end

local function drawConfigMenu(event)
  drawConfigMenuBars()
  updateMenuItems()
  if event == EVT_ENTER_BREAK then
    if menu.editSelected == true then
      -- confirm modified value
      saveConfig()
    end
    menu.editSelected = not menu.editSelected
    menu.updated = true
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT or event == EVT_PLUS_REPT) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_MINUS_REPT) then
    decMenuItem(menu.selectedItem)
  elseif not menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_LEFT) then
    menu.selectedItem = (menu.selectedItem - 1)
    if menu.offset >=  menu.selectedItem then
      menu.offset = menu.offset - 1
    end
  elseif not menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_RIGHT) then
    menu.selectedItem = (menu.selectedItem + 1)
    if menu.selectedItem - 11 > menu.offset then
      menu.offset = menu.offset + 1
    end
  end
  --wrap
  if menu.selectedItem > #menuItems then
    menu.selectedItem = 1 
    menu.offset = 0
  elseif menu.selectedItem  < 1 then
    menu.selectedItem = #menuItems
    menu.offset =  #menuItems - 11
  end
  --
  for m=1+menu.offset,math.min(#menuItems,11+menu.offset) do
    lcd.setColor(CUSTOM_COLOR,0xFFFF)   
    lcd.drawText(2,25 + (m-menu.offset-1)*20, menuItems[m][1],CUSTOM_COLOR)
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


--------------------------
-- RUN
--------------------------
local function run(event)
  lcd.setColor(CUSTOM_COLOR, 0x0AB1) -- hex 0x084c7b -- 073f66
  lcd.clear(CUSTOM_COLOR)
  ---------------------
  -- CONFIG MENU
  ---------------------  
  drawConfigMenu(event)
  return 0
end

local function init()
  loadConfig()
end

--------------------------------------------------------------------------------
-- SCRIPT END
--------------------------------------------------------------------------------
return {run=run, init=init, loadConfig=loadConfig, compileLayouts=compileLayouts, menuItems=menuItems}
