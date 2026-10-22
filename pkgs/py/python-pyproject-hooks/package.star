def package(c):
    return c.package(name = "python-pyproject-hooks", uses = ["python"], python = {"backend": "flit_core", "module": "pyproject_hooks"})
