local flightModes = {}
-- plane flight modes
flightModes[0]=""
flightModes[1]="Manual"
flightModes[2]="AltCtl" --px4 specific
flightModes[3]="PosCtl" --px4 specific
flightModes[4]="Ready" --px4 specific
flightModes[5]="Takeoff" --px4 specific
flightModes[6]="Loiter"
flightModes[7]="Mission" --px4 specific
flightModes[8]="RTL"
flightModes[9]="Land"
flightModes[10]="RTGS" --px4 specific
flightModes[11]="Follow"
flightModes[12]="PrecLand" --px4 specific
flightModes[13]=""
flightModes[14]="Acro"
flightModes[15]="OffBoard" --px4 specific
flightModes[16]="Stabilize"
flightModes[17]="RAttitude" --px4 specific
flightModes[18]="Simple" --px4 specific
flightModes[19]=""
flightModes[20]=""
flightModes[21]=""
flightModes[22]=""
flightModes[23]=""
--
return {flightModes=flightModes}
