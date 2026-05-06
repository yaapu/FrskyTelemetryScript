    --[[
    // Auto Pilot Modes enumeration
    enum control_mode_t {
        STABILIZE =     0,  // manual airframe angle with manual throttle
        ACRO =          1,  // manual body-frame angular rate with manual throttle
        ALT_HOLD =      2,  // manual airframe angle with automatic throttle
        AUTO =          3,  // fully automatic waypoint control using mission commands
        GUIDED =        4,  // fully automatic fly to coordinate or fly at velocity/direction using GCS immediate commands
        LOITER =        5,  // automatic horizontal acceleration with automatic throttle
        RTL =           6,  // automatic return to launching point
        CIRCLE =        7,  // automatic circular flight with automatic throttle
        LAND =          9,  // automatic landing with horizontal position control
        DRIFT =        11,  // semi-automous position, yaw and throttle control
        SPORT =        13,  // manual earth-frame angular rate control with manual throttle
        FLIP =         14,  // automatically flip the vehicle on the roll axis
        AUTOTUNE =     15,  // automatically tune the vehicle's roll and pitch gains
        POSHOLD =      16,  // automatic position hold with manual override, with automatic throttle
        BRAKE =        17,  // full-brake using inertial/GPS system, no pilot input
        THROW =        18,  // throw to launch mode using inertial/GPS system, no pilot input
        AVOID_ADSB =   19,  // automatic avoidance of obstacles in the macro scale - e.g. full-sized aircraft
        GUIDED_NOGPS = 20,  // guided mode but only accepts attitude and altitude
        SMART_RTL =    21,  // SMART_RTL returns to home by retracing its steps
        FLOWHOLD  =    22,  // FLOWHOLD holds position with optical flow without rangefinder
        FOLLOW    =    23,  // follow attempts to follow another vehicle or ground station
        ZIGZAG    =    24,  // ZIGZAG mode is able to fly in a zigzag manner with predefined point A and point B
        SYSTEMID  =    25,  // System ID mode produces automated system identification signals in the controllers
        AUTOROTATE =   26,  // Autonomous autorotation
        AUTO_RTL =     27,  // Auto RTL, this is not a true mode, AUTO will report as this mode if entered to perform a DO_LAND_START Landing sequence
        TURTLE =       28,  // Flip over after crash
    };
  --]]
  local flightModes = {}

  -- copter flight modes
  flightModes[0]=""
  flightModes[1]="Stabilize"
  flightModes[2]="Acro"
  flightModes[3]="AltHold"
  flightModes[4]="Auto"
  flightModes[5]="Guided"
  flightModes[6]="Loiter"
  flightModes[7]="RTL"
  flightModes[8]="Circle"
  flightModes[9]=""
  flightModes[10]="Land"
  flightModes[11]=""
  flightModes[12]="Drift"
  flightModes[13]=""
  flightModes[14]="Sport"
  flightModes[15]="Flip"
  flightModes[16]="AutoTune"
  flightModes[17]="PosHold"
  flightModes[18]="Brake"
  flightModes[19]="Throw"
  flightModes[20]="AvoidADSB"
  flightModes[21]="GuidedNOGPS"
  flightModes[22]="SmartRTL"
  flightModes[23]="FlowHold"
  flightModes[24]="Follow"
  flightModes[25]="ZigZag"
  flightModes[26]="SystemID"
  flightModes[27]="Autorotate"
  flightModes[28]="AutoRTL"
  flightModes[29]="Turtle"

return {flightModes=flightModes}
