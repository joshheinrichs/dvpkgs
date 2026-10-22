# rustc + cargo + std from the rustc-src tarball, x.py driven by `rust-bootstrap` (upstream
# binaries, build-only), codegen through our libLLVM.
def package(c):
    build = c.buildPkgs
    return c.package(
        name = "rust",
        dependencies = [c.pkgs.llvm22],  # the major rustc bundles and is tested with. Ours is one ahead
        # cross: stage1 runs here and links the build machine's libLLVM
        buildDependencies = c.on(c.platform.cross, [build.llvm22]) + [
            build["rust-bootstrap"],
            build.cpython,
            build.cmake,
            build.ninja,
            build.pkgconf,
        ],
        phases = ["rust.configure", "rust.build", "rust.install"],
        tests = {"run": False, "version": "-V"},  # x.py test: hours
        bin = ["rustc", "cargo"],
        exports = False,
    )
