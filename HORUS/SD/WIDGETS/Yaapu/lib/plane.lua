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
--[[
flightModes["MANU"]=1
flightModes["CIRC"]=2
flightModes["STAB"]=3
flightModes["TRAN"]=4
flightModes["ACRO"]=5
flightModes["FBWA"]=6
flightModes["FBWB"]=7
flightModes["CRUS"]=8
flightModes["ATUN"]=9
flightModes["AUTO"]=11
flightModes["RTL"]=12
flightModes["LOIT"]=13
flightModes["TKOF"]=14
flightModes["AVOI"]=15
flightModes["GUID"]=16
flightModes["INIT"]=17
flightModes["QSTB"]=18
flightModes["QHOV"]=19
flightModes["QLOT"]=20
flightModes["QLND"]=21
flightModes["QRTL"]=22
flightModes["QATN"]=23
flightModes["QACR"]=24
flightModes["THML"]=25

-- plane flight modes
flightModes[0]={"",""}
flightModes[1]={"Manual","MANU"}
flightModes[2]={"Circle","CIRC"}
flightModes[3]={"Stabilize","STAB"}
flightModes[4]={"Training","TRAN"}
flightModes[5]={"Acro","ACRO"}
flightModes[6]={"FlyByWireA","FBWA"}
flightModes[7]={"FlyByWireB","FBWB"}
flightModes[8]={"Cruise","CRUS"}
flightModes[9]={"Autotune","ATUN"}
flightModes[10]={"",""}
flightModes[11]={"Auto","AUTO"}
flightModes[12]={"RTL","RTL"}
flightModes[13]={"Loiter","LOIT"}
flightModes[14]={"Takeoff","TKOF"}
flightModes[15]={"AvoidADSB","AVOI"}
flightModes[16]={"Guided","GUID"}
flightModes[17]={"Initializing","INIT"}
flightModes[18]={"QStabilize","SSTB"}
flightModes[19]={"QHover","QHOV"}
flightModes[20]={"QLoiter","QLOT"}
flightModes[21]={"Qland","QLND"}
flightModes[22]={"QRTL","QRTL"}
flightModes[23]={"QAutotune","QATN"}
flightModes[24]={"QAcro","QACR"}
flightModes[25]={"Thermal","THML"}
--]]

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

