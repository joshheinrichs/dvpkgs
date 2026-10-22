def package(c):
    return c.package(
        name = "mpdecimal",
        uses = ["autotools"],
        tests = {"run": False},  # `check` wants IBM's decTest files, downloaded by tests/gettests.sh
    )
