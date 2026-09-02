#!/usr/bin/env bash
# Build meshoptimizer for WebAssembly (wasm32).
# Expects meshoptimizer checked out at ./meshoptimizer. Output: build/meshopt_wasm.o
#
# The libc that meshoptimizer needs (malloc, the mem* routines, the math
# functions, assert) comes from Odin's own vendor:libc-shim, used here as a
# clang sysroot -- the same approach vendor:cgltf, vendor:box2d and vendor:stb
# take. That avoids an Emscripten or WASI SDK dependency and keeps the result
# linkable by plain `odin build -target:js_wasm32` / `-target:wasi_wasm32`.
#
# The output is a single relocatable object, not an archive: Odin hands a .o to
# wasm-ld, but a foreign-imported .a is turned into wasm *imports* instead of
# being linked, which silently produces a module with unresolved symbols.
set -euo pipefail
cd "$(dirname "$0")/.."

CXX="${CXX:-clang++}"
ODIN_ROOT="${ODIN_ROOT:-$(odin root)}"

SYSROOT="$ODIN_ROOT/vendor/libc-shim"
if [ ! -d "$SYSROOT/include" ]; then
	echo "vendor:libc-shim not found at $SYSROOT (is ODIN_ROOT correct?)" >&2
	exit 1
fi

# wasm-ld comes with lld of LLVM. setup-odin puts /usr/lib/llvm-<ver>/bin on PATH.
WASM_LD="${WASM_LD:-}"
if [ -z "$WASM_LD" ]; then
	for candidate in wasm-ld wasm-ld-18 /usr/lib/llvm-*/bin/wasm-ld; do
		if command -v "$candidate" >/dev/null 2>&1; then WASM_LD="$candidate"; break; fi
	done
fi
if [ -z "$WASM_LD" ]; then
	echo "wasm-ld not found; install lld (apt-get install lld)" >&2
	exit 1
fi

# gnu++11 rather than c++11: vendor:libc-shim's stdlib.h declares atexit using
# `typeof`, which clang only accepts as a GNU extension.
#
# -mcpu=mvp keeps clang off post-MVP proposals (sign-ext, bulk-memory, ...) so
# the object loads in the widest set of runtimes, matching how meshoptimizer
# builds its own .wasm modules upstream.
#
# -include wasm_libc.h declares the three float math routines that libc-shim
# does not provide. scripts/wasm_shim.cpp defines them.
CXXFLAGS="-std=gnu++11 -O3 -fno-exceptions -fno-rtti -fno-threadsafe-statics"
CXXFLAGS="$CXXFLAGS --target=wasm32 --sysroot=$SYSROOT -mcpu=mvp"
CXXFLAGS="$CXXFLAGS -include scripts/wasm_libc.h"

rm -rf obj && mkdir -p obj build

for f in meshoptimizer/src/*.cpp; do
	echo "compiling $f"
	$CXX $CXXFLAGS -c "$f" -o "obj/$(basename "${f%.cpp}").o"
done

for f in scripts/shim.cpp scripts/wasm_shim.cpp; do
	echo "compiling $f"
	$CXX $CXXFLAGS -c "$f" -o "obj/$(basename "${f%.cpp}").o"
done

"$WASM_LD" --relocatable obj/*.o -o build/meshopt_wasm.o
echo "built build/meshopt_wasm.o"
