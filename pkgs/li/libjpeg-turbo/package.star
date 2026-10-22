def package(c):
    return c.package(
        name = "libjpeg-turbo",
        uses = ["cmake"],
        cmake = {"defs": {"WITH_JPEG8": True}},
        buildDependencies = [c.buildPkgs.nasm],
        # -shared and -static bit tests write the same testout* files in one directory
        tests = {"parallel": False},
    )
