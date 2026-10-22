def package(c):
    pkgs = c.pkgs
    return c.package(
        name = "libtiff",
        uses = ["cmake"],
        cmake = {"defs": {"tiff-docs": False, "lerc": False, "jbig": False}},
        dependencies = [pkgs.zlib, pkgs.xz, pkgs.zstd, pkgs["libjpeg-turbo"], pkgs.libwebp],
    )
