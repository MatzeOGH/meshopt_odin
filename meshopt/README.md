# Generated bindings

CI generates almost all of this folder. Do not edit those files by hand. The one
exception is `wasm.odin`. It is hand-written and committed to the repository.

The [`Generate bindings`](../.github/workflows/generate.yml) workflow creates
these files:

- `meshoptimizer.odin` — the Odin bindings (`package meshopt`), generated
- `wasm.odin` — hand-written. It adds `vendor:libc-shim` to a wasm build
- `meshopt_windows.lib` — static library for Windows (x64)
- `meshopt_linux.a` — static library for Linux (x64)
- `meshopt_macos.a` — universal static library for macOS (arm64 + x86_64)
- `meshopt_wasm.o` — relocatable object for wasm32

To use the package in your project, point an Odin collection at this folder, or
use a relative import. Read the [top-level README](../README.md).
