#include "includes/yaapu_inc.lua"

#ifdef X9
--------------------------------
-- Layout 212x64 taranis X9D+
--------------------------------
#define LCD_W 212

#define ALT_HUD_X_CENTER 147
#define ALT_HUD_X 116
#define ALT_HUD_WIDTH 62
#define ALT_HUD_X_MID 33

#define ALT_LEFTPANE_X 116
#define ALT_RIGHTPANE_X 178

#define ALT_YAW_STEPWIDTH 6.2
#define ALT_YAW_X_MIN 120
#define ALT_YAW_X_MAX 174
#define ALT_YAW_WIDTH ALT_HUD_WIDTH-5

#define BATTCELL_X 0
#define BATTCELL_Y 7
#define BATTCELL_YV 6
#define BATTCELL_YS 12
#define BATTCELL_FLAGS MIDSIZE

#define BATTVOLT_X 33
#define BATTVOLT_Y 19
#define BATTVOLT_YV 19
#define BATTVOLT_FLAGS SMLSIZE
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCURR_X 33
#define BATTCURR_Y 26
#define BATTCURR_YA 26
#define BATTCURR_FLAGS SMLSIZE
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 0
#define BATTPERC_Y 31
#define BATTPERC_YPERC 35
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTMAH_X 0
#define BATTMAH_Y 43
#define BATTMAH_FLAGS SMLSIZE+PREC1

#define ALT_HOMEDIR_X 165
#define ALT_HOMEDIR_Y 48
#define ALT_HOMEDIR_R 7

#define GPS_X 70
#define GPS_Y 8

#define ALTASL_X 31
#define ALTASL_Y 43
#define ALTASL_XLABEL 1
#define ALTASL_YLABEL 43
#define ALTASL_FLAGS SMLSIZE

#define HOMEDIST_X 115
#define HOMEDIST_Y 8
#define HOMEDIST_XLABEL 73
#define HOMEDIST_YLABEL 10
#define HOMEDIST_FLAGS RIGHT
#define HOMEDIST_ARROW_WIDTH 7

#define TOTDIST_X 115
#define TOTDIST_Y 17
#define TOTDIST_XLABEL 0
#define TOTDIST_YLABEL 17
#define TOTDIST_FLAGS RIGHT+SMLSIZE
#define TOTDIST_ARROW_WIDTH 4

--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------
#define SENSOR_LABEL 1
#define SENSOR_NAME 2
#define SENSOR_PREC 3
#define SENSOR_UNIT 4
#define SENSOR_MULT 5
#define SENSOR_MAX 6
#define SENSOR_FONT 7
#define SENSOR_WARN 8
#define SENSOR_CRIT 9

#define SENSOR1_X 0
#define SENSOR1_Y 26

#define SENSOR2_X 58
#define SENSOR2_Y 26

#define SENSOR3_X 0
#define SENSOR3_Y 33

#define SENSOR4_X 58
#define SENSOR4_Y 33

#define SENSOR5_X 0
#define SENSOR5_Y 44

#define SENSOR6_X 58
#define SENSOR6_Y 44

#else --X9
--------------------------------
-- Layout 128x64 QX7/X-Lite
--------------------------------
#define LCD_W 128

#define ALT_HUD_X_CENTER 65
#define ALT_HUD_X 31
#define ALT_HUD_WIDTH 64
#define ALT_HUD_X_MID 19

#define ALT_LEFTPANE_X 116
#define ALT_RIGHTPANE_X 178

#define ALT_YAW_STEPWIDTH 6.2
#define ALT_YAW_X_MIN 120
#define ALT_YAW_X_MAX 174
#define ALT_YAW_WIDTH ALT_HUD_WIDTH-5

#define BATTCELL_X 0
#define BATTCELL_Y 7
#define BATTCELL_YV 6
#define BATTCELL_YS 12
#define BATTCELL_FLAGS MIDSIZE

#define BATTVOLT_X 32
#define BATTVOLT_Y 19
#define BATTVOLT_YV 19
#define BATTVOLT_FLAGS SMLSIZE
#define BATTVOLT_FLAGSV SMLSIZE

#define BATTCURR_X 32
#define BATTCURR_Y 26
#define BATTCURR_YA 26
#define BATTCURR_FLAGS SMLSIZE
#define BATTCURR_FLAGSA SMLSIZE

#define BATTPERC_X 0
#define BATTPERC_Y 32
#define BATTPERC_YPERC 35
#define BATTPERC_FLAGS MIDSIZE
#define BATTPERC_FLAGSPERC SMLSIZE

#define BATTMAH_X 0
#define BATTMAH_Y 44
#define BATTMAH_FLAGS SMLSIZE+PREC1

#define ALT_HOMEDIR_X 25
#define ALT_HOMEDIR_Y 14
#define ALT_HOMEDIR_R 6

#define GPS_X 74
#define GPS_Y 8

#define ALTASL_X 31
#define ALTASL_Y 43
#define ALTASL_XLABEL 1
#define ALTASL_YLABEL 43
#define ALTASL_FLAGS SMLSIZE

#define HOMEDIST_X 32
#define HOMEDIST_Y 22
#define HOMEDIST_XLABEL 1
#define HOMEDIST_YLABEL 25
#define HOMEDIST_FLAGS RIGHT
#define HOMEDIST_ARROW_WIDTH 7

#define TOTDIST_X 32
#define TOTDIST_Y 24
#define TOTDIST_XLABEL 0
#define TOTDIST_YLABEL 24
#define TOTDIST_FLAGS RIGHT+SMLSIZE
#define TOTDIST_ARROW_WIDTH 4

#define ALT_ALT_X 94
#define ALT_ALT_Y 7

#define ALT_HSPEED_X 94
#define ALT_HSPEED_Y 19

--------------------------
-- CUSTOM SENSORS SUPPORT
--------------------------
#define SENSOR_LABEL 1
#define SENSOR_NAME 2
#define SENSOR_PREC 3
#define SENSOR_UNIT 4
#define SENSOR_MULT 5
#define SENSOR_MAX 6
#define SENSOR_FONT 7
#define SENSOR_WARN 8
#define SENSOR_CRIT 9

#define SENSOR1_X 0
#define SENSOR1_Y 33

#define SENSOR2_X 47
#define SENSOR2_Y 33

#define SENSOR3_X 0
#define SENSOR3_Y 41

#define SENSOR4_X 47
#define SENSOR4_Y 41

#define SENSOR5_X 0
#define SENSOR5_Y 49

#define SENSOR6_X 47
#define SENSOR6_Y 49

#endif --X9

local initSensors = true


#ifdef X9

local gpsLat = nil
local gpsLon = nil

---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawLeftPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- GPS status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  flags = BLINK+PREC1
  local mult = 1
  
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawNumber(20,9, telemetry.gpsHdopC*mult ,MIDSIZE+flags+RIGHT)
  else
    lcd.drawText(5, 8, "No", SMLSIZE+INVERS+BLINK)
    lcd.drawText(2, 16, "GPS", SMLSIZE+INVERS+BLINK)
  end

  if telemetry.gpsLat ~= nil then
    lcd.drawText(GPS_X,GPS_Y,telemetry.gpsLat,RIGHT+SMLSIZE)
    lcd.drawText(GPS_X,GPS_Y+8,telemetry.gpsLon,RIGHT+SMLSIZE)
  end 
  -- alt asl/rng
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
  flags = 0
  -- home dist
  local flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,MAX_DIST)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(x+HOMEDIST_X, HOMEDIST_Y+1, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), HOMEDIST_Y, dist*UNIT_DIST_SCALE,HOMEDIST_FLAGS+flags)
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+HOMEDIST_XLABEL+1, HOMEDIST_YLABEL-2,5,true,false)
  else
    drawLib.drawHomeIcon(x+HOMEDIST_XLABEL, HOMEDIST_YLABEL)
  end
  -- total distance
  lcd.drawText(TOTDIST_X, TOTDIST_Y, UNIT_DIST_LONG_LABEL, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos(), TOTDIST_Y, telemetry.totalDist*UNIT_DIST_LONG_SCALE*10, RIGHT+SMLSIZE+PREC1)  
  -- needs to be called often for strings created by decToDMSFull() fragment memory
  collectgarbage()
end
#else --X9
local function drawLeftPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- GPS status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  flags = BLINK+PREC1
  local mult = 1
  
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawNumber(x+1, 7,telemetry.gpsHdopC*mult ,flags+MIDSIZE)
  else
    lcd.drawText(x+3, 7, "No", SMLSIZE+INVERS+BLINK)
    lcd.drawText(x, 15, "Gps", SMLSIZE+INVERS+BLINK)
  end
  -- alt asl/rng
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
  flags = 0
  -- home dist
  local flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,MAX_DIST)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(x+HOMEDIST_X, HOMEDIST_Y+1, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), HOMEDIST_Y, dist*UNIT_DIST_SCALE,HOMEDIST_FLAGS+flags)
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+HOMEDIST_XLABEL+1, HOMEDIST_YLABEL-2,5,true,false)
  else
    drawLib.drawHomeIcon(x+HOMEDIST_XLABEL, HOMEDIST_YLABEL)
  end
  --[[
  -- altitude on right side
  local alt = getMaxValue(telemetry.homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE -- homeAlt is meters*3.28 = feet

  if math.abs(alt) < 10 then
      lcd.drawNumber(ALT_ALT_X+1,ALT_ALT_Y,alt * 10,PREC1+RIGHT+MIDSIZE)
  else
      lcd.drawNumber(ALT_ALT_X+1,ALT_ALT_Y,alt,RIGHT+MIDSIZE)
  end
  -- hspeed
  local speed = getMaxValue(telemetry.hSpeed,MAX_HSPEED) * UNIT_HSPEED_SCALE
  
  if math.abs(speed) > 99 then
    lcd.drawNumber(ALT_HSPEED_X+1,ALT_HSPEED_Y,speed*0.1,RIGHT+MIDSIZE)
  else
    lcd.drawNumber(ALT_HSPEED_X+1,ALT_HSPEED_Y,speed,PREC1+RIGHT+MIDSIZE)
  end
  --]]
  -- needs to be called ofter for strings created by decToDMSFull() fragment memory
  collectgarbage()
end
#endif --X9

-- max 6 extra sensors
local customSensors = nil
-- {label,name,prec:0,1,2,unit,multiplier,mninmax,font}

local function getSensorsConfigFilename()
  local info = model.getInfo()
  return "/MODELS/yaapu/" .. string.lower(string.gsub(info.name, "[%c%p%s%z]", "").."_sensors.lua")
end

local function loadSensors()
  local tmp = io.open(getSensorsConfigFilename(),"r")
  if tmp == nil then
    return
  else
    io.close(tmp)
  end
  local sensorScript = loadScript(getSensorsConfigFilename())
  collectgarbage()
  customSensors = sensorScript()
  sensorScript = nil
  collectgarbage()
  collectgarbage()
end


local customSensorXY = {
  { SENSOR1_X, SENSOR1_Y },
  { SENSOR2_X, SENSOR2_Y },
  { SENSOR3_X, SENSOR3_Y },
  { SENSOR4_X, SENSOR4_Y },
  { SENSOR5_X, SENSOR5_Y },
  { SENSOR6_X, SENSOR6_Y },
}

local function drawCustomSensors(x,status)
    if customSensors == nil then
      --drawNoCustomSensors(x)
      lcd.drawText(x+10,33, "NO CUSTOM SENSORS",0)
      lcd.drawText(x+30,45, "DEFINED",0)
      return
    end
    local label,data,prec,mult,flags,color,labelColor
    for i=1,6
    do
      -- default font attribute
      color = 0
      labelColor = 0
      
      if customSensors.sensors[i] ~= nil then 
        sensorConfig = customSensors.sensors[i]
        
        mult =  sensorConfig[SENSOR_PREC] == 0 and 1 or ( sensorConfig[SENSOR_PREC] == 1 and 10 or 100 )
        prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)
        
        local sensorName = sensorConfig[SENSOR_NAME]..(status.showMinMaxValues == true and sensorConfig[SENSOR_MAX] or "")
        local sensorValue = getValue(sensorName) 
        
        local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[SENSOR_MULT]
        
#ifdef X9        
        -- default font size
        flags = i<=2 and 0 or (sensorConfig[SENSOR_FONT] == 1 and 0 or MIDSIZE)
        
        -- reduce font if necessary
        if math.abs(value)/mult > 9999 then
          flags = 0
        end
        
        local voffset = (i>2 and flags==0) and 3 or 0
#else --X9
        flags = 0
        local voffset = 0
#endif --X9
        local sign = sensorConfig[SENSOR_MAX] == "+" and 1 or -1
        
        -- max tracking, high values are critical
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          if sensorValue*sign > sensorConfig[SENSOR_CRIT]*sign then
            color = BLINK
            labelColor = 0
          elseif sensorValue*sign > sensorConfig[SENSOR_WARN]*sign then
            color = 0
            labelColor = BLINK
          end
        end
        
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][sensorValue] ~= nil then
          lcd.drawText(x+customSensorXY[i][1], voffset+customSensorXY[i][2], customSensors.lookups[i][sensorValue] or value, flags+color)
        else
          lcd.drawNumber(x+customSensorXY[i][1], voffset+customSensorXY[i][2], value, flags+prec+color)
        end
#ifdef X9        
        lcd.drawText(lcd.getLastRightPos()-(sensorConfig[SENSOR_FONT]==MIDSIZE and 1 or 0), customSensorXY[i][2]+(i>2 and 5 or 1),sensorConfig[SENSOR_UNIT],labelColor+SMLSIZE)
#else --X9
        lcd.drawText(lcd.getLastRightPos(), customSensorXY[i][2],sensorConfig[SENSOR_UNIT],labelColor+SMLSIZE)
#endif -- X9
      collectgarbage()
      collectgarbage()
      end
    end
end

#ifdef X9
-- SYNTH VSPEED SUPPORT
local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0

local function drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)
  -- HUD
  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( roll == 0) then
    dx=0
    dy=telemetry.pitch
    cx=0
    cy=HUD_R2
    ccx=0
    ccy=2*HUD_R2
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * HUD_R2
    cy = math.sin(math.rad(90 - r)) * HUD_R2
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * HUD_R2
    ccy = math.sin(math.rad(90 - r)) * 2 * HUD_R2
  end
  -----------------------
  -- dark color for "ground"
  -----------------------
  local minY = 7
  local minX = ALT_HUD_X + 1
  local maxX = ALT_HUD_X + ALT_HUD_WIDTH - 6
  local maxY = 54
  local ox = ALT_HUD_X_CENTER + dx
  local oy = ALT_HUD_X_MID + dy
  local yy = 0
  local rollX = ALT_HUD_X_CENTER-1
  -- parallel lines above and below horizon line
  drawLib.drawLineWithClipping(rollX + dx - ccx,dy + ALT_HUD_X_MID + ccy,r,20,DOTTED,ALT_HUD_X,ALT_HUD_X + ALT_HUD_WIDTH,8,maxY)
  drawLib.drawLineWithClipping(rollX + dx - cx,dy + ALT_HUD_X_MID + cy,r,8,DOTTED,ALT_HUD_X,ALT_HUD_X + ALT_HUD_WIDTH,8,maxY)
  drawLib.drawLineWithClipping(rollX + dx + cx,dy + ALT_HUD_X_MID - cy,r,8,DOTTED,ALT_HUD_X,ALT_HUD_X + ALT_HUD_WIDTH,8,maxY)
  drawLib.drawLineWithClipping(rollX + dx + ccx,dy + ALT_HUD_X_MID - ccy,r,20,DOTTED,ALT_HUD_X,ALT_HUD_X + ALT_HUD_WIDTH,8,maxY)
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- for each pixel of the hud base/top draw vertical black 
  -- lines from hud border to horizon line
  -- horizon line moves with pitch/roll
  for xx= minX,maxX
  do
    yy = (oy - ox*angle) + math.floor(xx*angle)
    if telemetry.roll > 90 or telemetry.roll < -90 then
      if yy > minY then
        lcd.drawLine(xx, minY, xx, math.min(yy,maxY),SOLID,0)
      end
    else
      if yy < maxY then
        lcd.drawLine(xx, maxY, xx, math.max(yy,minY),SOLID,0)
      end
    end
  end

#ifdef SYNTHVSPEED  
  ------------------------------------
  -- synthetic vSpeed based on 
  -- home altitude when EKF is disabled
  -- updated at 1Hz (i.e every 1000ms)
  -------------------------------------
  if conf.enableSynthVSpeed == true then
    if (synthVSpeedTime == 0) then
      -- first time do nothing
      synthVSpeedTime = getTime()
      prevHomeAlt = telemetry.homeAlt -- dm
    elseif (getTime() - synthVSpeedTime > 100) then
      -- calc vspeed
      vspd = 1000*(telemetry.homeAlt-prevHomeAlt)/(getTime()-synthVSpeedTime) -- m/s
      -- update counters
      synthVSpeedTime = getTime()
      prevHomeAlt = telemetry.homeAlt -- m
    end
  else
    vspd = telemetry.vSpeed
  end
#else --SYNTHVSPEED  
  vspd = telemetry.vSpeed
#endif --SYNTHVSPEED  
  -------------------------------------
  -- vario indicator on right
  -------------------------------------
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 4, 7, ALT_HUD_X + ALT_HUD_WIDTH - 4, yPos + 40, SOLID, 0)
  local varioMax = 10
  local varioSpeed = math.min(math.abs(0.1*vspd),10)
  local varioY = 0
  local arrowY = -1
  if vspd > 0 then
    varioY = ALT_HUD_X_MID - 4 - varioSpeed/varioMax*22
  else
    varioY = ALT_HUD_X_MID + 7
    arrowY = 1
  end
  lcd.drawFilledRectangle(ALT_HUD_X + ALT_HUD_WIDTH - 4, varioY, 4, varioSpeed/varioMax*22, FORCE, 0)
  for i=0,16
  do
    lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 3, 9+i*3, ALT_HUD_X + ALT_HUD_WIDTH, 9+i*3, SOLID, ERASE)
    lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 2, arrowY+9+i*3, ALT_HUD_X + ALT_HUD_WIDTH-2, arrowY+9+i*3, SOLID, ERASE)
  end
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- lets erase to hide the artificial horizon lines
  -- black borders
  lcd.drawRectangle(ALT_HUD_X, ALT_HUD_X_MID - 5, LEFTWIDTH, 11, FORCE, 0)
  lcd.drawRectangle(ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 1, ALT_HUD_X_MID - 5, RIGHTWIDTH+1, 11, FORCE, 0)
  -- erase area
  lcd.drawFilledRectangle(ALT_HUD_X, ALT_HUD_X_MID - 4, LEFTWIDTH, 9, ERASE, 0)
  lcd.drawFilledRectangle(ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 1, ALT_HUD_X_MID - 4, RIGHTWIDTH+2, 9, ERASE, 0)
  -- erase tips
  lcd.drawLine(ALT_HUD_X + LEFTWIDTH,ALT_HUD_X_MID - 3,ALT_HUD_X + LEFTWIDTH,ALT_HUD_X_MID + 3, SOLID, ERASE)
  lcd.drawLine(ALT_HUD_X + LEFTWIDTH+1,ALT_HUD_X_MID - 2,ALT_HUD_X + LEFTWIDTH+1,ALT_HUD_X_MID + 2, SOLID, ERASE)
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 2,ALT_HUD_X_MID - 3,ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 2,ALT_HUD_X_MID + 3, SOLID, ERASE)
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 3,ALT_HUD_X_MID - 2,ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 3,ALT_HUD_X_MID + 2, SOLID, ERASE)
  -- left tip
  lcd.drawLine(ALT_HUD_X + LEFTWIDTH+2,ALT_HUD_X_MID - 2,ALT_HUD_X + LEFTWIDTH+2,ALT_HUD_X_MID + 2, SOLID, FORCE)
  lcd.drawLine(ALT_HUD_X + LEFTWIDTH-1,ALT_HUD_X_MID - 5,ALT_HUD_X + LEFTWIDTH+1,ALT_HUD_X_MID - 3, SOLID, FORCE)
  lcd.drawLine(ALT_HUD_X + LEFTWIDTH-1,ALT_HUD_X_MID + 5,ALT_HUD_X + LEFTWIDTH+1,ALT_HUD_X_MID + 3, SOLID, FORCE)
  -- right tip
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 4,ALT_HUD_X_MID - 2,ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 4,ALT_HUD_X_MID + 2, SOLID, FORCE)
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 3,ALT_HUD_X_MID - 3,ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 1,ALT_HUD_X_MID - 5, SOLID, FORCE)
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 3,ALT_HUD_X_MID + 3,ALT_HUD_X + ALT_HUD_WIDTH - RIGHTWIDTH - 1,ALT_HUD_X_MID + 5, SOLID, FORCE)
    -- altitude
  local alt = getMaxValue(telemetry.homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE -- homeAlt is meters*3.28 = feet

  if math.abs(alt) < 10 then
      lcd.drawNumber(ALT_HUD_X + ALT_HUD_WIDTH,ALT_HUD_X_MID - 3,alt * 10,SMLSIZE+PREC1+RIGHT)
  else
      lcd.drawNumber(ALT_HUD_X + ALT_HUD_WIDTH,ALT_HUD_X_MID - 3,alt,SMLSIZE+RIGHT)
  end
  -- hspeed
  local speed = getMaxValue(telemetry.hSpeed,MAX_HSPEED) * UNIT_HSPEED_SCALE
  if math.abs(speed) > 99 then
    lcd.drawNumber(ALT_HUD_X+1,ALT_HUD_X_MID - 3,speed*0.1,SMLSIZE)
  else
    lcd.drawNumber(ALT_HUD_X+1,ALT_HUD_X_MID - 3,speed,SMLSIZE+PREC1)
  end
  -- reference lines
  lcd.drawLine(ALT_HUD_X_CENTER-9-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER-4-1,ALT_HUD_X_MID ,SOLID,0) -- -1 to compensate for H offset 
  lcd.drawLine(ALT_HUD_X_CENTER-3-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER-3-1,ALT_HUD_X_MID+3 ,SOLID,0)
  lcd.drawLine(ALT_HUD_X_CENTER+4-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER+9-1,ALT_HUD_X_MID ,SOLID,0)
  lcd.drawLine(ALT_HUD_X_CENTER+3-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER+3-1,ALT_HUD_X_MID+3 ,SOLID,0)
  -- vspeed box (dm/s)
  local xx = math.abs(vspd*UNIT_VSPEED_SCALE) > 9999 and 4 or 3
  xx = xx + (vspd*UNIT_VSPEED_SCALE < 0 and 1 or 0)
  lcd.drawFilledRectangle(ALT_HUD_X_CENTER - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, ERASE)
  if math.abs(vspd*UNIT_VSPEED_SCALE) > 99 then -- 
    lcd.drawNumber(ALT_HUD_X_CENTER + (xx/2)*5, LCD_H - 15, vspd*0.1*UNIT_VSPEED_SCALE, HSPEED_FLAGS+RIGHT)
  else
    lcd.drawNumber(ALT_HUD_X_CENTER + (xx/2)*5, LCD_H - 15, vspd*UNIT_VSPEED_SCALE, HSPEED_FLAGS+RIGHT+PREC1)
  end
  lcd.drawRectangle(ALT_HUD_X_CENTER - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, FORCE)
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(ALT_HUD_X + ALT_HUD_WIDTH - 24, ALT_HUD_X_MID - 4,6,true,false)
    drawLib.drawVArrow(ALT_HUD_X + LEFTWIDTH + 4, ALT_HUD_X_MID - 4,6,true,false)
  end
  -- arming status, show only if timer is not running, hide otherwise
  if telemetry.ekfFailsafe == 0 and telemetry.battFailsafe == 0 and status.timerRunning == 0 then
    if (telemetry.statusArmed == 1) then
      lcd.drawText(ALT_HUD_X + ALT_HUD_WIDTH/2 - 15, 20, " ARMED ", SMLSIZE+INVERS)
    else
      lcd.drawText(ALT_HUD_X + ALT_HUD_WIDTH/2 - 21, 20, " DISARMED ", SMLSIZE+INVERS+BLINK)
    end
  end
  -- yaw angle box
  xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
  lcd.drawNumber(ALT_HUD_X_CENTER + xx - 6, YAW_Y-1, telemetry.yaw, MIDSIZE+INVERS)
end

#else --X9

#define MINIHUD_R2 6
#define MINIHUD_R3 8
#define ALT_LEFTWIDTH 16
#define ALT_RIGHTWIDTH 18

local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0

local function drawMiniHud(drawLib,conf,telemetry,status,battery,getMaxValue)
  ----------------------
  -- MINI HUD TOP LEFT
  ----------------------
  local r = -telemetry.roll
  local dx,dy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8

  if ( roll == 0) then
    dx=0
    dy=telemetry.pitch
    -- 1st line offsets
    cx=0
    cy=MINIHUD_R2
    -- 2nd line offsets
    ccx=0
    ccy=2*MINIHUD_R2
  else
    -- for a smaller hud vertical movement has to be scaled down
    dx = 0.4 * math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = 0.4 * math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * MINIHUD_R2
    cy = math.sin(math.rad(90 - r)) * MINIHUD_R2
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * MINIHUD_R3
    ccy = math.sin(math.rad(90 - r)) * 2 * MINIHUD_R3
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * MINIHUD_R3
    cccy = math.sin(math.rad(90 - r)) * 3 * MINIHUD_R3
  end

  local minY = 7
  local maxY = 7 + 24
  local minX = ALT_HUD_X + 1
  local maxX = ALT_HUD_X + 64
  local ox = ALT_HUD_X + 31 + dx

  local oy = 7 + 12 + dy
  local yy = 0
  -- angle of the line passing on point(ox,oy)
  local angle = math.tan(math.rad(-telemetry.roll))
  -- for each pixel of the hud base/top 
  -- draw vertical black lines from hud border to horizon line
  -- horizon line moves with pitch/roll
  for xx= minX,maxX
  do
    yy = (oy - ox*angle) + math.floor(xx*angle)
    if telemetry.roll > 90 or telemetry.roll < -90 then
      if yy > minY then
        lcd.drawLine(xx, minY, xx, math.min(yy,maxY),SOLID,0)
      end
    else
      if yy < maxY then
        lcd.drawLine(xx, maxY, xx, math.max(yy,minY),SOLID,0)
      end
    end
  end
  -- parallel lines above and below horizon of increasing length 5,7,16,16,7,5
  drawLib.drawLineWithClipping(ALT_HUD_X + 31 + dx - cccx,dy + 7 + 12 + cccy,r,16,DOTTED,ALT_HUD_X,ALT_HUD_X + 64,7,7+24)
  drawLib.drawLineWithClipping(ALT_HUD_X + 31 + dx - ccx,dy + 7 + 12 + ccy,r,10,DOTTED,ALT_HUD_X,ALT_HUD_X + 64,7,7+24)
  drawLib.drawLineWithClipping(ALT_HUD_X + 31 + dx - cx,dy + 7 + 12 + cy,r,16,DOTTED,ALT_HUD_X,ALT_HUD_X + 64,7,7+24)
  drawLib.drawLineWithClipping(ALT_HUD_X + 31 + dx + cx,dy + 7 + 12 - cy,r,16,DOTTED,ALT_HUD_X,ALT_HUD_X + 64,7,7+24)
  drawLib.drawLineWithClipping(ALT_HUD_X + 31 + dx + ccx,dy + 7 + 12 - ccy,r,10,DOTTED,ALT_HUD_X,ALT_HUD_X + 64,7,7+24)
  drawLib.drawLineWithClipping(ALT_HUD_X + 31 + dx + cccx,dy + 7 + 12 - cccy,r,16,DOTTED,ALT_HUD_X,ALT_HUD_X + 64,7,7+24)
  -------------------------------------
  -- vario indicator on right
  -------------------------------------
  lcd.drawFilledRectangle(ALT_HUD_X + ALT_HUD_WIDTH - 5, 7, 5, 24, ERASE, 0)
#ifdef SYNTHVSPEED  
  ------------------------------------
  -- synthetic vSpeed based on 
  -- home altitude when EKF is disabled
  -- updated at 1Hz (i.e every 1000ms)
  -------------------------------------
  if conf.enableSynthVSpeed == true then
    if (synthVSpeedTime == 0) then
      -- first time do nothing
      synthVSpeedTime = getTime()
      prevHomeAlt = telemetry.homeAlt -- dm
    elseif (getTime() - synthVSpeedTime > 100) then
      -- calc vspeed
      vspd = 1000*(telemetry.homeAlt-prevHomeAlt)/(getTime()-synthVSpeedTime) -- m/s
      -- update counters
      synthVSpeedTime = getTime()
      prevHomeAlt = telemetry.homeAlt -- m
    end
  else
    vspd = telemetry.vSpeed
  end
#else --SYNTHVSPEED  
  vspd = telemetry.vSpeed
#endif --SYNTHVSPEED  
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 6, 7, ALT_HUD_X + ALT_HUD_WIDTH - 6, 30, SOLID, FORCE)
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*vspd),5)
  local varioY = 0
  local arrowY = -1
  if vspd > 0 then
    varioY = ALT_HUD_X_MID - varioSpeed/varioMax*9 - 3
  else
    varioY = ALT_HUD_X_MID + 4
    arrowY = 1
  end
  lcd.drawFilledRectangle(ALT_HUD_X + ALT_HUD_WIDTH - 4, varioY, 4, varioSpeed/varioMax*9, FORCE, 0)
  --[[
  for i=0,8
  do
    lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 3, 8+i*3, ALT_HUD_X + ALT_HUD_WIDTH -1, 8+i*3, SOLID, ERASE)
    lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 2, arrowY+8+i*3, ALT_HUD_X + ALT_HUD_WIDTH-2, arrowY+8+i*3, SOLID, ERASE)
  end
  --]]
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 5, 19, ALT_HUD_X + ALT_HUD_WIDTH, 19, SOLID, FORCE)
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- lets erase to hide the artificial horizon lines
  -- black borders
  lcd.drawRectangle(ALT_HUD_X+1, ALT_HUD_X_MID - 5, ALT_LEFTWIDTH, 10, FORCE, 0)
  lcd.drawFilledRectangle(ALT_HUD_X+2, ALT_HUD_X_MID - 4, ALT_LEFTWIDTH, 8, ERASE, 0)
  lcd.drawLine(ALT_HUD_X+ALT_LEFTWIDTH+2,ALT_HUD_X_MID - 3,ALT_HUD_X+ALT_LEFTWIDTH+2,ALT_HUD_X_MID +2,SOLID,FORCE)
  lcd.drawPoint(ALT_HUD_X+ALT_LEFTWIDTH+1,ALT_HUD_X_MID - 4,SOLID+FORCE)
  lcd.drawPoint(ALT_HUD_X+ALT_LEFTWIDTH+1,ALT_HUD_X_MID + 3,SOLID+FORCE)
  
  lcd.drawRectangle(ALT_HUD_X + ALT_HUD_WIDTH - ALT_RIGHTWIDTH + 1, ALT_HUD_X_MID - 5, ALT_RIGHTWIDTH, 10, FORCE, 0)
  lcd.drawFilledRectangle(ALT_HUD_X + ALT_HUD_WIDTH - ALT_RIGHTWIDTH, ALT_HUD_X_MID - 4, ALT_RIGHTWIDTH, 8, ERASE, 0)
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - ALT_RIGHTWIDTH - 1, ALT_HUD_X_MID - 3,ALT_HUD_X + ALT_HUD_WIDTH - ALT_RIGHTWIDTH - 1, ALT_HUD_X_MID +2,SOLID,FORCE)
  lcd.drawPoint(ALT_HUD_X + ALT_HUD_WIDTH - ALT_RIGHTWIDTH, ALT_HUD_X_MID - 4,SOLID+FORCE)
  lcd.drawPoint(ALT_HUD_X + ALT_HUD_WIDTH - ALT_RIGHTWIDTH, ALT_HUD_X_MID + 3,SOLID+FORCE)
  
  -- altitude
  local alt = getMaxValue(telemetry.homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE -- homeAlt is meters*3.28 = feet
  if math.abs(alt) < 10 then
      lcd.drawNumber(ALT_HUD_X + ALT_HUD_WIDTH,ALT_HUD_X_MID - 3,alt * 10,SMLSIZE+PREC1+RIGHT)
  else
      lcd.drawNumber(ALT_HUD_X + ALT_HUD_WIDTH,ALT_HUD_X_MID - 3,alt,SMLSIZE+RIGHT)
  end
  -- hspeed
  local speed = getMaxValue(telemetry.hSpeed,MAX_HSPEED) * UNIT_HSPEED_SCALE
  if math.abs(speed) > 99 then
    lcd.drawNumber(ALT_HUD_X+2,ALT_HUD_X_MID - 3,speed*0.1,SMLSIZE)
  else
    lcd.drawNumber(ALT_HUD_X+2,ALT_HUD_X_MID - 3,speed,SMLSIZE+PREC1)
  end
  -- reference lines
  lcd.drawLine(ALT_HUD_X_CENTER-11-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER-6-1,ALT_HUD_X_MID ,SOLID,0) -- -1 to compensate for H offset 
  lcd.drawLine(ALT_HUD_X_CENTER-5-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER-5-1,ALT_HUD_X_MID+3 ,SOLID,0)
  lcd.drawLine(ALT_HUD_X_CENTER+2-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER+7-1,ALT_HUD_X_MID ,SOLID,0)
  lcd.drawLine(ALT_HUD_X_CENTER+1-1,ALT_HUD_X_MID,ALT_HUD_X_CENTER+1-1,ALT_HUD_X_MID+3 ,SOLID,0)
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(ALT_HUD_X + ALT_HUD_WIDTH - 24, ALT_HUD_X_MID - 4,6,true,false)
    drawLib.drawVArrow(ALT_HUD_X + LEFTWIDTH + 4, ALT_HUD_X_MID - 4,6,true,false)
  end
  -- yaw angle box
  local xx = telemetry.yaw < 10 and 0 or ( telemetry.yaw < 100 and -2 or -5 )
  lcd.drawNumber(ALT_HUD_X_CENTER + xx - 4, YAW_Y, telemetry.yaw, INVERS+SMLSIZE)
end
#endif --X7

local function drawRightPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  local perc = 0
  if (battery[BATT_CAP+battId] > 0) then
    perc = math.min(math.max((1 - (battery[BATT_MAH+battId]/battery[BATT_CAP+battId]))*100,0),99)
  end
  --  battery min cell
  local flags = 0
  local dimFlags = 0
  if status.showMinMaxValues == false then
    if status.battAlertLevel2 == true then
      flags = BLINK
      dimFlags = BLINK
    elseif status.battAlertLevel1 == true then
      dimFlags = BLINK+INVERS
    end
  end
  -- +0.5 because PREC2 does a math.floor()  and not a math.round()
  lcd.drawNumber(x+BATTCELL_X, BATTCELL_Y, (battery[BATT_CELL+battId] + 0.5)*(battery[BATT_CELL+battId] < 1000 and 1 or 0.1), BATTCELL_FLAGS+flags+(battery[BATT_CELL+battId] < 1000 and PREC2 or PREC1))  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+BATTCELL_X+26, BATTCELL_Y+2,6,false,true)
  else
    lcd.drawText(LCD_W, BATTCELL_YV, "V", dimFlags+SMLSIZE+RIGHT)
    --local xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
    local s = status.battsource == "a2" and "a" or (status.battsource == "vs" and "s" or "f")
    lcd.drawText(LCD_W, BATTCELL_YS, s, SMLSIZE+RIGHT)  
  end
  
  -- battery voltage
  lcd.drawText(x+BATTVOLT_X, BATTVOLT_YV, "V", SMLSIZE+RIGHT)  
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTVOLT_Y, battery[BATT_VOLT+battId],SMLSIZE+PREC1+RIGHT)
  -- battery current
  lcd.drawText(x+BATTCURR_X, BATTCURR_YA, "A", SMLSIZE+RIGHT)
  local mult = (battery[BATT_CURR+battId]*0.1 < 10) and 1 or 0.1  
  lcd.drawNumber(lcd.getLastLeftPos()-1, BATTCURR_Y, battery[BATT_CURR+battId]*mult,SMLSIZE+RIGHT+(mult == 1 and PREC1 or 0))
  -- battery percentage
  lcd.drawNumber(x+BATTPERC_X, BATTPERC_Y, perc, BATTPERC_FLAGS)
  lcd.drawText(lcd.getLastRightPos()+1, BATTPERC_YPERC, "%", BATTPERC_FLAGSPERC)
  -- battery mah
  lcd.drawNumber(x+BATTMAH_X, BATTMAH_Y, battery[BATT_MAH+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y, "Ah", SMLSIZE)
  -- battery cap
  lcd.drawNumber(x+BATTMAH_X, BATTMAH_Y+7, battery[BATT_CAP+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), BATTMAH_Y+7, "Ah", SMLSIZE)
end

--------------------
-- Single long function much more memory efficient than many little functions
---------------------
#ifdef X9
local sensorDelayStart = getTime()

local function drawView(drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)  
  
  -- delay loading and compile of sensor conf file
  if getTime() - sensorDelayStart > 20 then
    if initSensors == true then
      loadSensors()
      initSensors = false
      -- deallocate unused code
      loadSensors = nil
      getSensorsConfigFilename = nil
      collectgarbage()
      collectgarbage()
    end
  end
  
  drawCustomSensors(0,status)
  
  drawLib.drawRArrow(ALT_HOMEDIR_X,ALT_HOMEDIR_Y,ALT_HOMEDIR_R,telemetry.homeAngle - telemetry.yaw,1)
  drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)
  
  drawRightPane(LCD_W-32,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  drawLeftPane(0,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  
  lcd.drawLine(0,24 ,ALT_HUD_X-1, 24, SOLID, FORCE)
  lcd.drawLine(20, 7 , 20, 23, SOLID, FORCE)
  lcd.drawLine(70, 7 ,70, 23, SOLID, FORCE)
  lcd.drawLine(ALT_HUD_X - 1, 7 ,ALT_HUD_X - 1, 57, SOLID, FORCE)
  lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH, 7, ALT_HUD_X + ALT_HUD_WIDTH, 57, SOLID, FORCE)
  
  if telemetry.ekfFailsafe > 0 then
    lcd.drawText(ALT_HUD_X + ALT_HUD_WIDTH/2 - 31, 20, " EKF FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
  if telemetry.battFailsafe > 0 then
    lcd.drawText(ALT_HUD_X + ALT_HUD_WIDTH/2 - 33, 20, " BATT FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
end

#else
local sensorDelayStart = getTime()

local function drawView(drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  
  -- delay loading and compile of sensor conf file
  if getTime() - sensorDelayStart > 20 then
    if initSensors == true then
      loadSensors()
      initSensors = false
      -- deallocate unused code
      loadSensors = nil
      getSensorsConfigFilename = nil
      collectgarbage()
      collectgarbage()
    end
  end
  
  drawCustomSensors(0,status)
  
  drawRightPane(LCD_W-31,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  drawMiniHud(drawLib,conf,telemetry,status,battery,getMaxValue)
  drawLeftPane(0,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)  
  drawLib.drawRArrow(ALT_HOMEDIR_X,ALT_HOMEDIR_Y,ALT_HOMEDIR_R,telemetry.homeAngle - telemetry.yaw,FORCE)
  
  lcd.drawLine(95, 7 ,95, 56, SOLID, FORCE)
  lcd.drawLine(0, 31 ,95, 31, SOLID, FORCE)
  lcd.drawLine(32, 7 ,32, 31, SOLID, FORCE)
  --lcd.drawLine(64, 7 ,64, 31, SOLID, FORCE)
  
  -- arming status, show only if timer is not running, hide otherwise
  if telemetry.ekfFailsafe == 0 and telemetry.battFailsafe == 0 and status.timerRunning == 0 then
    if (telemetry.statusArmed == 1) then
      lcd.drawText(ALT_HUD_X + 20, 22, "ARMED", SMLSIZE+INVERS)
    else
      lcd.drawText(ALT_HUD_X+12, 22, "DISARMED", SMLSIZE+INVERS+BLINK)
    end
  end
  if telemetry.ekfFailsafe > 0 then
    lcd.drawText(ALT_HUD_X+14, 22, "EKF FAIL", SMLSIZE+INVERS+BLINK)
  end
  
  if telemetry.battFailsafe > 0 then
    lcd.drawText(ALT_HUD_X+14, 22, "BAT FAIL", SMLSIZE+INVERS+BLINK)
  end
end
#endif

#ifdef CUSTOM_BG_CALL
-- called at around 2Hz
local function background(conf,telemetry,status,getMaxValue,checkAlarm)
end
#endif --CUSTOM_BG_CALL

return {
  drawView=drawView,
#ifdef CUSTOM_BG_CALL
  background=background,
#endif --CUSTOM_BG_CALL
  customSensors=customSensors,
  customSensorXY=customSensorXY
}