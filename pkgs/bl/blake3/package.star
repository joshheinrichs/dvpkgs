def package(c):
    return c.package(
        name = "blake3",
        uses = ["cmake"],
        cmake = {"root": "c", "defs": {"BLAKE3_USE_TBB": False}},
    )
