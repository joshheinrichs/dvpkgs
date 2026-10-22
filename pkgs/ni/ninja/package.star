def package(c):
    exe = c.platform.ext.exe
    return c.package(
        name = "ninja",
        phases = ["ninja.build"],
        install = {"bin/ninja" + exe: "../build/ninja" + exe},
    )
