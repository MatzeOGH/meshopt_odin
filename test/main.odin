// Smoke test compiled and linked by the "Generate bindings" workflow to verify
// that the generated bindings link against the freshly built native library.
//
// On the wasm target it doubles as a check of the libc wiring: meshoptimizer
// gets its libc from Odin's vendor:libc-shim there (see scripts/build_wasm.sh),
// so the cases below deliberately reach the allocator and the float math
// routines rather than only calling leaf functions.
package test

import "core:fmt"
import meshopt "../meshopt"

main :: proc() {
	// quantizeHalf is a simple scalar-only exported function: exercising it
	// proves the binding declaration and the native library link correctly.
	h := meshopt.quantizeHalf(1.0)
	back := meshopt.dequantizeHalf(h)
	fmt.printfln("quantizeHalf(1.0) = 0x%04x -> %v", h, back)
	assert(back == 1.0, "half round-trip of 1.0 must be exact")

	// The simplification options come from an anonymous C enum that has to be
	// deanonymized before it can be turned into a bit_set (see bindgen.sjson).
	// Referencing the type keeps the generated declaration honest, and checking
	// the bit pattern proves the bit_set still maps onto the C flag values
	// (meshopt_SimplifyLockBorder = 1 << 0, meshopt_SimplifySparse = 1 << 1).
	opts := meshopt.Simplify_Options{.LockBorder, .Sparse}
	fmt.printfln("Simplify_Options{{.LockBorder, .Sparse}} = 0x%x", transmute(u32)opts)
	assert(transmute(u32)opts == 0x3, "simplify option flags must match the C bit values")

	// The exponential filter splits floats with frexpf and rebuilds them with
	// ldexpf -- neither is part of vendor:libc-shim, so on wasm this runs the
	// implementations in scripts/wasm_shim.cpp.
	src := [4]f32{1.0, -2.5, 0.125, 1024.0}
	buf := src
	meshopt.encodeFilterExp(&buf, 1, 16, 15, &src[0], .Separate)
	meshopt.decodeFilterExp(&buf, 1, 16)
	fmt.printfln("encode/decodeFilterExp %v -> %v", src, buf)
	for i in 0 ..< len(src) {
		tol := abs(src[i]) * 1e-3 + 1e-6
		assert(abs(buf[i] - src[i]) <= tol, "exponential filter round-trip lost too much precision")
	}

	// simplify allocates its working set through meshoptimizer's internal
	// allocator, which bottoms out in operator new/delete -> malloc/free, and
	// leans on sqrtf. This is the case that fails if the libc wiring is wrong.
	GRID :: 5
	positions: [GRID * GRID][3]f32
	for y in 0 ..< GRID {
		for x in 0 ..< GRID {
			positions[y * GRID + x] = {f32(x), f32(y), 0}
		}
	}

	indices: [dynamic]u32
	defer delete(indices)
	for y in 0 ..< GRID - 1 {
		for x in 0 ..< GRID - 1 {
			a := u32(y * GRID + x)
			b := a + 1
			cc := a + GRID
			d := cc + 1
			append(&indices, a, cc, b, b, cc, d)
		}
	}

	result := make([]u32, len(indices))
	defer delete(result)

	error: f32
	count := meshopt.simplify(
		raw_data(result), raw_data(indices), len(indices),
		&positions[0][0], len(positions), size_of([3]f32),
		len(indices) / 2, 1e-2, {}, &error,
	)
	fmt.printfln("simplify: %v indices -> %v (error %v)", len(indices), count, error)
	assert(count <= len(indices), "simplify must not grow the index buffer")
	assert(count % 3 == 0, "simplify must return whole triangles")
	assert(count > 0, "simplify must return a usable mesh")
}
