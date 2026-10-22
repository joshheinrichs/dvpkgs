def package(c):
    return c.package(
        name = "jansson",
        uses = ["autotools"],
        autotools = {"outOfTree": False},  # `make check` writes scripts/clang-format-check.log into the source
    )
