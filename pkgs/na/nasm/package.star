def package(c):
    return c.package(
        name = "nasm",
        uses = ["autotools"],
        buildDependencies = [c.buildPkgs.perl],
        tests = {"run": False},  # no check target, test/ compares against a reference nasm
    )
