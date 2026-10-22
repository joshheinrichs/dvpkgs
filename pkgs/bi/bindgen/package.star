# the bindgen CLI. libclang is dlopened at run time from LIBCLANG_PATH, callers set it
def package(c):
    return c.package(
        name = "bindgen",
        uses = ["cargo"],
        cargo = {"flags": ["-p", "bindgen-cli"]},
        tests = {"run": False},  # the suite diffs generated bindings against a pinned clang's output
        bin = ["bindgen"],
    )
