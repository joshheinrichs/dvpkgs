def package(c):
    return c.package(name = "python-flit-core", uses = ["python"], python = {"backend": "flit_core", "module": "flit_core"})
