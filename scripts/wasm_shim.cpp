// libc gap-fillers for the WebAssembly build.
//
// Odin's vendor:libc-shim is used as the sysroot for the wasm target (see
// scripts/build_wasm.sh). It covers nearly everything meshoptimizer needs, but
// it declares only the double-precision ldexp/log2 and has no frexp at all,
// while meshoptimizer calls the float variants in quantization.cpp and
// opacitymap.cpp. Define them here so the archive stays self-contained.
#include <math.h>

#include "wasm_libc.h"

#ifdef __wasm__

// frexpf splits x into a mantissa in [0.5, 1) and an exponent, x = m * 2^exp.
// Done on the bit pattern because the shim has no frexp to delegate to.
extern "C" float frexpf(float x, int *exp)
{
	unsigned int u;
	__builtin_memcpy(&u, &x, 4);
	int ex = int((u >> 23) & 0xff);

	if (ex == 0)
	{
		if (x == 0.f) // +-0 returns 0 with an exponent of 0
		{
			*exp = 0;
			return x;
		}

		// Subnormal: scale into the normal range, then correct the exponent.
		x *= 33554432.f; // 2^25
		__builtin_memcpy(&u, &x, 4);
		ex = int((u >> 23) & 0xff) - 25;
	}
	else if (ex == 0xff) // inf and nan are returned unchanged
	{
		*exp = 0;
		return x;
	}

	*exp = ex - 126;

	// Replace the exponent field with 2^-1 so the mantissa lands in [0.5, 1).
	u = (u & 0x807fffffu) | 0x3f000000u;
	__builtin_memcpy(&x, &u, 4);
	return x;
}

extern "C" float ldexpf(float x, int exp)
{
	return float(ldexp(double(x), exp));
}

extern "C" float log2f(float x)
{
	return float(log2(double(x)));
}

#endif
