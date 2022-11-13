--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry widget for the Ethos OS
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


local HUD_W = 240
local HUD_H = 150
local HUD_X = (480 - HUD_W)/2
local HUD_Y = 18

local function getTime()
  -- os.clock() resolution is 0.01 secs
  return os.clock()*100 -- 1/100th
end



local status = {
  -- telemetry
  telemetry = {
    -- STATUS
    flightMode = 0,
    simpleMode = 0,
    landComplete = 0,
    statusArmed = 0,
    battFailsafe = 0,
    ekfFailsafe = 0,
    failsafe = 0,
    imuTemp = 0,
    fencePresent = 0,
    fenceBreached = 0,
    -- GPS
    numSats = 0,
    gpsStatus = 0,
    gpsHdopC = 100,
    gpsAlt = 0,
    -- BATT 1
    batt1volt = 0,
    batt1current = 0,
    batt1mah = 0,
    -- BATT 2
    batt2volt = 0,
    batt2current = 0,
    batt2mah = 0,
    -- HOME
    homeDist = 0,
    homeAlt = 0,
    homeAngle = -1,
    -- VELANDYAW
    vSpeed = 0,
    hSpeed = 0,
    yaw = 0,
    -- ROLLPITCH
    roll = 0,
    pitch = 0,
    range = 0,
    -- PARAMS
    frameType = -1,
    batt1Capacity = 0,
    batt2Capacity = 0,
    -- GPS
    lat = nil,
    lon = nil,
    homeLat = nil,
    homeLon = nil,
    strLat = "N/A",
    strLon = "N/A",
    -- WP
    wpNumber = 0,
    wpDistance = 0,
    wpXTError = 0,
    wpBearing = 0,
    wpCommands = 0,
    wpOffsetFromCog = 0,
    -- VFR
    airspeed = 0,
    throttle = 0,
    baroAlt = 0,
    -- Total distance
    totalDist = 0,
    -- RPM
    rpm1 = 0,
    rpm2 = 0,
    -- TERRAIN
    heightAboveTerrain = 0,
    terrainUnhealthy = 0,
    -- WIND
    trueWindSpeed = 0,
    trueWindAngle = 0,
    apparentWindSpeed = 0,
    apparentWindAngle = 0,
    -- RSSI
    rssi = 0,
    rssiCRSF = 0,
  },

  -- configuration
  conf = {
    language = "en",
    defaultBattSourceId = 1, -- auto
    battery1Source = nil,
    battery2Source = nil,
    battAlertLevel1 = 375,
    battAlertLevel2 = 350,
    battCapOverride1 = 0,
    battCapOverride2 = 0,
    disableAllSounds = false,
    disableMsgBeep = 1,
    enableHaptic = false,
    timerAlert = 0,
    repeatAlertsPeriod = 10,
    minAltitudeAlert = 0,
    maxAltitudeAlert = 0,
    maxDistanceAlert = 0,
    battConf = 1,
    cell1Count = 0,
    cell2Count = 0,
    enableBattPercByVoltage = false,
    rangeFinderMax=0,
    horSpeedUnit = 1,
    horSpeedMultiplier=1,
    horSpeedLabel = "m/s",
    vertSpeedUnit = 1,
    vertSpeedMultiplier=1,
    vertSpeedLabel = "m/s",
    distUnit = 1,
    distUnitLabel = "m",
    distUnitScale = 1,
    distUnitLong = 1,
    distUnitLongLabel = "km",
    distUnitLongScale = 0.001,
    maxHdopAlert = 2,
    enablePX4Modes = false,
    enableCRSF = false,
    -- map support
    mapTypeId = 1,
    mapType = "GoogleSatelliteMap", -- applies to gmapcacther only

    googleZoomDefault = 18,
    googleZoomMax = 20,
    googleZoomMin = 1,

    gmapZoomDefault = 0,
    gmapZoomMax = 17,
    gmapZoomMin = -2,

    mapZoomMax = 20,
    mapZoomMin = 1,

    mapTrailDots = 10,
    enableMapGrid = true,
    screenToggleChannelId = 0,
    screenWheelChannelId = 0,
    screenWheelChannelDelay = 20,
    gpsFormat = 2, -- decimal
    mapProvider = 2, -- 1 GMapCatcher, 2 Google
    enableRPM = 3,
    enableWIND = true,
    plotSource1 = 1,
    plotSource2 = 1,
    -- layout
    layout = 1,
    -- external sport support
    telemetrySource = 1,
    -- test only
    num = 0, -- test da rimuovere
  },

  -- gps fix status
  gpsStatuses = {
    [0]={"No", "GPS"},
    [1]={"No", "Lock"},
    [2]={"2D", ""},
    [3]={"3D", ""},
    [4]={"DGPS",""},
    [5]={"RTK", "Flt"},
    [6]={"RTK", "Fxd"},
  },

  -- mavlink severity
  mavSeverity = {
    [0] = { "EMR", lcd.RGB(248, 109, 0) },
    [1] = { "ALR", lcd.RGB(248, 109, 0) },
    [2] = { "CRT", lcd.RGB(248, 109, 0) },
    [3] = { "ERR", lcd.RGB(248, 109, 0) },
    [4] = { "WRN", lcd.RGB(248, 109, 0) },
    [5] = { "NTC", lcd.RGB(0, 255, 0) },
    [6] = { "INF", lcd.RGB(255, 255, 255) },
    [7] = { "DBG", lcd.RGB(255, 255, 255) },
  },
  -- panels
  layoutFilenames = {
    "layout_default",
    "layout_map",
    "layout_plot",
  },
  centerPanelFilenames = {
    "center_panel"
  },
  rightPanelFilenames = {
    "right_panel",
    "right_panel_2",
  },
  leftPanelFilenames = {
    "left_panel",
    "left_panel",
  },
  counter = 0,

  -- layout
  lastScreen = 1, -- allows to switch to a different screen on same widget
  loadCycle = 0,
  layout = { nil, nil, nil },

  -- FLVSS 1
  cell1min = 0,
  cell1sum = 0,
  -- FLVSS 2
  cell2min = 0,
  cell2sum = 0,
  -- FC 1
  cell1sumFC = 0,
  cell1maxFC = 0,
  -- FC 2
  cell2sumFC = 0,
  cell2maxFC = 0,
  -- battery
  cell1count = 0,
  cell2count = 0,
  battsource = "fc",
  batt1sources = {
    vs = false,
    fc = false
  },
  batt2sources = {
    vs = false,
    fc = false
  },
  -- flight time
  lastTimerStart = 0,
  timerRunning = 0,
  flightTime = 0,
  -- events
  lastStatusArmed = 0,
  lastGpsStatus = 0,
  lastFlightMode = 0,
  lastSimpleMode = 0,
  -- battery levels
  batLevel = 99,
  battLevel1 = false,
  battLevel2 = false,
  lastBattLevel = 14,
  -- messages
  messages = {},
  msgBuffer = "",
  lastMsgValue = 0,
  lastMsgTime = 0,
  lastMessage = nil,
  lastMessageSeverity = 0,
  lastMessageCount = 1,
  messageCount = 0,
  messageOffset = 0,
  messageAutoScroll = true,
  -- telemetry status
  noTelemetryData = 1,
  hideNoTelemetry = false,
  showDualBattery = false,
  showMinMaxValues = false,
  -- maps
  screenTogglePage = 1,
  mapZoomLevel = 19,
  -- flightmode
  strFlightMode = nil,
  modelString = nil,
  -- terrain
  terrainEnabled = 0,
  terrainLastData = getTime(),
  -- airspeed
  airspeedEnabled = 0,
  -- PLOT data
  plotSources = nil,
  -- waypoint
  cog = nil,
  lastLat = nil,
  lastLon = nil,
  wpEnabled = 0,
  wpEnabledMode = 0,
  -- dynamic layout element hiding
  hidePower = 0,
  hideEfficiency = 0,
  -- blinking suppport
  blinkon = false,
  -- top bar
  linkQualitySource = nil,
  linkStatusSource2 = nil,
  linkStatusSource3 = nil,
  linkStatusSource4 = nil,
  -- traveled distance support
  avgSpeed = 0,
  lastUpdateTotDist = 0,

  -- telemetry params
  paramId = nil,
  paramValue = nil,

  -- message hash support
  shortHash = nil,
  parseShortHash = false,
  hashByteIndex = 0,
  hash = 0,
  hash_a = 0,
  hash_b = 0,

  currentModel = model.name(),
  pauseTelemetry = false,

  -- fletcher24 bytes hashes
  shortHashes = {
    [1934808] = false,  -- Soaring: Enabled
    [2074081] = false,  -- Soaring: Disabled
    [2397669] = false,  -- Soaring: reached upper altitude
    [2246114] = false,  -- Soaring: reached lower altitude
    [2860491] = false,  -- Soaring: thermal weak
    [2262475] = true,   -- reached command:
    [3466823] = true,   -- reached waypoint:
    [4597275] = true,   -- Passed waypoint:
    [3843641] = false,  -- Takeoff complete
    [1865209] = false,  -- Smart RTL deactivated
    [4170928] = false,  -- GPS home acquired
    [4224177] = false,  -- GPS home acquired
  },

  ---------------------------------
  -- ALARMS
  ---------------------------------
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
  --]]
  alarms = {
  --{ notified, alarm_start, armed, type(0=min,1=max,2=timer,3=batt), grace, ready, last_alarm}
    { false, 0 , false, 0, 0, false, 0}, --MIN_ALT
    { false, 0 , false, 1, 0, false, 0 }, --MAX_ALT
    { false, 0 , false, 1, 0, false, 0 }, --15
    { false, 0 , true, 1, 0, false, 0 }, --FS_EKF
    { false, 0 , true, 1, 0, false, 0 }, --FS_BAT
    { false, 0 , true, 2, 0, false, 0 }, --FLIGTH_TIME
    { false, 0 , false, 3, 4, false, 0 }, --BATT L1
    { false, 0 , false, 4, 4, false, 0 }, --BATT L2
    { false, 0 , true, 1, 0, false, 0 }, --FS
    { false, 0 , true, 1, 0, false, 0 }, --FENCE
    { false, 0 , true, 1, 0, false, 0 }, --TERRAIN
  },

  transitions = {
  --{ last_value, last_changed, transition_done, delay }
    { 0, 0, false, 30 },
  },

  ---------------------------
  -- BATTERY TABLE
  ---------------------------
  battery = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  batLevels = {0,5,10,15,20,25,30,40,50,60,70,80,90},
  minmaxValues = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},

  -- UNIT CONVERSION
  unitConversion = {},
  battPercByVoltage = {},
  wpEnabledModeList = {
    ['AUTO'] = 1,
    ['GUIDED'] = 1,
    ['LOITER'] = 1,
    ['RTL'] = 1,
    ['QRTL'] = 1,
    ['QLOITER'] = 1,
    ['QLAND'] = 1,
    ['FOLLOW'] = 1,
    ['ZIGZAG'] = 1,
  },
  colors = {
    white = WHITE,
    red = RED,
    green = GREEN,
    black = BLACK,
    yellow = lcd.RGB(255,206,0),
    panelLabel = lcd.RGB(150,150,150),
    panelText = lcd.RGB(255,255,255),
    panelBackground = lcd.RGB(56,60,56),
    barBackground = BLACK,
    barText = WHITE,
    hudSky = lcd.RGB(123,157,255),
    hudTerrain = lcd.RGB(100,185,95),
    hudDashes = lcd.RGB(250, 205, 205),
    hudLines = lcd.RGB(220, 220, 220),
    hudSideText = lcd.RGB(0,238,49),
    hudText = lcd.RGB(255,255,255),
    rpmBar = lcd.RGB(240,192,0),
    background = lcd.RGB(60, 60, 60)
  },
}

status.frameNames = nil -- require "/scripts/yaapu/lib/frame_names"
status.frameTypes = nil -- require "/scripts/yaapu/lib/frame_types"
status.frame = {}

local libs = {
  drawLib = nil,
  hudLib = nil,
  resetLib = nil,
  utils = nil,
  mapLib = nil,
  sport = nil,
}

--[[
UNIT_AMPERE
UNIT_AMPERE_HOUR
UNIT_CELSIUS
UNIT_CENTIMETER
UNIT_CENTIMETER_PER_SECOND
UNIT_DB
UNIT_DBM
UNIT_DEGREE
UNIT_FAHRENHEIT
UNIT_FOOT
UNIT_FOOT_PER_SECOND
UNIT_G
UNIT_HERTZ
UNIT_HOUR
UNIT_KILOMETER
UNIT_KNOT
UNIT_KPH
UNIT_METER
UNIT_METER_PER_SECOND
UNIT_MICROSECOND
UNIT_MILLIAMPERE
UNIT_MILLIAMPERE_HOUR
UNIT_MILLILITER
UNIT_MILLILITER_PER_MINUTE
UNIT_MILLILITER_PER_PULSE
UNIT_MILLISECOND
UNIT_MILLIVOLT
UNIT_MILLIWATT
UNIT_MINUTE
UNIT_MPH
UNIT_PERCENT
UNIT_RADIAN
UNIT_RPM
UNIT_SECOND
UNIT_VOLT
UNIT_WATT
]]
-- { value, decimals, unit}
status.luaSourcesConfig = {}

status.luaSourcesConfig.Voltage =  {0, 1, UNIT_VOLT, nil, 0.1}
status.luaSourcesConfig.Current =  {0, 1, UNIT_AMPERE, nil, 0.1}
status.luaSourcesConfig.Battery =  {0, 0, UNIT_PERCENT, nil, 1}
status.luaSourcesConfig.ArmStatus =   {0, 0, nil, "statusArmed", 1}
status.luaSourcesConfig.FlightMode =    {0, 0, nil, "flightMode", 1}
status.luaSourcesConfig.Heading =   {0, 0, UNIT_DEGREE, "yaw", 1}
status.luaSourcesConfig.Altitude =   {0, 0, UNIT_METER, "homeAlt", 1}
status.luaSourcesConfig.GPSAltitude =  {0, 0, UNIT_METER, "gpsAlt", 0.1}
status.luaSourcesConfig.AirSpeed =  {0, 1, UNIT_METER_PER_SECOND, "airspeed", 0.1}
status.luaSourcesConfig.GroundSpeed =  {0, 1, UNIT_METER_PER_SECOND, "hSpeed", 0.1}
status.luaSourcesConfig.VSpeed =  {0, 1, UNIT_METER_PER_SECOND, "vSpeed", 0.1}
status.luaSourcesConfig.Rpm1 =  {0, 0, UNIT_RPM, "rpm1" ,1}
status.luaSourcesConfig.Rpm2 =  {0, 0, UNIT_RPM, "rpm2", 1}
status.luaSourcesConfig.Throttle =   {0, 0, UNIT_PERCENT, "throttle", 1}
status.luaSourcesConfig.Roll =  {0, 0, UNIT_DEGREE, "roll", 1}
status.luaSourcesConfig.Pitch =  {0, 0, UNIT_DEGREE, "pitch", 1}

local function sourceWakeup(source)
  if source ~= nil then
    local v = status.luaSourcesConfig[source:name()]
    if source:name() == "Voltage" then
      source:value(status.battery[4] * v[5])
    elseif source:name() == "Current" then
      source:value(status.battery[7] * v[5])
    elseif source:name() == "Battery" then
      source:value(status.battery[16] * v[5])
    else
      if v[2] == 0 then
        source:value(tonumber(status.telemetry[v[4]])==nil and 0 or math.floor(0.5 + status.telemetry[v[4]] * v[5]))
      else
        source:value(tonumber(status.telemetry[v[4]])==nil and 0 or (status.telemetry[v[4]] * v[5]))
      end
    end
  end
end

local function loadLib(name)
  local lib = dofile("/scripts/yaaputelemetry/lib/"..name..".lua")
  if lib.init ~= nil then
    lib.init(status, libs)
  end
  return lib
end

local function initLibs()
  if status.frameNames == nil then
    status.frameNames = loadLib("frame_names")
  end
  if status.frameTypes == nil then
    status.frameTypes = loadLib("frame_types")
  end
  if libs.utils == nil then
    libs.utils = loadLib("utils")
  end
  if libs.drawLib == nil then
    libs.drawLib = loadLib("drawlib")
  end
  if libs.hudLib == nil then
    libs.hudLib = loadLib("hudlib")
  end
  if libs.resetLib == nil then
    libs.resetLib = loadLib("resetlib")
  end
  if libs.mapLib == nil then
    libs.mapLib = loadLib("maplib")
  end
  if libs.sportLib == nil then
    libs.sportLib = loadLib("sport")
  end
end

function checkLandingStatus()
  if status.timerRunning == 0 and status.telemetry.landComplete == 1 and status.lastTimerStart == 0 then
    libs.utils.startTimer()
  end
  if status.timerRunning == 1 and status.telemetry.landComplete == 0 and status.lastTimerStart ~= 0 then
    libs.utils.stopTimer()
    -- play landing complete anly if motorts are armed
    if status.telemetry.statusArmed == 1 then
      utils.playSound("landing")
    end
  end
  status.timerRunning = status.telemetry.landComplete
end

function checkCellVoltage()
  if status.battery[1] <= 0 then
    return
  end
  -- check alarms
  libs.utils.checkAlarm(status.conf.battAlertLevel1, status.battery[1], 7, -1, "batalert1", status.conf.repeatAlertsPeriod)
  libs.utils.checkAlarm(status.conf.battAlertLevel2, status.battery[1], 8, -1, "batalert2", status.conf.repeatAlertsPeriod)
  -- cell bgcolor is sticky but gets triggered with alarms
  if status.battLevel1 == false then status.battLevel1 = status.alarms[7][1] end
  if status.battLevel2 == false then status.battLevel2 = status.alarms[8][1] end
  --print("BATT L1",status.alarms[7][1],status.alarms[7][2],status.alarms[7][3],status.alarms[7][4],status.alarms[7][5],status.alarms[7][6],status.alarms[7][7])
end

function checkEvents()
  libs.utils.loadFlightModes()

  -- silence alarms when showing min/max values
  if status.showMinMaxValues == false then
    local alt = status.terrainEnabled == 1 and status.telemetry.heightAboveTerrain or status.telemetry.homeAlt
    libs.utils.checkAlarm(status.conf.minAltitudeAlert, alt, 1, -1, "minalt", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(status.conf.maxAltitudeAlert, alt, 2, 1, "maxalt", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(status.conf.maxDistanceAlert, status.telemetry.homeDist, 3, 1, "maxdist", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(1, 2*status.telemetry.ekfFailsafe, 4, 1, "ekf", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(1, 2*status.telemetry.battFailsafe, 5, 1, "lowbat", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(1, 2*status.telemetry.failsafe, 9, 1, "failsafe", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(1, 2*status.telemetry.fenceBreached, 10, 1, "fencebreach", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(1, 2*status.telemetry.terrainUnhealthy, 11, 1, "terrainko", status.conf.repeatAlertsPeriod)
    libs.utils.checkAlarm(status.conf.timerAlert, status.flightTime, 6, 1, "timealert", status.conf.timerAlert)
  end

  if status.conf.enableBattPercByVoltage == true then
    status.batLevel = libs.utils.getBattPercByCell(status.battery[1]*0.01)
  else
    if (status.battery[13] > 0) then
      status.batLevel = (1 - (status.battery[10]/status.battery[13]))*100
    else
      status.batLevel = 99
    end
  end

  for l=1,13 do
    -- trigger alarm as as soon as it falls below level + 1 (i.e 91%,81%,71%,...)
    if status.batLevel <= status.batLevels[l] + 1 and l < status.lastBattLevel then
      status.lastBattLevel = l
      libs.utils.playSound("bat"..status.batLevels[l])
      break
    end
  end

  if status.telemetry.statusArmed == 1 and status.lastStatusArmed == 0 then
    status.lastStatusArmed = status.telemetry.statusArmed
    libs.utils.playSound("armed")
    if status.telemetry.fencePresent == 1 then
      libs.utils.playSound("fence")
    end
    -- reset home on arming
    status.telemetry.homeLat = nil
    status.telemetry.homeLon = nil
  elseif status.telemetry.statusArmed == 0 and status.lastStatusArmed == 1 then
    status.lastStatusArmed = status.telemetry.statusArmed
    libs.utils.playSound("disarmed")
  end

  if status.telemetry.gpsStatus > 2 and status.lastGpsStatus <= 2 then
    status.lastGpsStatus = status.telemetry.gpsStatus
    libs.utils.playSound("gpsfix")
  elseif status.telemetry.gpsStatus <= 2 and status.lastGpsStatus > 2 then
    status.lastGpsStatus = status.telemetry.gpsStatus
    libs.utils.playSound("gpsnofix")
  end

  -- home detecting code
  if status.telemetry.homeLat == nil then
    if status.telemetry.gpsStatus > 2 and status.telemetry.homeAngle ~= -1 then
      status.telemetry.homeLat, status.telemetry.homeLon = libs.utils.getLatLonFromAngleAndDistance(status.telemetry.homeAngle, status.telemetry.homeDist)
    end
  end

  -- flightmode transitions have a grace period to prevent unwanted flightmode call out
  -- on quick radio mode switches
  if status.telemetry.frameType ~= -1 and libs.utils.checkTransition(1,status.telemetry.flightMode) then
    libs.utils.playSoundByFlightMode(status.telemetry.flightMode)
    -- check if we should enable waypoint plotting for this flight mode
    -- supported modes are AUTO, GUIDED, LOITER, RTL, QRTL, QLOITER, QLAND, FOLLOW, ZIGZAG
    -- see /MAVProxy/modules/mavproxy_map/__init__.py
    if status.wpEnabledModeList[string.upper(status.frame.flightModes[status.telemetry.flightMode])] == 1 then
      status.wpEnabledMode = 1
    else
      status.wpEnabledMode = 0
    end
    --print('luaDebug', status.wpEnabledMode)
  end

  if status.telemetry.simpleMode ~= status.lastSimpleMode then
    if status.telemetry.simpleMode == 0 then
      libs.utils.playSound( status.lastSimpleMode == 1 and "simpleoff" or "ssimpleoff" )
    else
      libs.utils.playSound( status.telemetry.simpleMode == 1 and "simpleon" or "ssimpleon" )
    end
    status.lastSimpleMode = status.telemetry.simpleMode
  end
end

local function checkSize(widget)
  w, h = lcd.getWindowSize()
  text_w, text_h = lcd.getTextSize("")
  lcd.font(FONT_STD)
  lcd.drawText(w/2, (h - text_h)/2, w.." x "..h, CENTERED)
  return true
end

local function createOnce(widget)
  -- only this widget instance will run bg tasks
  status.currentModel = model.name()
  widget.runBgTasks = true
  libs.utils.playSound("yaapu")
  libs.utils.pushMessage(7, "Yaapu Telemetry Widget 1.0.0 beta1".. " ("..'141293d'..")")
  -- create the YaapuTimer if missing
  if model.getTimer("Yaapu") == nil then
    local timer = model.createTimer()
    timer:name("Yaapu")
    timer:countdownStart(0)
    timer:audioMode(AUDIO_MUTE)
  end
  libs.utils.stopTimer()
  -- get a reference to the plotSources table
  --status.plotSources = menuLib.plotSources
end

local function reset(widget)
  if status.telemetry.statusArmed == 1 then
    libs.utils.pushMessage(1,"Reset ignored while armed")
    return
  end
  libs.resetLib.reset(widget)
end


local function loadLayout(widget)

  lcd.pen(SOLID)
  lcd.color(lcd.RGB(20, 20, 20))
  lcd.drawFilledRectangle(40, 70, 400, 140)
  lcd.color(status.colors.white)
  lcd.drawRectangle(40, 70, 400, 140,3)
  lcd.color(status.colors.white)
  lcd.font(FONT_XXL)
  lcd.drawText(240, 100, "loading layout...", CENTERED)

  if widget.screen == 1 then
    if widget.leftPanel == nil then
      --print("LEFT")
      widget.leftPanel = loadLib(status.leftPanelFilenames[widget.leftPanelIndex])
      return
    end

    if widget.centerPanel == nil then
      --print("CENTER")
      widget.centerPanel = loadLib(status.centerPanelFilenames[widget.centerPanelIndex])
      return
    end

    if widget.rightPanel == nil then
      --print("RIGHT")
      widget.rightPanel = loadLib(status.rightPanelFilenames[widget.rightPanelIndex])
      return
    end
  end

  if status.layout[widget.screen] == nil then
    --print("LAYOUT")
    status.layout[widget.screen] = loadLib(status.layoutFilenames[widget.screen])
  end
  widget.ready = true
end

status.blinkTimer = getTime()
local updateCog = 0

local sportConn = nil

local sportPacket = {
  physId = 0,
  primId = 0,
  appId = 0,
  data = 0,
}

-- 5Hz
local function task1(now)
  -- update total distance as often as po
  libs.utils.updateTotalDist()
end

-- 2Hz
local function task2(now)
  -- rssi
  if status.conf.enableCRSF then
    -- apply same algo used by ardupilot to estimate a 0-100 rssi value
    -- rssi = roundf((1.0f - (rssi_dbm - 50.0f) / 70.0f) * 255.0f);
    local rssi_dbm = math.abs(libs.utils.getSourceValue("1RSS"))
    if libs.utils.getSourceValue("ANT") ~= 0 then
      rssi_dbm = math.abs(libs.utils.getSourceValue("2RSS"))
    end
    status.telemetry.rssiCRSF = math.min(100, math.floor(0.5 + ((1-(rssi_dbm - 50)/70)*100)))
  end
  status.telemetry.rssi = libs.utils.getRSSI()
  -- update battery
  libs.utils.calcBattery()
  checkEvents()
  checkLandingStatus()
  checkCellVoltage()
end

-- 1Hz
local function task3(now)
  if status.telemetry.lat ~= nil and status.telemetry.lon ~= nil then
    if status.conf.gpsFormat == 1 then
      -- DMS
      status.telemetry.strLat = libs.utils.decToDMSFull(status.telemetry.lat)
      status.telemetry.strLon = libs.utils.decToDMSFull(status.telemetry.lon, status.telemetry.lat)
    else
      -- decimal
      status.telemetry.strLat = string.format("%.06f", status.telemetry.lat)
      status.telemetry.strLon = string.format("%.06f", status.telemetry.lon)
    end
  end

  -- if we do not see terrain data for more than 5 sec we assume TERRAIN_ENABLE = 0
  if status.terrainEnabled == 1 and now - status.terrainLastData > 500 then
    status.terrainEnabled = 0
    status.telemetry.terrainUnhealthy = 0
  end

  if status.currentModel ~=  model.name() then
    status.currentModel = model.name()
    libs.resetLib.reset()
  end
end

-- 1Hz
local function task4(now)
  libs.utils.updateFlightTime()

  if status.telemetry.lat ~= nil and status.telemetry.lon ~= nil then
    if updateCog == 1 then
      -- update COG
      if status.lastLat ~= nil and status.lastLon ~= nil and status.lastLat ~= status.telemetry.lat and status.lastLon ~= status.telemetry.lon then
        local cog = libs.utils.getAngleFromLatLon(status.lastLat, status.lastLon, status.telemetry.lat, status.telemetry.lon)
        status.cog = cog ~= nil and cog or status.cog
      end
      updateCog = 0
    else
      -- update last GPS coords
      status.lastLat = status.telemetry.lat
      status.lastLon = status.telemetry.lon
      -- process wpLat and wpLon updates
      if status.wpEnabled == 1 then
        status.wpLat, status.wpLon = libs.utils.getLatLonFromAngleAndDistance(status.telemetry.wpBearing, status.telemetry.wpDistance)
      end
      updateCog = 1
    end
  end
  -- lua sources update
  pcall(sourceWakeup)

  -- flight mode
  if status.frame.flightModes then
    status.strFlightMode = status.frame.flightModes[status.telemetry.flightMode]
    if status.strFlightMode ~= nil and status.telemetry.simpleMode > 0 then
      local strSimpleMode = status.telemetry.simpleMode == 1 and "(S)" or "(SS)"
      status.strFlightMode = string.format("%s%s",status.strFlightMode,strSimpleMode)
    end
  end
end

-- 1Hz
local function task5(now)
  -- layout background callback
  for screen=1,4
  do
    if status.layout[screen] ~= nil and status.layout[screen].background  ~= nil then
      status.layout[screen].background(widget)
    end
  end

  -- top bar model frame and name
  if status.modelString == nil then
    local fn = status.frameNames[status.telemetry.frameType]
    if fn ~= nil then
      status.modelString = model.name()
    end
  else
    if model.name() ~= status.modelString then
      print("*********** modelChange *************")
      libs.resetLib.reset()
    end
  end
end

-- 0.5Hz
local function task6(now)
  -- if we do not see terrain data for more than 5 sec we assume TERRAIN_ENABLE = 0
  if status.terrainEnabled == 1 and now - status.terrainLastData > 500 then
    status.terrainEnabled = 0
    status.telemetry.terrainUnhealthy = 0
  end

  if status.currentModel ~=  model.name() then
    status.currentModel = model.name()
    libs.resetLib.reset()
  end
end


local tasks = {
  {0, 20, task1},     -- 5.0Hz
  {0, 50, task2},     -- 2.0Hz
  {0, 50, task3},     -- 2.0Hz
  {0, 50, task4},     -- 2.0Hz
  {0, 100, task5},    -- 1.0Hz
  {0, 200, task6},    -- 0.5Hz
}

local function checkTaskTimeConstraints(now, taskId)
  return (now - tasks[taskId][1]) >= tasks[taskId][2]
end

local function runScheduler(tasks)
  local now = getTime()
  local maxDelayTaskId = -1
  local maxDelay = 0
  local delay = 0

  for taskId=1,#tasks
  do
    delay = (now - (tasks[taskId][1]))/tasks[taskId][2]
    if (delay >= maxDelay and checkTaskTimeConstraints(now, taskId)) then
      maxDelay = delay
      maxDelayTaskId = taskId
    end
  end
  if maxDelayTaskId < 0 then
    return maxDelayTaskId
  end
  tasks[maxDelayTaskId][1] = now;
  tasks[maxDelayTaskId][3](getTime())
end

local bg_counter = 0
local bg_rate = 0
local bg_timer = 0

local function bgtasks(widget)
  -- background rate calculator
  -- skip first iteration
  if bg_rate == 0 then
    bg_rate = bg_counter
  end

  bg_counter=bg_counter+1

  local now = getTime()
  if now - bg_timer > 100 then
    bg_rate = bg_rate*0.5 + bg_counter*0.5
    bg_counter = 0
    bg_timer = now
  end

  -- blinking support
  local now = getTime()
  status.counter = status.counter + 1
  ------------------------------
  if status.conf.telemetrySource == 1 and status.pauseTelemetry == false then
    for i=1,10
    do
      local physId, primId, appId, data = libs.utils.telemetryPop()
      if primId == 0x10 then
        status.noTelemetryData = 0
        -- no telemetry dialog only shown once
        status.hideNoTelemetry = true
        libs.utils.processTelemetry(appId, data, now)
      end
    end
  elseif status.conf.telemetrySource == 2 then
    if sportConn == nil then
      sportConn = serial.open("sport")
    else
      local buff = sportConn:read()
      --print("sport.read()", #buff)
      for i=1,#buff
      do
        if libs.sportLib.process_byte(sportPacket, buff:byte(i)) then
          status.noTelemetryData = 0
          -- no telemetry dialog only shown once
          status.hideNoTelemetry = true
          if sportPacket.primId == 0x10 then
            --[[
            print("packet.physId", string.format("%02X",sportPacket.physId))
            print("packet.primId", string.format("%02X",sportPacket.primId))
            print("packet.appId", string.format("%04X",sportPacket.appId))
            print("packet.data", string.format("%08X",sportPacket.data))
            --]]
            libs.utils.processTelemetry(sportPacket.appId, sportPacket.data, now)
          end
        end
      end
    end
  end

  runScheduler(tasks)

  if now - status.blinkTimer > 60 then
    status.blinkon = not status.blinkon
    status.blinkTimer = now
  end
  status.loadCycle = (status.loadCycle + 1) % 8
end


local function onScreenChange(widget)
  status.showMessages = false
end

local fg_counter = 0
local fg_rate = 0
local fg_timer = 0

-- called only when visible
local function paint(widget)

    lcd.pen(SOLID)

    local now = getTime()
    if status.lastScreen ~= widget.screen then
      onScreenChange(widget)
      status.lastScreen = widget.screen
    end

    if not checkSize(widget) then
      return
    end

    if status.showMessages then
      lcd.color(status.colors.black)
      lcd.drawFilledRectangle(0,0,480,320)
      libs.drawLib.drawMessagesBar(widget,26)
    else
      lcd.color(status.colors.background)
      lcd.drawFilledRectangle(0,0,480,320)
      if widget.ready == true then
        status.layout[widget.screen].draw(widget)

        if status.layout[widget.screen].showArmingStatus == true then
          libs.drawLib.drawArmingStatus(widget)
        end

        if status.layout[widget.screen].showFailsafe == true then
          libs.drawLib.drawFailsafe(widget)
        end
      end
    end

    -- no telemetry/minmax outer box
    if status.pauseTelemetry then
      lcd.color(status.colors.yellow)
      libs.drawLib.drawBlinkRectangle(0,0,480,320,3)
      libs.drawLib.drawWidgetPaused()
    else
      if libs.utils.telemetryEnabled() == false then
        -- no telemetry inner box
        if not status.hideNoTelemetry then
          libs.drawLib.drawNoTelemetryData(widget)
        end
        lcd.color(RED)
        libs.drawLib.drawBlinkRectangle(0,0,480,320,3)
      else
        if status.showMinMaxValues == true then
          lcd.color(status.colors.yellow)
          libs.drawLib.drawBlinkRectangle(0,0,480,320,3)
        end
      end
    end

    -- skip first iteration
    if fg_rate == 0 then
      fg_rate = fg_counter
    end

    fg_counter=fg_counter+1

    if now - fg_timer > 100 then
      fg_rate = fg_rate*0.5 + fg_counter*0.5
      fg_counter = 0
      fg_timer = now
    end
end

-- called when event is passed to the widget
local function event(widget, category, value, x, y)
--[[
    print("EVT:")
    print("   cat:", category)
    print("   val:", value)
    print("   x,y:",x,y)
--]]
    local kill = false
    if category == EVT_TOUCH then
      --and value == TOUCH_ENTER
      if widget.screen == 1 and value == 16641 then
        kill = true
        -- main view
        if y < 320*0.73 then
          -- process the event and activate the context menu
          kill = false
        else
          if status.showMessages then
            status.showMessages = false
          else
            status.showMessages = true
          end
        end
      elseif widget.screen == 2 and value == 16641 then
        kill = true
        if libs.drawLib.isInside(x, y, 480*0.625, 0,480, 320/2) == true then
          status.mapZoomLevel = math.min(status.conf.mapZoomMax, status.mapZoomLevel+1)
        elseif libs.drawLib.isInside(x, y, 480*0.625, 320/2, 480,320) == true then
          status.mapZoomLevel = math.max(status.conf.mapZoomMin, status.mapZoomLevel-1)
        else
          kill = false
        end
      elseif widget.screen == 3 then
      end
    end
    if kill then
      system.killEvents(value)
      return true
    end
    return false
end

-- widget custom context menu
local function menu(widget)
  local startStopLabel = "Yaapu: "..(status.pauseTelemetry == false and "Pause widget" or "Start widget")

  if widget.screen == 2 then
    return {
      { "Yaapu: Zoom in", function() status.mapZoomLevel = math.min(status.conf.mapZoomMax, status.mapZoomLevel+1) end},
      { "Yaapu: Zoom out", function() status.mapZoomLevel = math.max(status.conf.mapZoomMin, status.mapZoomLevel-1) end},
      { startStopLabel, function() status.pauseTelemetry = not status.pauseTelemetry end},
      { "Yaapu: Reset widget", function() reset(widget) end },
    }
  else
    return {
      { startStopLabel, function() status.pauseTelemetry = not status.pauseTelemetry end},
      { "Yaapu: Reset widget", function() reset(widget) end },
    }
  end
end


local timer5Hz = getTime()
local timer10Hz = getTime()
-- always called @10Hz even when in system menus
local function wakeup(widget)
  local now = getTime()
  -- one time init
  -- multiple instances of the same
  -- widget need to call this only once
  if status.initPending then
    createOnce(widget)
    status.initPending = false
  end

  if widget.runBgTasks then
    bgtasks(widget)
  end


  if not widget.ready or status.layout[widget.screen] == nil then
    loadLayout(widget);
  end
  if now - timer5Hz > 20 then
    lcd.invalidate()
    timer5Hz = now
  else
    if widget.screen == 1 then
      -- artificial horizon @10Hz
      if now - timer10Hz > 10 then
        lcd.invalidate(HUD_X, HUD_Y, HUD_W, HUD_H)
        timer10Hz = now
      end
    else
      -- other screens refresh at full speed
      lcd.invalidate()
    end
  end
  --[[
  print("=========================")
  local mem = {}
  mem = system.getMemoryUsage()
  print("Main Stack: "..mem["mainStackAvailable"])
  print("RAM Avail: "..mem["ramAvailable"])
  print("LUA RAM Avail: "..mem["luaRamAvailable"])
  print("LUA BMP Avail: "..mem["luaBitmapsRamAvailable"])
  print("=========================")
  --]]
end

------------------------------------------------
-- create() is called once at widget creation
-- it sets widget properties
-- status.conf is shared between widget instances
-------------------------------------------------
local function create()
    if not status.initPending then
      status.initPending = true
    end

    initLibs()
    return {
      ------------------
      -- shared config
      ------------------
      conf = status.conf,

      ------------------
      -- widget config
      ------------------
      ready = false,
      runBgTasks = false,
      -- screen type
      screen=1,
      -- panel config
      centerPanelIndex = 1,
      leftPanelIndex = 1,
      rightPanelIndex = 1,
      -------------------
      -- widget properties
      -------------------
      layout = nil,
      centerPanel = nil,
      leftPanel = nil,
      rightPanel = nil,
    }
end

local function applyDefault(value, defaultValue, lookup)
  local v = value ~= nil and value or defaultValue
  if lookup ~= nil then
    return lookup[v]
  end
  return v
end

local function storageToConfig(name, defaultValue, lookup)
  local storageValue = storage.read(name)
  local value = applyDefault(storageValue, defaultValue, lookup)
  print("storageToConfig()", name, storageValue, value)
  return value
end

local function configToStorage(value, lookup)
  if lookup ~= nil then
    for i=1,#lookup
    do
      if lookup[i] == value then
        return i
      end
    end
    return 1 -- assume 1 as default index
  end
  return value
end

local function configure(widget)
  local f
  local line = form.addLine("Link quality source")
  form.addSourceField(line, nil, function() return status.conf.linkQualitySource end, function(value) status.conf.linkQualitySource = value end)

  line = form.addLine("Link status source 2")
  form.addSourceField(line, nil, function() return status.conf.linkStatusSource2 end, function(value) status.conf.linkStatusSource2 = value end)

  line = form.addLine("Link status source 3")
  form.addSourceField(line, nil, function() return status.conf.linkStatusSource3 end, function(value) status.conf.linkStatusSource3 = value end)

  line = form.addLine("Link status source 4")
  form.addSourceField(line, nil, function() return status.conf.linkStatusSource4 end, function(value) status.conf.linkStatusSource4 = value end)
    line = form.addLine("Telemetry source")
    widget.screenField = form.addChoiceField(line, form.getFieldSlots(line)[0],  {{"default",1}, {"external sport", 2}}, function() return status.conf.telemetrySource end, function(value) status.conf.telemetrySource = value end);
  line = form.addLine("Screen Type")
  widget.screenField = form.addChoiceField(line, form.getFieldSlots(line)[0],
      {
        {"default",1},
        {"maps", 2},
        --{"plot",3},
      }, function() return widget.screen end,
    function(value)
      widget.screen = value
      widget.centerPanelField:enable(widget.screen == 1)
      widget.leftPanelField:enable(widget.screen == 1)
      widget.rightPanelField:enable(widget.screen == 1)
    end
  );
  -- Center
  line = form.addLine("Center Panel")
  widget.centerPanelField = form.addChoiceField(line, form.getFieldSlots(line)[0], {{"default",1}}, function() return widget.centerPanelIndex end, function(value) widget.centerPanelIndex = value end);
  -- Left
  line = form.addLine("Left Panel")
  widget.leftPanelField = form.addChoiceField(line, form.getFieldSlots(line)[0], {{"default",1}}, function() return widget.leftPanelIndex end, function(value) widget.leftPanelIndex = value end);
  -- Right
  line = form.addLine("Right Panel")
  widget.rightPanelField = form.addChoiceField(line, form.getFieldSlots(line)[0], {{"default",1}}, function() return widget.rightPanelIndex end, function(value) widget.rightPanelIndex = value end);

  -- battery
  line = form.addLine("Battery voltage source")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"Telemetry", 1}, {"Frsky FLVSS", 2}}, function() return status.conf.defaultBattSourceId end,
    function(value)
      status.conf.defaultBattSourceId = value
      widget.battery1SourceField:enable(value==2)
      widget.battery2SourceField:enable(value==2)
    end
  )

  line = form.addLine("Battery 1 LiPo sensor")
  widget.battery1SourceField = form.addSourceField(
    line, nil,
    function() return status.conf.battery1Source end,
    function(value) status.conf.battery1Source = value end
  )
  widget.battery1SourceField:enable(status.conf.defaultBattSourceId==2)

  line = form.addLine("Battery 2 LiPo sensor")
  widget.battery2SourceField = form.addSourceField(
    line, nil,
    function() return status.conf.battery2Source end,
    function(value) status.conf.battery2Source = value end
  )
  widget.battery2SourceField:enable(status.conf.defaultBattSourceId==2)

  line = form.addLine("Enable battery % by voltage")
  form.addBooleanField(line, nil, function() return status.conf.enableBattPercByVoltage end, function(value) status.conf.enableBattPercByVoltage = value end)

  line = form.addLine("Enable battery % by voltage")
  form.addBooleanField(line, nil, function() return status.conf.enableBattPercByVoltage end, function(value) status.conf.enableBattPercByVoltage = value end)

  line = form.addLine("Battery voltage alert level 1")
  f = form.addNumberField(line, nil, 0, 10000, function() return status.conf.battAlertLevel1 end, function(value) status.conf.battAlertLevel1 = value end )
  f:step(5)
  f:decimals(2)
  f:suffix("V")

  line = form.addLine("Battery voltage alert level 2")
  f = form.addNumberField(line, nil, 0, 10000, function() return status.conf.battAlertLevel2 end, function(value) status.conf.battAlertLevel2 = value end )
  f:step(5)
  f:decimals(2)
  f:suffix("V")

  line = form.addLine("Dual battery config")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"Parallel", 1}, {"Series", 2}, {"Dual with alerts on B1", 3}, {"Dual with alerts on B2", 4}, {"Volts from B1, Curr from B2",5}, {"Volts from B2, Curr from B1",6}}, function() return status.conf.battConf end, function(value) status.conf.battConf = value end)

  line = form.addLine("Battery 1 cell count override")
  f = form.addNumberField(line, nil, 0, 16, function() return status.conf.cell1Count end, function(value) status.conf.cell1Count = value end )
  f:suffix("s")
  line = form.addLine("Battery 2 cell count override")
  f = form.addNumberField(line, nil, 0, 16, function() return status.conf.cell2Count end, function(value) status.conf.cell2Count = value end )
  f:suffix("s")

  line = form.addLine("Battery 1 capacity override")
  f = form.addNumberField(line, nil, 0, 500, function() return status.conf.battCapOverride1 end, function(value) status.conf.battCapOverride1 = value end )
  f:step(1)
  f:decimals(1)
  f:suffix("Ah")
  line = form.addLine("Battery 2 capacity override")
  f = form.addNumberField(line, nil, 0, 500, function() return status.conf.battCapOverride2 end, function(value) status.conf.battCapOverride2 = value end )
  f:step(1)
  f:decimals(1)
  f:suffix("Ah")

  line = form.addLine("Airspeed/Groundspeed unit")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"m/s", 1}, {"km/h", 2}, {"mph", 3}, {"kn",4}}, function() return status.conf.horSpeedUnit end, function(value) status.conf.horSpeedUnit = value end)

  line = form.addLine("Vertical speed unit")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"m/s", 1}, {"ft/s", 2}, {"ft/min", 3}}, function() return status.conf.vertSpeedUnit end, function(value) status.conf.vertSpeedUnit = value end)

  line = form.addLine("Altitude/Distance unit")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"m", 1}, {"ft", 2}}, function() return status.conf.distUnit end, function(value) status.conf.distUnit = value end)

  line = form.addLine("Long distance unit")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"km", 1}, {"mi", 2}}, function() return status.conf.distUnitLong end, function(value) status.conf.distUnitLong = value end)

  line = form.addLine("GPS coordinates format")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"DMS", 1}, {"Decimal", 2}}, function() return status.conf.gpsFormat end, function(value) status.conf.gpsFormat = value end)

  line = form.addLine("Disable all sounds")
  form.addBooleanField(line, nil, function() return status.conf.disableAllSounds end, function(value) status.conf.disableAllSounds = value end)

  line = form.addLine("Silence incoming message beep")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"Never", 1}, {"All but critical messages", 2}, {"Always", 3}}, function() return status.conf.disableMsgBeep end, function(value) status.conf.disableMsgBeep = value end)

  line = form.addLine("Enable haptic feedback")
  form.addBooleanField(line, nil, function() return status.conf.enableHaptic end, function(value) status.conf.enableHaptic = value end)

  line = form.addLine("Timer alert period")
  f = form.addNumberField(line, nil, 0, 600, function() return status.conf.timerAlert end, function(value) status.conf.timerAlert = value end )
  f:suffix("sec")

  line = form.addLine("Generic alerts period")
  f = form.addNumberField(line, nil, 5, 600, function() return status.conf.repeatAlertsPeriod end, function(value) status.conf.repeatAlertsPeriod = value end )
  f:suffix("sec")

  line = form.addLine("Minimun altitude alert")
  f = form.addNumberField(line, nil, 0, 500, function() return status.conf.minAltitudeAlert end, function(value) status.conf.minAltitudeAlert = value end )
  f:suffix("m")
  f:step(1)

  line = form.addLine("Maximum altitude alert")
  f = form.addNumberField(line, nil, 0, 10000, function() return status.conf.maxAltitudeAlert end, function(value) status.conf.maxAltitudeAlert = value end )
  f:suffix("m")
  f:step(5)

  line = form.addLine("Maximum distance alert")
  f = form.addNumberField(line, nil, 0, 1000000, function() return status.conf.maxDistanceAlert end, function(value) status.conf.maxDistanceAlert = value end )
  f:suffix("m")
  f:step(5)

  line = form.addLine("Rangefinder max distance")
  f = form.addNumberField(line, nil, 0, 5000, function() return status.conf.rangeFinderMax end, function(value) status.conf.rangeFinderMax = value end )
  f:suffix("cm")
  f:step(10)

  line = form.addLine("Enable PX4 support")
  form.addBooleanField(line, nil, function() return status.conf.enablePX4Modes end, function(value) status.conf.enablePX4Modes = value end)

  line = form.addLine("Enable CRSF support")
  f = form.addBooleanField(line, nil, function() return status.conf.enableCRSF end, function(value) status.conf.enableCRSF = value end)
  f:enable(true)

  line = form.addLine("Display RPM data")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"no", 1}, {"RPM 1", 2}, {"RPM 1 + RPM 2", 3}}, function() return status.conf.enableRPM end, function(value) status.conf.enableRPM = value end)

  line = form.addLine("Display WIND data")
  form.addBooleanField(line, nil, function() return status.conf.enableWIND end, function(value) status.conf.enableWIND = value end)

  line = form.addLine("Map provider")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"GMapCatcher", 1}, {"Google", 2}}, function() return status.conf.mapProvider end,
    function(value)
      status.conf.mapProvider = value
      widget.googleZoomField:enable(value==2)
      widget.googleZoomMaxField:enable(value==2)
      widget.googleZoomMinField:enable(value==2)
      widget.gmapZoomField:enable(value==1)
      widget.gmapZoomMaxField:enable(value==1)
      widget.gmapZoomMinField:enable(value==1)
    end
  )

  line = form.addLine("Map type")
  form.addChoiceField(line, form.getFieldSlots(line)[0], {{"Satellite", 1}, {"Hybrid (Google only)", 2}, {"Map", 3}, {"Terrain", 4}}, function() return status.conf.mapTypeId end, function(value) status.conf.mapTypeId = value end)

  line = form.addLine("Google zoom")
  widget.googleZoomField = form.addNumberField(line, nil, 1, 20,
    function()
      widget.googleZoomField:enable(status.conf.mapProvider==2)
      return status.conf.googleZoomDefault
    end,
    function(value)
      status.conf.googleZoomDefault = value
    end
  )

  line = form.addLine("Google zoom max")
  widget.googleZoomMaxField = form.addNumberField(line, nil, 1, 20,
    function()
      widget.googleZoomMaxField:enable(status.conf.mapProvider==2)
      return status.conf.googleZoomMax
    end,
    function(value)
      status.conf.googleZoomMax = value
      status.conf.googleZoomDefault = math.min(status.conf.googleZoomMax, status.conf.googleZoomDefault)
    end
  )

  line = form.addLine("Google zoom min")
  widget.googleZoomMinField = form.addNumberField(line, nil, 1, 20,
    function()
      widget.googleZoomMinField:enable(status.conf.mapProvider==2)
      return status.conf.googleZoomMin
    end,
    function(value)
      status.conf.googleZoomMin = value
      status.conf.googleZoomDefault = math.max(status.conf.googleZoomMin, status.conf.googleZoomDefault)
    end
  )

  line = form.addLine("GMapCatcher zoom")
  widget.gmapZoomField = form.addNumberField(line, nil, -2, 17,
    function()
      widget.gmapZoomField:enable(status.conf.mapProvider==1)
      return status.conf.gmapZoomDefault
    end,
    function(value)
      status.conf.gmapZoomDefault = value
    end
  )

  line = form.addLine("GMapCatcher zoom max")
  widget.gmapZoomMaxField = form.addNumberField(line, nil, -2, 17,
    function()
      widget.gmapZoomMaxField:enable(status.conf.mapProvider==1)
      return status.conf.gmapZoomMax
    end,
    function(value)
      status.conf.gmapZoomMax = value
      status.conf.gmapZoomDefault = math.min(status.conf.gmapZoomMax, status.conf.gmapZoomDefault)
    end
  )

  line = form.addLine("GMapCatcher zoom min")
  widget.gmapZoomMinField = form.addNumberField(line, nil, -2, 17,
    function()
      widget.gmapZoomMinField:enable(status.conf.mapProvider==1)
      return status.conf.gmapZoomMin
    end,
    function(value)
      status.conf.gmapZoomMin = value
      status.conf.gmapZoomDefault = math.max(status.conf.gmapZoomMin, status.conf.gmapZoomDefault)
    end
  )

  line = form.addLine("Enable map grid")
  form.addBooleanField(line, nil, function() return status.conf.enableMapGrid end, function(value) status.conf.enableMapGrid = value end)
end

local function applyConfig()
  status.battsource = applyDefault(status.conf.defaultBattSourceId, 1, {"fc","vs"})

  status.conf.horSpeedLabel = applyDefault(status.conf.horSpeedUnit, 1, {"m/s", "km/h", "mph", "kn"})
  status.conf.vertSpeedLabel = applyDefault(status.conf.vertSpeedUnit, 1, {"m/s", "ft/s", "ft/min"})
  status.conf.distUnitLabel = applyDefault(status.conf.distUnit, 1, {"m", "ft"})
  status.conf.distUnitLongLabel = applyDefault(status.conf.distUnitLong, 1, {"km", "mi"})

  status.conf.horSpeedMultiplier = applyDefault(status.conf.horSpeedUnit, 1, {1, 3.6, 2.23694, 1.94384})
  status.conf.vertSpeedMultiplier = applyDefault(status.conf.vertSpeedUnit, 1, {1, 3.28084, 196.85})
  status.conf.distUnitScale = applyDefault(status.conf.distUnit, 1, {1, 3.28084})
  status.conf.distUnitLongScale = applyDefault(status.conf.distUnitLong, 1, {1/1000,  1/1609.34})

  status.conf.mapType = applyDefault(status.conf.mapTypeId, 1, status.conf.mapProvider == 1 and {"sat_tiles","tiles","tiles","ter_tiles"} or {"GoogleSatelliteMap","GoogleHybridMap","GoogleMap","GoogleTerrainMap"})

  if status.conf.mapProvider == 1 then
    status.mapZoomLevel = status.conf.gmapZoomDefault
    status.conf.mapZoomMin = status.conf.gmapZoomMin
    status.conf.mapZoomMax = status.conf.gmapZoomMax
  else
    status.mapZoomLevel = status.conf.googleZoomDefault
    status.conf.mapZoomMin = status.conf.googleZoomMin
    status.conf.mapZoomMax = status.conf.googleZoomMax
  end

  -- CRSF or SPORT?
  -- utils.drawRssi = drawRssi
  libs.utils.telemetryPop = libs.utils.passthroughTelemetryPop

  if status.conf.enableCRSF then
    libs.utils.telemetryPop = libs.utils.crossfireTelemetryPop
    --utils.drawRssi = drawRssiCRSF
    -- we need a lower value here to prevent CPU Kill
    -- when decoding multiple packet frames
    -- telemetryPopLoops = 8
  end
end
--------------------------------------------------------------------
-- configuration read/write
-- properties must be read in the same order they are written
--------------------------------------------------------------------
local function read(widget)
  widget.screen = storageToConfig("screen",1)
  widget.centerPanelIndex = storageToConfig("centerPanelIndex", 1)
  widget.leftPanelIndex = storageToConfig("leftPanelIndex", 1)
  widget.rightPanelIndex = storageToConfig("rightPanelIndex", 1)
  status.conf.battConf = storageToConfig("battConf", 1)
  status.conf.cell1Count = storageToConfig("cell1Count", 0)
  status.conf.cell2Count = storageToConfig("cell2Count", 0)
  status.conf.battCapOverride1 = storageToConfig("battCapOverride1", 0)
  status.conf.battCapOverride2 = storageToConfig("battCapOverride2", 0)
  status.conf.battAlertLevel1 = storageToConfig("battAlertLevel1", 375)
  status.conf.battAlertLevel2 = storageToConfig("battAlertLevel2", 350)
  status.conf.defaultBattSourceId = storageToConfig("defaultBattSourceId", 1)
  status.conf.disableAllSounds = storageToConfig("disableAllSounds", false)
  status.conf.disableMsgBeep = storageToConfig("disableMsgBeep", 1)
  status.conf.enableHaptic = storageToConfig("enableHaptic", false)
  status.conf.enableBattPercByVoltage = storageToConfig("enableBattPercByVoltage", false)
  status.conf.timerAlert = storageToConfig("timerAlert", 0)
  status.conf.repeatAlertsPeriod = storageToConfig("repeatAlertsPeriod", 10)
  status.conf.minAltitudeAlert = storageToConfig("minAltitudeAlert", 0)
  status.conf.maxAltitudeAlert = storageToConfig("maxAltitudeAlert", 0)
  status.conf.maxDistanceAlert = storageToConfig("maxDistanceAlert", 0)
  status.conf.rangeFinderMax = storageToConfig("rangeFinderMax", 0)
  status.conf.horSpeedUnit = storageToConfig("horSpeedUnit", 1)
  status.conf.vertSpeedUnit = storageToConfig("vertSpeedUnit",1)
  status.conf.distUnit = storageToConfig("distUnit", 1)
  status.conf.distUnitLong = storageToConfig("distUnitLong", 1)
  status.conf.enablePX4Modes = storageToConfig("enablePX4Modes", false)
  status.conf.enableCRSF = storageToConfig("enableCRSF", false)
  status.conf.enableRPM = storageToConfig("enableRPM", 1)
  status.conf.enableWIND = storageToConfig("enableWIND", true)
  status.conf.gpsFormat = storageToConfig("gpsFormat", 2)
  status.conf.mapProvider = storageToConfig("mapProvider", 2)
  status.conf.mapTypeId = storageToConfig("mapTypeId", 1)
  status.conf.googleZoomDefault = storageToConfig("googleZoomDefault", 18)
  status.conf.googleZoomMin = storageToConfig("googleZoomMin", 1)
  status.conf.googleZoomMax = storageToConfig("googleZoomMax", 20)
  status.conf.gmapZoomDefault = storageToConfig("gmapZoomDefault", 0)
  status.conf.gmapZoomMin = storageToConfig("gmapZoomMin", -2)
  status.conf.gmapZoomMax = storageToConfig("gmapZoomMax", 17)
  status.conf.enableMapGrid = storageToConfig("enableMapGrid", true)
  status.conf.battery1Source = storageToConfig("battery1Source", nil)
  status.conf.battery2Source = storageToConfig("battery2Source", nil)
  status.conf.linkQualitySource = storageToConfig("linkQualitySource", nil)
  status.conf.telemetrySource = storageToConfig("telemetrySource", nil)
  status.conf.linkStatusSource2 = storageToConfig("linkStatusSource2", nil)
  status.conf.linkStatusSource3 = storageToConfig("linkStatusSource3", nil)
  status.conf.linkStatusSource4 = storageToConfig("linkStatusSource4", nil)
  -- apply config
  applyConfig()
end

local function write(widget)
  storage.write("screen", widget.screen)
  storage.write("centerPanelIndex", widget.centerPanelIndex)
  storage.write("leftPanelIndex", widget.leftPanelIndex)
  storage.write("rightPanelIndex", widget.rightPanelIndex)
  storage.write("battConf", status.conf.battConf)
  storage.write("cell1Count", status.conf.cell1Count)
  storage.write("cell2Count", status.conf.cell2Count)
  storage.write("battCapOverride1", status.conf.battCapOverride1)
  storage.write("battCapOverride2", status.conf.battCapOverride2)
  storage.write("battAlertLevel1", status.conf.battAlertLevel1)
  storage.write("battAlertLevel2", status.conf.battAlertLevel2)
  storage.write("defaultBattSourceId", status.conf.defaultBattSourceId)
  storage.write("disableAllSounds", status.conf.disableAllSounds)
  storage.write("disableMsgBeep", status.conf.disableMsgBeep)
  storage.write("enableHaptic", status.conf.enableHaptic)
  storage.write("enableBattPercByVoltage", status.conf.enableBattPercByVoltage)
  storage.write("timerAlert", status.conf.timerAlert)
  storage.write("repeatAlertsPeriod", status.conf.repeatAlertsPeriod)
  storage.write("minAltitudeAlert", status.conf.minAltitudeAlert)
  storage.write("maxAltitudeAlert", status.conf.maxAltitudeAlert)
  storage.write("maxDistanceAlert", status.conf.maxDistanceAlert)
  storage.write("rangeFinderMax", status.conf.rangeFinderMax)
  storage.write("horSpeedUnit", status.conf.horSpeedUnit)
  storage.write("vertSpeedUnit", status.conf.vertSpeedUnit)
  storage.write("distUnit", status.conf.distUnit)
  storage.write("distUnitLong", status.conf.distUnitLong)
  storage.write("enablePX4Modes", status.conf.enablePX4Modes)
  storage.write("enableCRSF", status.conf.enableCRSF)
  storage.write("enableRPM", status.conf.enableRPM)
  storage.write("enableWIND", status.conf.enableWIND)
  storage.write("gpsFormat", status.conf.gpsFormat)
  storage.write("mapProvider", status.conf.mapProvider)
  storage.write("mapTypeId", status.conf.mapTypeId)
  storage.write("googleZoomDefault", status.conf.googleZoomDefault)
  storage.write("googleZoomMin", status.conf.googleZoomMin)
  storage.write("googleZoomMax", status.conf.googleZoomMax)
  storage.write("gmapZoomDefault", status.conf.gmapZoomDefault)
  storage.write("gmapZoomMin", status.conf.gmapZoomMin)
  storage.write("gmapZoomMax", status.conf.gmapZoomMax)
  storage.write("enableMapGrid", status.conf.enableMapGrid)
  storage.write("battery1Source", status.conf.battery1Source)
  storage.write("battery2Source", status.conf.battery2Source)
  storage.write("linkQualitySource", status.conf.linkQualitySource)
  storage.write("telemetrySource", status.conf.telemetrySource)
  storage.write("linkStatusSource2", status.conf.linkStatusSource2)
  storage.write("linkStatusSource3", status.conf.linkStatusSource3)
  storage.write("linkStatusSource4", status.conf.linkStatusSource4)
  -- apply config
  applyConfig()

  -- reset the layout
  libs.resetLib.resetLayout(widget)
end

local function sourceInit(source)
  source:value(status.luaSourcesConfig[source:name()][1])
  source:decimals(status.luaSourcesConfig[source:name()][2])
  source:unit(status.luaSourcesConfig[source:name()][3])
end

local function registerSources()
  system.registerSource({key="Y_ARM", name="ArmStatus", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_FM", name="FlightMode", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_VOLT", name="Voltage", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_CURR", name="Current", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_BATT", name="Battery", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_HDG", name="Heading", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_ALT", name="Altitude", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_GALT", name="GPSAltitude", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_ASPD", name="AirSpeed", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_GSPD", name="GroundSpeed", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_VSPD", name="VSpeed", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_RPM1", name="Rpm1", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_RPM2", name="Rpm2", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_THR", name="Throttle", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_ROLL", name="Roll", init=sourceInit, wakeup=sourceWakeup})
  system.registerSource({key="Y_PTCH", name="Pitch", init=sourceInit, wakeup=sourceWakeup})
end

local function init()
  -- there's a limit on key size of 7 characters
  system.registerWidget({key="yaaputl", name="Yaapu Telemetry", paint=paint, event=event, wakeup=wakeup, create=create, configure=configure, menu=menu, read=read, write=write })
  registerSources()
end

return {init=init}

