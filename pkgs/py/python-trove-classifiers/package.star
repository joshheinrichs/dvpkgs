def package(c):
    return c.package(
        name = "python-trove-classifiers",
        uses = ["python"],
        python = {"module": "trove_classifiers"},
        buildDependencies = [c.buildPkgs["python-setuptools"]],
    )
