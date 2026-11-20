# Vision Sorting Demo — PLC Sorting and Palletizing

This is an Open Industry Project (OIP) training project. It continuously feeds simulated cartons, classifies them from the simulated RGB sensor values, sends the robot to the matching pallet, and uses the wrapper and AGV to deliver completed pallets to color-matched warehouse bays.

## Open and run

1. Download or clone this repository.
2. In OIP, open the `scenes/vision-sorting-demo/` project folder.
3. Press **F5** to run the built-in simulation.

## What is included

- `project.json` and `scene.json`: the complete project and 3D scene arrangement.
- `parts/`: the project-owned part copies needed to load the scene.
- `plc/program.st`: the simulated IEC Structured Text control program.
- `tests/`: sorting/delivery and emergency-stop-recovery regression cases.

This demonstrates PLC-controlled sorting; it does **not** use a webcam or a computer-vision neural network. The RGB sensor values are simulated. `parts/user.part-2` is a simple 0.6 m cube placeholder, not a color sensor. OIP components in `parts/oip.*` are third-party dependencies; see `THIRD_PARTY_NOTICES.md`.

## Verification boundary

The local OIP physics tests completed 500 simulated seconds: three red, three green, and three blue cartons were sorted, wrapped, and delivered to matching bays; the emergency-stop recovery test also passed. This is evidence from OIP's built-in simulation only. TIA Portal, S7-PLCSIM, real PLCs, camera hardware, and safety-rated circuits were not tested or connected.

## License

The MIT license in this folder applies to the original scene arrangement, PLC program, tests, and original project documentation only. Third-party OIP component copies retain their upstream terms.
