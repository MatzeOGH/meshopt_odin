// Self-contained allocation shim so the meshoptimizer static libraries do not
// depend on the C++ runtime (libstdc++ / libc++ / msvcprt).
//
// meshoptimizer's internal temporary allocator defaults to global
// operator new / operator delete. We provide them here backed by malloc/free.
// These objects are only pulled into the archive if meshoptimizer actually
// references the symbols, so the shim is harmless when unused.
#include <stddef.h>
#include <stdlib.h>

void *operator new(size_t n) { return malloc(n ? n : 1); }
void *operator new[](size_t n) { return malloc(n ? n : 1); }

void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p, size_t) noexcept { free(p); }
void operator delete[](void *p, size_t) noexcept { free(p); }
