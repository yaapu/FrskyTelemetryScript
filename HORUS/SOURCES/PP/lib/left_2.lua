#include "includes/yaapu_inc.lua"
#include "includes/layout_2_inc.lua"

#define ALTASL_X 73
#define ALTASL_Y 33+8
#define ALTASL_XLABEL 73
#define ALTASL_YLABEL 21+8

#define HOMEDIST_X 155
#define HOMEDIST_Y 41
#define HOMEDIST_XLABEL 155
#define HOMEDIST_YLABEL 29
#define HOMEDIST_FLAGS MIDSIZE
#define HOMEDIST_ARROW_WIDTH 8

#define TOTDIST_X 155
#define TOTDIST_Y 107
#define TOTDIST_XLABEL 155
#define TOTDIST_YLABEL 95
#define TOTDIST_FLAGS MIDSIZE

#define HSPEED_X 73
#define HSPEED_Y 107
#define HSPEED_XLABEL 73
#define HSPEED_YLABEL 95
#define HSPEED_XDIM 48
#define HSPEED_YDIM 33
#define HSPEED_FLAGS MIDSIZE
#define HSPEED_ARROW_WIDTH 10

#define EFF_X 155
#define EFF_Y 150
#define EFF_YW 165
#define EFF_FLAGS SMLSIZE
#define EFF_FLAGSW MIDSIZE

local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)   
  if conf.rangeMax > 0 then
    flags = 0
    local rng = telemetry.range
    if rng > conf.rangeMax then
      flags = BLINK+INVERS
    end
    rng = utils.getMaxValue(rng,MAX_RANGE)
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)   
    lcd.drawText(ALTASL_XLABEL, ALTASL_YLABEL, "Rng("..UNIT_ALT_LABEL..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)       
    lcd.drawText(ALTASL_X, ALTASL_Y, string.format("%.1f",rng*0.01*UNIT_ALT_SCALE), MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  else
    flags = BLINK
    -- always display gps altitude even without 3d lock
    local alt = telemetry.gpsAlt/10
    if telemetry.gpsStatus  > 2 then
      flags = 0
      -- update max only with 3d or better lock
      alt = utils.getMaxValue(alt,MAX_GPSALT)
    end
    if status.showMinMaxValues == true then
      flags = 0
    end
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)       
    lcd.drawText(ALTASL_XLABEL, ALTASL_YLABEL, "AltAsl("..UNIT_ALT_LABEL..")", SMLSIZE+CUSTOM_COLOR+RIGHT)
    local stralt = string.format("%d",alt*UNIT_ALT_SCALE)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)       
    lcd.drawText(ALTASL_X, ALTASL_Y, stralt, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  end
  -- LABELS
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)       
  drawLib.drawHomeIcon(HOMEDIST_XLABEL - 68, HOMEDIST_YLABEL,utils)
  lcd.drawText(HOMEDIST_XLABEL, HOMEDIST_YLABEL, "Dist("..UNIT_DIST_LABEL..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(HSPEED_XLABEL, HSPEED_YLABEL, "Spd("..UNIT_HSPEED_LABEL..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(TOTDIST_XLABEL, TOTDIST_YLABEL, "Travel("..UNIT_DIST_LONG_LABEL..")", EFF_FLAGS+RIGHT+CUSTOM_COLOR)
  -- VALUES
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)       
  -- home distance
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,MAX_DIST)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist*UNIT_DIST_SCALE)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  --lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW) --yellow  
  lcd.drawText(HOMEDIST_X, HOMEDIST_Y, strdist, HOMEDIST_FLAGS+flags+RIGHT+CUSTOM_COLOR)
  -- total distance
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)  
  lcd.drawNumber(TOTDIST_X, TOTDIST_Y, telemetry.totalDist*UNIT_DIST_LONG_SCALE*100, PREC2+TOTDIST_FLAGS+RIGHT+CUSTOM_COLOR)
  -- hspeed
  local speed = utils.getMaxValue(telemetry.hSpeed,MAX_HSPEED)
  
  lcd.drawNumber(HSPEED_X,HSPEED_Y,speed * UNIT_HSPEED_SCALE,HSPEED_FLAGS+RIGHT+PREC1+CUSTOM_COLOR)
  
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(4, ALTASL_Y + 4,true,false,utils)
    drawLib.drawVArrow(HOMEDIST_X-70, HOMEDIST_Y + 4 ,true,false,utils)
    drawLib.drawVArrow(4,HSPEED_Y+4,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
end

return {drawPane=drawPane,background=background}