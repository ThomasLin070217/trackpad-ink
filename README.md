# Trackpad Ink

An open-source experiment to write into Mac apps such as Goodnotes using a MacBook trackpad and a pen.

## Current status

This repository currently contains an **input lab**, not a Goodnotes integration. It shows strokes from a finger or a passive capacitive pen when the Mac trackpad recognizes that contact. It does not inject input into other apps.

Apple Pencil is not recognized by current MacBook trackpad hardware. This project will investigate that separately; its software prototype does **not** claim Apple Pencil compatibility.

## Try the input lab

Requirements: macOS 13 or later and Xcode Command Line Tools.

```sh
swift run TrackpadInkLab
```

Touch the trackpad while the lab window is focused. If a stroke appears, that input method is detected. Press Delete to clear the canvas. Try a finger first, then a passive capacitive pen. A pen that works on an iPad as an active stylus is not automatically a capacitive pen.

## Goal

Convert recognized trackpad positions into controlled pen or mouse strokes in the selected Mac app, with Goodnotes as the primary target. The first integration milestone is a short handwritten note that can be saved and reopened in Goodnotes.

## Roadmap

1. Measure which pens generate usable trackpad touches and how precise the positions are.
2. Add an explicit pen-mode toggle and map absolute trackpad positions to a selectable screen region.
3. Send strokes to Goodnotes and verify the saved document, including lifts between strokes, undo, and navigation.
4. Improve jitter filtering, palm rejection, calibration, and multi-display behavior.
5. Research whether Apple Pencil input is possible with additional hardware. Keep this work separate from the software-only milestones.

## Constraints

- The trackpad's small size may make sustained handwriting uncomfortable.
- A passive capacitive pen may have less precision than an active pen.
- Global event injection will require macOS permissions and must be tested against Goodnotes; this repository does not yet provide it.
- Any Apple private API explored later may break across macOS releases.

## License

MIT. See [LICENSE](LICENSE).
