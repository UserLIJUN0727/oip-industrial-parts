# My Industrial Parts Library

This is a personal Open Industry Project (OIP) part library. The library currently collects five user-created 3D equipment models:

| Part | Library ID | Current behavior |
|---|---|---|
| CNC Lathe | `userlijun0727.cnc-lathe` | Static teaching model |
| Compact STS Crane | `userlijun0727.compact-sts-crane` | Static model; trolley/spreader do not move |
| Tow Tractor AGV | `userlijun0727.agv-tow-tractor` | Static model |
| Lift AMR | `userlijun0727.lift-amr` | Static model; lift does not animate |
| Three-Floor Elevator | `userlijun0727.three-floor-elevator` | Moving cabin and articulated doors; see the independent training scene |

Each published `.oippart` is a portable OIP package containing its manifest, behavior source, and model assets. The original imported part folders are preserved under `source/`; the package builder never changes those source manifests. License metadata is currently **All rights reserved** for both code and model assets; no open-use license is granted.

## Training scenes

The repository is public. These OIP training projects are kept in separate folders so they can be downloaded and opened independently:

- [Vision Sorting Demo](scenes/vision-sorting-demo/README.md) — simulated RGB sorting, palletizing, wrapping, and AGV delivery.
- [Four-Way Traffic Intersection](scenes/traffic-light-intersection/README.md) — a two-road signal cycle with a reusable intersection model.
- [Three-Floor Elevator Demo](scenes/three-floor-elevator-demo/README.md) — PLC-controlled cabin movement, floor calls, doors, and emergency-stop recovery.

The Vision Sorting Demo and Four-Way Traffic Intersection have scoped MIT licenses. The elevator scene and its custom part follow the repository-root library license stated above; the scoped MIT licenses do not change the rights for the library models. The scene folders that include unmodified OIP component copies carry separate third-party notices.

## Add future parts

1. Copy a new OIP part folder (it must contain `manifest.json`, `behavior.js`, and its `assets/` files) into a new folder under `source/`, using a unique lowercase folder slug.
2. Add `library-entry.json` in that folder with a unique ID under `userlijun0727.`, a display name, category, and a plain-text description. The behavior must use the OIP SDK lifecycle (`step(ctx)`; a static part may use an empty `step()`).
3. Build and verify the library:

   ```powershell
   node tools/build-library.mjs . "<OIP-source-root>"
   ```

The builder appends a new, hash-named version only when a part changes; it does not overwrite earlier versions. After the library is hosted, push the updated `index.json` and `.oippart` file, then use the same `index.json` URL in OIP's **Get Parts → Add library**. Pick the part and choose **Add to project**. OIP does not automatically add parts to every new project.

## Hosting status

Public repository: https://github.com/UserLIJUN0727/oip-industrial-parts

Existing parts library URL: https://raw.githubusercontent.com/UserLIJUN0727/oip-industrial-parts/main/index.json

The traffic-intersection model has a separate scoped OIP library index at `scenes/traffic-light-intersection/part-library/index.json`. The Vision Sorting Demo is a project assembly rather than a standalone custom mesh; its full project and part copies are in `scenes/vision-sorting-demo/`.
