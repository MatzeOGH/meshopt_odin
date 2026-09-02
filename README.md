# meshopt_odin

Automated [Odin](https://odin-lang.org/) bindings for
[meshoptimizer](https://github.com/zeux/meshoptimizer), generated and kept up to
date entirely by GitHub Actions.

Unlike a hand-maintained binding, everything here — the native static libraries
for Windows, Linux and macOS **and** the `.odin` bindings — is produced by CI
from a pinned meshoptimizer release. When upstream ships a new release, the
bindings regenerate on their own.

## Usage

The bindings live in [`meshopt/`](meshopt/) as `package meshopt` and ship with a
prebuilt static library per platform. Point an Odin collection at the folder (or
vendor it into your project) and import it:

```odin
import meshopt "path/to/meshopt"

// Names have the `meshopt_` prefix stripped:
h := meshopt.quantizeHalf(1.0)
count := meshopt.generateVertexRemap(/* ... */)
```

The library is **self-contained C** — although meshoptimizer is implemented in
C++, the shipped archives bundle a tiny `operator new`/`delete` shim and disable
thread-safe static guards, so **no C++ runtime** (libstdc++ / libc++) needs to
be linked. Just import and build.

| Platform      | Library               |
| ------------- | --------------------- |
| Windows (x64) | `meshopt_windows.lib` |
| Linux (x64)   | `meshopt_linux.a`     |
| macOS         | `meshopt_macos.a` (universal: arm64 + x86_64) |

Prebuilt libraries are also attached to each [Release](../../releases).

## How the automation works

Two workflows drive everything:

### [`Generate bindings`](.github/workflows/generate.yml)

The core pipeline. Run it manually from the **Actions** tab
(`workflow_dispatch`), optionally passing a meshoptimizer `version` (e.g. `v1.2`;
empty = latest release). It:

1. **Builds** a self-contained static library on `windows-latest`,
   `ubuntu-latest` and `macos-latest` by compiling every `meshoptimizer/src/*.cpp`
   (the file list is globbed, not hardcoded, so it survives upstream refactors).
2. **Generates** the bindings with
   [odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen), driven by
   [`bindgen.sjson`](bindgen.sjson).
3. **Verifies** the bindings compile and link by building [`test/`](test/main.odin)
   against the freshly built library.
4. **Commits** the updated `meshopt/` and records the bound version in
   `.meshopt-version`, then **publishes a Release** with the libraries attached.

### [`Check upstream`](.github/workflows/check-upstream.yml)

Runs weekly (and on demand). It compares meshoptimizer's latest release against
`.meshopt-version` and, when they differ, calls `Generate bindings` for the new
version — so the repo tracks upstream automatically.

## Bootstrapping a fork

A freshly forked/empty repo has no bindings yet. Enable Actions, then trigger
**Generate bindings** once (Actions → Generate bindings → Run workflow). It will
populate `meshopt/` and cut the first release. From then on `Check upstream`
keeps it current.

> Actions needs write access to push the generated bindings: **Settings → Actions
> → General → Workflow permissions → Read and write permissions**.

## Building locally

You can reproduce a platform's library without CI (requires a C++ compiler):

```bash
git clone --depth 1 --branch v1.2 https://github.com/zeux/meshoptimizer
bash scripts/build_linux.sh      # or build_macos.sh
# Windows (from a VS developer prompt):
#   pwsh -File scripts/build_windows.ps1
```

The generation step additionally needs [Odin](https://odin-lang.org/) and
[odin-c-bindgen](https://github.com/karl-zylinski/odin-c-bindgen); see the
`bindings` job in [`generate.yml`](.github/workflows/generate.yml) for the exact
steps.

## Configuration

Binding shape (renames, bit-sets, prefix stripping, per-platform imports) is
controlled by [`bindgen.sjson`](bindgen.sjson) and
[`imports.odin`](imports.odin). Build flags live in [`scripts/`](scripts/).

## License

MIT — see [LICENSE](LICENSE). meshoptimizer is © 2016-2025 Arseny Kapoulkine,
also MIT.
