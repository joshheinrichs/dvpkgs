def package(c):
    return c.package(
        name = "lmdb",
        uses = ["make"],
        make = {
            "root": "libraries/liblmdb",
            "flags": ["CC=cc", "AR=llvm-ar", "SOEXT=" + c.platform.ext.shared],
            # `make install` copies them by their suffix-less name
            "programs": ["mdb_stat", "mdb_copy", "mdb_dump", "mdb_load"],
            "testTarget": ["test"],
        },
    )
