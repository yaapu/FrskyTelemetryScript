#include "includes/yaapu_inc.lua"

#ifdef X9

#define GPS_X 0
#define GPS_Y 6
#define GPS_BORDER 0

#define ALTASL_X 60
#define ALTASL_Y 31
#define ALTASL_XLABEL 2
#define ALTASL_YLABEL 30
#define ALTASL_FLAGS RIGHT+SMLSIZE

#define WPN_X 0
#define WPN_Y 21

#define WPB_X 27
#define WPB_Y 25
#define WPB_R 5

#define WPD_X 60
#define WPD_Y 21

#define HOMEDIST_X 60
#define HOMEDIST_Y 37
#define HOMEDIST_XLABEL 0
#define HOMEDIST_YLABEL 41
#define HOMEDIST_FLAGS RIGHT+MIDSIZE
#define HOMEDIST_ARROW_WIDTH 8

#define TOTDIST_X 60
#define TOTDIST_Y 49
#define TOTDIST_XLABEL 0
#define TOTDIST_YLABEL 49
#define TOTDIST_FLAGS RIGHT+SMLSIZE
#define TOTDIST_ARROW_WIDTH 8

#define THROTTLE_X 0
#define THROTTLE_Y 49

#else

#define GPS_X 1
#define GPS_Y 6
#define GPS_BORDER 0

#define ALTASL_X 31
#define ALTASL_Y 43
#define ALTASL_XLABEL 1
#define ALTASL_YLABEL 43
#define ALTASL_FLAGS SMLSIZE

#define HOMEDIST_X 31
#define HOMEDIST_Y 50
#define HOMEDIST_XLABEL 1
#define HOMEDIST_YLABEL 52
#define HOMEDIST_FLAGS SMLSIZE+RIGHT
#define HOMEDIST_ARROW_WIDTH 7

#define WPB_X 5
#define WPB_Y 32
#define WPB_R 5

#define WPN_X 31
#define WPN_Y 29

#define WPD_X 31
#define WPD_Y 36


#endif

#ifdef X9
local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- gps status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  local strNumSats = ""
  local flags = BLINK
  local mult = 1
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(x+GPS_X,GPS_Y + 2, strStatus, SMLSIZE)
    if telemetry.numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",telemetry.numSats)
    end
    lcd.drawText(x+GPS_X + 35, GPS_Y+1, strNumSats, MIDSIZE+RIGHT)
    lcd.drawText(x+GPS_X + 37, GPS_Y + 2 , "H", SMLSIZE)
    lcd.drawNumber(x+GPS_X + 60, GPS_Y+1, telemetry.gpsHdopC*mult , MIDSIZE+flags+RIGHT)
    lcd.drawLine(x+GPS_X + 35,GPS_Y+1,x+GPS_X+35,GPS_Y + 12,SOLID,FORCE)
  else
    lcd.drawText(x+GPS_X + 10, GPS_Y+1, strStatus, MIDSIZE+INVERS+BLINK)
  end  
  lcd.drawLine(x+GPS_X ,GPS_Y + 13,x+GPS_X+60,GPS_Y + 13,SOLID,FORCE)
  if status.showMinMaxValues == true then
    flags = 0
  end
  if conf.rangeFinderMax > 0 then
    -- rng finder
    flags = 0
    local rng = telemetry.range
    -- rng is centimeters, RANGE_MAX is feet
    if rng > conf.rangeFinderMax then
      flags = BLINK+INVERS
    end
    rng = getMaxValue(rng,MAX_RANGE)
    lcd.drawText(x+ALTASL_XLABEL + 4, ALTASL_YLABEL, "Rng", SMLSIZE)
    lcd.drawText(x+ALTASL_X, ALTASL_Y , UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), ALTASL_Y-1 , rng*0.01*UNIT_ALT_SCALE*100, PREC2+ALTASL_FLAGS+flags)
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10 -- meters
    flags = BLINK
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,MAX_GPSALT)
    end
    lcd.drawText(x+ALTASL_XLABEL + 4, ALTASL_YLABEL, "Asl", SMLSIZE)
    lcd.drawText(x+ALTASL_X, ALTASL_Y, UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), ALTASL_Y-1 ,alt*UNIT_ALT_SCALE, ALTASL_FLAGS+flags)
  end
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,MAX_DIST)
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- home distance
  lcd.drawText(x+HOMEDIST_X, HOMEDIST_Y+5, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), HOMEDIST_Y, dist*UNIT_DIST_SCALE, HOMEDIST_FLAGS+flags)
  -- waypoints
  lcd.drawNumber(x+WPN_X, WPN_Y, telemetry.wpNumber, SMLSIZE)
  drawLib.drawRArrow(lcd.getLastRightPos()+4,WPB_Y,WPB_R,telemetry.wpBearing*45,FORCE)
  lcd.drawText(x+WPD_X, WPD_Y+1, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), WPD_Y, telemetry.wpDistance*UNIT_DIST_SCALE, RIGHT)  
  -- total distance
  lcd.drawText(x+TOTDIST_X, TOTDIST_Y, UNIT_DIST_LONG_LABEL, RIGHT+SMLSIZE)
  lcd.drawNumber(lcd.getLastLeftPos(), TOTDIST_Y, telemetry.totalDist*UNIT_DIST_LONG_SCALE*10, RIGHT+SMLSIZE+PREC1)
  -- throttle
  lcd.drawNumber(x+THROTTLE_X, THROTTLE_Y, telemetry.throttle,SMLSIZE)
  lcd.drawText(lcd.getLastRightPos(), THROTTLE_Y, "%", SMLSIZE)
  -- minmax
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+HOMEDIST_XLABEL + 2, HOMEDIST_YLABEL-2,6,true,false)
    drawLib.drawVArrow(x+ALTASL_XLABEL,ALTASL_YLABEL - 1,6,true,false)
  else
    drawLib.drawVArrow(x+ALTASL_XLABEL,ALTASL_YLABEL - 1,7,true,true)
    drawLib.drawHomeIcon(x+HOMEDIST_XLABEL + 1,HOMEDIST_YLABEL,7)
  end
  -- airspeed
  local speed = telemetry.airspeed*UNIT_HSPEED_SCALE
  if math.abs(speed) > 99 then
    lcd.drawNumber(HUD_X+6,HUD_X_MID + 10,speed*0.1,SMLSIZE)
  else
    lcd.drawNumber(HUD_X+6,HUD_X_MID + 10,speed,SMLSIZE+PREC1)
  end  
end
#endif --X9

#ifdef X7
---------------------
-- Single long function much more memory efficient than many little functions
---------------------
local function drawPane(x,drawLib,conf,telemetry,status,battery,battId,getMaxValue,gpsStatuses)
  -- GPS status
  local strStatus = gpsStatuses[telemetry.gpsStatus]
  flags = BLINK+PREC1
  local mult = 1
  lcd.drawLine(x,GPS_Y + 20,GPS_X+30,GPS_Y + 20,SOLID,FORCE)
  if telemetry.gpsStatus  > 2 then
    if telemetry.homeAngle ~= -1 then
      flags = PREC1
    end
    if telemetry.gpsHdopC > 99 then
      flags = 0
      mult=0.1
    end
    lcd.drawText(x+GPS_X, GPS_Y+13, strStatus, SMLSIZE)
    local strNumSats
    if telemetry.numSats >= 15 then
      strNumSats = string.format("%d+",15)
    else
      strNumSats = string.format("%d",telemetry.numSats)
    end
    lcd.drawText(x+GPS_X + 29, GPS_Y + 13, strNumSats, SMLSIZE+RIGHT)
    lcd.drawText(x+GPS_X, GPS_Y + 2 , "Hd", SMLSIZE)
    lcd.drawNumber(x+GPS_X + 29, GPS_Y+1, telemetry.gpsHdopC*mult ,MIDSIZE+flags+RIGHT)
    
  else
    lcd.drawText(x+GPS_X + 8, GPS_Y+3, "No", SMLSIZE+INVERS+BLINK)
    lcd.drawText(x+GPS_X + 5, GPS_Y+12, strStatus, SMLSIZE+INVERS+BLINK)
  end
  -- alt asl/rng
  if status.showMinMaxValues == true then
    flags = 0
  end
  -- varrow is shared
    flags = 0
  if conf.rangeFinderMax > 0 then
    -- rng finder
    local rng = telemetry.range
    if rng > conf.rangeFinderMax then
      flags = BLINK+INVERS
    end
      -- update max only with 3d or better lock
    rng = getMaxValue(rng,MAX_RANGE)
    lcd.drawText(x+ALTASL_X, ALTASL_Y+1 , UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    
    if rng*UNIT_ALT_SCALE*0.01 > 10 then
      lcd.drawNumber(lcd.getLastLeftPos(), ALTASL_Y, rng*UNIT_ALT_SCALE*0.1, flags+RIGHT+ALTASL_FLAGS+PREC1)
    else
      lcd.drawNumber(lcd.getLastLeftPos(), ALTASL_Y, rng*UNIT_ALT_SCALE, flags+RIGHT+ALTASL_FLAGS+PREC2)
    end
    
    if status.showMinMaxValues == true then
      drawLib.drawVArrow(x+ALTASL_XLABEL, ALTASL_YLABEL,5,true,false)
    else
      lcd.drawText(x+ALTASL_XLABEL, ALTASL_YLABEL, "R", SMLSIZE)
    end
  else
    -- alt asl, always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    flags = BLINK
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = getMaxValue(alt,MAX_GPSALT)
    end
    lcd.drawText(x+ALTASL_X, ALTASL_Y,UNIT_ALT_LABEL, SMLSIZE+RIGHT)
    lcd.drawNumber(lcd.getLastLeftPos(), ALTASL_Y, alt*UNIT_ALT_SCALE, flags+RIGHT+ALTASL_FLAGS)
    
    if status.showMinMaxValues == true then
      drawLib.drawVArrow(x+ALTASL_XLABEL+1, ALTASL_YLABEL + 1,5,true,false)
    else
      drawLib.drawVArrow(x+ALTASL_XLABEL+1,ALTASL_YLABEL,5,true,true)
    end
  end
  -- home dist
  local flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = getMaxValue(telemetry.homeDist,MAX_DIST)
  if status.showMinMaxValues == true then
    flags = 0
  end
  lcd.drawText(x+HOMEDIST_X, HOMEDIST_Y, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), HOMEDIST_Y, dist*UNIT_DIST_SCALE,HOMEDIST_FLAGS+flags)
  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(x+HOMEDIST_XLABEL+1, HOMEDIST_YLABEL-2,5,true,false)
  else
    drawLib.drawHomeIcon(x+HOMEDIST_XLABEL, HOMEDIST_YLABEL)
  end
  -- WP
  drawLib.drawRArrow(x+WPB_X,WPB_Y,WPB_R,telemetry.wpBearing*45,FORCE)
  lcd.drawNumber(x+WPN_X, WPN_Y, telemetry.wpNumber, SMLSIZE+RIGHT)
  
  lcd.drawText(WPD_X, WPD_Y, UNIT_DIST_LABEL,SMLSIZE+RIGHT)
  lcd.drawNumber(lcd.getLastLeftPos(), WPD_Y, telemetry.wpDistance*UNIT_DIST_SCALE, SMLSIZE+RIGHT)  
  -- airspeed
  local speed = telemetry.airspeed*UNIT_HSPEED_SCALE
  if math.abs(speed) > 99 then
    lcd.drawNumber(HUD_X+5,HUD_X_MID + 7,speed*0.1,SMLSIZE)
  else
    lcd.drawNumber(HUD_X+5,HUD_X_MID + 7,speed,SMLSIZE+PREC1)
  end 
end
#endif --X7


#ifdef CUSTOM_BG_CALL
local function background(conf,telemetry,status,getMaxValue,checkAlarm)
end
#endif

return {
  drawPane=drawPane,
#ifdef CUSTOM_BG_CALL
  background=background
#endif
}