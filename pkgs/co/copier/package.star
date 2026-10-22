# a Python application from uv.lock: wheels where the lock has compatible ones, pyyaml from sdist
# against our libyaml (sys-libs), pydantic-core from sdist to exercise Rust sdists (crates
# vendored by fetch/pypi-vendor.nu, maturin + our rustc)
def package(c):
    return c.package(
        name = "copier",
        uses = ["pyapp"],
        pyapp = {
            "check": ["copier"],
            "deps": c.fetch.pythonDeps(
                source = c.sources.fetch("default"),
                python = c.pkgs.cpython,
                sdist = ["pydantic-core"],
            ),
        },
        dependencies = [c.pkgs.cpython],
        env = {"SETUPTOOLS_SCM_PRETEND_VERSION": c.sources.version},
        tests = {"version": True},
    )
