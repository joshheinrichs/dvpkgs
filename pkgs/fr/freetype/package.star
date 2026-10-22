def package(c):
    return c.package(
        name = "freetype",
        uses = ["meson"],
        meson = {"defs": {
            "zlib": "system",
            "png": "enabled",
            "bzip2": "enabled",
            "harfbuzz": "disabled",
            "brotli": "disabled",
        }},
        dependencies = [c.pkgs.zlib, c.pkgs.libpng, c.pkgs.bzip2],
    )
