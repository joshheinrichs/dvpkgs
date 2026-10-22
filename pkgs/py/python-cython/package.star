def package(c):
    return c.package(
        name = "python-cython",
        uses = ["python"],
        python = {"module": "Cython"},
        dependencies = [c.pkgs.cpython],  # bin/cython runs under it
        buildDependencies = [c.buildPkgs["python-setuptools"]],
        bin = ["cython"],
    )
