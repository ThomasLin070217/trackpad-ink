# Trackpad Ink

An open-source experiment to write into Mac apps such as Goodnotes using a MacBook trackpad and a pen.

## Current status

This repository contains two experimental tools:

- `TrackpadInkLab` displays raw touches inside its own window.
- `TrackpadInkBridge` turns recognized single-contact motion into mouse strokes in the **frontmost Goodnotes app**. It is a compiled prototype; handwriting quality and Goodnotes compatibility still need hands-on testing.

Apple Pencil is not recognized by current MacBook trackpad hardware. This project will investigate that separately; its software prototype does **not** claim Apple Pencil compatibility.

## Try the input lab

Requirements: macOS 13 or later and Xcode Command Line Tools.

```sh
swift run TrackpadInkLab
```

Touch the trackpad while the lab window is focused. If a stroke appears, that input method is detected. Press Delete to clear the canvas. Try a finger first, then a passive capacitive pen. A pen that works on an iPad as an active stylus is not automatically a capacitive pen.

## Try the Goodnotes bridge

The bridge currently targets the installed Goodnotes bundle ID `com.goodnotesapp.x` and was built on macOS 15.7.9 with Swift 6.1.2. It requires **Input Monitoring** and **Accessibility** access to monitor pointer events and post drawing events. It also uses [OpenMultitouchSupport 3.0.3](https://github.com/Kyome22/OpenMultitouchSupport), an MIT-licensed wrapper around Apple's **private** `MultitouchSupport.framework`; this can break with a macOS update and requires the app sandbox to be off.

```sh
./scripts/build-app.sh
```

Open `dist/Trackpad Ink.app`. Its control window has **开始试写** and **停止试写** buttons. Grant the macOS permissions when prompted, restart the app if macOS asks, and press Start again. Open Goodnotes, select its pen tool, put the cursor over a blank page, and write with one finger or a passive capacitive stylus. Lifting should finish one stroke. A second contact stops drawing until all contacts lift. Goodnotes controls cannot be clicked while drawing mode is on; use **停止试写** first. The **✎ Ink** menu bar item also has Start, Stop, and Quit controls.

The bridge uses macOS's cursor path, including the system's pointer processing. It uses raw touch frames only to detect contact and lift. It does **not** reproduce Apple's proprietary pointer algorithm or use TrackpadDraft's code. It posts normal left mouse down/drag/up events, so it cannot provide true pen pressure or tilt. No strokes are recorded or sent over a network.

**Test still needed:** short words and equations in Goodnotes, missing strokes after lifting, accidental clicks, and whether a chosen pen moves the cursor at all. The bridge is a research prototype and may feel worse than native Three-Finger Drag. Stop it from the menu if it interferes with navigation.

### Which pens can work?

- **Apple Pencil:** current MacBook trackpads do not pair with or decode its active pen signal. Software alone cannot make its tip work here. Use an iPad as the Pencil input device if Apple Pencil is required.
- **Passive capacitive stylus:** may work if its tip registers like a finger and moves the Mac cursor. The lab checks detection; handwriting precision remains to be tested.
- **Trackpad-specific active pen:** [SonarPen USB-C for Mac](https://www.sonarpen.com/mac) is a vendor-documented hardware and driver route that claims trackpad drawing and pressure. It is a proprietary solution, and we have not verified it in Goodnotes. Its dedicated driver would handle pen identification and pressure; this bridge does not talk to that driver.

## Goal

Convert recognized trackpad positions into controlled pen or mouse strokes in the selected Mac app, with Goodnotes as the primary target. The first integration milestone is a short handwritten note that can be saved and reopened in Goodnotes.

## Usability baseline

On an M4 MacBook Air running macOS 15.7.9, a hands-on trial of `ongchi/stylus` produced handwriting that the user found unreliable. The same user found macOS's built-in Three-Finger Drag easier to write with. This is a first-person usability report, not a controlled benchmark.

Three-Finger Drag is already enabled on the test Mac. New prototypes should be compared with it in Goodnotes using the same short words, equations, and pen lifts. We should measure missing strokes, unintended marks, cursor placement, and writing effort. A custom input mode is only worthwhile if it improves on that baseline.

## Roadmap

1. Record a short Goodnotes handwriting sample with native Three-Finger Drag as the baseline.
2. Measure which pens generate usable trackpad touches and how precise the positions are.
3. Prototype one alternative input mode and compare it with the baseline before adding more features.
4. If the prototype is better, send strokes to Goodnotes and verify the saved document, including lifts between strokes, undo, and navigation.
5. Improve jitter filtering, palm rejection, calibration, and multi-display behavior only where testing shows a benefit.
6. Research whether Apple Pencil input is possible with additional hardware. Keep this work separate from the software-only milestones.

## Constraints

- The trackpad's small size may make sustained handwriting uncomfortable.
- A passive capacitive pen may have less precision than an active pen.
- Global event injection requires macOS permissions and still needs hands-on testing against Goodnotes.
- Any Apple private API explored later may break across macOS releases.

## License

MIT. See [LICENSE](LICENSE).
