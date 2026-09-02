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
}
