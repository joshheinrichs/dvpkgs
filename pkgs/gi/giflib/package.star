def package(c):
    return c.package(
        name = "giflib",
        uses = ["make"],
        patches = [path("upstream-darwin-install-name.patch")],
        make = {
            "flags": [
                "CC=cc",
                # libutil.so only serves the uninstalled helper programs, and on Darwin it does not even link
                "SHARED_LIBS=$(LIBGIFSO)",
            ],
            # the default goal also renders the docs with ImageMagick
            "buildTarget": ["shared-lib", "static-lib", "gif2rgb", "gifbuild", "giftool", "giftext", "gifclrmp", "giffix"],
            "installTarget": ["install-bin", "install-include", "install-lib"],
        },
        tests = {"run": False},  # compares against ImageMagick output
    )
