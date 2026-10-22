def package(c):
    return c.package(
        name = "python-hatch-vcs",
        uses = ["python"],
        python = {"backend": "hatchling", "module": "hatch_vcs"},
        buildDependencies = [c.buildPkgs["python-hatchling"]],
        dependencies = [c.pkgs["python-setuptools-scm"]],
    )
