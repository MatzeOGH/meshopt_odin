// Declarations for the handful of libc functions that meshoptimizer uses but
// Odin's vendor:libc-shim does not declare. Force-included (-include) into every
// translation unit of the wasm build. The definitions are in wasm_shim.cpp.
#pragma once

#ifdef __wasm__

extern "C" {
float frexpf(float x, int *exp);
float ldexpf(float x, int exp);
float log2f(float x);
}

#endif
