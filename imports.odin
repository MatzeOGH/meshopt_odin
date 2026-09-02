// This block is inlined verbatim at the top of the generated bindings
// (meshopt/meshoptimizer.odin) by odin-c-bindgen.
//
// meshoptimizer exposes a pure C API. Although its implementation is C++, the
// static libraries shipped here are fully self-contained: a small shim provides
// operator new/delete (backed by malloc/free) and thread-safe static guards are
// disabled, so no C++ runtime (libstdc++/libc++) needs to be linked.
when ODIN_OS == .Windows {
	foreign import lib "meshopt_windows.lib"
} else when ODIN_OS == .Darwin {
	foreign import lib "meshopt_macos.a"
} else when ODIN_OS == .Linux {
	foreign import lib "meshopt_linux.a"
} else {
	#panic("meshopt: unsupported platform")
}
