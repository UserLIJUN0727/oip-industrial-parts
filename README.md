# My Industrial Parts Library

This is a personal Open Industry Project (OIP) part library. The first release collects four user-created 3D equipment models:

| Part | Library ID | Current behavior |
|---|---|---|
| CNC Lathe | `userlijun0727.cnc-lathe` | Static teaching model |
| Compact STS Crane | `userlijun0727.compact-sts-crane` | Static model; trolley/spreader do not move |
| Tow Tractor AGV | `userlijun0727.agv-tow-tractor` | Static model |
| Lift AMR | `userlijun0727.lift-amr` | Static model; lift does not animate |

Each published `.oippart` is a portable OIP package containing its manifest, behavior source, and model assets. The original imported part folders are preserved under `source/`; the package builder never changes those source manifests. License metadata is currently **All rights reserved** for both code and model assets; no open-use license is granted.

## Add future parts

1. Copy a new OIP part folder (it must contain `manifest.json`, `behavior.js`, and its `assets/` files) into a new folder under `source/`, using a unique lowercase folder slug.
2. Add `library-entry.json` in that folder with a unique ID under `userlijun0727.`, a display name, category, and a plain-text description. The behavior must use the OIP SDK lifecycle (`step(ctx)`; a static part may use an empty `step()`).
3. Build and verify the library:

   ```powershell
   node tools/build-library.mjs . "<OIP-source-root>"
   ```

The builder appends a new, hash-named version only when a part changes; it does not overwrite earlier versions. After the library is hosted, push the updated `index.json` and `.oippart` file, then use the same `index.json` URL in OIP's **Get Parts → Add library**. Pick the part and choose **Add to project**. OIP does not automatically add parts to every new project.

## Hosting status

Local library prepared. A GitHub URL is not included yet because the repository's public/private visibility has not been confirmed. OIP's external-library URL must be reachable by the app; a public raw GitHub `index.json` URL is the simplest option. Do not publish this folder publicly until the owner approves public visibility.
