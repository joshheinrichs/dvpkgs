def package(c):
    return c.package(
        name = "bdw-gc",
        uses = ["cmake"],
        cmake = {"defs": {
            "enable_cplusplus": True,  # nix
            "enable_large_config": True,
            "enable_mmap": True,
            "enable_docs": False,
        }},
        # nix evaluations overflow the default mark stack
        cc = {"cflags": ["-DINITIAL_MARK_STACK_SIZE=1048576"]},
    )
