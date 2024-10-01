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
  lcd.drawText(x+115, 8+1, unitLabel,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), 8, dist*unitScale,RIGHT+flags)
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+73+1, 10-2,5,true,false)
  else
    drawLib.drawHomeIcon(x+73, 10)
  end
  -- total distance
  lcd.drawText(70, 8, unitLongLabel, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos(), 8, telemetry.totalDist*unitLongScale*10, RIGHT+SMLSIZE+PREC1)
  -- needs to be called often for strings created by decToDMSFull() fragment memory
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
  { 0, 26 },
  { 58, 26 },
  { 0, 33 },
  { 58, 33 },
  { 0, 44 },
  { 58, 44 },
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

        -- default font size
        flags = i<=2 and 0 or (sensorConfig[7] == 1 and 0 or MIDSIZE)

        -- reduce font if necessary
        if math.abs(value)/mult > 9999 then
          flags = 0
        end

        local voffset = (i>2 and flags==0) and 3 or 0
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
        lcd.drawText(lcd.getLastRightPos()-(sensorConfig[7]==MIDSIZE and 1 or 0), customSensorXY[i][2]+(i>2 and 5 or 1),sensorConfig[4],labelColor+SMLSIZE)
        doGarbageCollect()
      end
    end
end

-- SYNTH VSPEED SUPPORT
local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0

local function drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)
  -- HUD
  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy
  local yPos = 0 + 7 + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of 6
  if ( roll == 0) then
    dx=0
    dy=telemetry.pitch
    cx=0
    cy=6
    ccx=0
    ccy=2*6
  else
    -- center line offsets
    dx = math.cos(math.rad(90 - r)) * -telemetry.pitch
    dy = math.sin(math.rad(90 - r)) * telemetry.pitch
    -- 1st line offsets
    cx = math.cos(math.rad(90 - r)) * 6
    cy = math.sin(math.rad(90 - r)) * 6
    --[[
    -- 2nd line offsets
    ccx = math.cos(math.rad(90 - r)) * 2 * HUD_R2
    ccy = math.sin(math.rad(90 - r)) * 2 * HUD_R2
    --]]
  end
  -----------------------
  -- dark color for "ground"
  -----------------------
  local minY = 7
  local minX = 116 + 1
  local maxX = 116 + 62 - 6
  local maxY = 54
  local ox = 147 + dx
  local oy = 33 + dy
  local yy = 0
  local rollX = 147-1
  for dist=1,6
  do
    drawLib.drawLineWithClipping(rollX + dx - dist*cx,dy + 33 + dist*cy,r,(dist%2==0 and 20 or 8),DOTTED,116,116 + 62,8,maxY)
    drawLib.drawLineWithClipping(rollX + dx + dist*cx,dy + 33 - dist*cy,r,(dist%2==0 and 20 or 8),DOTTED,116,116 + 62,8,maxY)
  end
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
  vspd = telemetry.vSpeed
  -------------------------------------
  -- vario indicator on right
  -------------------------------------
  lcd.drawLine(116 + 62 - 4, 7, 116 + 62 - 4, yPos + 40, SOLID, 0)
  local varioMax = 10
  local varioSpeed = math.min(math.abs(0.1*vspd),10)
  local varioY = 0
  local arrowY = -1
  if vspd > 0 then
    varioY = 33 - 4 - varioSpeed/varioMax*22
  else
    varioY = 33 + 6
    arrowY = 1
  end
  lcd.drawFilledRectangle(116 + 62 - 4, varioY, 4, varioSpeed/varioMax*22, FORCE, 0)
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- black borders
  lcd.drawRectangle(116, 33 - 5, 19, 11, FORCE, 0)
  lcd.drawRectangle(116 + 62 -  17 - 3, 33 - 5, 20, 11, FORCE, 0)
  -- erase area
  lcd.drawFilledRectangle(116, 33 - 4, 18, 9, ERASE, 0)
  lcd.drawFilledRectangle(116 + 62 -  17 - 2, 33 - 4, 19, 9, ERASE, 0)
  -- altitude
  local alt = getMaxValue(telemetry.homeAlt,11) * unitScale -- homeAlt is meters*3.28 = feet

  if math.abs(alt) < 10 then
      lcd.drawNumber(116 + 62,33 - 3,alt * 10,SMLSIZE+PREC1+RIGHT)
  else
      lcd.drawNumber(116 + 62,33 - 3,alt,SMLSIZE+RIGHT)
  end
  -- hspeed
  local speed = getMaxValue(telemetry.hSpeed,14) * conf.horSpeedMultiplier
  if math.abs(speed) > 99 then
    lcd.drawNumber(116+1,33 - 3,speed*0.1,SMLSIZE)
  else
    lcd.drawNumber(116+1,33 - 3,speed,SMLSIZE+PREC1)
  end
  -- reference lines
  lcd.drawLine(147-9-1,33,147-4-1,33 ,SOLID,0) -- -1 to compensate for H offset
  lcd.drawLine(147-3-1,33,147-3-1,33+3 ,SOLID,0)
  lcd.drawLine(147+4-1,33,147+9-1,33 ,SOLID,0)
  lcd.drawLine(147+3-1,33,147+3-1,33+3 ,SOLID,0)
  -- vspeed box (dm/s)
  local xx = math.abs(vspd*conf.vertSpeedMultiplier) > 9999 and 4 or 3
  xx = xx + (vspd*conf.vertSpeedMultiplier < 0 and 1 or 0)
  lcd.drawFilledRectangle(147 - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, ERASE)
  if math.abs(vspd*conf.vertSpeedMultiplier) > 99 then --
    lcd.drawNumber(147 + (xx/2)*5, LCD_H - 15, vspd*0.1*conf.vertSpeedMultiplier, SMLSIZE+RIGHT)
  else
    lcd.drawNumber(147 + (xx/2)*5, LCD_H - 15, vspd*conf.vertSpeedMultiplier, SMLSIZE+RIGHT+PREC1)
  end
  lcd.drawRectangle(147 - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, FORCE)
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(116 + 62 - 24, 33 - 4,6,true,false)
    drawLib.drawVArrow(116 +   17 + 4, 33 - 4,6,true,false)
  end
  -- arming status, show only if timer is not running, hide otherwise
  if telemetry.ekfFailsafe == 0 and telemetry.battFailsafe == 0 and status.timerRunning == 0 then
    if (telemetry.statusArmed == 1) then
      lcd.drawText(116 + 62/2 - 15, 20, " ARMED ", SMLSIZE+INVERS)
    else
      lcd.drawText(116 + 62/2 - 21, 20, " DISARMED ", SMLSIZE+INVERS+BLINK)
    end
  end
  -- yaw angle box
  xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
  lcd.drawNumber(147 + xx - 6, 0+7-1, telemetry.yaw, MIDSIZE+INVERS)
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
    lcd.drawText(212, 6, "V", dimFlags+SMLSIZE+RIGHT)
    --local xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
    local s = status.battsource == "a2" and "a" or (status.battsource == "vs" and "s" or "f")
    lcd.drawText(212, 12, s, SMLSIZE+RIGHT)
  end

  -- battery voltage
  lcd.drawText(x+33, 19, "V", SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos()-1, 19, battery[4+battId],SMLSIZE+PREC1+RIGHT)
  -- battery current
  lcd.drawText(x+33, 26, "A", SMLSIZE+RIGHT)
  local mult = (battery[7+battId]*0.1 < 10) and 1 or 0.1
  lcd.drawNumber(lcd.getLastLeftPos()-1, 26, battery[7+battId]*mult,SMLSIZE+RIGHT+(mult == 1 and PREC1 or 0))
  -- battery percentage
  lcd.drawNumber(x+0, 31, perc, MIDSIZE)
  lcd.drawText(lcd.getLastRightPos()+1, 35, "%", SMLSIZE)
  -- battery mah
  lcd.drawNumber(x+0, 43, battery[10+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 43, "Ah", SMLSIZE)
  -- battery cap
  lcd.drawNumber(x+0, 43+7, battery[13+battId]/10, SMLSIZE+PREC2)
  lcd.drawText(lcd.getLastRightPos(), 43+7, "Ah", SMLSIZE)
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

  drawLib.drawRArrow(165,48,7,telemetry.homeAngle - telemetry.yaw,1)
  drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)

  drawRightPane(212-32,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  drawLeftPane(0,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)

  lcd.drawLine(0,24 ,116-1, 24, SOLID, FORCE)
  lcd.drawLine(20, 7 , 20, 23, SOLID, FORCE)
  lcd.drawLine(70, 7 ,70, 23, SOLID, FORCE)
  lcd.drawLine(116 - 1, 7 ,116 - 1, 57, SOLID, FORCE)
  lcd.drawLine(116 + 62, 7, 116 + 62, 57, SOLID, FORCE)

  if telemetry.ekfFailsafe + telemetry.battFailsafe + telemetry.failsafe > 0 then
    local msg = "  FAILSAFE  "
    if telemetry.ekfFailsafe > 0 then
      msg = " EKF FAILSAFE "
    elseif telemetry.battFailsafe > 0 then
      msg = " BATT FAILSAFE "
    end
    lcd.drawText(116 + 62/2 - 33, 20, msg, SMLSIZE+INVERS+BLINK)
  end
  -- terrain status
  local xNext = 116 + 2


end



return {
  drawView=drawView,
  customSensors=customSensors,
  customSensorXY=customSensorXY
}
