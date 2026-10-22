# Builder behaviour: every directory here is a test. Its test.nu runs under the seed's nu with
# builder/ and lib/ on the include path and $env.fixtures set to the directory. One with a
# package.star is first built as out-of-tree package test-<name> ($env.pkg, $env.debug), so each
# test needs only its own toolchain.
#   dv instantiate tests/builder/default.star --root . -A checks.cc
load("//bootstrap/default.star", "bootstrap")
load("//nix/set.star", "package_set")

_HERE = "//tests/builder"

def _tests():
    return sorted([n for n, t in read_dir(_HERE).items() if t == "directory" and n != "lib"])

def _is_package(n):
    return path_exists("%s/%s/package.star" % (_HERE, n))

def _set_args(system, platform):
    # as test-<name>: a bare `go` would replace the set's go, which the go build system runs
    return dict(
        system = system,
        platform = platform,
        packages = {"test-" + n: "%s/%s" % (_HERE, n) for n in _tests() if _is_package(n)},
    )

def check(name, args):
    system = args["system"]
    pkgs = package_set(**_set_args(system, args["platform"]))
    seed = force(bootstrap(system).seed)
    d = path("%s/%s" % (_HERE, name))
    attrs = dict(
        name = "check-" + name,
        system = system,
        __contentAddressed = True,
        outputHashMode = "recursive",
        outputHashAlgo = "sha256",
        PATH = "%s/bin" % seed,
        fixtures = d,
        builder = "%s/bin/nu" % seed,
        # nu separates include dirs with \x1e
        args = [
            "--no-config-file",
            "--include-path=%s\x1e%s" % (path("//builder"), path(_HERE + "/lib")),
            d + "/test.nu",
        ],
    )
    if _is_package(name):
        pkg = getattr(pkgs, "test-" + name)
        attrs.update(pkg = pkg, debug = pkg.debug, src = d + "/src")
    return derivation(**attrs)

def make_checks(system = None, platform = None):
    system = system or current_system()
    return lazy_attrs(check, {"system": system, "platform": platform or system}, names = _tests())

checks = make_checks()
