def package(c):
    return c.package(name = "python-packaging", uses = ["python"], python = {"backend": "flit_core", "module": "packaging"})
