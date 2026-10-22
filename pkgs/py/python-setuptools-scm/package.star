# sdists carry PKG-INFO, so setuptools-scm reads the version from there, no git needed
def package(c):
    pkgs = c.pkgs
    return c.package(
        name = "python-setuptools-scm",
        uses = ["python"],
        python = {"module": "setuptools_scm"},
        buildDependencies = [c.buildPkgs["python-setuptools"]],
        dependencies = [pkgs["python-packaging"], pkgs["python-setuptools"], pkgs["python-vcs-versioning"]],
    )
