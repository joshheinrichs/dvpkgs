def package(c):
    pkgs = c.pkgs
    return c.package(
        name = "libarchive",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {
                "ENABLE_OPENSSL": False,
                "ENABLE_LIBXML2": False,
                "ENABLE_EXPAT": True,
                "ENABLE_ACL": False,
                "ENABLE_XATTR": False,
                "ENABLE_TEST": False,
            },
        },
        dependencies = [pkgs.zlib, pkgs.bzip2, pkgs.xz, pkgs.zstd, pkgs.lz4, pkgs.expat],
        tests = {"run": False},  # ENABLE_TEST: 30 min, several want a real tty/locale
        bin = ["bsdtar", "bsdcpio", "bsdunzip"],
    )
