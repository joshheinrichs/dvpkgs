# pkg-config implementation without the glib dependency. Installs the pkg-config name too.
def package(c):
    return c.package(
        name = "pkgconf",
        uses = ["autotools"],
        bootstrapTools = True,
        autotools = {"flags": [
            # no built-in search path: core.nu sets PKG_CONFIG_PATH from dependencies
            "--with-pkg-config-dir=",
            "--with-personality-dir=",
            "--with-system-libdir=/nonexistent",
            "--with-system-includedir=/nonexistent",
        ]},
        tests = {"run": False},  # kyua
        links = {"bin/pkg-config": "pkgconf"},
        bin = ["pkgconf", "pkg-config"],
    )
