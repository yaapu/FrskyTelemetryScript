#include "includes/yaapu_inc.lua"

-- SYNTH VSPEED SUPPORT
local vspd = 0
local synthVSpeedTime = 0
local prevHomeAlt = 0

local yawRibbonPoints = {}

yawRibbonPoints[0]="N"
yawRibbonPoints[1]=""
yawRibbonPoints[2]="NE"
yawRibbonPoints[3]=""
yawRibbonPoints[4]="E"
yawRibbonPoints[5]=""
yawRibbonPoints[6]="SE"
yawRibbonPoints[7]=""
yawRibbonPoints[8]="S"
yawRibbonPoints[9]=""
yawRibbonPoints[10]="SW"
yawRibbonPoints[11]=""
yawRibbonPoints[12]="W"
yawRibbonPoints[13]=""
yawRibbonPoints[14]="NW"
yawRibbonPoints[15]=""

local function drawHud(drawLib,conf,telemetry,status,battery,getMaxValue)
    -- compass ribbon centered +/- 90 on yaw
#ifdef X9
  local centerYaw = (telemetry.yaw+270)%360
#else
  local centerYaw = (telemetry.yaw+270+3)%360 -- +3 to center the ribbon on screen
#endif
  -- this is the first point left to be drawn on the compass ribbon
  local nextPoint = math.floor(centerYaw/22.5) * 22.5
  -- x coord of first ribbon letter
  local nextPointX = 2 + YAW_X_MIN + (nextPoint - centerYaw)/22.5 * YAW_STEPWIDTH

  local i = (nextPoint / 22.5) % 16
  for idx=1,12
  do
      local letterOffset = 0
      local lineOffset = 2
      if #yawRibbonPoints[i] > 1 then
        letterOffset = -2
        lineOffset = 3
      end
      if nextPointX >= YAW_X_MIN -3 and nextPointX < YAW_X_MAX then
        if #yawRibbonPoints[i] == 0 then
          lcd.drawLine(nextPointX + lineOffset, YAW_Y, nextPointX + lineOffset, YAW_Y + 2, SOLID, 0)
        else
          lcd.drawText(nextPointX + letterOffset,YAW_Y+1 ,yawRibbonPoints[i],SMLSIZE)
        end
      end
      i = (i + 1) % 16
      nextPointX = nextPointX + YAW_STEPWIDTH
  end
  -- home icon
  local homeOffset = 0 --YAW_WIDTH-14
  local angle = telemetry.homeAngle - telemetry.yaw
  if angle < 0 then
    angle = 360 + angle
  end
  if angle > 270 or angle < 90 then
    homeOffset = ((angle + 90) % 180)/180  * (YAW_WIDTH-12)
  elseif angle >= 90 and angle <= 180 then
    homeOffset = YAW_WIDTH-10--0
  end
  drawLib.drawHomeIcon(YAW_X_MIN + homeOffset,YAW_Y + 12)
  -- clean right and left
  lcd.drawFilledRectangle(HUD_X-2, YAW_Y, 5, 10, ERASE, 0)
  lcd.drawFilledRectangle(HUD_X+HUD_WIDTH-7, YAW_Y, 8, 10, ERASE, 0)
  -- HUD
  local r = -telemetry.roll
  local cx,cy,dx,dy,ccx,ccy
  local yPos = TOPBAR_Y + TOPBAR_HEIGHT + 8
  -----------------------
  -- artificial horizon
  -----------------------
  -- no roll ==> segments are vertical, offsets are multiples of R2
  if ( telemetry.roll == 0) then
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
  local rollX = LCD_W/2 - 1 - 2
  -- parallel lines above and below horizon line
  drawLib.drawLineWithClipping(rollX + dx - ccx,dy + HUD_X_MID + ccy,r,20,DOTTED,HUD_X,HUD_X + HUD_WIDTH,8,BOTTOMBAR_Y - 1)
  drawLib.drawLineWithClipping(rollX + dx - cx,dy + HUD_X_MID + cy,r,8,DOTTED,HUD_X,HUD_X + HUD_WIDTH,8,BOTTOMBAR_Y - 1)
  drawLib.drawLineWithClipping(rollX + dx + cx,dy + HUD_X_MID - cy,r,8,DOTTED,HUD_X,HUD_X + HUD_WIDTH,8,BOTTOMBAR_Y - 1)
  drawLib.drawLineWithClipping(rollX + dx + ccx,dy + HUD_X_MID - ccy,r,20,DOTTED,HUD_X,HUD_X + HUD_WIDTH,8,BOTTOMBAR_Y - 1)
  -----------------------
  -- dark color for "ground"
  -----------------------
  local minY = 8
  local minX = HUD_X + 1
  -- vario width is 6
  local maxX = HUD_X + HUD_WIDTH - 8
#ifdef X9
  local maxY = 54
  local ox = 106 + dx - 2
#else --X9
  local maxY = 55
  local ox = 64 + dx - 2
#endif --X7
  local oy = HUD_X_MID + dy
  local yy = 0
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
#else
  vspd = telemetry.vSpeed
#endif
  -------------------------------------
  -- vario indicator on right
  -------------------------------------
  lcd.drawLine(HUD_X + HUD_WIDTH - 6, 7, HUD_X + HUD_WIDTH - 6, yPos + 40, SOLID, 0)
  
  local varioMax = 10
  local varioSpeed = math.min(math.abs(0.1*vspd),10)
  local varioY = 0
  local arrowY = -1
  if vspd > 0 then
    varioY = HUD_X_MID - 4 - varioSpeed/varioMax*22
  else
    varioY = HUD_X_MID + 6
    arrowY = 1
  end
  lcd.drawFilledRectangle(HUD_X + HUD_WIDTH - 6, varioY, 6, varioSpeed/varioMax*22, FORCE, 0)
  for i=0,16
  do
    lcd.drawLine(HUD_X + HUD_WIDTH - 4, 9+i*3, HUD_X + HUD_WIDTH-2, 9+i*3, SOLID, ERASE)
    lcd.drawLine(HUD_X + HUD_WIDTH - 3, arrowY+9+i*3, HUD_X + HUD_WIDTH-3, arrowY+9+i*3, SOLID, ERASE)
  end
  -- hashmarks
  local offset = 0
  for i=0,5
  do
  -- left hashmarks
    offset = 48 - ((telemetry.hSpeed - i*8) % 46)/46 * 46
    lcd.drawLine(HUD_X+1, YAW_Y + offset, HUD_X + 2, YAW_Y + offset, SOLID, 0)
  -- right hashmarks
    offset = 48 - ((telemetry.homeAlt - i*8) % 46)/46 * 46
    lcd.drawLine(HUD_X + HUD_WIDTH - 9, YAW_Y + offset, HUD_X + HUD_WIDTH - 8, YAW_Y + offset, SOLID, 0)
  end
  -------------------------------------
  -- left and right indicators on HUD
  -------------------------------------
  -- lets erase to hide the artificial horizon lines
  -- black borders
  lcd.drawRectangle(HUD_X, HUD_X_MID - 5, LEFTWIDTH, 11, FORCE, 0)
  lcd.drawRectangle(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1, HUD_X_MID - 5, RIGHTWIDTH+1, 11, FORCE, 0)
  -- erase area
  lcd.drawFilledRectangle(HUD_X, HUD_X_MID - 4, LEFTWIDTH, 9, ERASE, 0)
  lcd.drawFilledRectangle(HUD_X + HUD_WIDTH - RIGHTWIDTH - 1, HUD_X_MID - 4, RIGHTWIDTH+2, 9, ERASE, 0)
  -- erase tips
  lcd.drawLine(HUD_X + LEFTWIDTH,HUD_X_MID - 3,HUD_X + LEFTWIDTH,HUD_X_MID + 3, SOLID, ERASE)
  lcd.drawLine(HUD_X + LEFTWIDTH+1,HUD_X_MID - 2,HUD_X + LEFTWIDTH+1,HUD_X_MID + 2, SOLID, ERASE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 2,HUD_X_MID - 3,HUD_X + HUD_WIDTH - RIGHTWIDTH - 2,HUD_X_MID + 3, SOLID, ERASE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID - 2,HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID + 2, SOLID, ERASE)
  -- left tip
  lcd.drawLine(HUD_X + LEFTWIDTH+2,HUD_X_MID - 2,HUD_X + LEFTWIDTH+2,HUD_X_MID + 2, SOLID, FORCE)
  lcd.drawLine(HUD_X + LEFTWIDTH-1,HUD_X_MID - 5,HUD_X + LEFTWIDTH+1,HUD_X_MID - 3, SOLID, FORCE)
  lcd.drawLine(HUD_X + LEFTWIDTH-1,HUD_X_MID + 5,HUD_X + LEFTWIDTH+1,HUD_X_MID + 3, SOLID, FORCE)
  -- right tip
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 4,HUD_X_MID - 2,HUD_X + HUD_WIDTH - RIGHTWIDTH - 4,HUD_X_MID + 2, SOLID, FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID - 3,HUD_X + HUD_WIDTH - RIGHTWIDTH - 1,HUD_X_MID - 5, SOLID, FORCE)
  lcd.drawLine(HUD_X + HUD_WIDTH - RIGHTWIDTH - 3,HUD_X_MID + 3,HUD_X + HUD_WIDTH - RIGHTWIDTH - 1,HUD_X_MID + 5, SOLID, FORCE)
    -- altitude
  local alt = getMaxValue(telemetry.homeAlt,MINMAX_ALT) * UNIT_ALT_SCALE -- homeAlt is meters*3.28 = feet

  if math.abs(alt) < 10 then
      lcd.drawNumber(HUD_X + HUD_WIDTH,HUD_X_MID - 3,alt * 10,PREC1+RIGHT)
  else
      lcd.drawNumber(HUD_X + HUD_WIDTH,HUD_X_MID - 3,alt,RIGHT)
  end
  -- hspeed
  local speed = getMaxValue(telemetry.hSpeed,MAX_HSPEED) * UNIT_HSPEED_SCALE
  if math.abs(speed) > 99 then
    lcd.drawNumber(HUD_X+1,HUD_X_MID - 3,speed*0.1,0)
  else
    lcd.drawNumber(HUD_X+1,HUD_X_MID - 3,speed,PREC1)
  end
  
  lcd.drawLine(LCD_W/2-9-3,HUD_X_MID,LCD_W/2-4-3,HUD_X_MID ,SOLID,0) -- -1 to compensate for H offset 
  lcd.drawLine(LCD_W/2-3-3,HUD_X_MID,LCD_W/2-3-3,HUD_X_MID+3 ,SOLID,0)
  
  lcd.drawLine(LCD_W/2+4-3,HUD_X_MID,LCD_W/2+9-3,HUD_X_MID ,SOLID,0)
  lcd.drawLine(LCD_W/2+3-3,HUD_X_MID,LCD_W/2+3-3,HUD_X_MID+3 ,SOLID,0)
  -- vspeed box (dm/s)
  local xx = math.abs(vspd*UNIT_VSPEED_SCALE) > 9999 and 4 or 3
  xx = xx + (vspd*UNIT_VSPEED_SCALE < 0 and 1 or 0)
  
  lcd.drawFilledRectangle((LCD_W)/2 - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, ERASE)
  
  if math.abs(vspd*UNIT_VSPEED_SCALE) > 99 then -- 
    lcd.drawNumber((LCD_W)/2 + (xx/2)*5, LCD_H - 15, vspd*0.1*UNIT_VSPEED_SCALE, HSPEED_FLAGS+RIGHT)
  else
    lcd.drawNumber((LCD_W)/2 + (xx/2)*5, LCD_H - 15, vspd*UNIT_VSPEED_SCALE, HSPEED_FLAGS+RIGHT+PREC1)
  end
  lcd.drawRectangle((LCD_W)/2 - (xx/2)*5 - 2, LCD_H - 17, xx*5+3, 10, FORCE+SOLID)
    
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(HUD_X + LEFTWIDTH + 4, HUD_X_MID - 4,6,true,false)
  end
  -- min/max arrows
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(HUD_X + HUD_WIDTH - 24, HUD_X_MID - 4,6,true,false)
  end
  -- arming status, show only if timer is not running, hide otherwise
  if telemetry.ekfFailsafe == 0 and telemetry.battFailsafe == 0 and status.timerRunning == 0 then
    if (telemetry.statusArmed == 1) then
      lcd.drawText(HUD_X + HUD_WIDTH/2 - 15, 20, " ARMED ", SMLSIZE+INVERS)
    else
      lcd.drawText(HUD_X + HUD_WIDTH/2 - 21, 20, " DISARMED ", SMLSIZE+INVERS+BLINK)
    end
  end
  -- yaw angle box
  xx = telemetry.yaw < 10 and 1 or ( telemetry.yaw < 100 and -2 or -5 )
  lcd.drawNumber(LCD_W/2 + xx - 8, YAW_Y-1, telemetry.yaw, MIDSIZE+INVERS)
end

#ifdef CUSTOM_BG_CALL
local function background(conf,telemetry,status,getMaxValue,checkAlarm)
end
#endif --CUSTOM_BG_CALL

return {
  drawHud=drawHud,
#ifdef CUSTOM_BG_CALL
  background=background,
#endif --CUSTOM_BG_CALL
  yawRibbonPoints=yawRibbonPoints
}