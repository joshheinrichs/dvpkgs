# Node.js LTS with npm. V8, libuv, nghttp2, c-ares, ICU (small) stay bundled; zlib and openssl are ours.
def package(c):
    pkgs = c.pkgs
    return c.package(
        name = "nodejs",
        dependencies = [
            pkgs.zlib,
            pkgs.openssl,
            pkgs.zstd,
            pkgs.brotli,
            pkgs.libuv,
            pkgs.nghttp2,
            pkgs["c-ares"],
            pkgs.sqlite,
        ],
        buildDependencies = [c.buildPkgs.cpython, c.buildPkgs.ninja],
        patches = [
            path("upstream-libcxx-includes.patch"),
            path("upstream-icu-emulator.patch"),
            path("v8-cfi-arm64.patch"),
            path("upstream-highway-rvv-baseline.patch"),
        ],
        phases = ["nodejs.configure", "nodejs.build", "nodejs.install"],
        tests = {"run": False},  # hours
        bin = ["node", "npm", "npx"],
    )
