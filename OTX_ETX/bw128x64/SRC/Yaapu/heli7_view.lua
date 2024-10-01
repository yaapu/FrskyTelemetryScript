--
-- A FRSKY SPort/FPort/FPort2 and TBS CRSF telemetry script for the Taranis class radios
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

-----------------------
-- UNIT SCALING
-----------------------
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"

local function doGarbageCollect()
    collectgarbage()
    collectgarbage()
end

local initSensors = true
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
  local dist = getMaxValue(telemetry.homeDist,15)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(x+32, 22+1, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 22, dist*unitScale,RIGHT+flags)
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+1+1, 25-2,5,true,false)
  else
    drawLib.drawHomeIcon(x+1, 25)
  end
  doGarbageCollect()
end

-- max 6 extra sensors
local customSensors = nil
-- {label,name,prec:0,1,2,unit,multiplier,mninmax,font}

local function getSensorsConfigFilename()
  local info = model.getInfo()
  return "/MODELS/yaapu/" .. string.gsub(info.name, "[%c%p%s%z]", "").."_sensors.lua"
end

local function loadSensors()
  local tmp = io.open(getSensorsConfigFilename(),"r")
  if tmp == nil then
    return
  else
    io.close(tmp)
  end
  local sensorScript = loadScript(getSensorsConfigFilename())
  customSensors = sensorScript()
  sensorScript = nil
  doGarbageCollect()
  -- handle nil values for warning and critical levels
  for i=1,6
  do
    if customSensors.sensors[i] ~= nil then
      local sign = customSensors.sensors[i][6] == "+" and 1 or -1
      if customSensors.sensors[i][9] == nil then
        customSensors.sensors[i][9] = math.huge*sign
      end
      if customSensors.sensors[i][8] == nil then
        customSensors.sensors[i][8] = math.huge*sign
      end
    end
  end
  doGarbageCollect()
end


local customSensorXY = {
  { 0, 33 },
  { 47, 33 },
  { 0, 41 },
  { 47, 41 },
  { 0, 49 },
  { 47, 49 },
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

        mult =  sensorConfig[3] == 0 and 1 or ( sensorConfig[3] == 1 and 10 or 100 )
        prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)

        local sensorName = sensorConfig[2]..(status.showMinMaxValues == true and sensorConfig[6] or "")
        local sensorValue = getValue(sensorName)

        local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[5]

        flags = 0
        local voffset = 0
        local sign = sensorConfig[6] == "+" and 1 or -1

        -- max tracking, high values are critical
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          if sensorValue*sign > sensorConfig[9]*sign then
            color = BLINK
            labelColor = 0
          elseif sensorValue*sign > sensorConfig[8]*sign then
            color = 0
            labelColor = BLINK
          end
        end

        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][sensorValue] ~= nil then
          lcd.drawText(x+customSensorXY[i][1], voffset+customSensorXY[i][2], customSensors.lookups[i][sensorValue] or value, flags+color)
        else
          lcd.drawNumber(x+customSensorXY[i][1], voffset+customSensorXY[i][2], value, flags+prec+color)
        end
        lcd.drawText(lcd.getLastRightPos(), customSensorXY[i][2],sensorConfig[4],labelColor+SMLSIZE)
        doGarbageCollect()
      end
    end
end



local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0

local function drawMiniHud(drawLib,conf,telemetry,status,battery,getMaxValue)
  ----------------------
  -- MINI HUD TOP LEFT
  ----------------------
  local r = -telemetry.roll
  local dx,dy
  local yPos = 0 + 7 + 8

  if ( roll == 0) then
    dx=0
    dy=telemetry.pitch
    -- 1st line offsets
    cx=0
    cy=6
    -- 2nd line offsets
    ccx=0
    ccy=2*6
  else
    -- for a smaller hud vertical movement has to be scaled down
    dx = 0.4 * math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = 0.4 * math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 6
    cy = math.sin(math.rad(90 - r)) * 6
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * 8
    ccy = math.sin(math.rad(90 - r)) * 2 * 8
    -- 3rd line offsets
    cccx = math.cos(math.rad(90 - r)) * 3 * 8
    cccy = math.sin(math.rad(90 - r)) * 3 * 8
  end

  local minY = 7
  local maxY = 7 + 24
  local minX = 31 + 1
  local maxX = 31 + 64
  local ox = 31 + 31 + dx

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
  drawLib.drawLineWithClipping(31 + 31 + dx - cccx,dy + 7 + 12 + cccy,r,16,DOTTED,31,31 + 64,7,7+24)
  drawLib.drawLineWithClipping(31 + 31 + dx - ccx,dy + 7 + 12 + ccy,r,10,DOTTED,31,31 + 64,7,7+24)
  drawLib.drawLineWithClipping(31 + 31 + dx - cx,dy + 7 + 12 + cy,r,16,DOTTED,31,31 + 64,7,7+24)
  drawLib.drawLineWithClipping(31 + 31 + dx + cx,dy + 7 + 12 - cy,r,16,DOTTED,31,31 + 64,7,7+24)
  drawLib.drawLineWithClipping(31 + 31 + dx + ccx,dy + 7 + 12 - ccy,r,10,DOTTED,31,31 + 64,7,7+24)
  drawLib.drawLineWithClipping(31 + 31 + dx + cccx,dy + 7 + 12 - cccy,r,16,DOTTED,31,31 + 64,7,7+24)
  -------------------------------------
  -- vario indicator on right
  -------------------------------------
  lcd.drawFilledRectangle(31 + 64 - 5, 7, 5, 24, ERASE, 0)
  vspd = telemetry.vSpeed

  lcd.drawLine(31 + 64 - 6, 7, 31 + 64 - 6, 30, SOLID, FORCE)
  local varioMax = 5
  local varioSpeed = math.min(math.abs(0.1*vspd),5)
  local varioY = 0
  local arrowY = -1
  if vspd > 0 then
    varioY = 19 - varioSpeed/varioMax*9 - 3
  else
    varioY = 19 + 4
    arrowY = 1
  end
  lcd.drawFilledRectangle(31 + 64 - 4, varioY, 4, varioSpeed/varioMax*9, FORCE, 0)
  --[[
  for i=0,8
  do
    lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 3, 8+i*3, ALT_HUD_X + ALT_HUD_WIDTH -1, 8+i*3, SOLID, ERASE)
    lcd.drawLine(ALT_HUD_X + ALT_HUD_WIDTH - 2, arrowY+8+i*3, ALT_HUD_X + ALT_HUD_WIDTH-2, arrowY+8+i*3, SOLID, ERASE)
  end
  --]]
  lcd.drawLine(31 + 64 - 5, 19, 31 + 64, 19, SOLID, FORCE)
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- lets erase to hide the artificial horizon lines
  -- black borders
  lcd.drawRectangle(31+1, 19 - 5, 16, 10, FORCE, 0)
  lcd.drawFilledRectangle(31+2, 19 - 4, 16, 8, ERASE, 0)
  lcd.drawLine(31+16+2,19 - 3,31+16+2,19 +2,SOLID,FORCE)
  lcd.drawPoint(31+16+1,19 - 4,SOLID+FORCE)
  lcd.drawPoint(31+16+1,19 + 3,SOLID+FORCE)

  lcd.drawRectangle(31 + 64 - 18 + 1, 19 - 5, 18, 10, FORCE, 0)
  lcd.drawFilledRectangle(31 + 64 - 18, 19 - 4, 18, 8, ERASE, 0)
  lcd.drawLine(31 + 64 - 18 - 1, 19 - 3,31 + 64 - 18 - 1, 19 +2,SOLID,FORCE)
  lcd.drawPoint(31 + 64 - 18, 19 - 4,SOLID+FORCE)
  lcd.drawPoint(31 + 64 - 18, 19 + 3,SOLID+FORCE)

  -- altitude
  local alt = getMaxValue(telemetry.homeAlt,11) * unitScale -- homeAlt is meters*3.28 = feet
  if math.abs(alt) < 10 then
      lcd.drawNumber(31 + 64,19 - 3,alt * 10,SMLSIZE+PREC1+RIGHT)
  else
      lcd.drawNumber(31 + 64,19 - 3,alt,SMLSIZE+RIGHT)
  end
  -- hspeed
  local speed = getMaxValue(telemetry.hSpeed,14) * conf.horSpeedMultiplier
  if math.abs(speed) > 99 then
    lcd.drawNumber(31+2,19 - 3,speed*0.1,SMLSIZE)
  else
    lcd.drawNumber(31+2,19 - 3,speed,SMLSIZE+PREC1)
  end
  -- reference lines
  lcd.drawLine(65-11-1,19,65-6-1,19 ,SOLID,0) -- -1 to compensate for H offset
  lcd.drawLine(65-5-1,19,65-5-1,19+3 ,SOLID,0)
  lcd.drawLine(65+2-1,19,65+7-1,19 ,SOLID,0)
  lcd.drawLine(65+1-1,19,65+1-1,19+3 ,SOLID,0)
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(31 + 64 - 24, 19 - 4,6,true,false)
    drawLib.drawVArrow(31 +   17 + 4, 19 - 4,6,true,false)
  end
  -- yaw angle box
  local xx = telemetry.yaw < 10 and 0 or ( telemetry.yaw < 100 and -2 or -5 )
  lcd.drawNumber(65 + xx - 4, 0+7, telemetry.yaw, INVERS+SMLSIZE)
end

local function drawRightPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  local perc = battery[16+battId]
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
  lcd.drawNumber(x+0, 7, (battery[1+battId] + 0.5)*(battery[1+battId] < 1000 and 1 or 0.1), MIDSIZE+flags+(battery[1+battId] < 1000 and PREC2 or PREC1))
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+0+26, 7+2,6,false,true)
  else
    lcd.drawText(128, 6, "V", dimFlags+SMLSIZE+RIGHT)
    --local xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
    local s = status.battsource == "a2" and "a" or (status.battsource == "vs" and "s" or "f")
    lcd.drawText(128, 12, s, SMLSIZE+RIGHT)
  end

  -- battery voltage
  lcd.drawText(x+32, 19, "V", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 19, battery[4+battId],SMLSIZE+PREC1+RIGHT)
  -- battery current
  lcd.drawText(x+32, 26, "A", SMLSIZE+RIGHT)
  local mult = (battery[7+battId]*0.1 < 10) and 1 or 0.1
  lcd.drawNumber(lcd.getLastLeftPos()-1, 26, battery[7+battId]*mult,SMLSIZE+RIGHT+(mult == 1 and PREC1 or 0))
  -- battery percentage
  lcd.drawNumber(x+0, 32, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos()+1, 35, "%", SMLSIZE)
  -- battery mah
  lcd.drawNumber(x+0, 44, battery[10+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 44, "Ah", SMLSIZE)
  -- battery cap
  lcd.drawNumber(x+0, 44+7, battery[13+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 44+7, "Ah", SMLSIZE)
end

--------------------
-- Single long function much more memory efficient than many little functions
---------------------
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
      doGarbageCollect()
    end
  end

  drawCustomSensors(0,status)

  drawRightPane(128-31,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  drawMiniHud(drawLib,conf,telemetry,status,battery,getMaxValue)
  drawLeftPane(0,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  drawLib.drawRArrow(25,14,6,telemetry.homeAngle - telemetry.yaw,FORCE)

  lcd.drawLine(95, 7 ,95, 56, SOLID, FORCE)
  lcd.drawLine(0, 31 ,95, 31, SOLID, FORCE)
  lcd.drawLine(32, 7 ,32, 31, SOLID, FORCE)
  --lcd.drawLine(64, 7 ,64, 31, SOLID, FORCE)

  -- arming status, show only if timer is not running, hide otherwise
  if telemetry.ekfFailsafe == 0 and telemetry.battFailsafe == 0 and status.timerRunning == 0 then
    if (telemetry.statusArmed == 1) then
      lcd.drawText(31 + 20, 22, "ARMED", SMLSIZE+INVERS)
    else
      lcd.drawText(31+12, 22, "DISARMED", SMLSIZE+INVERS+BLINK)
    end
  end
  if telemetry.ekfFailsafe > 0 then
    lcd.drawText(31+14, 22, "EKF FAIL", SMLSIZE+INVERS+BLINK)
  end

  if telemetry.battFailsafe > 0 then
    lcd.drawText(31+14, 22, "BAT FAIL", SMLSIZE+INVERS+BLINK)
  end
end


return {
  drawView=drawView,
  customSensors=customSensors,
  customSensorXY=customSensorXY
}
