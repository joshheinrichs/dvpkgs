def package(c):
    return c.package(
        name = "libxml2",
        uses = ["autotools"],
        autotools = {"flags": ["--sysconfdir=/etc"]},  # the machine's XML/SGML catalogs
        dependencies = [c.pkgs.zlib, c.pkgs.xz] + c.on(c.platform.os == "windows", [c.pkgs.libiconv]),
    )
