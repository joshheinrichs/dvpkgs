def package(c):
    return c.package(
        name = "numactl",
        platforms = {"os": ["linux"]},
        uses = ["autotools"],
        tests = {"run": False},  # test/ wants a NUMA machine
    )
