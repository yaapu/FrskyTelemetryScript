--[[
enum FlightMode {
    MANUAL        = 0,
    CIRCLE        = 1,
    STABILIZE     = 2,
    TRAINING      = 3,
    ACRO          = 4,
    FLY_BY_WIRE_A = 5,
    FLY_BY_WIRE_B = 6,
    CRUISE        = 7,
    AUTOTUNE      = 8,
    AUTO          = 10,
    RTL           = 11,
    LOITER        = 12,
    TAKEOFF       = 13,
    AVOID_ADSB    = 14,
    GUIDED        = 15,
    INITIALISING  = 16,
    QSTABILIZE    = 17,
    QHOVER        = 18,
    QLOITER       = 19,
    QLAND         = 20,
    QRTL          = 21,
    QAUTOTUNE	    = 22,
    QACRO         = 23,
    THERMAL       = 24,
};
--]]

local flightModes = {}
-- plane flight modes
flightModes[0]=""
flightModes[1]="Manual"
flightModes[2]="Circle"
flightModes[3]="Stabilize"
flightModes[4]="Training"
flightModes[5]="Acro"
flightModes[6]="FlyByWireA"
flightModes[7]="FlyByWireB"
flightModes[8]="Cruise"
flightModes[9]="Autotune"
flightModes[10]=""
flightModes[11]="Auto"
flightModes[12]="RTL"
flightModes[13]="Loiter"
flightModes[14]="Takeoff"
flightModes[15]="AvoidADSB"
flightModes[16]="Guided"
flightModes[17]="Initializing"
flightModes[18]="QStabilize"
flightModes[19]="QHover"
flightModes[20]="QLoiter"
flightModes[21]="Qland"
flightModes[22]="QRTL"
flightModes[23]="QAutotune"
flightModes[24]="QAcro"
flightModes[25]="Thermal"
--
return {flightModes=flightModes}

