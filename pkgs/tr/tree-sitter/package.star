# the C runtime library. The CLI is a cargo project in the same tree
def package(c):
    return c.package(
        name = "tree-sitter",
        uses = ["make"],
        make = {"flags": [
            "CC=cc",
            "STRIP=",  # else it strips the library after linking
            "MACHINE=" + c.platform.gnuTriple,  # it greps `cc -dumpmachine` for "darwin", clang says arm64-apple-macos
        ]},
        tests = {"run": False},  # the tests are the CLI's
    )
