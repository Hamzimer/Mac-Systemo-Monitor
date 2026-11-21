<h1 align="center">Mac Systemo Monitor</h1>
<p align="center"><strong>Your Mac’s performance, in an instrument worth looking at.</strong></p>
<p align="center">Three connected gauges · 12 styles · Native macOS</p>
<p align="center">English · <a href="README.ja.md">日本語</a> · <a href="README.zh-Hant.md">繁體中文</a></p>

![macOS](https://img.shields.io/badge/macOS-14%2B-111111?logo=apple)
![Apple Silicon](https://img.shields.io/badge/Apple-Silicon-00bde7)
![Swift](https://img.shields.io/badge/Swift-native-f05138?logo=swift&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

> **Publication in progress:** this repository currently contains documentation and the MIT license. The prepared app source, interface previews and DMG have not yet been uploaded. A downloadable GitHub release is not available yet.

## Performance you can see

Bring CPU, GPU and memory activity onto your desktop as a floating instrument cluster. Choose glass, brushed metal, neon or analog needles, then tuck the monitor into the menu bar when you need the space.

- **12 visual styles.** One set of live measurements, twelve ways to make it yours.
- **A floating silhouette.** Transparent outside the gauges. Drag to move; use the MEM gauge’s lower-right grip to resize.
- **CPU core activity.** Overall usage and activity for each logical CPU core.
- **GPU readings without invented detail.** Device, renderer and tiler utilization where available; unsupported readings show “—”.
- **Memory at a glance.** Used and total RAM, with application, wired, compressed, cache and swap details.
- **Menu-bar mode.** Press ⌘M to keep CPU, GPU and memory readouts and mini graphs visible.
- **Native and local.** SwiftUI and AppKit, no third-party runtime dependencies, no account and no telemetry uploads.

## Twelve materials, one instrument

| Style | Character |
| --- | --- |
| Pure Glass | Light, connected glass |
| Brushed Aluminum | Metal finish and precise rings |
| Liquid Dynamic | Flowing liquid inside a blue frame |
| Dark Pro | Quiet dark surfaces and bright indicators |
| HUD Neon | Segmented gauges and angular framing |
| Monochrome Elegance | Silver and black instruments |
| Aurora | Blue, purple and green light with moving waves |
| Ultra Minimal | A white frame and clear essentials |
| Frosted Blur | Soft translucent material |
| Depth Glass | Layered reflections and luminous depth |
| Classic Instrument | Analog needles, metal and screws |
| Space Black | Deep black with illuminated contours |

Interface previews will be added with the app files. Preview renders will be labeled separately from desktop screenshots.

## Requirements and availability

The prepared build is **HUD Systemo Monitor 5.1.3**, for **Apple Silicon Macs running macOS 14 or later**. Intel Macs are not supported by that build. Menus currently use Japanese; these documents are available in English, Japanese and Traditional Chinese.

Once published, the DMG and SHA-256 checksum will be available under [Releases](https://github.com/Hamzimer/Mac-Systemo-Monitor/releases). Quit an older copy with ⌘Q, open the DMG, and drag **HUD Systemo Monitor.app** into **Applications**.

The prepared app is ad-hoc signed, **not Developer ID signed or notarized**. macOS may block a downloaded copy.

## Controls

| Action | Control |
| --- | --- |
| Move | Drag the gauge body |
| Resize | Drag the diagonal grip at the lower-right of MEM |
| Alternative resizing | Option + scroll, or right-click → smaller / larger |
| Choose a style | Right-click → style submenu; selection is saved |
| Menu-bar mode | ⌘M or right-click → minimize |
| Restore | Click the menu-bar readout → show monitor |
| More detail | Right-click → details |
| Keep on top | View menu → always on top |
| Quit | ⌘Q |

## Measurements, clearly defined

Readings refresh every **1 second** with at most **60 history samples per metric**. CPU bars show current logical-core activity; GPU and memory bars show recent history. The details view adds storage use and interface-aggregated network rates.

**Physical GPU per-core utilization is unavailable.** A readable hardware core count is not a per-core load measurement. GPU counters vary by hardware and macOS; missing data is displayed as “—”. Temperature, fan speed and clock frequency are not implemented. Virtual or VPN network interfaces can cause double counting.

Liquid Dynamic, Aurora and Depth Glass include decorative waves whose level follows utilization. Wave redraws pause while minimized or hidden, and Reduce Motion is respected. Menu-bar measurements continue while minimized.

Bounded history and paused hidden animations help limit work. Full GUI memory usage has not been benchmarked, so this project does not claim minimum RAM usage.

## Validation and feedback

The prepared source was built and CPU, GPU and memory sampled on an **M2 Max Mac with 32 GB RAM**. Rendering checks covered all 12 styles and transparent outer pixels. Automated checks cover native menu-object stability, resize geometry and grip hit testing.

Manual desktop verification of continuous mouse dragging, menu selection, minimize/restore and Dock icon appearance remains outstanding in the restricted development environment.

Have a refinement or compatibility report? [Open an issue](https://github.com/Hamzimer/Mac-Systemo-Monitor/issues) with your Mac model, macOS version, app version and reproduction steps. Remove personal details from screenshots and logs.

**If you like the idea, a star helps other Mac users discover it.**

## License

[MIT](LICENSE) · Copyright © 2026 Hamzimer.
