def package(c):
    return c.package(
        # pwd.h, fnmatch
        platforms = {"posix": True},
        name = "findutils",
        uses = ["autotools"],
        bootstrapTools = True,
        patches = [path("relocatable.patch")],  # frcode and find next to the script, not under the prefix
        autotools = {"flags": [
            "--without-selinux",
            "--localstatedir=/tmp",  # locate's default db dir. install-data-hook mkdirs it
            "ac_cv_path_SORT=sort",  # updatedb would record the build machine's
            "SORT_SUPPORTS_Z=true",
        ]},
        tests = {"run": False},  # dejagnu + python
        bin = ["find", "xargs"],
    )
