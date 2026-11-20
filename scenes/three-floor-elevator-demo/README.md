# Three-Floor Elevator Demo

An Open Industry Project (OIP) training project for a three-level elevator. It includes a detailed shaft and cabin, three landing-door sets, floor call buttons, status lights, an IEC Structured Text program, and regression tests.

## Open and run

1. Download or clone this repository.
2. In OIP, open the `scenes/three-floor-elevator-demo/` project folder.
3. Press **F5** to run the built-in simulation. Use the floor call buttons or edit the target-floor tag in the PLC panel.

## Included control behavior

- Calls select floor 1, 2, or 3; the PLC moves the cabin to the requested floor and opens the doors.
- Floor-position, moving, door, and fault states are exposed as PLC tags.
- Emergency stop inhibits queued motion; after the stop is released and reset, a new request can be served.

## Verification boundary

The OIP headless project validator accepted the saved project in strict mode. Both listed simulation tests passed: a floor-3 request reached floor 3 and opened the doors, and the emergency-stop test blocked motion before recovering to floor 3. This verifies OIP's built-in simulation only. TIA Portal, S7-PLCSIM, a physical elevator, and any real PLC were not connected or tested.

## Files and library

- `project.json`, `scene.json`: project configuration and 3D layout.
- `parts/user.three-floor-elevator/`: custom 3D geometry and simulation behavior.
- `plc/program.st`: IEC Structured Text control logic.
- `tests/`: the two regression cases listed in `project.json`.
- `parts/oip.*`: copied OIP built-in push-button and stack-light parts; see `THIRD_PARTY_NOTICES.md`.

The custom part is also published in the repository's main OIP parts library. In **Get Parts → Add library**, use:

`https://raw.githubusercontent.com/UserLIJUN0727/oip-industrial-parts/main/index.json`

The published library part ID is `userlijun0727.three-floor-elevator`.

## License

The custom elevator model and this project follow the license stated in the repository-root `index.json` (`All rights reserved`). The copied OIP built-in parts retain their upstream MIT license, reproduced in `Open-Industry-Project-MIT.txt`.
