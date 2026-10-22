def package(c):
    return c.package(name = "python-installer", uses = ["python"], python = {"backend": "flit_core", "module": "installer"})
