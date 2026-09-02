// This block is inlined verbatim at the top of the generated bindings
// (meshopt/meshoptimizer.odin) by odin-c-bindgen.
//
// meshoptimizer exposes a pure C API. Although its implementation is C++, the
// static libraries shipped here are fully self-contained: a small shim provides
// operator new/delete (backed by malloc/free) and thread-safe static guards are
// disabled, so no C++ runtime (libstdc++/libc++) needs to be linked.
//
// The wasm object is built against Odin's own vendor:libc-shim as its sysroot,
// so it needs that package linked in as well. Odin does not allow `import`
// inside a `when`, so that pull-in lives in the hand-written meshopt/wasm.odin
// instead -- the same arrangement vendor:cgltf uses.
// NOTE: this deliberately does not try to exclude the wasm64p32 targets.
// meshopt_wasm.o is a wasm32 object and clang has no triple matching
// wasm64p32's ABI (32-bit pointers, 64-bit size_t), but the compiler currently
// reports ODIN_ARCH as .wasm32 for those targets too, so they cannot be told
// apart here. Building for wasm64p32 links with signature-mismatch warnings
// from wasm-ld and traps at runtime. Use wasm32. vendor:cgltf has the same
// caveat.
when ODIN_ARCH == .wasm32 {
	foreign import lib "meshopt_wasm.o"
} else when ODIN_OS == .Windows {
	foreign import lib "meshopt_windows.lib"
} else when ODIN_OS == .Darwin {
	foreign import lib "meshopt_macos.a"
} else when ODIN_OS == .Linux {
	foreign import lib "meshopt_linux.a"
} else {
	#panic("meshopt: unsupported platform")
}
