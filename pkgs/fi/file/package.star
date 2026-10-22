def package(c):
    cross = c.platform.cross
    return c.package(
        name = "file",
        uses = ["autotools"],
        patches = [
            path("relocatable.patch"),  # the magic database relative to libmagic
            path("upstream-mingw-timespec.patch"),  # struct timespec is real on mingw, not winsock's timeval
        ],
        # cross: compiling the magic database takes a `file` of the same version
        buildDependencies = c.on(cross, [c.buildPkgs.file]),
        # the Makefile would call file.exe here when the target is windows
        autotools = {"makeFlags": c.on(cross, ["FILE_COMPILE=file"])},
        dependencies = [c.pkgs.zlib, c.pkgs.bzip2, c.pkgs.xz, c.pkgs.zstd] + c.on(c.platform.os == "windows", [c.pkgs.tre]),  # mingw has no regex(3)
    )
