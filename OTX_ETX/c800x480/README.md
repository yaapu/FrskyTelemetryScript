# Yaapu Telemetry Widget - 800x480 EdgeTX

This is the 800x480 resolution variant of the Yaapu Telemetry Widget for EdgeTX radios with high-resolution color LCDs (e.g., RadioMaster TX16S Mark II, Jumper T18 Pro, etc.).

## Installation

Copy the contents of the `SD/` folder to your radio's SD card:

- `WIDGETS/yaapu/` → Widget files
- `SCRIPTS/TOOLS/` → Configuration and debug tools

**Important:** You also need the shared map tiles from `color_common/SD/IMAGES/yaapu/maps/` if using map features.

## Bitmap Assets

The `images/` folder contains bitmap assets inherited from the 480x272 variant. The following bitmaps should be regenerated at the appropriate size for optimal display on 800x480 screens:

- `hud.png` and `hud_bg.png` — HUD overlay (should be 400x230px)
- `variogauge_*.png` — Vario gauge
- `graph_bg_120x*.png` — Graph backgrounds (consider 200px width versions)
- `menubar.png` — Menu navigation bar (if using touch)

Other icon bitmaps (armed, failsafe, GPS status, etc.) can remain at their original size.

## Layout

```
800x480 Screen Layout (default HUD view):
┌──────────────────────────────────────────────────────────────────────────────────┐
│ Top Bar (18px): Model Name | RSSI/CRSF | TX Voltage | Time                     │
├────────────┬──────────────────────────────────────────────────────┬──────────────┤
│            │                                                      │              │
│  Left      │              HUD / Artificial Horizon                │   Right      │
│  Panel     │                  (400x230px)                         │   Panel      │
│  (200px)   │           Compass | Speed | Altitude                │   (200px)    │
│            │              Vario | VSpeed                          │              │
├────────────┴──────────────────────────────────────────────────────┴──────────────┤
│ Info Strip: RPM 1 | RPM 2 | THR% | EFF | PWR | Home Arrow                      │
├─────────────────────────────────────────────────────────────────────────────────── │
│ Custom Sensors (up to 10 slots)                                                  │
├──────────────────────────────────────────────────────────────────────────────────┤
│ Status Bar: Flight Mode | GPS/HDOP/Sats | Coordinates | Messages | Timer        │
└──────────────────────────────────────────────────────────────────────────────────┘
```

## Changes from 480x272

- HUD area expanded from 240x130 to 400x230 pixels
- Left/right panels widened from 120px to 200px
- Custom sensor bar supports up to 10 sensors (was 6)
- Status bar message area supports 6 rows (was 4)
- Plot area expanded to 600px wide
- Map layout uses 7x3 tile grid (was 3x2)
- Menu shows 18 items at once (was 11)
