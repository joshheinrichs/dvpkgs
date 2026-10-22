# the VCS querying half of setuptools-scm, split out in setuptools-scm 10
def package(c):
    return c.package(
        name = "python-vcs-versioning",
        uses = ["python"],
        python = {"module": "vcs_versioning"},
        buildDependencies = [c.buildPkgs["python-setuptools"]],
        dependencies = [c.pkgs["python-packaging"]],
    )
