def package(c):
    return c.package(
        name = "attr",
        uses = ["autotools"],
        patches = [path("relocatable.patch")],  # xattr.conf relative to libattr
        tests = {"run": False},  # set user.* xattrs, the sandbox's build directory refuses them
        bin = ["getfattr", "setfattr", "attr"],
        platforms = {"os": ["linux"]},
    )
