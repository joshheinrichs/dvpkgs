def package(c):
    return c.package(
        name = "python-pluggy",
        uses = ["python"],
        python = {"module": "pluggy"},
        buildDependencies = [c.buildPkgs["python-setuptools"], c.buildPkgs["python-setuptools-scm"]],
    )
