def package(c):
    platform = c.platform
    return c.package(
        name = "sqlite",
        uses = ["make"],  # autosetup, not autoconf
        make = {
            # what distributions ship and dependents test for (dbmate: fts5, nodejs: session, column-metadata)
            "configureFlags": ["--enable-all", "--enable-column-metadata"] +
                              # autosetup takes the shared library suffix from --host, else from the build machine
                              c.on(platform.cross, ["--host=" + platform.gnuTriple]),
            # upstream leaves the soname to the packager (main.mk LDFLAGS.libsqlite3.soname);
            # without one every DT_NEEDED naming libsqlite3.so keeps its absolute build-time path
            "flags": c.on(platform.os == "linux", ["LDFLAGS.libsqlite3.soname=-Wl,-soname,libsqlite3.so.0"]),
        },
        tests = {"run": False},  # needs tcl
        dependencies = [c.pkgs.zlib],
    )
