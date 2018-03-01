# Yaapu Frsky Telemetry script

A lua based telemetry script for the Taranis X9D+,X9E and X7 radio using the frsky passthrough protocol.

Requires OpenTX 2.2 and a recent release of arducoper, arduplane or rover.

Tested on a pixracer with copter 3.5.3 and on a pixhawk clone with copter 3.5.4

## Screenshots

![Taranis X9D+](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9d.png)

![Taranis X9D+](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9ddual.png)

![Taranis X9D+](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9dmessages.png)

![Taranis X7](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7.png)

![Taranis X7](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7dual.png)

![Taranis X7](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7messages.png)
## Features

 - configuration menu, long press [MENU] to display
 - flight mode (modes are displayed based on the frame type:copter,plane or rover)
 - artificial horizon with roll,pitch and yaw with numeric compass heading
 - mini home icon on yaw compass at home angle position
 - battery voltage from 3 sources (in order of priority), short pressing ENTER cycles between the sources
 - - frsky FLVSS voltage sensor if available (vs is displayed next to voltage)
 - - frsky analog port if available (a2 is displayed next to voltage)
 - - flight controller via telemetry (fc is displayed next to voltage)
 - battery lowest cell if available or cell average if not
 - battery current
 - battery capacity and battery capacity used in mAh and %
 - power as battery voltage * current
 - vertical speed on left side of HUD
 - altitude on right side of HUD 
 - gps altitude
 - gps fix extendend status (2D,3D,DGPS,RTK)
 - gps HDop
 - flight time
 - rssi value
 - transmitter voltage
 - home distance
 - horizontal ground speed
 - home heading as rotating triangle
 - mavlink messages with history accessible with +/- buttons short press
 - english and italian sound files for selected events: battery levels, failsafe, flightmodes, alerts and landing

## Advanced Features 

 - dual battery support (dual FLVSS and/or dual battery from ArduPilot) short press [ENTER] to display second battery info
 - capacity ovveride for battery 1 and 2
 - min/max for battery/cell voltage, current, altitude, ground and vertical speed, short press [MENU] to display min/max values
 
 ![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9dminmax.png)
 
 ![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7minmax.png)

 - vocal alerts for battery levels, max distance and min/max altitude (vocal fence)
 - configurable vocal timer alert every n minutes
 - sensors VFAS,CURR,Alt,VSpd,GAlt,Hdg,GSpd,Fuel,Tmp1,Tmp2 are exposed to OpenTX, see the [wiki](https://github.com/yaapu/FrskyTelemetryScript/wiki/Exposed-Telemetry-Variables) for details. You need to run "discover new sensors" in your model telemetry page to use the sensors in OpenTX.
 
## Voltage Sources

The script can use the A2 analog voltage source from X4R and X6R receivers (a2 is displayed next to cell voltage).

The script can use a second FLVSS voltage sensor but the variable in opentx needs to be renamed to "cels2".

## Configuration

![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9dmenupag1.png)

![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9dmenupag2.png)

![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7manupag1.png)

![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7menupag2.png)

## Installation

Copy the contents of the SD folder to your radio SD Card.
Make sure to have the SOUNDS/yaapu0 and MODELS/yaapu folders.

For the X9D/X9D+ and X9E use the yaapu9.lua script.
For the QX7 radio use the yaapu7.lua script.

The script is quite big and compilation on your radio may fail.
The safest way is to compile it on Companion and then copy the .luac compiled version to the SD card in the /SCRIPTS/TELEMETRY folder.
I do provide already compiled versions for both X9D and QX7.

Note: On radios without the luac option enabled it is necessary to rename the script from yaapu9.luac to yaapu9.lua and from yaapu7.luac to yaapu7.lua

To enable sound files playback copy them to /SOUNDS/yaapu0/en and /SOUNDS/yaapu0/it folders.

## Compilation

In order to compile your own version you must first preprocess the SOURCES/yaapu0.lua script with the pproc.lua preprocessor.
Details on the preprocessor can be found [here](https://gist.github.com/incinirate/d52e03f453df94a65e1335d9c36d114e)

You need a working lua interpreter for this to work.
On a command line simply run "lua pproc.lua yaapu0.lua yaapu9.lua"
The yaapu9.lua script is now ready to be compiled in Companion.


## Hardware requirements

Please refer to the arducopter wiki for information on how to configure your flight controller for passthrough protocol
 - http://ardupilot.org/copter/docs/common-frsky-passthrough.html

For information on how to connect the FrSky equipment together, please refer to 
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#common-frsky-equipment
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#frsky-cables

