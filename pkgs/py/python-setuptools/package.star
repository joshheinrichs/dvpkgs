def package(c):
    return c.package(name = "python-setuptools", uses = ["python"], python = {"module": "setuptools"})
