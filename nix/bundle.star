# bundle drv: a package's output as one self-contained tree (builder/bundle.nu), for
# `repkgs bootstrap`. Nix supplies the closure and checks that no store reference is left.

load("//bootstrap/default.star", "bootstrap")
load("//nix/set.star", "package_set")

def bundle(drv, system = None, seed = None):
    """`drv` (a package of the set for `system`) bundled."""
    system = system or current_system()
    b = bootstrap(system, seed)
    nu = force(b.seed)
    tools = [package_set(system = system, seed = seed).formatelf, b.stage1.llvm, nu]
    tree = path("//builder")
    return derivation(
        name = drv.name + "-bundle",
        system = system,
        __structuredAttrs = True,
        __contentAddressed = True,
        outputHashMode = "recursive",
        outputHashAlgo = "sha256",
        builder = "%s/bin/nu" % nu,
        args = ["--no-config-file", "--include-path=" + tree, path("//builder/bundle.nu", name = "bundle.nu")],
        package = drv,
        exportReferencesGraph = {"closure": [drv]},
        outputChecks = {"out": {"allowedReferences": []}},
        PATH = ":".join(["%s/bin" % t for t in tools]),
    )
