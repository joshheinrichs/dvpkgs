def package(c):
    return c.package(
        # langinfo.h, wait
        platforms = {"posix": True},
        name = "gawk",
        uses = ["autotools"],
        bootstrapTools = True,
        # AWKPATH, AWKLIBPATH, locale and awklib helpers relative to the binary
        patches = [
            path("relocatable.patch"),
            # 5.4.1 without MPFR: unassigned array elements compare != "" (breaks libpng's checksym.awk)
            path("upstream-node-struct-without-mpfr.patch"),
        ],
        autotools = {"flags": ["--disable-mpfr"]},
        tests = {"run": False},  # locale-dependent, wants a full /usr/share/locale
        bin = ["gawk", "awk"],
    )
