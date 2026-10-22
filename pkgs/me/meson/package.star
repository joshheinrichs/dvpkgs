def package(c):
    return c.package(
        name = "meson",
        uses = ["python"],
        python = {"module": "mesonbuild"},
        buildDependencies = [c.buildPkgs["python-setuptools"]],
        # bin/meson is `#!.../python3`: the interpreter is a run-time dependency, found via the launcher
        dependencies = [c.pkgs.cpython],
    )
