# Upstream's static Go toolchain, only ever a buildDependency of pkgs/go/go
def package(c):
    return c.package(
        name = "go-bootstrap",
        source = c.platform.os + "-" + c.platform.cpu,
        # static binaries, nothing to implant: "ldso" just skips debug split and fixup without
        # pulling in formatelf (and thereby rust)
        prebuilt = "ldso",
        install = {".": ["bin", "pkg", "src", "lib", "go.env", "VERSION"]},
        bin = ["go"],
        tests = {"version": "version"},
        exports = False,
    )
