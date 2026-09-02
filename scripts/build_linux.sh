#!/usr/bin/env bash
# Build a self-contained static meshoptimizer library for Linux (x64).
# Expects meshoptimizer checked out at ./meshoptimizer. Output: build/meshopt_linux.a
set -euo pipefail
cd "$(dirname "$0")/.."

CXX="${CXX:-clang++}"
CXXFLAGS="-std=c++11 -O3 -fno-exceptions -fno-rtti -fno-threadsafe-statics -fPIC"

rm -rf obj && mkdir -p obj build

for f in meshoptimizer/src/*.cpp; do
	echo "compiling $f"
	$CXX $CXXFLAGS -c "$f" -o "obj/$(basename "${f%.cpp}").o"
done

echo "compiling scripts/shim.cpp"
$CXX $CXXFLAGS -c scripts/shim.cpp -o obj/shim.o

ar rcs build/meshopt_linux.a obj/*.o
echo "built build/meshopt_linux.a"
