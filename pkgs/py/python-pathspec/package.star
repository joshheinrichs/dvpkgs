def package(c):
    return c.package(name = "python-pathspec", uses = ["python"], python = {"backend": "flit_core", "module": "pathspec"})
