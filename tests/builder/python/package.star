def package(c):
    return c.package(
        name = "test-python",
        version = "0.3",
        source = path("src"),
        uses = ["python"],
        buildDependencies = [c.buildPkgs["python-setuptools"]],
        dependencies = [c.pkgs.cpython],
        python = {"module": "tpy"},
        tests = {"version": "tpy-hello"},
    )
