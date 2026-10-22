def package(c):
    linux = c.platform.os == "linux"
    return c.package(
        name = "hidapi",
        uses = ["cmake"],
        # backends: IOKit on macOS, hid.dll on Windows, libusb (and hidraw, no libudev yet) on Linux
        cmake = {"defs": c.on(linux, {"HIDAPI_WITH_HIDRAW": False})},
        dependencies = c.on(linux, [c.pkgs.libusb]),
    )
