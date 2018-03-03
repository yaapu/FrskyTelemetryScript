# Yaapu Frsky Telemetry script

A lua based telemetry script for the Taranis X9D+,X9E and X7 radio using the frsky passthrough protocol.

The script supports all of the telemetry DIY 0x5000 packets sent by ardupilot’s frsky passthrough protocol library https://github.com/ArduPilot/ardupilot/tree/master/libraries/AP_Frsky_Telem1

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
 - per model configuration saved in MODELS/yaapu/modelname.cfg
 - flight mode (modes are displayed based on the frame type:copter,plane or rover)
 - artificial horizon with roll,pitch and yaw with numeric compass heading
 - mini home icon on yaw compass at home angle position
 - battery voltage from 3 sources (in order of priority), short pressing [ENTER] cycles between the sources
   - frsky FLVSS voltage sensor if available (vs is displayed next to voltage)
   - frsky analog port if available (a2 is displayed next to voltage)
   - flight controller via telemetry (fc is displayed next to voltage)
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

- dual battery support (dual FLVSS and/or dual battery from ArduPilot) short press [ENTER] to display second battery info. If a second battery is detected there will be a "B1+B2" label on screen.
 - capacity ovveride for battery 1 and 2
 - tracking of min/max values for battery/cell voltage, current, altitude, ground and vertical speed, short press [MENU] to display them, an up pointing arrow will indicate max values whereas a down pointing arrow will indicate min values
 
 ![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9dminmax.png)
 
 ![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7minmax.png)

 - vocal alerts for battery levels, max distance and min/max altitude (vocal fence)
 - configurable vocal timer alert every n minutes
 - sensors VFAS,CURR,Alt,VSpd,GAlt,Hdg,GSpd,Fuel,Tmp1,Tmp2 are exposed to OpenTX, see the [wiki](https://github.com/yaapu/FrskyTelemetryScript/wiki/Exposed-Telemetry-Variables) for details. You need to run "discover new sensors" in your model telemetry page to use the sensors in OpenTX.
 
Sensor valus are passed to OpenTX only when the script receives valid telemetry from the rx!
 
## Voltage Sources

Battery voltage is tracked independentely for 3 battery sources: FLVSS, analog port A2 and flight controller. (The script can also use the A2 analog voltage source from X4R and X6R receivers, a2 would be displayed next to cell voltage). A short press of [ENTER] cycles between all the sources. Min value is also tracked for the 3 sources and can be shown with a [MENU] short press.

If you use a second FLVSS voltage sensor the OpenTX variable has to renamed to "cel2"

When a second battery is detected the script also tracks "aggregate" battery values and shows a "B1+B2" label in the right panel. Cell value and battery voltage is the "minimum" between the two batteries, current is summed and capacity percent is averaged. A short press of [MENU] will show min/max values for this aggregate view.

A short press of [ENTER] switches from single aggregate view to individual dual battery view. Subsequent short presses of [ENTER] in this dual view cycle between voltage sources. In this dual view a short press of [MENU] shows individual packs min/max values.

To get back to aggregate view short press [EXIT].

## Alerts

There are 2 battery level alerts, both are set as cell voltage so independent from cell count.
When minimum cell voltage reaches the first level it will trigger a vocal alert and the V next to the cell voltage will start blinking.
Battery level 1 should be set higher then battery level 2.
When the cell voltage reaches the second battery level it will trigger a second vocal alert and the cell voltage will start blinking.
If the battery reaches the failsafe level (it must be configured in mission planner) the script will display "batt failsafe" on the hud and play a vocal alert every n seconds (period can be configured from the menu).

It is possible to configure a timer that will trigger a vocal alert every n minutes of flight time.

The script also support a "vocal fence" feature by setting a minimun altitude, a maximum altitude and a maximum distance alert.
When the vehicle moves outside of the fence the script will play a vocal alert every n seconds.

## Configuration

![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9dmenupag1.png)

![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x9dmenupag2.png)

![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7manupag1.png)

![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/blob/master/IMAGES/x7menupag2.png)

The language of the vocal alerts is independent from the radio language and can be configured from the menu.
Right now only english and italian are supported but new languages can be added with ease.

Battery capacity for battery 1 and battery 2 is automatically read from the values configured in mission planner but can both be overidden from the menu. When a new capacity is definet from the menu it will immediately be used in all calculations and it's value will be displayed on screen.

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

