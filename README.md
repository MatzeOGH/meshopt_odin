# meshopt_odin

[Odin](https://odin-lang.org/) bindings for
[meshoptimizer](https://github.com/zeux/meshoptimizer). GitHub Actions makes the
bindings and keeps them current.

CI builds every part of this repository from a pinned meshoptimizer release.
This includes the native libraries for Windows, Linux, macOS and wasm32, and
also the `.odin` bindings. When a new meshoptimizer release appears, the
bindings regenerate without manual work.

## Usage

The bindings are in [`meshopt/`](meshopt/) as `package meshopt`. One prebuilt
library per platform is included. Point an Odin collection at the folder, or copy
the folder into your project, then import it:

```odin
import meshopt "path/to/meshopt"

// Names have the `meshopt_` prefix stripped:
h := meshopt.quantizeHalf(1.0)
count := meshopt.generateVertexRemap(/* ... */)
```

The library is self-contained C. meshoptimizer uses C++ internally, but each
library here includes a small shim for `operator new` and `operator delete`, and
the build disables thread-safe static guards. Thus you do not link a C++ runtime
(libstdc++ or libc++). Import the package and build.

| Platform      | Library               |
| ------------- | --------------------- |
| Windows (x64) | `meshopt_windows.lib` |
| Linux (x64)   | `meshopt_linux.a`     |
| macOS         | `meshopt_macos.a` (universal: arm64 + x86_64) |
| wasm32        | `meshopt_wasm.o`      |

### Download

Each [Release](../../releases) includes a complete package. The layout is the
same as the vendored packages of Odin. The file `meshopt-odin-<version>.zip`
(and the equivalent `.tar.gz`) contains one `meshopt/` directory with the
bindings and all four prebuilt binaries. Copy that directory into your project,
or into the `vendor/` directory of Odin, then import it. No build step is
necessary.

### WebAssembly

The wasm build uses plain `odin build`. Emscripten and the WASI SDK are not
necessary:

```bash
odin build your_project -target:js_wasm32     # or -target:wasi_wasm32
```

Clang compiles `meshopt_wasm.o` against
[`vendor:libc-shim`](https://github.com/odin-lang/Odin/tree/master/vendor/libc-shim)
of Odin as its sysroot. The shim supplies `malloc`, the `mem*` routines and the
math functions. The packages `vendor:cgltf`, `vendor:box2d` and `vendor:stb` use
the same method. The file `meshopt/wasm.odin` adds that package to the link for
you. The shim does not contain three float routines that meshoptimizer needs
(`frexpf`, `ldexpf` and `log2f`). The file `scripts/wasm_shim.cpp` supplies them.

Use the wasm32 targets. `meshopt_wasm.o` is a wasm32 object, and clang has no
triple that matches the ABI of wasm64p32 (32-bit pointers with a 64-bit
`size_t`). A wasm64p32 build links with signature mismatch warnings from
`wasm-ld`, and then it traps at runtime. `freestanding_wasm32` also fails,
because `vendor:libc-shim` itself does not compile for freestanding targets.

## How the automation works

Two workflows do all the work.

### [`Generate bindings`](.github/workflows/generate.yml)

This is the main pipeline. Start it manually from the **Actions** tab
(`workflow_dispatch`). You can give it a meshoptimizer `version`, for example
`v1.2`. An empty value selects the latest release. The pipeline does these steps:

1. **Build** a self-contained library on `windows-latest`, `ubuntu-latest` and
   `macos-latest`, and also a wasm32 object. The build compiles every
   `meshoptimizer/src/*.cpp` file. It globs the file list instead of a hardcoded
   list, so upstream refactors do not break it.
2. **Generate** the bindings with
   [odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen). The file
   [`bindgen.sjson`](bindgen.sjson) controls the generator.
3. **Verify** the bindings. The job builds and runs [`test/`](test/main.odin)
   against the new library, first natively, then as `wasi_wasm32` under the WASI
   runtime of Node. Thus the wasm target must run, and not only link.
4. **Commit** the new `meshopt/` directory and write the bound version into
   `.meshopt-version`. Then **publish a release** with the packaged bindings.

### [`Check upstream`](.github/workflows/check-upstream.yml)

This workflow runs each week, and also on demand. It compares the latest
meshoptimizer release against `.meshopt-version`. If the two versions differ, it
calls `Generate bindings` for the new version. Thus the repository tracks
upstream automatically.

## Bootstrap of a fork

A new fork or an empty repository has no bindings. Enable Actions, then start
**Generate bindings** one time (Actions → Generate bindings → Run workflow). The
workflow fills the `meshopt/` directory and makes the first release. After that,
`Check upstream` keeps the repository current.

> Actions must have write access to push the generated bindings. Set it at
> **Settings → Actions → General → Workflow permissions → Read and write
> permissions**.

## Local build

You can build the library for one platform without CI. You need a C++ compiler:

```bash
git clone --depth 1 --branch v1.2 https://github.com/zeux/meshoptimizer
bash scripts/build_linux.sh      # or build_macos.sh
# Windows (from a VS developer prompt):
#   pwsh -File scripts/build_windows.ps1
```

The wasm object also needs Odin on `PATH`, because the build reads the
`vendor:libc-shim` sysroot from there. It also needs `wasm-ld` from lld of LLVM:

```bash
bash scripts/build_wasm.sh
```

The generation step also needs [Odin](https://odin-lang.org/) and
[odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen). For the exact
steps, read the `bindings` job in
[`generate.yml`](.github/workflows/generate.yml).

## Configuration

[`bindgen.sjson`](bindgen.sjson) and [`imports.odin`](imports.odin) control the
shape of the bindings: the renames, the bit sets, the removal of prefixes, and
the imports for each platform. The build flags are in [`scripts/`](scripts/).

## License

MIT. Read [LICENSE](LICENSE). meshoptimizer is © 2016-2025 Arseny Kapoulkine,
also MIT.
