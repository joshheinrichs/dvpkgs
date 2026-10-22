def package(c):
    return c.package(
        name = "libffi",
        uses = ["autotools"],
        # decided from `ld --help`, which lists ELF options whatever lld targets
        autotools = {"flags": c.on(c.platform.binfmt != "elf", ["--disable-symvers"])},
    )
