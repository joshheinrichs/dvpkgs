# Headless Wine: the emulator for x86_64-windows-* test phases and version checks, like qemu for
# linux cross. No X11/Wayland/audio/graphics drivers. The PE side is built with the toolchain's
# clang in MSVC mode against Wine's own headers and CRT, the ELF side with cc
def package(c):
    return c.package(
        name = "wine",
        platforms = {"os": ["linux"], "cpu": ["x86_64"]},
        uses = ["autotools"],
        # wine-preloader is freestanding (-nodefaultlibs): zero-init of its buffers calls memset
        cc = {"hardening": {"trivialautovarinit": False}},
        buildDependencies = [c.buildPkgs.flex, c.buildPkgs.bison],
        # compiled-in BINDIR/LIBDIR are last-resort fallbacks, ntdll.so finds everything relative
        # to itself. A prefix that is not the store path keeps them out of the relocatability check
        autotools = {
            "flags": [
                "--prefix=/usr",
                "--enable-nls",  # here the nls/ directory (locale tables wineserver cannot start without), not gettext
                "x86_64_CC=clang",
                "--enable-archs=x86_64",
                "--disable-tests",
                "--without-x",
                "--without-wayland",
                "--without-freetype",
                "--without-gstreamer",
                "--without-alsa",
                "--without-pulse",
                "--without-opengl",
                "--without-vulkan",
                "--without-cups",
                "--without-sane",
                "--without-gphoto",
                "--without-krb5",
                "--without-netapi",
                "--without-pcap",
                "--without-usb",
                "--without-v4l2",
                "--without-sdl",
                "--without-udev",
                "--without-dbus",
                "--without-gnutls",
                "--without-unwind",
            ],
            "installFlags": ["prefix=$(out)"],
        },
        # the preloader maps the loader and its PT_INTERP by hand, ours is relative with a stub
        # entry. It only pre-reserves address ranges, ntdll execs the loader directly without it
        phases = {"after": {"autotools.install": [{
            "name": "no-preloader",
            "run": "rm $\"($c.out)/lib/wine/x86_64-unix/wine-preloader\"",
        }]}},
        tests = {"version": "wine --version"},
    )
