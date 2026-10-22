# dvpkgs

[repkgs](https://github.com/Mic92/repkgs) written in Starlark and evaluated by
[dv](https://github.com/joshheinrichs/dv) instead of the Nix evaluator. The store, the derivations and the builders are the
same: every package instantiates to the same `.drv` as `nix-instantiate` does on repkgs.

repkgs is an experimental package set: one LLVM toolchain for every platform, relocatable
outputs, nushell builders, a compile cache below Nix and a short bootstrap from a static seed.
[docs/design.md](docs/design.md) explains why. Those docs describe the Nix version; the
packages and builder/ are the same here.

## Status

Works, and is checked against repkgs:

- All 198 packages, their separate test suites, tests/builder's packages and `bundle`
  instantiate to the `.drv` paths `nix-instantiate` gives on repkgs. That holds for
  x86_64-linux and cross to riscv64-linux, aarch64-linux, x86_64-windows-gnu,
  x86_64-windows-msvc and aarch64-macos. Unsupported packages agree on `supported`, and the
  one package Nix fails on (openblas on windows and macOS, for want of flang-rt) fails here too.
  `tools/parity [PLATFORM…]` checks it again (`REPKGS`, `DV`, `STORE` in its header).
- The whole set evaluates in about 30 ms on 16 threads (70 ms on one), release build. A second
  run takes its results from dv's cache. Editing one package re-evaluates that package, plus
  its dependents only if its derivation changed.

Not yet:

- **Building.** dv computes the derivations but does not yet write them to the store (the
  daemon protocol is the next piece of dv). Until then `nix-build` on repkgs is how to build.
- tools/repkgs, lints/ and bench/ still call Nix on repkgs. nix/checks.nix (the CI matrix)
  and pkgs/se/seed/build.nix (the seed, built with nixpkgs) were not ported.
- `overrides`, `features` and out-of-tree `packages` are arguments of `package_set()` in
  Starlark. There is no command line flag for them yet.

## Evaluating

```console
$ dv instantiate default.star -A pkgs.jq                     # the .drv path
$ dv instantiate default.star -A pkgs.jq -A pkgs.ripgrep     # several, in parallel
$ dv instantiate default.star -A pkgs.jq.tests -A pkgs.libiconv.supported
$ dv --stats instantiate default.star -A pkgs.jq             # how much came from the cache
```

Another platform is another set, from a file of your own:

```python
load("//nix/set.star", "package_set")
pkgs = package_set(platform = "riscv64-linux")
```

```console
$ dv instantiate --root ~/dvpkgs riscv.star -A pkgs.jq
```

## Writing a package

A package is a directory with two files:

```
pkgs/li/libpng/
├── package.star    how to build it
└── sources.toml    where it comes from: upstream id, URL template, pinned version and hash
```

```python
def package(c):
    return c.package(
        name = "libpng",
        uses = ["cmake"],
        cmake = {"defs": {"PNG_STATIC": False, "PNG_TOOLS": True}},
        dependencies = [c.pkgs.zlib],
    )
```

`c` is what the set hands every package: `c.package` (spec -> package), `c.variant`,
`c.pkgs` and `c.buildPkgs`, `c.platform`, `c.toolchain`, `c.sources` (this directory's
sources.toml), `c.fetch` (lock-file fetchers), `c.on`, `c.lib` and `c.features`. A name with a
dash is read with `c.pkgs["cmake-bootstrap"]`. Packages are lazy: `c.pkgs.zlib` is evaluated
when something uses it, once, on whichever thread gets there first.

`sources.toml` supplies version and tarball. `uses` names the build system, and the build
system brings its tools, its phases (configure, build, test, install) and its options. Options
are things like `cmake.defs` above, `cargo.features` or `go.tags`. Every build system also takes
`<name>.tool` to swap the program itself (`"cargo": {"tool": c.buildPkgs["rust-bootstrap"]}`).
Names and types are checked at evaluation time, so a typo is an error instead of an attribute
nobody reads.

A package with build-time tools and its tests turned off, curl:

```python
def package(c):
    return c.package(
        name = "curl",
        uses = ["cmake"],
        cmake = {"defs": {"CURL_USE_OPENSSL": True, "CURL_CA_PATH": "/etc/ssl/certs"}},
        dependencies = [c.pkgs.openssl, c.pkgs.zlib, c.pkgs.zstd],  # linked, target platform
        buildDependencies = [c.buildPkgs.perl],  # run during the build, build platform
        tests = {"run": False},  # the suite wants python and minutes
    )
```

Dependencies are found through the ordinary search paths (`-I`, `-L`, pkg-config, cmake), so
the package says nothing more about them. `patches = [path("x.patch")]` are applied after
unpacking; `path()` copies a file beside package.star to the store. `bin = ["rg"]` names the
executables when they differ from the package name.

Lock files need no translation. For Cargo, Go, npm, pnpm, Yarn, Bundler, Deno, Hex, Hackage
and LuaRocks, the lock file in the source is turned into fixed-output fetches at build time, by
a dynamic derivation, with the hashes the lock file already has. Where it has none (Go,
Hackage, LuaRocks) they are kept in `locks/*.toml`.

`phases` edits the build system's list: `before.<phase>`, `after.<phase>`, `replace.<phase>`
take a phase or a list, `remove` a list. A phase is one of a build system's or a piece of nu
with a name. Inside the nu, `$c` holds the paths and facts of the build (`$c.out`, `$c.src`,
`$c.build`, `$c.njobs`, `$c.platform`):

```python
phases = {
    "after": {"autotools.install": {"name": "sh-alias", "run": '^ln -s bash $"($c.out)/bin/sh"'}},
    "replace": {"autotools.configure": "perl.configure"},
    "remove": ["cargo.test"],
}
```

Longer nu goes in `c.lib.text("""…""")`, which strips the common indentation the way a Nix
`''` string does. A phase `"rust.configure"` whose prefix is no build system is `rust.nu` next
to package.star (pkgs/ru/rust).

Something Nix would only evaluate on some platforms, like a string naming `c.buildPkgs.x`
when cross compiling, belongs behind an `if`: `c.on(cond, value)` evaluates `value` either
way.

Choices a user may want to make differently are features, declared at the top of package.star
and read back as `c.features`:

```python
FEATURES = {
    "tls": {"values": ["openssl", "gnutls", "none"], "default": "openssl", "doc": "TLS backend"},
    "http3": {"default": False},
}

def package(c):
    tls = c.features["tls"]
    return c.package(
        name = "curl",
        dependencies = c.on(tls != "none", [c.pkgs[tls]]) + c.on(c.features["http3"], [c.pkgs.ngtcp2]),
        cmake = {"defs": {"USE_NGTCP2": c.features["http3"]}},
    )
```

`package_set(features = {"tls": "gnutls"})` sets one for every package that declares it,
`package_set(overrides = {"curl": {"features": {"http3": True}}})` for curl alone.

The rest of the vocabulary (`prebuilt`, `install`, `completions`, `exports`, `tests.separate`,
`cc.hardening` …) is repkgs', described in its README.

## Repository layout

```
pkgs/xx/<name>/   the packages, xx being the first two letters
bootstrap/        seed → stage0 (musl cc) → stage1 (llvm) → stage2 (cc, one per platform)
nix/              evaluation, *.star: set.star is the set, package.star turns a spec into a
                  derivation, build_systems.star defines each `uses` entry, fetch.star the
                  lock-file fetchers. The directory keeps its name: builder/ refers to it
builder/          build time. prepare, finish, and one nu module per build system
locks/            hashes that lock files lack (go.sum, hackage, luarocks)
tests/builder/    tiny packages per language that check what builder/ does to them
docs/             repkgs' design.md (why), uptrack.md, plan.md
```

builder/, the patches, sources.toml files and recipes are byte for byte repkgs': their store
hashes are part of every derivation.

## License

MIT, see [LICENSE](LICENSE). Patches under `pkgs/` carry the license of the project they apply to.
