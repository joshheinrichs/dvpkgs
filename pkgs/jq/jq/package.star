def package(c):
    return c.package(
        name = "jq",
        uses = ["autotools"],
        autotools = {
            "flags": ["--with-oniguruma=yes", "--disable-docs", "--disable-maintainer-mode"],
            "testTarget": ["check", "TESTS=tests/jqtest"],  # shtest wants a tty and /dev/stdin tricks
        },
        tests = {"separate": True},
        dependencies = [c.pkgs.oniguruma],
    )
