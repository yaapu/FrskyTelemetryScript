--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Horus class radios
-- based on ArduPilot's passthrough telemetry protocol
--
-- Author: Alessandro Apostoli, https://github.com/yaapu
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
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"


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
  {"pause telemetry processing:", "PTP", 2, { "yes", "no" }, { true, false } },
  {"voice language:", "L1", 1, { "english", "italian", "french", "german" } , {"en","it","fr","de"} },
  {"color theme:", "TH", 1, { "default", "ethos" } , { 1, 2} },
  {"batt alert level 1:", "V1", 375, 0,5000,"V",PREC2,5 },
  {"batt alert level 2:", "V2", 350, 0,5000,"V",PREC2,5 },
  {"batt[1] capacity override:", "B1", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[2] capacity override:", "B2", 0, 0,5000,"Ah",PREC2,10 },
  {"batt[1] cell count override:", "CC", 0, 0,16," cells",0,1 },
  {"batt[2] cell count override:", "CC2", 0, 0,16," cells",0,1 },
  {"dual battery config:", "BC", 1, { "parallel", "series", "dual with alert on B1", "dual with alert on B2", "volts on B1, % on B2", "volts on B2, % on B1" }, { 1, 2, 3, 4, 5, 6 } },
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
  {"widget layout:", "WL", 1, { "default"}, { 1 } },
  {"main screen center panel:", "CPANE", 1, { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"main screen  right panel:", "RPANE", 1,  { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"main screen  left panel:", "LPANE", 1,   { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"screen [2]: center panel:", "CPANE2", 1, { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"screen [2]: right panel:", "RPANE2", 1,  { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"screen [2]: left panel:", "LPANE2", 1,   { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"screen [3]: center panel:", "CPANE3", 1, { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"screen [3]: right panel:", "RPANE3", 1,  { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"screen [3]: left panel:", "LPANE3", 1,   { "","","","","","","","","","" }, { 1, 2, 3, 4, 5, 6, 7, 8 ,9 ,10 } },
  {"enable PX4 flightmodes:", "PX4", 1, { "no", "yes" }, { false, true } },
  {"enable CRSF support:", "CRSF", 1, { "no", "yes" }, { false, true } },
  {"enable RPM support:", "RPM", 1, { "no", "rpm1", "rpm1+rpm2" }, { 1, 2, 3 } },
  {"enable WIND support:", "WIND", 1, { "no", "yes" }, { false, true } },
  {"emulated page channel:", "STC", 0, 0, 32,nil,0,1 },
  {"emulated wheel channel:", "SWC", 0, 0, 32,nil,0,1 },
  {"emulated wheel delay in seconds:", "SWCD", 1, 0, 50,"sec",PREC1, 1 },
  {"GPS coordinates format:", "GPS", 1, { "DMS", "decimal" }, { 1, 2 } },
  {"map provider:", "MAPP", 1, { "GMapCatcher", "Google" }, { 1, 2 } },
  {"map type:", "MAPT", 1, { "satellite", "map", "terrain" }, { "sat_tiles", "tiles", "ter_tiles" } },
  {"map zoom level default value:", "MAPZ", -2, -2, 17,nil,0,1 },
  {"map zoom level min value:", "MAPmZ", -2, -2, 17,nil,0,1 },
  {"map zoom level max value:", "MAPMZ", 17, -2, 17,nil,0,1 },
  {"map grid lines:", "MAPG", 1, { "yes", "no" }, { true, false } },
  -- allow up to 20 plot sources to be defined by updateMenuItems()
  {"plot telemetry source 1:", "PLT1", 1, { "","","","","","","","","","","","","","","","","","","","","","","","","","","","","","" }, { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30 } },
  {"plot telemetry source 2:", "PLT2", 1, { "","","","","","","","","","","","","","","","","","","","","","","","","","","","","","" }, { 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30 } },
}

-------------------------------
-- PLOT SOURCE DEFINITIONS
-------------------------------
-- { desc, telemetry, unit, scale, label }
-- unit: 1=alt,2=dist,3=hspeed,4=vspeed,5=none
local plotSources = {
  {"None", "nome", 5, 1, },           -- dm
  {"Altitude", "homeAlt", 1, 1 },           -- dm
  {"Airspeed", "airspeed", 3, 0.1 },
  {"Batt[1] Voltage", "batt1volt", 5, 0.1 },
  {"Batt[1] Current", "batt1current", 5, 0.1 },
  {"Batt[2] Voltage", "batt2volt", 5, 0.1 },
  {"Batt[2] Current", "batt2current", 5, 0.1 },
  {"Groundspeed","hSpeed", 3, 0.1},  -- dm
  {"Height Above Terrain", "heightAboveTerrain", 1, 1 },
  {"Home Distance", "homeDist", 2, 1 },    -- m
  {"HDOP", "gpsHdopC", 5, 0.1},
  {"Num Sats", "numSats", 5, 1},
  {"Pitch", "pitch", 5, 1 },
  {"Rangefinder", "range", 5, 1 },
  {"Roll", "roll", 5, 1 },
  {"RPM[1]", "rpm1", 5, 1 },
  {"RPM[2]", "rpm2", 5, 1 },
  {"RSSI", "rssi", 5, 1 },
  {"RSSI CRSF", "rssiCRSF", 5, 1 },
  {"Sonar", "range", 5, 1 },
  {"Throttle", "throttle", 5, 1 },
  {"Vertical Speed", "vSpeed", 4, 0.1},   -- dm
  {"Wind Speed", "trueWindSpeed", 3, 0.1 },
  {"Wind Direction", "trueWindAngle", 5, 1 },
  {"Yaw", "yaw", 5, 1}, -- deg
}

-- map from NEW to OLD settings
local mapNewToOldItemCfg = {
  ["SWC"] = "ZTC" -- ZTC was replaced by SWC
}

local utils = {}
local menuItemsByName = {}

local menu  = {
  selectedItem = 1,
  editSelected = false,
  offset = 0,
  updated = true, -- if true menu needs a call to updateMenuItems()
  wrapOffset = 0, -- changes according to enabled/disabled features and panels
}

local widgetLayoutFiles = { "layout_def" }

local centerPanelFiles = {}
local rightPanelFiles = {}
local leftPanelFiles = {}

---------------------------
-- LIBRARY LOADING
---------------------------
local basePath = "/WIDGETS/yaapu/"
local libBasePath = basePath.."lib/"

utils.doLibrary = function(filename)
  local f = assert(loadScript(libBasePath..filename..".lua"))
  return f()
end

local panels = utils.doLibrary("panels").panels

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

local function plotSourcesToMenuOptions(plotSources)
  local labels = {}
  local values = {}

  for i=1,#plotSources
  do
    labels[i] = plotSources[i][1]
    values[i] = i
  end
  return labels, values
end

local function updateMenuItems()
  if menu.updated == true then
    local layout, layout_name, layout_idx = getMenuItemByName(menuItems,"WL")
    for screen=1,3
    do
      local screen_suffix = screen == 1 and "" or tostring(screen)
      ---------------------
      -- large hud layout
      ---------------------
      value, name, idx = getMenuItemByName(menuItems,"CPANE"..screen_suffix)
      menuItems[idx][4] = panels.default.center.labels
      menuItems[idx][5] = panels.default.center.options;

      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end

      value, name, idx = getMenuItemByName(menuItems,"RPANE"..screen_suffix)
      menuItems[idx][4] = panels.default.right.labels
      menuItems[idx][5] = panels.default.right.options

      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end

      value, name, idx = getMenuItemByName(menuItems,"LPANE"..screen_suffix)
      menuItems[idx][4] = panels.default.left.labels
      menuItems[idx][5] = panels.default.left.options

      if menuItems[idx][3] > #menuItems[idx][4] then
        menuItems[idx][3] = 1
      end

      centerPanelFiles = panels.default.center.files
      rightPanelFiles = panels.default.right.files
      leftPanelFiles = panels.default.left.files
    end

    local value, name, idx = getMenuItemByName(menuItems,"MAPP")

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

      if menuItems[idx2][3] > #menuItems[idx2][4] then
        menuItems[idx2][3] = 1
      end
    end

    value2, name2, idx2 = getMenuItemByName(menuItems,"MAPmZ")

    local idxzmin = idx2

    if value2 ~= nil then
      if value == 1 then        -- GMapCatcher
        menuItems[idx2][4] = -2
        menuItems[idx2][5] = 17
        menuItems[idx2][3] = math.max(value2,-2)
      else                      -- Google
        menuItems[idx2][4] = 1
        menuItems[idx2][5] = 20
        menuItems[idx2][3] = math.max(value2,1)
      end
    end

    value2, name2, idx2 = getMenuItemByName(menuItems,"MAPMZ")

    local idxzmax = idx2

    if value2 ~= nil then
      if value == 1 then        -- GMapCatcher
        menuItems[idx2][4] = -2
        menuItems[idx2][5] = 17
        menuItems[idx2][3] = math.min(value2,17)
      else                      -- Google
        menuItems[idx2][4] = 1
        menuItems[idx2][5] = 20
        menuItems[idx2][3] = math.min(value2,20)
      end
    end

    value2, name2, idx2 = getMenuItemByName(menuItems,"MAPZ")

    if value2 ~= nil then
      menuItems[idx2][4] = menuItems[idxzmin][3]
      menuItems[idx2][5] = menuItems[idxzmax][3]
      menuItems[idx2][3] = math.min(math.max(value2,menuItems[idxzmin][3]),menuItems[idxzmax][3])
    end

    -- plot sources
    value2, name2, idx2 = getMenuItemByName(menuItems,"PLT1")
    if value2 ~= nil then
      local plotLabels, plotValues= plotSourcesToMenuOptions(plotSources)
      menuItems[idx2][4] = plotLabels
      menuItems[idx2][5] = plotValues
    end

    value2, name2, idx2 = getMenuItemByName(menuItems,"PLT2")
    if value2 ~= nil then
      local plotLabels, plotValues= plotSourcesToMenuOptions(plotSources)
      menuItems[idx2][4] = plotLabels
      menuItems[idx2][5] = plotValues
    end

    menu.updated = false
  end
end

local function getConfigFilename()
  local info = model.getInfo()
  return "/WIDGETS/Yaapu/cfg/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".cfg")
end

local function getConfigTriggerFilename()
  local info = model.getInfo()
  return "/WIDGETS/Yaapu/cfg/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "")..".reload")
end

local function triggerConfigReload()
  local cfg = assert(io.open(getConfigTriggerFilename(),"w"))
  if cfg ~= nil then
    io.write(cfg, "1")
    io.close(cfg)
  end
  collectgarbage()
  collectgarbage()
end

local function applyConfigValues(conf)
  if menu.updated == true then
    updateMenuItems()
    menu.updated = false
  end
  conf.pauseTelemetry = getMenuItemByName(menuItems,"PTP")
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
  -- multiple screens setup
  for screen=1,3
  do
    local screen_suffix = screen == 1 and "" or tostring(screen)

    conf.centerPanel[screen] = getMenuItemByName(menuItems,"CPANE"..screen_suffix)
    conf.centerPanelFilename[screen] = centerPanelFiles[conf.centerPanel[screen]]
    conf.rightPanel[screen] = getMenuItemByName(menuItems,"RPANE"..screen_suffix)
    conf.rightPanelFilename[screen] = rightPanelFiles[conf.rightPanel[screen]]
    conf.leftPanel[screen] = getMenuItemByName(menuItems,"LPANE"..screen_suffix)
    conf.leftPanelFilename[screen] = leftPanelFiles[conf.leftPanel[screen]]
  end

  conf.enablePX4Modes = getMenuItemByName(menuItems,"PX4")
  conf.enableCRSF = getMenuItemByName(menuItems,"CRSF")
  conf.enableRPM = getMenuItemByName(menuItems,"RPM")
  conf.enableWIND = getMenuItemByName(menuItems,"WIND")

  conf.mapZoomLevel = getMenuItemByName(menuItems,"MAPZ")
  conf.mapZoomMin = getMenuItemByName(menuItems,"MAPmZ")
  conf.mapZoomMax = getMenuItemByName(menuItems,"MAPMZ")

  conf.mapType = getMenuItemByName(menuItems,"MAPT")

  local chInfo = getFieldInfo("ch"..getMenuItemByName(menuItems,"STC"))
  conf.screenToggleChannelId = (chInfo == nil and -1 or chInfo['id'])

  chInfo = getFieldInfo("ch"..getMenuItemByName(menuItems,"SWC"))
  conf.screenWheelChannelId = (chInfo == nil and -1 or chInfo['id'])

  conf.enableMapGrid = getMenuItemByName(menuItems,"MAPG")
  conf.mapProvider = getMenuItemByName(menuItems,"MAPP")

  conf.screenWheelChannelDelay = getMenuItemByName(menuItems,"SWCD")

  -- set default voltage source
  if getMenuItemByName(menuItems,"VS") ~= nil then
    conf.defaultBattSource = getMenuItemByName(menuItems,"VS")
  end
  conf.gpsFormat = getMenuItemByName(menuItems,"GPS")
  conf.enableBattPercByVoltage = getMenuItemByName(menuItems,"BPBV")

  conf.plotSource1 = getMenuItemByName(menuItems,"PLT1")
  conf.plotSource2 = getMenuItemByName(menuItems,"PLT2")

  conf.theme = getMenuItemByName(menuItems,"TH")

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
  triggerConfigReload()
  --[[
  model.setGlobalVariable(CONF_GV,CONF_FM_GV, 99)
  --]]
end

local function drawConfigMenuBars()
  local info = model.getInfo()
  lcd.setColor(CUSTOM_COLOR,lcd.RGB(16,20,25))
  local itemIdx = string.format("%d/%d",menu.selectedItem,#menuItems)
  lcd.drawFilledRectangle(0,0, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawRectangle(0, 0, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawFilledRectangle(0,LCD_H-20, LCD_W, 20, CUSTOM_COLOR)
  lcd.drawRectangle(0, LCD_H-20, LCD_W, 20, CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawText(LCD_W,3,"Yaapu Telemetry Widget 2.0.0 beta2".." ("..'3e285e4'..")",CUSTOM_COLOR+SMLSIZE+RIGHT)
  lcd.drawText(0,0,info.name,CUSTOM_COLOR)
  lcd.drawText(0,LCD_H-20+1,getConfigFilename(),CUSTOM_COLOR)
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
  lcd.setColor(CUSTOM_COLOR,WHITE)
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
  elseif menu.editSelected and (event == EVT_PLUS_BREAK or event == EVT_ROT_RIGHT or event == EVT_PLUS_REPT) then
    incMenuItem(menu.selectedItem)
  elseif menu.editSelected and (event == EVT_MINUS_BREAK or event == EVT_ROT_LEFT or event == EVT_MINUS_REPT) then
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
    lcd.setColor(CUSTOM_COLOR,WHITE)
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
  lcd.setColor(CUSTOM_COLOR, lcd.RGB(50,50,50)) -- hex 0x084c7b -- 073f66
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
return {run=run, init=init, loadConfig=loadConfig, compileLayouts=compileLayouts, menuItems=menuItems, plotSources=plotSources}
