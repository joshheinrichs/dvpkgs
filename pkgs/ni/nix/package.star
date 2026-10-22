def package(c):
    platform, pkgs, build = c.platform, c.pkgs, c.buildPkgs
    x86 = platform.cpu == "x86_64"
    linux = platform.os == "linux"
    defs = {
        "unit-tests": False,
        "functional-tests": False,
        "json-schema-checks": False,
        "doc-gen": False,
        "nix:mimalloc": "enabled",
    }
    defs.update(c.on(x86, {"libutil:cpuid": "enabled"}))
    defs.update(c.on(linux, {"libstore:seccomp-sandboxing": "enabled"}))
    return c.package(
        name = "nix",
        uses = ["meson"],
        meson = {"defs": defs},
        dependencies = [
            pkgs.bzip2,
            pkgs.curl,
            pkgs.libarchive,
            pkgs.openssl,
            pkgs.sqlite,
            pkgs.xz,
            pkgs.zlib,
            pkgs.zstd,
            pkgs["bdw-gc"],
            pkgs.blake3,
            pkgs.boost,
            pkgs.libsodium,
            pkgs.lowdown,
            pkgs.brotli,
            pkgs["nlohmann-json"],
            pkgs.libgit2,
            pkgs.toml11,
            pkgs.editline,
            pkgs.mimalloc,
        ] + c.on(x86, [pkgs.libcpuid]) + c.on(linux, [pkgs.libseccomp]),
        buildDependencies = [build.bison, build.cmake, build.flex],
        patches = [path("upstream-clang23-nodiscard.patch"), path("relocatable.patch")],
        tests = {"run": False},
    )
