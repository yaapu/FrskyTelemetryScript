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

local drawLib = {}

local status
local telemetry
local conf
local utils
local libs

-- model and opentx version
local ver, radio, maj, minor, rev = getVersion()
local yawRibbonPoints = {"N",nil,"NE",nil,"E",nil,"SE",nil,"S",nil,"SW",nil,"W",nil,"NW",nil}

function drawLib.init(param_status, param_telemetry, param_conf, param_utils, param_libs)
  status = param_status
  telemetry = param_telemetry
  conf = param_conf
  utils = param_utils
  libs = param_libs
end

function drawLib.drawHArrow(x,y,width,left,right,drawBlinkBitmap)
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
--
function drawLib.drawVArrow(x,y,top,bottom)
  if top == true then
    utils.drawBlinkBitmap("uparrow",x,y)
  else
    utils.drawBlinkBitmap("downarrow",x,y)
  end
end

function drawLib.drawHomeIcon(x,y)
  lcd.drawBitmap(utils.getBitmap("minihomeorange"),x,y)
end

function drawLib.computeOutCode(x,y,xmin,ymin,xmax,ymax)
    local code = 0; --initialised as being inside of hud
    --
    if x < xmin then --to the left of hud
        code = bit32.bor(code,1);
    elseif x > xmax then --to the right of hud
        code = bit32.bor(code,2);
    end
    if y < ymin then --below the hud
        code = bit32.bor(code,8);
    elseif y > ymax then --above the hud
        code = bit32.bor(code,4);
    end
    return code;
end

local function etxDrawLineWithClipping(x1,y1,x2,y2,style,xmin,xmax,ymin,ymax,color)
  lcd.drawLineWithClipping(x1,y1,x2,y2,xmin,xmax,ymin,ymax,style,color)
end

local function otxDrawLineWithClipping(x1,y1,x2,y2,style,xmin,xmax,ymin,ymax,color)
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
        lcd.drawLine(x[1],y[1],x[2],y[2], style, color)
      end
    end
  end
end

if lcd.drawLineWithClipping == nil then
  drawLib.drawLineWithClippingXY = otxDrawLineWithClipping
else
  drawLib.drawLineWithClippingXY = etxDrawLineWithClipping
end

local RAD_CONST = math.pi / 180

function drawLib.drawLineByOriginAndAngle(ox, oy, angle, len, style, xmin, xmax, ymin, ymax, color, drawDiameter)
    local cos = math.cos
    local sin = math.sin
    
    local halfLen = len * 0.5
    local angleRad = angle * RAD_CONST
    
    local xx = cos(angleRad) * halfLen
    local yy = sin(angleRad) * halfLen

    local x1 = ox + xx
    local y1 = oy + yy

    if drawDiameter == false then
        drawLib.drawLineWithClippingXY(ox, oy, x1, y1, style, xmin, xmax, ymin, ymax, color)
    else
        local x0 = ox - xx
        local y0 = oy - yy
        drawLib.drawLineWithClippingXY(x0, y0, x1, y1, style, xmin, xmax, ymin, ymax, color)
    end
end

function drawLib.drawNumberWithDim(x,y,xDim,yDim,number,dim,flags,dimFlags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawNumber(x, y, number,flags)
  lcd.drawText(xDim, yDim, dim, dimFlags)
end

function drawLib.drawRVehicle(x,y,r,angle,color,half)
  local ang = math.rad(angle - 90)
  local x1 = x + r * math.cos(ang)
  local y1 = y + r * math.sin(ang)

  ang = math.rad(angle - 90 + 150)
  local x2 = x + r * math.cos(ang)
  local y2 = y + r * math.sin(ang)

  ang = math.rad(angle - 90 - 150)
  local x3 = x + r * math.cos(ang)
  local y3 = y + r * math.sin(ang)
  ang = math.rad(angle - 270)
  local x4 = x + r * 0.5 * math.cos(ang)
  local y4 = y + r * 0.5 *math.sin(ang)
  --
  lcd.drawLine(x1,y1,x2,y2,SOLID,color)
  lcd.drawLine(x1,y1,x3,y3,SOLID,color)
  if half ~= true then
    lcd.drawLine(x2,y2,x4,y4,SOLID,color)
    lcd.drawLine(x3,y3,x4,y4,SOLID,color)
  end
end

function drawLib.drawRArrow(x, y, r1, r2, r3, angle, color)
  local drawLine = lcd.drawLine
  local rad = math.rad
  local cos = math.cos
  local sin = math.sin

  local base_ang = rad(angle - 90)
  local cos_b = cos(base_ang)
  local sin_b = sin(base_ang)

  local x0 = x - r1 * cos_b
  local y0 = y - r1 * sin_b
  local x1 = x + r1 * cos_b
  local y1 = y + r1 * sin_b

  local ang_p = rad(angle - 90 + r3)
  local x2 = x + r2 * cos(ang_p)
  local y2 = y + r2 * sin(ang_p)

  local ang_m = rad(angle - 90 - r3)
  local x3 = x + r2 * cos(ang_m)
  local y3 = y + r2 * sin(ang_m)

  drawLine(x1, y1, x2, y2, SOLID, color)
  drawLine(x1, y1, x3, y3, SOLID, color)
  drawLine(x1, y1, x0, y0, SOLID, color)
end


function drawLib.drawFenceStatus(x,y)
  if telemetry.fencePresent == 0 then
    return x
  end
  if telemetry.fenceBreached == 1 then
    utils.drawBlinkBitmap("fence_breach",x,y)
    return x+21
  end
  lcd.drawBitmap(utils.getBitmap("fence_ok"),x,y)
  return x+21
end

function drawLib.drawTerrainStatus(x,y)
  if status.terrainEnabled == 0 then
    return x
  end
  if telemetry.terrainUnhealthy == 1 then
    utils.drawBlinkBitmap("terrain_error",x,y)
    return x+21
  end
  lcd.drawBitmap(utils.getBitmap("terrain_ok"),x,y)
  return x+21
end


function drawLib.drawMinMaxBar(x, y, w, h, color, value, min, max, flags)
  local perc = math.min(math.max(value,min),max)
  lcd.setColor(CUSTOM_COLOR,WHITE)
  lcd.drawFilledRectangle(x,y,w,h,CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR,color)
  lcd.drawGauge(x, y,w,h,perc-min,max-min,CUSTOM_COLOR)
  lcd.setColor(CUSTOM_COLOR, BLACK)
  local strperc = string.format("%02d%%",value)
  local xOffset = flags==0 and 10 or 17
  local yOffset = flags==0 and 1 or 4
  lcd.drawText(x+w/2-xOffset, y-yOffset, strperc, flags+CUSTOM_COLOR)
end

-- initialize up to 5 bars
local barMaxValues = {}
local barAvgValues = {}
local barSampleCounts = {}

function drawLib.initMapTable(mapTable,name)
  if mapTable[name] == nil then
    mapTable[name] = 0
  end
end

function drawLib.updateBar(name, value)
  -- init
  drawLib.initMapTable(barSampleCounts,name)
  drawLib.initMapTable(barMaxValues,name)
  drawLib.initMapTable(barAvgValues,name)

  -- update metadata
  barSampleCounts[name] = barSampleCounts[name]+1
  barMaxValues[name] = math.max(value,barMaxValues[name])
  -- weighted average on 5 samples
  barAvgValues[name] = barAvgValues[name]*0.9 + value*0.1
end

-- draw an horizontal dynamic bar with an average red pointer of the last 5 samples
function drawLib.drawBar(name, x, y, w, h, color, value, flags)
  -- Data update logic
  drawLib.updateBar(name, value)

  -- Localize LCD calls for performance
  local drawFilled = lcd.drawFilledRectangle
  local setColor = lcd.setColor
  local maxVal = barMaxValues[name] or 0
  
  -- Step 1: Draw White Background
  setColor(CUSTOM_COLOR, WHITE)
  drawFilled(x, y, w, h, CUSTOM_COLOR)

  -- Percentage calculation with safety check
  local perc = 0
  local avgPerc = 0
  if maxVal > 0 then
    perc = value / maxVal
    avgPerc = (barAvgValues[name] or 0) / maxVal
  end

  -- Step 2: Draw Value Bar (Dynamic Color)
  local barW = perc * w
  setColor(CUSTOM_COLOR, color)
  drawFilled(math.max(x, x + w - barW), y + 1, math.min(w, barW), h - 2, CUSTOM_COLOR)

  -- Step 3: Draw Average Indicator (RED) - double line for thickness
  local avgX = x + w - avgPerc * (w - 2)
  setColor(CUSTOM_COLOR, RED)
  lcd.drawLine(avgX, y + 1, avgX, y + h - 2, SOLID, CUSTOM_COLOR)
  lcd.drawLine(avgX + 1, y + 1, avgX + 1, y + h - 2, SOLID, CUSTOM_COLOR)

  -- Step 4: Draw UI Elements (BLACK) - grouped to save setColor calls
  setColor(CUSTOM_COLOR, BLACK)
  lcd.drawNumber(x + w - 1, y - 3, value, CUSTOM_COLOR + flags + RIGHT)
  lcd.drawRectangle(x, y, w, h, CUSTOM_COLOR) -- Border
end


-- max is 20 samples every 1 sec
local graphSampleTime = {}
local graphMaxValues = {}
local graphMinValues = {}
local graphAvgValues = {}
local graphSampleCounts = {}
local graphSamples = {}

function drawLib.resetGraph(name)
  graphSampleTime[name] = 0
  graphMaxValues[name] = 0
  graphMinValues[name] = 0
  graphAvgValues[name] = 0
  graphSampleCounts[name] = 0
  graphSamples[name] = {}
end

function drawLib.updateGraph(name, value, maxSamples)
  local updated = false
  if maxSamples == nil then
    maxSamples = 20
  end
  -- init
  drawLib.initMapTable(graphSampleTime,name)
  drawLib.initMapTable(graphMaxValues,name)
  drawLib.initMapTable(graphMinValues,name)
  drawLib.initMapTable(graphAvgValues,name)
  drawLib.initMapTable(graphSampleCounts,name)

  if graphSamples[name] == nil then
    graphSamples[name] = {}
  end

  if getTime() - graphSampleTime[name] > 100 then
    graphSampleCounts[name] = graphSampleCounts[name]+1
    graphAvgValues[name] = graphAvgValues[name]*0.9 + value*0.1
    graphSamples[name][graphSampleCounts[name]%maxSamples] = value -- 0->49
    graphSampleTime[name] = getTime()
    updated = true
  end

  if graphSampleCounts[name] < 2 then
    return updated
  end
  return updated
end

function drawLib.getGraphMin(name)
  return graphMinValues[name] == math.huge and 0 or graphMinValues[name]
end

function drawLib.getGraphMax(name)
  return graphMaxValues[name] == -math.huge and 0 or graphMaxValues[name]
end

function drawLib.getGraphAvg(name)
  return graphAvgValues[name]
end

function drawLib.drawGraph(name, x, y, w, h, color, value, draw_bg, draw_value, unit, maxSamples)
    local drawLib = drawLib
    local lcd = lcd
    local m_min, m_max = math.min, math.max

    maxSamples = maxSamples or 20
    local samples = graphSamples[name]
    local count = graphSampleCounts[name]
    
    drawLib.updateGraph(name, value, maxSamples)
    if not samples or count < 2 then return nil end

    if draw_bg then
        lcd.setColor(CUSTOM_COLOR, WHITE)
        lcd.drawFilledRectangle(x, y, w, h, CUSTOM_COLOR)
    end

    local height = h - 2
    local maxY = y + height
    local step = (w - 2) / (maxSamples - 1)
    
    local gMin = graphMinValues[name] or 0
    local minMaxWindow = (graphMaxValues[name] or 0) - gMin
    local scale = (minMaxWindow == 0) and 1 or (height / minMaxWindow)

    lcd.setColor(CUSTOM_COLOR, color)
    
    local sampleWindow = m_min(maxSamples - 1, count - 1)
    local offset = count - sampleWindow
    local lastY = nil
    
    local tempMin = math.huge
    local tempMax = -math.huge

    local startIdx = (offset % maxSamples)
    if startIdx == 0 then startIdx = maxSamples end 
    local prevSample = samples[startIdx]
    
    if prevSample == nil then prevSample = value or 0 end
    
    local x_prev = x + step

    for i = 2, sampleWindow do
        local idx = (offset + i - 1) % maxSamples
        if idx == 0 then idx = maxSamples end
        
        local curSample = samples[idx]
        
        if curSample then
            local x_cur = x + i * step
            local y1 = m_min(maxY, m_max(y, maxY - (prevSample - gMin) * scale))
            local y2 = m_min(maxY, m_max(y, maxY - (curSample - gMin) * scale))
            
            lcd.drawLine(x_prev, y1, x_cur, y2, SOLID, CUSTOM_COLOR)
            
            x_prev = x_cur
            prevSample = curSample
            lastY = y2
            
            if curSample < tempMin then tempMin = curSample end
            if curSample > tempMax then tempMax = curSample end
        end
    end

    if tempMin ~= math.huge then
        graphMinValues[name] = tempMin
        graphMaxValues[name] = tempMax
    end
    
    if lastY then
        lcd.setColor(CUSTOM_COLOR, lcd.RGB(180, 180, 180))
        lcd.drawLine(x + 2, lastY, x + w - 2, lastY, DOTTED, CUSTOM_COLOR)

        if draw_bg then
            lcd.setColor(CUSTOM_COLOR, BLACK)
            lcd.drawRectangle(x, y, w, h, CUSTOM_COLOR)
        end

        if draw_value then
            lcd.setColor(CUSTOM_COLOR, WHITE)
            lcd.drawText(x + 2, lastY - 6, value .. unit, CUSTOM_COLOR + SMLSIZE + INVERS)
        end
    end

    return lastY
end

--[[
 x,y = top,left
 image = background image
 gx,gy = gauge center point
 r1 = gauge radius
 r2 = gauge distance from center
 perc = value % normalized between min, max
 max = angle max
--]]
function drawLib.drawGauge(x, y, image, gx, gy, r1, r2, perc, max, color)
  local rad, cos, sin = math.rad, math.cos, math.sin
  local drawLine = lcd.drawLine
  
  local ang = 360 - (max * 0.5) + (perc * 0.01 * max)

  if ang > 360 then ang = ang - 360 end

  local base_rad = rad(ang - 90)
  local rad_offset = rad(20)
  
  local ra_left  = base_rad - rad_offset
  local ra_right = base_rad + rad_offset

  local x1, y1 = gx + r1 * cos(base_rad), gy + r1 * sin(base_rad)
  local x2, y2 = gx + r2 * cos(ra_left),  gy + r2 * sin(ra_left)
  local x3, y3 = gx + r2 * cos(ra_right), gy + r2 * sin(ra_right)

  lcd.drawBitmap(utils.getBitmap(image), x, y)

  drawLine(x1, y1, x2, y2, SOLID, color)
  drawLine(x1, y1, x3, y3, SOLID, color)
  drawLine(x2, y2, x3, y3, SOLID, color)
end

function drawLib.drawFailsafe(x,y) --150, 45
  if telemetry.ekfFailsafe > 0 then
    utils.drawBlinkBitmap("ekffailsafe", x, y)
  elseif telemetry.battFailsafe > 0 then
    utils.drawBlinkBitmap("battfailsafe", x, y)
  elseif telemetry.failsafe > 0 then
    utils.drawBlinkBitmap("failsafe", x, y)
  end
end

function drawLib.drawArmStatus(x,y)
  -- armstatus
  if not utils.failsafeActive(telemetry) and status.timerRunning == 0 then
    if telemetry.statusArmed == 1 then
      lcd.drawBitmap(utils.getBitmap("armed"), x, y)
    else
      utils.drawBlinkBitmap("disarmed", x, y)
    end
  end
end

function drawLib.drawFilledRectangle(x,y,w,h,flags)
    if w > 0 and h > 0 then
      lcd.drawFilledRectangle(x,y,w,h,flags)
    end
end

local function fillTriangle(ox, oy, x1, x2, roll, angle, color)
  local drawRect = lcd.drawRectangle
  local abs = math.abs
  local step = 2

  -- Pre-calculate constant part of the linear equation: y = ax + b
  -- b = oy - (ox * angle)
  local intercept = oy - (ox * angle)
  
  local y1 = intercept + x1 * angle
  local y2 = intercept + x2 * angle

  local steps = abs(y2 - y1) / step
  
  if roll > 0 and roll <= 180 then
    local startY = (roll <= 90) and y1 or y2
    for s = 0, steps do
      local yy = startY + (s * step)
      -- Solving x = (y - b) / a
      local xx = (yy - intercept) / angle
      drawRect(x1, yy, xx - x1, step, color)
    end
  elseif roll < 0 and roll > -180 then
    local startY = (roll <= -90) and y1 or y2
    for s = 0, steps do
      local yy = startY + (s * step)
      local xx = (yy - intercept) / angle
      drawRect(xx, yy, x2 - xx + 1, step, color)
    end
  end
end

function drawLib.drawCompassRibbon(y, myWidget, width, xMin, xMax, stepWidth, bigFont, ribbonFont, ribbonColor)
    local lcd = lcd
    local tele = telemetry
    local floor = math.floor
    
    local heading = tele.yaw
    local minY = y + 1
    local midX = (xMax + xMin) * 0.5
    
    local tickNo = 4
    local stepCount = (xMax - xMin - 24) / (2 * tickNo)
    
    local closestHeading = floor(heading * 0.0444444) * 22.5
    local closestHeadingX = midX + (closestHeading - heading) * 0.0444444 * stepCount
    
    local tickIdx = (closestHeading * 0.0444444 - tickNo) % 16
    local tickX = closestHeadingX - tickNo * stepCount
    
    for i = 1, 10 do
        if tickX >= xMin and tickX < xMax then
            local label = yawRibbonPoints[floor(tickIdx + 1)]
            if label == nil then
                lcd.setColor(CUSTOM_COLOR, WHITE)
                lcd.drawLine(tickX, minY, tickX, y + 5, SOLID, CUSTOM_COLOR)
            else
                lcd.setColor(CUSTOM_COLOR, ribbonColor)
                lcd.drawText(tickX, minY - 3, label, CUSTOM_COLOR + CENTER + ribbonFont)
            end
        end
        tickIdx = (tickIdx + 1) % 16
        tickX = tickX + stepCount
    end

    local angle = (tele.homeAngle - heading) % 360
    local homeOffset
    
    if angle > 270 or angle < 90 then
        homeOffset = (((angle + 90) % 180) * 0.0055555 * width) - 3 -- 1/180 = 0.0055555
    elseif angle >= 90 and angle < 180 then
        homeOffset = width - 13
    else
        homeOffset = 0
    end
    
    if heading < 0 then heading = heading + 360 end
    
    local w = (heading < 10 and 20) or (heading < 100 and 40) or 60
    local scale = bigFont and 0.9 or 0.6
    local textY = bigFont and (minY - 4) or (minY - 1)
    local scaledW_2 = (w * 0.5) * scale
    
    lcd.setColor(CUSTOM_COLOR, BLACK)
    lcd.drawFilledRectangle(midX - scaledW_2, minY - 1, w * scale, 28 * scale, CUSTOM_COLOR + SOLID)
    
    lcd.setColor(CUSTOM_COLOR, WHITE)
    local flags = CUSTOM_COLOR + (bigFont and DBLSIZE or 0) + CENTER
    lcd.drawNumber(midX, textY, heading, flags)

    local homeY = minY + (bigFont and 28 or 20)
    drawLib.drawHomeIcon(xMin + homeOffset, homeY, utils)

end

function drawLib.drawCustomSensors(customSensors, customSensorXY, colorLabel)
  if #customSensorXY == 0 then
    return
  end
  if customSensorXY.boxY ~= nil then
    lcd.setColor(CUSTOM_COLOR,utils.colors.black)
    lcd.drawFilledRectangle(0,customSensorXY.boxY,320,35,CUSTOM_COLOR)
    lcd.setColor(CUSTOM_COLOR,utils.colors.grey)
    lcd.drawLine(1,customSensorXY.boxY+35,320-2,customSensorXY.boxY+35,SOLID,CUSTOM_COLOR)
  end

  local label,data,prec,mult,flags,sensorConfig
  for i=1,#customSensorXY
  do
    if customSensors.sensors[i] ~= nil then
      sensorConfig = customSensors.sensors[i]

      if sensorConfig[4] == "" then
        label = string.format("%s",sensorConfig[1])
      else
        label = string.format("%s(%s)",sensorConfig[1],sensorConfig[4])
      end
      -- draw sensor label
      lcd.setColor(CUSTOM_COLOR,customSensorXY[i][5] == nil and colorLabel or customSensorXY[i][5])
      lcd.drawText(customSensorXY[i][1], customSensorXY[i][2],label, SMLSIZE+RIGHT+CUSTOM_COLOR)

      mult =  sensorConfig[3] == 0 and 1 or ( sensorConfig[3] == 1 and 10 or 100 )
      prec =  mult == 1 and 0 or (mult == 10 and 32 or 48)

      local sensorName = sensorConfig[2]..(status.showMinMaxValues == true and sensorConfig[6] or "")
      local sensorValue = getValue(sensorName)
      local value = (sensorValue+(mult == 100 and 0.005 or 0))*mult*sensorConfig[5]

      local sign = sensorConfig[6] == "+" and 1 or -1
      flags = sensorConfig[7] == 1 and 0 or MIDSIZE

      if sensorConfig[10] == true then
      -- RED lcd.RGB(255,0, 0)
      -- GREEN lcd.RGB(0, 255, 0)
      -- YELLOW lcd.RGB(255, 204, 0)
        local color = lcd.RGB(255,0, 0)
        -- min/max tracking
        if math.abs(value) ~= 0 then
          color = ( sensorValue*sign > sensorConfig[9]*sign and lcd.RGB(255, 0, 0) or (sensorValue*sign > sensorConfig[8]*sign and lcd.RGB(255, 204, 0) or lcd.RGB(0, 255, 0)))
        end
        drawLib.drawMinMaxBar(customSensorXY[i][3]-sensorConfig[11],customSensorXY[i][4]+5,sensorConfig[11],sensorConfig[12],color,value,sensorConfig[13],sensorConfig[14],flags)
      else
        -- default font size
        local color = utils.colors.white
        -- min/max tracking
        if math.abs(value) ~= 0 and status.showMinMaxValues == false then
          color = ( sensorValue*sign > sensorConfig[9]*sign and lcd.RGB(255,70,0) or (sensorValue*sign > sensorConfig[8]*sign and utils.colors.yellow or utils.colors.white))
        end
        lcd.setColor(CUSTOM_COLOR,color)
        local voffset = flags==0 and 6 or 0
        -- if a lookup table exists use it!
        if customSensors.lookups[i] ~= nil and customSensors.lookups[i][value] ~= nil then
          lcd.drawText(customSensorXY[i][3], customSensorXY[i][4]+voffset, customSensors.lookups[i][value] or value, flags+RIGHT+CUSTOM_COLOR)
        else
          lcd.drawNumber(customSensorXY[i][3], customSensorXY[i][4]+voffset, value, flags+RIGHT+prec+CUSTOM_COLOR)
        end
      end
    end
  end
end

function drawLib.drawWindArrow(x, y, r1, r2, arrow_angle, angle, skew, color)
    -- Localizzazione funzioni math
    local sin = math.sin
    local cos = math.cos
    
    -- L'angolo base è (angle - 90), la metà dell'apertura è arrow_angle / 2
    local base_rad = (angle - 90) * RAD_CONST
    local half_arrow_rad = (arrow_angle * 0.5) * RAD_CONST
    
    -- Angoli per i tre punti della freccia
    local a = base_rad
    local ap = base_rad + half_arrow_rad
    local am = base_rad - half_arrow_rad

    -- Calcolo del vertice (punta della freccia)
    local x1 = x + r1 * cos(a) * skew
    local y1 = y + r1 * sin(a)
    
    -- Calcolo delle due ali della freccia
    local x2 = x + r2 * cos(ap) * skew
    local y2 = y + r2 * sin(ap)
    local x3 = x + r2 * cos(am) * skew
    local y3 = y + r2 * sin(am)

    -- Disegno delle linee
    lcd.drawLine(x1, y1, x2, y2, SOLID, color)
    lcd.drawLine(x1, y1, x3, y3, SOLID, color)
end

local function otxDrawHudRectangle(pitch, roll, minX, maxX, minY, maxY, color, ox, oy, dx, dy, scale)
  local lcd = lcd
  local floor = math.floor
  local abs = math.abs
  local rad = math.rad
  local tan = math.tan
  
  local width = maxX - minX
  local height = maxY - minY
  local midY = minY + height * 0.5

  if roll == 0 then
    local h = midY - dy - minY
    if h > 0 then
        lcd.drawFilledRectangle(minX, minY + height - h, width, h, CUSTOM_COLOR)
    end
    return
  elseif abs(roll) >= 180 then
    local h = midY + dy - minY
    if h > 0 then
        lcd.drawFilledRectangle(minX, minY, width, h, CUSTOM_COLOR)
    end
    return
  end

  local angle = tan(rad(-roll))
  if abs(angle) < 0.001 then angle = 0.001 end

  local inverted = abs(roll) > 90
  local yRect = inverted and minY or maxY
  local fillNeeded = false

  local step = 2
  local invAngle = 1 / angle

  if roll > 0 then
    for yy = minY, maxY - step, step do
      local xx = ox + (yy - oy) * invAngle
      if xx >= minX and xx <= maxX then
        lcd.drawFilledRectangle(xx, yy, maxX - xx + 1, step, CUSTOM_COLOR)
      elseif xx < minX then
        if inverted then yRect = yy + step else yRect = math.min(yy, yRect) end
        fillNeeded = true
      end
    end
  else
    for yy = minY, maxY - step, step do
      local xx = ox + (yy - oy) * invAngle
      if xx >= minX and xx <= maxX then
        lcd.drawFilledRectangle(minX, yy, xx - minX, step, CUSTOM_COLOR)
      elseif xx > maxX then
        if inverted then yRect = yy + step else yRect = math.min(yy, yRect) end
        fillNeeded = true
      end
    end
  end

  if fillNeeded then
    local h = inverted and (yRect - minY) or (maxY - yRect)
    if h > 0 then
      local yPos = inverted and minY or yRect
      lcd.drawFilledRectangle(minX, yPos, width, h, CUSTOM_COLOR)
    end
  end
end

local function etxDrawHudRectangle(pitch, roll, minX, maxX, minY, maxY, color, ox, oy, dx, dy, scale)
  lcd.drawHudRectangle(pitch, roll+0.001, minX, maxX, minY, maxY, color)
end

local drawHudRectangle = etxDrawHudRectangle
if lcd.drawHudRectangle == nil then
  drawHudRectangle = otxDrawHudRectangle
end

function drawLib.drawArtificialHorizon(x, y, w, h, bgBitmapName, colorSky, colorTerrain, lineCount, lineOffset, scale)
    local lcd = lcd
    local tele = telemetry
    local pitch = tele.pitch
    local roll = tele.roll
    local abs_roll = math.abs(roll)
    local r = -roll
    
    local midX = x + w * 0.5
    local midY = y + h * 0.5
    
    local dx, dy, cx, cy
    
    if roll == 0 or abs_roll == 180 then
        dx = 0
        dy = pitch * scale
        cx = 0
        cy = lineOffset
    else
        -- 90 - (-roll) = 90 + roll
        local angle_rad = (90 + roll) * RAD_CONST
        local cos_a = math.cos(angle_rad)
        local sin_a = math.sin(angle_rad)
        
        dx = cos_a * -pitch
        dy = sin_a * pitch * scale
        cx = cos_a * lineOffset
        cy = sin_a * lineOffset
    end

    local ox = midX + dx
    local oy = midY + dy

    if bgBitmapName == nil then
        lcd.setColor(CUSTOM_COLOR, colorSky)
        lcd.drawFilledRectangle(x, y, w, h, CUSTOM_COLOR)
    else
        local bmp = utils.getBitmap(bgBitmapName)
        if bmp then lcd.drawBitmap(bmp, x, y) end
    end

    lcd.setColor(CUSTOM_COLOR, colorTerrain)
    drawHudRectangle(pitch, roll, x, x + w, y, y + h, CUSTOM_COLOR, ox, oy, dx, dy, scale)

    -- Pitch lines
    lcd.setColor(CUSTOM_COLOR, WHITE)
    
    local drawLine = libs.drawLib.drawLineByOriginAndAngle
    local mMinX, mMaxX = x + 2, x + w - 2
    local mMinY, mMaxY = y + 2, y + h - 2
    
    local rollX_dx = midX + dx
    
    for dist = 1, lineCount do
        -- 80 if even, 40 if odd
        local len = (dist % 2 == 0) and 40 or 10
        local dist_cx = dist * cx
        local dist_cy = dist * cy
        
        -- above
        drawLine(rollX_dx - dist_cx, oy + dist_cy, r, len, DOTTED, mMinX, mMaxX, mMinY, mMaxY, CUSTOM_COLOR)
        -- below
        drawLine(rollX_dx + dist_cx, oy - dist_cy, r, len, DOTTED, mMinX, mMaxX, mMinY, mMaxY, CUSTOM_COLOR)
    end
end


return drawLib
