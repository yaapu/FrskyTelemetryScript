# Yaapu Frsky Telemetry script

A lua based telemetry script for the Frsky Horus X10,X10S,X12 and Taranis X9D+,X9E and X7 radios using the frsky passthrough protocol.

The script supports all of the telemetry DIY 0x5000 packets sent by ardupilot’s [frsky passthrough protocol library](https://github.com/ArduPilot/ardupilot/tree/master/libraries/AP_Frsky_Telem)

Requires OpenTX 2.2 and a recent release of arducoper, arduplane or rover.

Tested on a pixracer with copter 3.5.5 and on a pixhawk clone with copter 3.5.4 and 3.5.5

## Screenshots

![X10](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10.png)

![X9D](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9d.png)

![X7](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7.png)

dual battery view

![X10dual](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10dualbattery.png)

![X9Ddual](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9ddual.png)

![X7dual](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7dual.png)

mavlink message history

![X10messages](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10messages.png)

![X9Dmessages](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9dmessages.png)

![X7messages](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7messages.png)

## Index

 - [display layout](#display-layout)
 - [features](#features)
 - [advanced features](#advanced-features)
 - [supported flight modes](#supported-flight-modes)
 - [voltage sources](#voltage-sources)
 - [cell count detection](#cell-count-detection)
 - [alerts](#alerts)
 - [script timing and update rates](#script-timing-and-update-rates)
 - [configuration](#configuration)
 - [installation](#installation)
 - [sound files customization](#sound-files-customization)
 - [compilation](#compilation)
 - [hardware requirements](#hardware-requirements)
 - [credits](#credits)
 
## Display layout

![X12](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x12displayinfo.png)

![X9D](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9displayinfo.png)

![QX7](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7displayinfo.png)

## Features

 - configuration menu, long press [MENU] on Taranis or [MDL] on Horus
 - per model configuration saved in MODELS/yaapu/modelname.cfg on Taranis, SCRIPTS/YAAPU/CFG/modelname.cfg on Horus
 - flight [modes](#supported-flight-modes) based on frame type:copter,plane or rover with vocal sound support
 - artificial horizon with roll,pitch and yaw with numeric compass heading
 - vertical variometer gauge on left side of center panel
 - rangefinder with max range support in config menu
 - mini home icon on yaw compass at home angle position
 - battery voltage from 3 sources (in order of priority), short pressing [ENTER]/[ENCODER] cycles between the sources
   - frsky FLVSS voltage sensor if available (vs is displayed next to voltage)
   - frsky analog port if available (a2 is displayed next to voltage)
   - flight controller via telemetry (fc is displayed next to voltage)
 - battery lowest cell if available or cell average if not
 - battery current
 - battery capacity and battery capacity used in mAh and %
 - power as battery voltage * current
 - vertical speed on left side of HUD
 - "synthetic vertical speed" calculated from altitude variations (no vspeed is sent by the autopilot in DCM mode)
 - altitude on right side of HUD 
 - gps altitude
 - gps fix extendend status (2D,3D,DGPS,RTK)
 - gps HDop
 - flight time
 - rssi value
 - transmitter voltage
 - home distance
 - horizontal ground speed or air speed (available if configured in mission planner)
 - home heading as rotating triangle
 - mavlink messages with history accessible with [PLUS]/[MINUS] or by turning the [ENCODER] buttons
 - english, italian and french sound files for selected events: battery levels, failsafe, flightmodes, alerts and landing

## Advanced Features 

- dual battery support (dual FLVSS and/or dual battery from ArduPilot) short press [ENTER] on Taranis or [ENCODER] on Horus to display second battery info. If a second battery is detected there will be a "B1+B2" label on screen.
 - capacity ovveride for battery 1 and 2
 - tracking of min/max values for battery/cell voltage, current, altitude, ground and vertical speed, short press [MENU] on Taranis or [SYS] on Horus to display them, an up pointing arrow will indicate max values whereas a down pointing arrow will indicate min values
 
 ![X10 minmax](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10minmax.png)
 
 ![X9D minmax](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9dminmax.png)
 
 ![X7 minmax](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7minmax.png)

 - vocal alerts for battery levels, 
 - vocal fence: max distance and min/max altitude alerts
 - configurable vocal timer alert every n minutes
 - sensors VFAS,CURR,Alt,VSpd,GAlt,Hdg,GSpd,Fuel,Tmp1,Tmp2 are exposed to OpenTX, see the [wiki](https://github.com/yaapu/FrskyTelemetryScript/wiki/Telemetry-sensors-exposed-to-OpenTX-by-the-Yaapu-script) for details.
 
 On the Taranis you need to run "discover new sensors" in your model telemetry page to use the sensors in OpenTX, the script has to be running for this to work.
 
On the Horus the procedure is different: you start sensor discovery in the model telemetry page, leave it running and run the Yaapu Script as usual. Close the script and go back to the telemetry page where discovery should still be running and all sensors should have been discovered.
If this does not work sensors can still be created manually in the model telemetry page.

Note: The A2 sensor (analog input port) will only be discovered on X4R and X6R receivers.
 
 ![X10 sensors](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10sensors.png)
 
Sensor valus are passed to OpenTX only when the script receives valid telemetry from the rx!
 
## Supported Flight Modes

### Copter

| #  | flight mode | sound support |
|---:|:------------|:-----------|
|1|Stabilize|YES|
|2|Acro|YES|
|3|AltHold|YES|
|4|Auto|YES|
|5|Guided|YES|
|6|Loiter|YES|
|7|RTL|YES|
|8|Circle|YES|
|10|Land|YES|
|12|Drift|YES|
|14|Sport|YES|
|15|Flip|YES|
|16|AutoTune|YES|
|17|PosHold|YES|
|18|Brake|YES|
|19|Throw|YES|
|20|AvoidADSB|YES|
|21|GuidedNOGPS|YES|
|22|SmartRTL|YES|

### Plane
| #  | flight mode | sound support |
|---:|:------------|:-----------|
|1|Manual|YES|
|2|Circle|YES|
|3|Stabilize|YES|
|4|Training|YES|
|5|Acro|YES|
|6|FlyByWireA|YES|
|7|FlyByWireB|YES|
|8|Cruise|YES|
|9|Autotune|YES|
|11|Auto|YES|
|12|RTL|YES|
|13|Loiter|YES|
|15|AvoidADSB|YES|
|16|Guided|YES|
|17|Initializing|YES|
|18|QStabilize|YES|
|19|QHover|YES|
|20|QLoiter|YES|
|21|Qland|YES|
|22|QRTL|YES|

### Rover

| #  | flight mode | sound support |
|---:|:------------|:-----------|
|1|Manual|YES|
|2|Acro|YES|
|4|Steering|YES|
|5|Hold|YES|
|11|Auto|YES|
|12|RTL|YES|
|13|SmartRTL|YES|
|16|Guided|YES|
|17|Initializing|YES|

## Voltage Sources

Battery voltage is tracked independentely for 3 battery sources: FLVSS, analog port A2 and flight controller. (The script can use the A2 analog voltage source from X4R and X6R receivers, a2 would be displayed next to cell voltage). In single battery mode a short press of [ENTER] on Taranis or [ENCODER] on Horus cycles between all the sources. Min value is also tracked for the 3 sources and can be shown with a [MENU] short press on Taranis or [SYS] on the Horus.

Note:If you use a second FLVSS voltage sensor the OpenTX variable has to be renamed to "Cel2"

When a second battery is detected the script also tracks "aggregate" battery values and shows a "B1+B2" label in the right panel. Cell value and battery voltage is the "minimum" between the two batteries, current is summed and capacity percent is averaged. A short press of [MENU] on Taranis or [ENCODER] on the Horus will show min/max values for this aggregate view.

In dual battery mode a short press of [ENTER] on the Taranis or [ENCODER] on the Horus switches from single aggregate view to individual dual battery view. Subsequent short presses of [ENTER]/[ENCODER] in this dual view will cycle between voltage sources. In dual view a short press of [MENU] on Taranis or [SYS] on Horus shows individual packs min/max values.

To get back to aggregate view and retain the selected voltage source short press [EXIT] on Taranis or [RTN] on Horus.

## Supported battery configurations

- A2 analog port only: In this configuration only 1 battery will be detected,a2 will be displayed next to the cell voltage, Cell voltage is calculated as A2 battery voltage divided by cell count. No current or battery consumption will be availbale. If the user overrides battery capacity from the config menu battery % will be stuck at 99%.
- Single power module: In this configuration only 1 battery will be detected, fc will be displayed next to the cell voltage, Cell voltage is calculated as battery pack voltage divided by cell count. Current and consumed mAh will be reported. Battery percentage depends on battery capacity either received from ArduPilot or overriden from the menu.
- Dual power module: In this configuration 2 batteries will be detected, fc will be displayed next to the cell voltage, Cell voltage is calculated as battery pack voltage divided by cell count. Current and consumed mAh will be reported. Battery percentage depends on battery capacity either received from ArduPilot or overriden from the menu. Battery stats can be displayed in aggregate view or separate battery view (battery 1 in right pane and battery 2 in left pane)
In aggregate battery view Cell voltage is the minimun cell voltage between battery 1 and 2, current is the sum of current 1 and current 2, consumed mAh is the sum of mAh 1 and mAh 2 and battery percentage is the weighted average of percentage 1 and percentage 2
- Single FLVSS sensor:  In this configuration only 1 battery will be detected,vs will be displayed next to the cell voltage, Cell voltage is the minimum cell voltage of the pack. No current or battery consumption will be availbale. If the user overrides battery capacity from the config menu battery % will be stuck at 99%.
- Dual FLVSS sensor:  In this configuration only 2 batteries will be detected,vs will be displayed next to the cell voltage, Cell voltage is the minimum cell voltage of the pack. No current or battery consumption will be availbale. If the user overrides battery capacity from the config menu battery % will be stuck at 99%.
Battery stats can be displayed in aggregate view or separate battery view (battery 1 in right pane and battery 2 in left pane)
In aggregate battery view Cell voltage is the minimun cell voltage between battery 1 and 2.

## Cell Count Detection

The script uses a simple way to calculate cell count for voltage sources fc and a2:
- if the maximum pack voltage is higher then 21.75v i.e 4.35x5 then it's a 6s.
- if the maximum pack voltage is higher then 17.4v i.e 4.35x4 then it's a 5s.
- if the maximum pack voltage is higher then 13.05v i.e 4.35x3 then it's a 4s.
- if the maximum pack voltage is higher then 8.7v i.e 4.35x2 then it's a 3s.
- else it's a 2s

This in turn means that:
- if you hook a 6s with cell voltage lower then 3.625V it will be detected as a 5s.
- if you hook a 5s with cell voltage lower then 3.48V it will be detected as a 4s.
- if you hook a 4s with cell voltage lower then 3.27V it will be detected as a 3s.

For 3s and 2s the limit is so low that's not a problem.

Please note that the voltage used for the calculation is the maximum pack voltage so if after detection the cell voltage lowers below the above limits it will be ok.

The script supports autodetection up to 6s.
It's always possible to override auto detection from the menu and set cell count up to 12s.

## Alerts

There are 2 battery level alerts, both are set as cell voltage so independent from cell count. Battery level 1 should be set higher than battery level 2.

When cell voltage falls below level 1 it will trigger a vocal alert and the V next to the cell voltage will start blinking: once triggered blinking will persist even if the voltage raises above level 1.

When cell voltage falls below battery level 2 it will trigger a second vocal alert and the cell voltage digits will start blinking: once triggered blinking will persist even if the voltage raises above level 2.

If the battery reaches the failsafe level (it must be configured in mission planner) the script will display "batt failsafe" on the hud and play a vocal alert every n seconds (period can be configured from the menu).

It's also possible to configure a timer that will trigger a vocal alert every n minutes of flight time.

The script also support a "vocal fence" feature by setting a minimun altitude, a maximum altitude and a maximum distance alert.
When the vehicle moves outside of the fence the script will play a vocal alert every n seconds.

## Script update rates

- The script processes telemetry up to 60Hz
- Sport telemetry stream is at around 40Hz
- Screen is redrawn at 20Hz
- VSpd sensor is exposed to OpenTX at 8Hz
- All other frsky sensors are exposed to OpenTX at 4Hz
- Events and alarms are checked at 2Hz

## Configuration

![X10 menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10menu.png)

![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9dmenupag1.png)

![X9D menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9dmenupag2.png)

![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7menupag1.png)

![X7 menu](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7menupag2.png)

The language of the vocal alerts is independent from the radio language and can be configured from the menu.
Right now only english, italian and french are supported but new languages can be added with ease.

Battery capacity for battery 1 and battery 2 is automatically read from the values configured in mission planner but can both be overidden from the menu. When a new capacity is defined from the menu it will immediately be used in all calculations and it's value will be displayed on screen.

## Installation

Copy the contents of the SD folder to your radio SD Card.

On Taranis Make sure to have the SOUNDS/yaapu0 and MODELS/yaapu folders.
On Horus make sure you have the SOUNDS/yaapu0, SCRIPTS/YAAPU/CFG and SCRIPTS/YAAPU/IMAGES folders.

- For the X10/X12 use the yaapux.luac script (rename it to yaapux.lua if the radio doesn't start it, see the note below).
- For the X9D/X9D+ and X9E use the yaapu9.luac script (rename it to yaapu9.lua if the radio doesn't start it, see the note below).
- For the QX7 radio use the yaapu7.luac script (rename it to yaapu7.lua if the radio doesn't start it, see the note below).

The script is quite big and compilation on your radio may fail.
The safest way is to compile it on Companion and then copy the .luac compiled version to the SD card in the /SCRIPTS/TELEMETRY folder on Taranis or to the /SCRIPTS/YAAPU folder on the Horus.

I do provide already compiled versions for X10/X12,X9D and QX7.

**Note: On radios without the luac option enabled it is necessary to rename the script from .luac to .lua**

To enable sound files playback copy them to /SOUNDS/yaapu0/en, /SOUNDS/yaapu0/it and SOUNDS/yaapu0/fr folders.

**Note: On the Horus the script needs to be started in one time mode, see the [wiki](https://github.com/yaapu/FrskyTelemetryScript/wiki/How-to-run-the-Yaapu-script-on-X10-and-X12) on how to do it.**

## Sound files customization

All sound files are inside the SOUNDS/yaapu0/"language" folder, where language is a 2 chars language code.The following table is a list of all english files.
 
| folder path  | filename | TTS text |
|:---|:------------|:-----------| 
|SOUNDS/yaapu0/en|acro|Acro flight mode|
|SOUNDS/yaapu0/en|acro_r|Acro mode|
|SOUNDS/yaapu0/en|althold|Altitude hold flight mode|
|SOUNDS/yaapu0/en|armed|Motors armed|
|SOUNDS/yaapu0/en|auto|Auto flight mode|
|SOUNDS/yaapu0/en|auto_r|Auto mode|
|SOUNDS/yaapu0/en|autotune|Autotune enabled|
|SOUNDS/yaapu0/en|avoidadsb|Avoid A D S B flight mode|
|SOUNDS/yaapu0/en|bat5|Battery at 5 percent|
|SOUNDS/yaapu0/en|bat10|Battery at 10 percent|
|SOUNDS/yaapu0/en|bat15|Battery at 15 percent|
|SOUNDS/yaapu0/en|bat20|Battery at 20 percent|
|SOUNDS/yaapu0/en|bat25|Battery at 25 percent|
|SOUNDS/yaapu0/en|bat30|Battery at 30 percent|
|SOUNDS/yaapu0/en|bat40|Battery at 40 percent|
|SOUNDS/yaapu0/en|bat50|Battery at 50 percent|
|SOUNDS/yaapu0/en|bat60|Battery at 60 percent|
|SOUNDS/yaapu0/en|bat70|Battery at 70 percent|
|SOUNDS/yaapu0/en|bat80|Battery at 80 percent|
|SOUNDS/yaapu0/en|bat90|Battery at 90 percent|
|SOUNDS/yaapu0/en|batalert|Battery alert|
|SOUNDS/yaapu0/en|batalert1|Battery level 1 alert|
|SOUNDS/yaapu0/en|batalert2|Battery level 2 alert|
|SOUNDS/yaapu0/en|brake|Brake flight mode|
|SOUNDS/yaapu0/en|circle|Circle flight mode|
|SOUNDS/yaapu0/en|cruise|Cruise flight mode|
|SOUNDS/yaapu0/en|disarmed|Motors disarmed|
|SOUNDS/yaapu0/en|drift|Drift flight mode|
|SOUNDS/yaapu0/en|ekf|E K F failsafe|
|SOUNDS/yaapu0/en|flip|Flip flight mode|
|SOUNDS/yaapu0/en|flybywirea|Fly by wire a flight mode|
|SOUNDS/yaapu0/en|flybywireb|Fly by wire b flight mode|
|SOUNDS/yaapu0/en|gpsfix|GPS 3D fix lock|
|SOUNDS/yaapu0/en|gpsnofix|No gps|
|SOUNDS/yaapu0/en|guided|Guided flight mode|
|SOUNDS/yaapu0/en|guided_r|Guided mode|
|SOUNDS/yaapu0/en|guidednogps|Guided no gps flight mode|
|SOUNDS/yaapu0/en|hold_r|Hold mode|
|SOUNDS/yaapu0/en|initializing|Initializing|
|SOUNDS/yaapu0/en|land|Land flight mode|
|SOUNDS/yaapu0/en|landing|Landing complete|
|SOUNDS/yaapu0/en|loiter|Loiter flight mode|
|SOUNDS/yaapu0/en|lowbat|Low battery|
|SOUNDS/yaapu0/en|manual|Manual flight mode|
|SOUNDS/yaapu0/en|manual_r|Manual mode|
|SOUNDS/yaapu0/en|maxalt|Max altitude alert|
|SOUNDS/yaapu0/en|maxdist|Max distance alert|
|SOUNDS/yaapu0/en|minalt|Low altitude alert|
|SOUNDS/yaapu0/en|poshold|Position hold flight mode|
|SOUNDS/yaapu0/en|qhover|Q hover flight mode|
|SOUNDS/yaapu0/en|qland|Q land flight mode|
|SOUNDS/yaapu0/en|qloiter|Q loiter flight mode|
|SOUNDS/yaapu0/en|qrtl|Q return to home flight mode|
|SOUNDS/yaapu0/en|qstabilize|Q stabilize flight mode|
|SOUNDS/yaapu0/en|rtl|Return to home|
|SOUNDS/yaapu0/en|rtl_r|Return to home mode|
|SOUNDS/yaapu0/en|smartrtl|Smart return to home flight mode|
|SOUNDS/yaapu0/en|smartrtl_r|Smart return to home mode|
|SOUNDS/yaapu0/en|sport|Sport flight mode|
|SOUNDS/yaapu0/en|stabilize|Stabilize flight mode|
|SOUNDS/yaapu0/en|steering_r|Steering mode|
|SOUNDS/yaapu0/en|throw|Throw flight mode|
|SOUNDS/yaapu0/en|timealert|Timer alert|
|SOUNDS/yaapu0/en|training|Training flight mode|
|SOUNDS/yaapu0/en|yaapu|Yaapu telemetry ready|

Sound files can be customized but must be compatible with [OpenTX](https://opentx.gitbooks.io/manual-for-opentx-2-2/content/advanced/audio.html)

An easy way to automate creation of sound files is by using the [TTSAutomate](https://github.com/CaffeineAU/TTSAutomate) tool with a phrase file.

A reference [phrase file](https://github.com/yaapu/FrskyTelemetryScript/blob/master/TARANIS/SOURCES/english.psv) for the english language is provided as a template for other languages.
Taranis and Horus phrase files may differ so make sure to pick the right one.

**Note:In order to add new languages the script needs to be recompiled because the language must be added to the script configuration menu.**

## Compilation

To compile your own version you must first preprocess the SOURCES/yaapu0.lua script with the pproc.lua preprocessor.
Details on the preprocessor can be found [here](https://gist.github.com/incinirate/d52e03f453df94a65e1335d9c36d114e)

There are many #define each activates a specific feature of the script.

You need a working lua interpreter for this to work.
On a command line simply run "lua pproc.lua yaapu0.lua yaapu9.lua"
The yaapu9.lua script is now ready to be compiled in Companion.


## Hardware requirements

Please refer to the arducopter wiki for information on how to configure your flight controller for passthrough protocol
 - http://ardupilot.org/copter/docs/common-frsky-passthrough.html

For information on how to connect the FrSky equipment together, please refer to 
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#common-frsky-equipment
 - http://ardupilot.org/copter/docs/common-frsky-telemetry.html#diy-cable-for-x-receivers
 
 ## Credits
 
 Thanks go to 
 - Marco Robustini (X9D tester), 
 - Chris Rey (QX7 tester)
 - Alain Chartier (frech sound files)
 - [Johnex](https://github.com/Johnex) for TTSAutomate phrase file
 - Franck Perruchoud (X12 main beta tester)
 - Chen Zhengzhong (X10 tester)
 - Andras Schaffer (X12 tester)
 - Massild (X10 tester)
 - Zeek (X10 tester)
 - Vova Reznik (X10 tester)
 - Craft&Theory for the passthrough protocol
