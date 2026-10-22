# Upstream's bun binary run under our dynamic linker (`prebuilt`), a build tool for the bun build
# system like `rust` is for cargo. From source later (docs/plan.md).
def package(c):
    return c.package(
        name = "bun",
        prebuilt = True,
        install = {"bin/bun": "bun"},
        links = {"bin/bunx": "bun"},
        tests = {"version": True},
    )
