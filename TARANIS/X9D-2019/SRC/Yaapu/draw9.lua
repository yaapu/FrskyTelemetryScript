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
local unitScale = getGeneralSettings().imperial == 0 and 1 or 3.28084
local unitLabel = getGeneralSettings().imperial == 0 and "m" or "ft"
local unitLongScale = getGeneralSettings().imperial == 0 and 1/1000 or 1/1609.34
local unitLongLabel = getGeneralSettings().imperial == 0 and "km" or "mi"
local function doGarbageCollect()
    collectgarbage()
    collectgarbage()
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


local function drawHomeIcon(x,y)
  lcd.drawRectangle(x,y,5,5,SOLID)
  lcd.drawLine(x+2,y+3,x+2,y+4,SOLID,FORCE)
  lcd.drawPoint(x+2,y-1,FORCE)
  lcd.drawLine(x,y+1,x+5,y+1,SOLID,FORCE)
  lcd.drawLine(x-1,y+1,x+2,y-2,SOLID, FORCE)
  lcd.drawLine(x+5,y+1,x+3,y-1,SOLID, FORCE)
end

local function drawLineWithClipping(ox,oy,angle,len,style,xmin,xmax,ymin,ymax)
  local xx = math.cos(math.rad(angle)) * len * 0.5
  local yy = math.sin(math.rad(angle)) * len * 0.5
  
  local x1 = ox - xx
  local x2 = ox + xx
  local y1 = oy - yy
  local y2 = oy + yy
  
  local x= {}
  local y = {}
  if not(x1 < xmin and x2 < xmin) and not(x1 > xmax and x2 > xmax) then
    if not(y1 < ymin and y2 < ymin) and not(y1 > ymax and y2 > ymax) then
      x[1]=x1
      y[1]=y1
      x[2]=x2
      y[2]=y2
      for i=1,2
      do
        if x[i] < xmin then
          x[i] = xmin
          y[i] = ((y2-y1)/(x2-x1))*(xmin-x1)+y1
        elseif x[i] > xmax then
          x[i] = xmax
          y[i] = ((y2-y1)/(x2-x1))*(xmax-x1)+y1
        end

        if y[i] < ymin then
          y[i] = ymin
          x[i] = ((x2-x1)/(y2-y1))*(ymin-y1)+x1
        elseif y[i] > ymax then
          y[i] = ymax
          x[i] = ((x2-x1)/(y2-y1))*(ymax-y1)+x1
        end
      end
      if not(x[1] < xmin and x[2] < xmin) and not(x[1] > xmax and x[2] > xmax) then
        lcd.drawLine(x[1],y[1],x[2],y[2], style, 0)
      end
    end
  end
end

local function drawBottomBar(msg,lastMsgTime)
  lcd.drawText(0,56+1,msg,SMLSIZE+INVERS)
end


local function drawGrid()
  lcd.drawLine(62 - 1, 7 ,62 - 1, 57, SOLID, FORCE)
  lcd.drawLine(62 + 88, 7, 62 + 88, 55, SOLID, FORCE)
end

local function drawTopBar(strMode,simpleMode,flightTime,telemetryEnabled,rssi)
  -- flight mode
  -- simplemode
  if strMode ~= nil then
    lcd.drawText(1, 0, strMode, SMLSIZE+INVERS)
    if ( simpleMode > 0) then
      local strSimpleMode = simpleMode == 1 and "(S)" or "(SS)"
      lcd.drawText(lcd.getLastRightPos(), 0, strSimpleMode, SMLSIZE+INVERS)
    end
  end
  lcd.drawTimer(212-1, 0, flightTime, SMLSIZE+INVERS+TIMEHOUR+RIGHT)
  -- tx voltage
  local vTx = string.format("Tx%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(115, 0, vTx, SMLSIZE+INVERS)
  -- RSSI
  if (not telemetryEnabled()) then
    lcd.drawText(105, 0, "no telem!", SMLSIZE+BLINK+INVERS)
  else
    lcd.drawText(105, 0, rssi, SMLSIZE+INVERS+RIGHT)
    lcd.drawText(lcd.getLastLeftPos(), 0, "R:", SMLSIZE+INVERS+RIGHT)
  end
end

local function drawFailSafe(showDualBattery,ekfFailsafe,battFailsafe,failsafe)
  if ekfFailsafe+battFailsafe+failsafe == 0 then
    return
  end
  local msg = "    FAILSAFE   "
  if ekfFailsafe > 0 then
    msg = " EKF FAILSAFE  "
  elseif battFailsafe > 0 then
    msg = " BATT FAILSAFE "
  end
  lcd.drawText(62 + 88/2 - 31, 20, msg, SMLSIZE+INVERS+BLINK)
end

local function drawNoTelemetry(telemetryEnabled,hideNoTelemetry)
  -- no telemetry data
  if (not telemetryEnabled() and not hideNoTelemetry) then
    lcd.drawFilledRectangle((212-130)/2,18, 130, 30, SOLID)
    lcd.drawRectangle((212-130)/2,18, 130, 30, ERASE)
    lcd.drawText(60, 29, "no telemetry data", INVERS)
    return
  end
end

local function drawRArrow(x,y,rad,angle,flags)
  local x1 = x + rad * math.cos(math.rad(angle - 90))
  local y1 = y + rad * math.sin(math.rad(angle - 90))
  local x2 = x + (rad-1) * math.cos(math.rad(angle - 90 + 140))
  local y2 = y + (rad-1) * math.sin(math.rad(angle - 90 + 140))
  local x3 = x + (rad-1) * math.cos(math.rad(angle - 90 - 140))
  local y3 = y + (rad-1) * math.sin(math.rad(angle - 90 - 140))
  local x4 = x + (rad-1) * 0.5 * math.cos(math.rad(angle - 270))
  local y4 = y + (rad-1) * 0.5 *math.sin(math.rad(angle - 270))
  --
  lcd.drawLine(x1,y1,x2,y2,SOLID,flags)
  lcd.drawLine(x1,y1,x3,y3,SOLID,flags)
  lcd.drawLine(x2,y2,x4,y4,SOLID,flags)
  lcd.drawLine(x3,y3,x4,y4,SOLID,flags)
  lcd.drawPoint(x1,y1,SOLID+flags)
end

return {
  drawFailSafe=drawFailSafe,
  drawTopBar=drawTopBar,
  drawHArrow=drawHArrow,
  drawVArrow=drawVArrow,
  drawRArrow=drawRArrow,
  drawGrid=drawGrid,
  drawBottomBar=drawBottomBar,
  drawHomeIcon=drawHomeIcon,
  drawLineWithClipping=drawLineWithClipping,
  drawNoTelemetry=drawNoTelemetry
  }
