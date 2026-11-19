# Campus explorer assets

The user placed the authorized GLBs in this folder on 2026-10-04.

- `tsudanuma-campus.glb`: 4,139,212 bytes
- `shinnarashino-campus.glb`: 10,311,688 bytes

Both are valid GLB v2 (Khronos validator: no errors or warnings). Coordinates:
Y-up, X-east, -Z-north. Exterior shapes and heights include estimates.

`viewer.html` and `campus_engine.js` render the same models in free-camera,
ground-car and aircraft modes. Vehicle geometry is procedural. Building bounds
and ground raycasts provide approximate movement constraints, not realistic
vehicle physics or real-world road guidance.

Source, locked dependencies, build script and motion tests live in
`tools/campus_3d/`. Rebuild with `npm ci --prefix tools/campus_3d` followed by
`npm run build --prefix tools/campus_3d`. Preserve the generated license notice.

See `docs/CAMPUS_3D_MAP.md` for screenshots, validation and limitations.
