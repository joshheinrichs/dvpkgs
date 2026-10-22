def package(c):
    return c.package(
        # pwd.h, waitpid
        platforms = {"posix": True},
        name = "coreutils",
        uses = ["autotools"],
        bootstrapTools = True,
        patches = [path("relocatable.patch")],  # stdbuf finds libstdbuf.so relative to itself
        autotools = {"flags": [
            "--disable-acl",
            "--disable-xattr",
            "--disable-libcap",
            "--without-selinux",
            "--without-openssl",
            "--without-libgmp",
            "--enable-no-install-program=kill,uptime",
            # single multicall binary + symlinks: 1 ELF to relocate instead of 106
            "--enable-single-binary=symlinks",
        ]},
        env = {"FORCE_UNSAFE_CONFIGURE": "1"},
        tests = {"run": False},  # perl, and many root/tty assumptions
        bin = ["ls", "cp", "install", "sort"],
    )
