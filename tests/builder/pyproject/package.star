# cpython's project devEnv: bin/python3 that imports the checkout named by REPKGS_PROJECT
load("//nix/python.star", "project")

def package(c):
    return project(c, c.pkgs.cpython, src = "//tests/builder/pyproject/src").devEnv
