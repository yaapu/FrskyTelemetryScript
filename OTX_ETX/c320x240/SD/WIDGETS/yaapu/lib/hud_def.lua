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

local drawNumber = lcd.drawNumber
local drawText = lcd.drawText
local setColor = lcd.setColor
local drawFilledRectangle = lcd.drawFilledRectangle
local drawRectangle = lcd.drawRectangle
local m_floor = math.floor
local m_abs = math.abs
local m_min = math.min

local panel = {}
local conf, telemetry, status, utils, libs

function panel.init(p_status, p_telemetry, p_conf, p_utils, p_libs)
    status, telemetry, conf, utils, libs = p_status, p_telemetry, p_conf, p_utils, p_libs
end

function panel.draw(widget)

    local colText = utils.colors.white
    local colGreen = utils.colors.green

    libs.drawLib.drawArtificialHorizon(80, 16, 160, 114, "hud_bg", nil, utils.colors.hudTerrain, 5, 12.3, 1.85)

    -------------
    -- Hashmarks (Tapes)
    -------------
    local startY = 16 + 1
    local endY = 16 + 114 - 10
    local step = 12
    local stepRatio = 0.2 * step
    local textOffset = step * 0.77
    -- hSpeed Tape
    local valHS = telemetry.hSpeed * conf.horSpeedMultiplier * 0.1
    local roundHSpeed = m_floor((valHS / 5) + 0.5) * 5
    local offsetHS = m_floor((valHS - roundHSpeed) * stepRatio)
    
    setColor(CUSTOM_COLOR, utils.colors.hudDash)
    for i = 0, 8 do -- Ridotto il range del loop per performance (40 unità totali)
        local j = roundHSpeed + 20 - (i * 5)
        local yy = startY + (i * step) + offsetHS - textOffset
        if yy >= startY and yy < endY then
            drawNumber(121, yy, j, SMLSIZE + CUSTOM_COLOR + RIGHT)
        end
    end

    -- Altitude Tape
    local valAlt = telemetry.homeAlt * unitScale
    local roundAlt = m_floor((valAlt / 5) + 0.5) * 5
    local offsetAlt = m_floor((valAlt - roundAlt) * stepRatio)
    
    for i = 0, 8 do
        local j = roundAlt + 20 - (i * 5)
        local yy = startY + (i * step) + offsetAlt - textOffset
        if yy >= startY and yy < endY then
            drawNumber(198, yy, j, SMLSIZE + CUSTOM_COLOR)
        end
    end

    setColor(CUSTOM_COLOR, WHITE)
    lcd.drawBitmap(utils.getBitmap("hud"), 80, 16)

    -------------------------------------
    -- Altitude Indicators
    -------------------------------------
    local homeAlt = utils.getMaxValue(telemetry.homeAlt, 11) * unitScale
    local alt = (status.terrainEnabled == 1) and (telemetry.heightAboveTerrain * unitScale) or homeAlt

    if status.terrainEnabled == 1 then
        setColor(CUSTOM_COLOR, RED)
        drawRectangle(196, 86, 44 - 11, 17, CUSTOM_COLOR)
        setColor(CUSTOM_COLOR, BLACK)
        drawFilledRectangle(196, 86, 44 - 11, 17, CUSTOM_COLOR + SOLID)
    end

    local absAlt = m_abs(alt)
    local alt_val = (absAlt >= 10) and alt or alt * 10
    local alt_flags = (absAlt >= 10) and DBLSIZE or (DBLSIZE + PREC1)
    if absAlt > 999 or alt < -99 then alt_flags = MIDSIZE end
    
    setColor(CUSTOM_COLOR, colGreen)
    drawNumber(196, 56, alt_val, alt_flags + CUSTOM_COLOR)

    if status.terrainEnabled == 1 then
        setColor(CUSTOM_COLOR, colText)
        local hAlt_val = (m_abs(homeAlt) < 10) and homeAlt * 10 or homeAlt
        local hAlt_flags = (m_abs(homeAlt) < 10) and (MIDSIZE + PREC1) or MIDSIZE
        drawNumber(196, 81, hAlt_val, hAlt_flags + CUSTOM_COLOR)
    end

    -------------------------------------
    -- Speed Indicators
    -------------------------------------
    local hSpeed = utils.getMaxValue(telemetry.hSpeed, 14) * 0.1 * conf.horSpeedMultiplier
    -- default is ground speed
    local speed = hSpeed
    if status.airspeedEnabled == 1 then
        -- if airspeed is availavle show airspeeed instead
        speed = telemetry.airspeed * 0.1 * conf.horSpeedMultiplier
    end
    local absSpd = m_abs(speed)
    local spd_val = (absSpd >= 10) and speed or speed * 10
    local spd_flags = (absSpd >= 10) and DBLSIZE or (DBLSIZE + PREC1)
    
    setColor(CUSTOM_COLOR, colGreen)
    drawNumber(121 + 4, 56, spd_val, spd_flags + CUSTOM_COLOR + RIGHT)
    
    if status.airspeedEnabled == 1 then
        -- show ground speed as well
        setColor(CUSTOM_COLOR, lcd.RGB(10, 20, 30))
        drawFilledRectangle(80, 86, 44, 17, CUSTOM_COLOR + SOLID)
        setColor(CUSTOM_COLOR, colGreen)
        drawText(80, 60, "A", CUSTOM_COLOR + SMLSIZE)
        setColor(CUSTOM_COLOR, WHITE)
        drawText(80, 81, "G", CUSTOM_COLOR + SMLSIZE)
        local absSpd = m_abs(hSpeed)
        local spd_val = (absSpd >= 10) and hSpeed or hSpeed * 10
        local spd_flags = (absSpd >= 10) and MIDSIZE or (MIDSIZE + PREC1)
        drawNumber(121 + 4, 81, spd_val, spd_flags + CUSTOM_COLOR + RIGHT)
    end

    -------------------------------------
    -- Wind Data
    -------------------------------------
    if conf.enableWIND then
        setColor(CUSTOM_COLOR, BLACK)
        drawFilledRectangle(80, 113, 44, 19, CUSTOM_COLOR + SOLID)
        setColor(CUSTOM_COLOR, colText)
        drawText(80 + 2, 113 + 1, "W", CUSTOM_COLOR + SMLSIZE)
        drawNumber(121 + 4, 109, telemetry.trueWindSpeed * conf.horSpeedMultiplier, PREC1 + CUSTOM_COLOR + MIDSIZE + RIGHT)
    end

    -------------------------------------
    -- Min/Max & VSpeed
    -------------------------------------
    if status.showMinMaxValues then
        libs.drawLib.drawVArrow(112, 64, true, false)
        libs.drawLib.drawVArrow(201, 64, true, false)
    end

    local vSpeedScaled = utils.getMaxValue(telemetry.vSpeed, 13) * 0.1 * conf.vertSpeedMultiplier
    local absVS = m_abs(vSpeedScaled)
    local vSpd_val = (absVS * 10 > 99) and vSpeedScaled or (vSpeedScaled * 10)
    local vSpd_flags = (absVS * 10 > 99) and MIDSIZE or (MIDSIZE + PREC1)
    
    setColor(CUSTOM_COLOR, colText)
    drawNumber(160, 109, vSpd_val, vSpd_flags + CUSTOM_COLOR + CENTER)

    -- Compass Ribbon
    libs.drawLib.drawCompassRibbon(16, widget, 160, 80, 240, 25, true, 0, utils.colors.compassRibbon)
    
    -------------------------------------
    -- Vario Bar
    -------------------------------------
    local varioSpeed = m_min(m_abs(0.1 * telemetry.vSpeed), 5)
    local varioH = (varioSpeed / 5) * (114 * 0.38)
    if telemetry.vSpeed > 0 then
        setColor(CUSTOM_COLOR, utils.colors.darkyellow)
        drawFilledRectangle(232, 16 + (114 * 0.38) - varioH, 8, varioH, CUSTOM_COLOR)
    else
        setColor(CUSTOM_COLOR, utils.colors.red)
        --drawFilledRectangle(232, 86, (320 > 500 and 18 or 11), varioH, CUSTOM_COLOR)
        drawFilledRectangle(232, 86, 8, varioH, CUSTOM_COLOR)
    end
    
    -------------------------------------
    -- Pitch & Roll Numbers
    -------------------------------------
    setColor(CUSTOM_COLOR, utils.colors.hudFgColor)
    drawNumber(160 + (m_abs(telemetry.pitch) > 99 and 6 or 0), 79, telemetry.pitch, CUSTOM_COLOR + CENTER)
    drawNumber(144, 65, telemetry.roll, CUSTOM_COLOR + RIGHT)

    if conf.enableWIND then
        local windAngle = telemetry.trueWindAngle - telemetry.yaw
        libs.drawLib.drawWindArrow(320/2, 16 + (114*0.52), 30, 46, 46, windAngle, 1.5, CUSTOM_COLOR)
        libs.drawLib.drawWindArrow(320/2, 16 + (114*0.52), 35, 46, 46, windAngle, 1.5, CUSTOM_COLOR)        
    end

end

function panel.background(widget) end

return panel
