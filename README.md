# dc-motor

Technical note on a project whose source was never published: position, speed and torque control of a DC motor from a PySimpleGUI desktop application, through an Arduino with an L298N dual H-bridge shield.

## What it is

Documentation only. The repository tracks `README.md`, `LICENSE` and `tests/run.sh`, and contains no application code on any branch or tag: no Python application, no Arduino sketch, no `.gitignore`. Its history is three commits — the initial README (2023-05-29), an edit to it the same day, and the licence commit of 2026-10-08. Nothing described here has been run against hardware, because there is nothing here to run.

What the repository does record is the project's original one-line description and its hardware list, and that is the whole specification available:

- **Interface**: a desktop GUI (PySimpleGUI), not a CLI.
- **Modes**: three — position, speed and torque.
- **Actuation**: an Arduino driving the motor through the L298N shield.
- **Link**: a serial connection between the host and the Arduino, implied by "via Arduino".

### What is missing

Everything that would make the project reproducible:

- The Arduino firmware: the shield's pin mapping (PWM/enable and direction), the motor supply voltage, and whether the control loop ran on the Arduino or on the host.
- The host application: the window layout, the serial protocol and framing, the control period, and the units of each of the three modes.
- **The feedback source.** An L298N shield is an open-loop driver: position and speed control need an encoder or a potentiometer, and the original README mentions neither. Which one was used, and at what resolution, is not recorded anywhere in this repository.
- The controller — PID or otherwise — its gains, and where it ran.
- Dependency versions (`pysimplegui` and `pyserial` follow from the description but were never pinned).

### If it is reconstructed

Record those items before the code, not after: pin map, feedback device and counts per revolution, serial framing, control period, controller and gains. The three modes on a GUI are the easy part; the feedback path is the part that cannot be guessed from this repository.

## Requirements

The original README listed exactly one item:

- 1× Arduino 2A H-Bridge Dual Channel DC Motor Driver Shield Module L298NH (two-channel, L298N-class), with a link to the vendor page.

The Arduino board and the DC motor follow from the description but were never listed separately. Nothing is vendored here and there is no dependency manifest.

## Install

Nothing to install: there is no code, no build file and no dependency manifest. The repository is its own documentation.

## Usage

No code to run. The original README was the only usage record that ever existed, and its content is reproduced above; the application itself lived elsewhere and was never versioned here.

## Tests

Not applicable to code, because there is none. The one check that means anything here is `tests/run.sh` (`bash tests/run.sh`), which confirms that this README exists, that every internal reference in it resolves (markdown links and inline-code paths), that the tree carries no editor junk (`.DS_Store`, `Thumbs.db`, `*.swp`) and that no file has the shape of a secret. It is a hygiene check, not a behavioural test: there is no behaviour to test. Its negatives are proven by `bash tests/run.sh --self-test`, where a missing `LICENSE`, a missing cited image, an added `.DS_Store` and an added `.env` each make the run fail.

## Structure

```
README.md      this file
LICENSE        MIT, Copyright (c) 2023 André Neto
tests/run.sh   reference and hygiene checks for this repository
```

## License

MIT — Copyright (c) 2023 André Neto, the year of the first commit. See [LICENSE](LICENSE). No third-party code is redistributed here, so the whole repository is covered by that one licence.
