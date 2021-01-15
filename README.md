# Yaapu Frsky Telemetry Script

This is the home of the Yaapu Telemetry Script project, a [LUA](https://www.lua.org/about.html) telemetry script for the Frsky Horus and Taranis radios using the ArduPilot frsky passthru telemetry protocol.

**Note:**
- **OpenTX 2.3.5 on X9D/X9D+ has a bug in handling the exit key press events: it will always quit the telemetry script!**
- **the latest release versions are downloadable from the [clone/download](https://github.com/yaapu/FrskyTelemetryScript/archive/master.zip) button**
- **the latest pre-release versions are downloadable from the [releases](https://github.com/yaapu/FrskyTelemetryScript/releases) section** 


![X10](https://github.com/yaapu/FrskyTelemetryScript/raw/master/HORUS/IMAGES/x10.png)

![X9D](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x9d.png)

![X7](https://github.com/yaapu/FrskyTelemetryScript/raw/master/TARANIS/IMAGES/x7.png)

The supported radios are:
- Taranis X9D(+) and QX7 on OpenTX 2.2.2 or greater
- X-Lite on OpenTX 2.2.2 or greater (by using the QX7 version)
- Horus X10 and X12, Jumper T16 and Radiomaster TX16S on OpenTX 2.3.x

Here you'll find
- a **Telemetry** script for the Taranis radios: X9D,QX7 and X-Lite ([changelog](https://github.com/yaapu/FrskyTelemetryScript/raw/master/taranis-changelog.txt))
- a **Widget** for the Frsky Horus radios: X10/S and X12 and for Jumper T16 ([changelog](https://github.com/yaapu/FrskyTelemetryScript/raw/master/horus-changelog.txt))


both support all of the telemetry DIY 0x5000 packets sent by ardupilot’s [frsky passthrough protocol library](https://github.com/ArduPilot/ardupilot/tree/master/libraries/AP_Frsky_Telem)

The script is also compatible with the excellent [MavlinkToPassthru](https://github.com/zs6buj/MavlinkToPassthru) converter firmware by Eric Stockenstrom

Requires [OpenTX 2.2.x](http://www.open-tx.org/) and a recent release of [ArduPilot](http://ardupilot.org/ardupilot/index.html).

## Donation

This project is free and will always be.

If you like it you can support it by making a donation!

[![donate](https://user-images.githubusercontent.com/30294218/61724877-16fa7a80-ad6f-11e9-80de-9771e0b820ae.png)](https://paypal.me/yaapu)
