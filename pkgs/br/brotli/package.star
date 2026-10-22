def package(c):
    return c.package(
        name = "brotli",
        uses = ["cmake"],
        patches = [path("upstream-loongarch-model-attr.patch")],
    )
