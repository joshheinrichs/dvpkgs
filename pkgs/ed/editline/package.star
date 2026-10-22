def package(c):
    return c.package(
        # termios
        platforms = {"posix": True},
        name = "editline",
        uses = ["autotools"],
    )
