#include "includes/yaapu_inc.lua"
#include "includes/layout_2_inc.lua"

#define ALTASL_X 68
#define ALTASL_Y 31
#define ALTASL_XLABEL 8
#define ALTASL_YLABEL 20

#define HOMEDIST_X 153
#define HOMEDIST_Y 31
#define HOMEDIST_XLABEL 69
#define HOMEDIST_YLABEL 20
#define HOMEDIST_FLAGS MIDSIZE
#define HOMEDIST_ARROW_WIDTH 8

#define TOTDIST_X 152
#define TOTDIST_Y 54
#define TOTDIST_XLABEL 69
#define TOTDIST_YLABEL 54
#define TOTDIST_FLAGS SMLSIZE

#define THROTTLE_X 153
#define THROTTLE_Y 122
#define THROTTLE_YW 134
#define THROTTLE_FLAGS SMLSIZE
#define THROTTLE_FLAGSW MIDSIZE

#define WPN_X 57
#define WPN_Y 87
#define WPN_XLABEL 69
#define WPN_YLABEL 76
#define WPN_FLAGS MIDSIZE

#define WPB_X 67
#define WPB_Y 100
#define WPB_R 10

#define WPD_X 153
#define WPD_Y 87
#define WPD_XLABEL 153
#define WPD_YLABEL 76
#define WPD_FLAGS MIDSIZE

#define HSPEED_X 68
#define HSPEED_Y 134
#define HSPEED_XLABEL 69
#define HSPEED_YLABEL 122
#define HSPEED_XDIM 48
#define HSPEED_YDIM 33
#define HSPEED_FLAGS MIDSIZE
#define HSPEED_ARROW_WIDTH 10

local function drawPane(x,drawLib,conf,telemetry,status,alarms,battery,battId,gpsStatuses,utils)--,getMaxValue,getBitmap,drawBlinkBitmap,lcdBacklightOn)
  if conf.rangeFinderMax > 0 then
    local rng = telemetry.range
    rng = utils.getMaxValue(rng,MAX_RANGE)
    lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)     
    lcd.drawText(ALTASL_XLABEL, ALTASL_YLABEL, "Range("..UNIT_ALT_LABEL..")", SMLSIZE+CUSTOM_COLOR)
    if rng > conf.rangeFinderMax and status.showMinMaxValues == false then
      lcd.setColor(CUSTOM_COLOR,COLOR_RED)       
      lcd.drawFilledRectangle(ALTASL_X-65, ALTASL_Y+4,65,21,CUSTOM_COLOR)
    end
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)     
    lcd.drawText(ALTASL_X, ALTASL_Y, string.format("%.1f",rng*0.01*UNIT_ALT_SCALE), MIDSIZE+RIGHT+CUSTOM_COLOR)
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
    lcd.drawText(ALTASL_XLABEL, ALTASL_YLABEL, "AltAsl("..UNIT_ALT_LABEL..")", SMLSIZE+CUSTOM_COLOR)
    local stralt = string.format("%d",alt*UNIT_ALT_SCALE)
    lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)     
    lcd.drawText(ALTASL_X, ALTASL_Y, stralt, MIDSIZE+flags+RIGHT+CUSTOM_COLOR)
  end
  -- LABELS
  lcd.setColor(CUSTOM_COLOR,COLOR_LABEL)
  lcd.drawText(HOMEDIST_X, HOMEDIST_YLABEL, "Dist("..UNIT_DIST_LABEL..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(HSPEED_XLABEL, HSPEED_YLABEL, "AS("..UNIT_HSPEED_LABEL..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(WPN_XLABEL, WPN_YLABEL, "WPN", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(WPD_XLABEL, WPD_YLABEL, "WPD("..UNIT_DIST_LABEL..")", SMLSIZE+RIGHT+CUSTOM_COLOR)
  lcd.drawText(THROTTLE_X, THROTTLE_Y, "THR(%)", THROTTLE_FLAGS+RIGHT+CUSTOM_COLOR)
  -- VALUES
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)
  -- home distance
  drawLib.drawHomeIcon(HOMEDIST_XLABEL + 15, HOMEDIST_YLABEL + 2,utils)
  flags = 0
  if telemetry.homeAngle == -1 then
    flags = BLINK
  end
  local dist = utils.getMaxValue(telemetry.homeDist,MAX_DIST)
  if status.showMinMaxValues == true then
    flags = 0
  end
  local strdist = string.format("%d",dist*UNIT_DIST_SCALE)
  --lcd.setColor(CUSTOM_COLOR,COLOR_YELLOW)   
  lcd.drawText(HOMEDIST_X, HOMEDIST_Y, strdist, HOMEDIST_FLAGS+flags+RIGHT+CUSTOM_COLOR)
  -- total distance
  strdist = string.format("%.02f%s", telemetry.totalDist*UNIT_DIST_LONG_SCALE,UNIT_DIST_LONG_LABEL)
  lcd.setColor(CUSTOM_COLOR,COLOR_TEXT)   
  lcd.drawText(TOTDIST_X, TOTDIST_Y, strdist, TOTDIST_FLAGS+RIGHT+CUSTOM_COLOR)
  -- airspeed
  lcd.drawNumber(HSPEED_X,HSPEED_Y,telemetry.airspeed * UNIT_HSPEED_SCALE,HSPEED_FLAGS+RIGHT+PREC1+CUSTOM_COLOR)
  -- wp number
  lcd.drawNumber(WPN_X, WPN_Y, telemetry.wpNumber,WPN_FLAGS+RIGHT+CUSTOM_COLOR)
  -- wp distance
  lcd.drawNumber(WPD_X, WPD_Y, telemetry.wpDistance * UNIT_DIST_SCALE,WPD_FLAGS+RIGHT+CUSTOM_COLOR)
  -- throttle %
  lcd.drawNumber(THROTTLE_X,THROTTLE_YW,telemetry.throttle,THROTTLE_FLAGSW+RIGHT+CUSTOM_COLOR)
  -- LINES
  lcd.setColor(CUSTOM_COLOR,COLOR_LINES) --yellow
  -- wp bearing
  drawLib.drawRArrow(WPB_X,WPB_Y,WPB_R,telemetry.wpBearing*45,CUSTOM_COLOR)
  --
  if status.showMinMaxValues == true then
    drawLib.drawVArrow(ALTASL_X-70, ALTASL_Y+4,true,false,utils)
    drawLib.drawVArrow(HOMEDIST_X-78, HOMEDIST_Y+4 ,true,false,utils)
  end
end

local function background(myWidget,conf,telemetry,status,utils)
  -- RC CHANNELS
  --[[
  if conf.enableRCChannels == true then
    for i=1,#telemetry.rcchannels do
      setTelemetryValue(Thr_ID, Thr_SUBID, Thr_INSTANCE + i, telemetry.rcchannels[i], 13 , Thr_PRECISION , "RC"..i)
    end
  end
  --]]
  
  -- VFR
  setTelemetryValue(ASpd_ID, ASpd_SUBID, ASpd_INSTANCE, telemetry.airspeed*0.1, 4 , ASpd_PRECISION , ASpd_NAME)
  setTelemetryValue(BAlt_ID, BAlt_SUBID, BAlt_INSTANCE, telemetry.baroAlt*10, 9 , BAlt_PRECISION , BAlt_NAME)
  setTelemetryValue(Thr_ID, Thr_SUBID, Thr_INSTANCE, telemetry.throttle, 13 , Thr_PRECISION , Thr_NAME)
  
  -- WP
  setTelemetryValue(WPN_ID, WPN_SUBID, WPN_INSTANCE, telemetry.wpNumber, 0 , WPN_PRECISION , WPN_NAME)
  setTelemetryValue(WPD_ID, WPD_SUBID, WPD_INSTANCE, telemetry.wpDistance, 9 , WPD_PRECISION , WPD_NAME)
  
  -- crosstrack error and wp bearing not exposed as OpenTX variables by default
  --[[
  setTelemetryValue(WPX_ID, WPX_SUBID, WPX_INSTANCE, telemetry.wpXTError, 9 , WPX_PRECISION , WPX_NAME)
  setTelemetryValue(WPB_ID, WPB_SUBID, WPB_INSTANCE, telemetry.wpBearing, 20 , WPB_PRECISION , WPB_NAME)
  --]]
end

return {drawPane=drawPane,background=background}