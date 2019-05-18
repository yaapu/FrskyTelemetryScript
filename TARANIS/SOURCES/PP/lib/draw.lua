#include "includes/yaapu_inc.lua"

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
#ifdef X9  
  if top == true then
    lcd.drawLine(x - 1,y + 1,x - 2,y  + 2, SOLID, 0)
    lcd.drawLine(x + 1,y + 1,x + 2,y  + 2, SOLID, 0)
  end
  if bottom == true then
    lcd.drawLine(x - 1,y  + h - 1,x - 2,y + h - 2, SOLID, 0)
    lcd.drawLine(x + 1,y  + h - 1,x + 2,y + h - 2, SOLID, 0)
  end
#else
  if top == true then
    lcd.drawPoint(x - 1,y + 1)
    lcd.drawPoint(x + 1,y + 1)
  end
  if bottom == true then
    lcd.drawPoint(x - 1,y  + h - 1)
    lcd.drawPoint(x + 1,y  + h - 1)
  end
#endif
end


#ifdef X9
local function drawHomeIcon(x,y)
  lcd.drawRectangle(x,y,5,5,SOLID)
  lcd.drawLine(x+2,y+3,x+2,y+4,SOLID,FORCE)
  lcd.drawPoint(x+2,y-1,FORCE)
  lcd.drawLine(x,y+1,x+5,y+1,SOLID,FORCE)
  lcd.drawLine(x-1,y+1,x+2,y-2,SOLID, FORCE)
  lcd.drawLine(x+5,y+1,x+3,y-1,SOLID, FORCE)
end
#else --X9
local function drawHomeIcon(x,y)
  lcd.drawRectangle(x,y,3,4,SOLID)
  lcd.drawFilledRectangle(x,y,3,4,SOLID)
  lcd.drawPoint(x-1,y+1,FORCE)
  lcd.drawPoint(x+3,y+1,FORCE)
  lcd.drawPoint(x+1,y-1,FORCE)
end
#endif

#define CS_INSIDE 0
#define CS_LEFT 1
#define CS_RIGHT 2
#define CS_BOTTOM 4
#define CS_TOP 8

local function computeOutCode(x,y,xmin,ymin,xmax,ymax)
    local code = CS_INSIDE; --initialised as being inside of hud
    --
    if x < xmin then --to the left of hud
        code = bit32.bor(code,CS_LEFT);
    elseif x > xmax then --to the right of hud
        code = bit32.bor(code,CS_RIGHT);
    end
    if y < ymin then --below the hud
        code = bit32.bor(code,CS_BOTTOM);
    elseif y > ymax then --above the hud
        code = bit32.bor(code,CS_TOP);
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
    if ( bit32.bor(outcode0,outcode1) == CS_INSIDE) then
      -- bitwise OR is 0: both points inside window; trivially accept and exit loop
      accept = true;
      break;
    elseif (bit32.band(outcode0,outcode1) ~= CS_INSIDE) then
      -- bitwise AND is not 0: both points share an outside zone (LEFT, RIGHT, TOP, BOTTOM)
      -- both must be outside window; exit loop (accept is false)
      break;
    else
      -- failed both tests, so calculate the line segment to clip
      -- from an outside point to an intersection with clip edge
      local x = 0
      local y = 0
      -- At least one endpoint is outside the clip rectangle; pick it.
      local outcodeOut = outcode0 ~= CS_INSIDE and outcode0 or outcode1
      -- No need to worry about divide-by-zero because, in each case, the
      -- outcode bit being tested guarantees the denominator is non-zero
      if bit32.band(outcodeOut,CS_TOP) ~= CS_INSIDE then --point is above the clip window
        x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
        y = ymax
      elseif bit32.band(outcodeOut,CS_BOTTOM) ~= CS_INSIDE then --point is below the clip window
        x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
        y = ymin
      elseif bit32.band(outcodeOut,CS_RIGHT) ~= CS_INSIDE then --point is to the right of clip window
        y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
        x = xmax
      elseif bit32.band(outcodeOut,CS_LEFT) ~= CS_INSIDE then --point is to the left of clip window
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

local function drawBottomBar(msg,lastMsgTime)
  lcd.drawText(0,BOTTOMBAR_Y+1,msg,SMLSIZE+INVERS)
end

#ifdef DEV
local function drawCircle(x0,y0,radius,delta)
  local x = radius-1
  local y = 0
  local dx = delta
  local dy = delta
  local err = dx - bit32.lshift(radius,1)
  while (x >= y) do
    lcd.drawPoint(x0 + x, y0 + y);
    lcd.drawPoint(x0 + y, y0 + x);
    lcd.drawPoint(x0 - y, y0 + x);
    lcd.drawPoint(x0 - x, y0 + y);
    lcd.drawPoint(x0 - x, y0 - y);
    lcd.drawPoint(x0 - y, y0 - x);
    lcd.drawPoint(x0 + y, y0 - x);
    lcd.drawPoint(x0 + x, y0 - y);
    if err <= 0 then
      y=y+1
      err = err + dy
      dy = dy + 2
    end
    if err > 0 then

      x=x-1
      dx = dx + 2
      err = err + dx - bit32.lshift(radius,1)
    end
  end
end
#endif --DEV

local function drawGrid()
  lcd.drawLine(HUD_X - 1, 7 ,HUD_X - 1, 57, SOLID, FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH, 7, HUD_X + HUD_WIDTH, 55, SOLID, FORCE)
end

local function drawTopBar(strMode,simpleMode,flightTime,telemetryEnabled)
  -- flight mode
  -- simplemode
  if strMode ~= nil then
    lcd.drawText(FLIGHTMODE_X, FLIGHTMODE_Y, strMode, FLIGHTMODE_FLAGS)
    if ( simpleMode > 0) then
      local strSimpleMode = simpleMode == 1 and "(S)" or "(SS)"
      lcd.drawText(lcd.getLastRightPos(), FLIGHTMODE_Y, strSimpleMode, FLIGHTMODE_FLAGS)
    end
  end  
#ifdef X9
  lcd.drawTimer(LCD_W-1, FLIGHTTIME_Y, flightTime, FLIGHTTIME_FLAGS+RIGHT)
#else
  lcd.drawTimer(FLIGHTTIME_X, FLIGHTTIME_Y, flightTime, FLIGHTTIME_FLAGS)
#endif
  -- RSSI
  if (not telemetryEnabled()) then
#ifdef X9
    lcd.drawText(RSSI_X, RSSI_Y, "no telem!", SMLSIZE+BLINK+INVERS)
#else
    lcd.drawText(RSSI_X-24, RSSI_Y, "no telem!", SMLSIZE+BLINK+INVERS)
#endif
  else
    lcd.drawText(RSSI_X, RSSI_Y, "RS:", RSSI_FLAGS)
#ifdef DEMO
    lcd.drawText(lcd.getLastRightPos(), RSSI_Y, 87, RSSI_FLAGS)  
#else --DEMO
    lcd.drawText(lcd.getLastRightPos(), RSSI_Y, getRSSI(), RSSI_FLAGS)  
#endif --DEMO
  end
#ifdef X9
  -- tx voltage
  local vTx = string.format("Tx%.1fv",getValue(getFieldInfo("tx-voltage").id))
  lcd.drawText(TXVOLTAGE_X, TXVOLTAGE_Y, vTx, TXVOLTAGE_FLAGS)
#endif --X9
end

local function drawFailSafe(showDualBattery,ekfFailsafe,battFailsafe)
  local xoffset = 0
  local yoffset = 0
  if ekfFailsafe > 0 then
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 31, 20 + yoffset, " EKF FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
  if battFailsafe > 0 then
    lcd.drawText(xoffset + HUD_X + HUD_WIDTH/2 - 31, 20 + yoffset, " BATT FAILSAFE ", SMLSIZE+INVERS+BLINK)
  end
end

#ifndef NOTELEM_POPUP
local function drawNoTelemetry(telemetryEnabled,hideNoTelemetry)
  -- no telemetry data
#ifdef X9
  if (not telemetryEnabled() and not hideNoTelemetry) then
    lcd.drawFilledRectangle((212-130)/2,18, 130, 30, SOLID)
    lcd.drawRectangle((212-130)/2,18, 130, 30, ERASE)
    lcd.drawText(60, 29, "no telemetry data", INVERS)
    return
  end
#else
  if (not telemetryEnabled() and not hideNoTelemetry) then
    lcd.drawFilledRectangle(12,18, 105, 30, SOLID)
    lcd.drawRectangle(12,18, 105, 30, ERASE)
    lcd.drawText(30, 29, "no telemetry", INVERS)
    return
  end
#endif --X9
end
#endif

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