# std for the target triple, built by the finished rust (x.py, library only) and linked with the
# target cc. cargo.nu overlays it on rust's sysroot when cross compiling
def package(c):
    return c.variant(c.pkgs.rust, {
        "dependencies": {"set": []},
        "buildDependencies": {"set": [c.buildPkgs.rust, c.buildPkgs.cpython]},
        "phases": {"set": ["rust.stdConfigure", "rust.stdBuild", "rust.stdInstall"]},
        "bin": {"set": []},
        "tests": {"set": {"run": False}},
    })
