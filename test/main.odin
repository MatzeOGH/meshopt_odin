// Smoke test compiled and linked by the "Generate bindings" workflow to verify
// that the generated bindings link against the freshly built static library.
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
}
