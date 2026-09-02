#!/usr/bin/env bash
# Build a self-contained universal (arm64 + x86_64) static meshoptimizer library
# for macOS. Expects meshoptimizer checked out at ./meshoptimizer.
# Output: build/meshopt_macos.a
set -euo pipefail
cd "$(dirname "$0")/.."

CXX="${CXX:-clang++}"
CXXFLAGS="-std=c++11 -O3 -fno-exceptions -fno-rtti -fno-threadsafe-statics -arch arm64 -arch x86_64 -mmacosx-version-min=11.0"

rm -rf obj && mkdir -p obj build

for f in meshoptimizer/src/*.cpp; do
	echo "compiling $f"
	$CXX $CXXFLAGS -c "$f" -o "obj/$(basename "${f%.cpp}").o"
done

echo "compiling scripts/shim.cpp"
$CXX $CXXFLAGS -c scripts/shim.cpp -o obj/shim.o

# libtool is the sanctioned archiver for universal (fat) objects on macOS.
libtool -static -o build/meshopt_macos.a obj/*.o
echo "built build/meshopt_macos.a"
lipo -info build/meshopt_macos.a || true
