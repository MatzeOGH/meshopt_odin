#+build wasm32
package meshopt

// meshopt_wasm.a is compiled with Odin's vendor:libc-shim as its sysroot (see
// scripts/build_wasm.sh), so the shim has to be part of the link: it supplies
// malloc/free, the mem* routines, the math functions and the assert handler
// that the archive leaves undefined.
//
// This file is hand-written, not generated -- odin-c-bindgen only ever writes
// meshoptimizer.odin. Odin forbids `import` inside a `when`, so the pull-in
// needs its own #+build-tagged file, exactly like vendor:cgltf's cgltf_wasm.odin.
@(require) import _ "vendor:libc-shim"
