def package(c):
    return c.package(
        name = "python-build",
        uses = ["python"],
        python = {"backend": "flit_core", "module": "build"},
        dependencies = [c.pkgs["python-packaging"], c.pkgs["python-pyproject-hooks"]],
    )
