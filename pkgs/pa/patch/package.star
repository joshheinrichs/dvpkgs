def package(c):
    return c.package(
        # gnulib dirent replacement does not build on mingw
        platforms = {"posix": True},
        name = "patch",
        uses = ["autotools"],
        bootstrapTools = True,
        tests = {"run": False},  # ed
    )
