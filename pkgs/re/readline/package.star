def package(c):
    windows = c.platform.os == "windows"
    return c.package(
        name = "readline",
        uses = ["autotools"],
        autotools = {
            "flags": ["--with-curses", "--with-shared-termcap-library"] + c.on(windows, ["CFLAGS=-D__USE_MINGW_ALARM -D_POSIX"]),
            # shobj-conf says --export-all, lld only knows the long spelling
            "makeFlags": c.on(windows, ["SHOBJ_LDFLAGS=-shared -Wl,--export-all-symbols -Wl,--enable-auto-import"]),
        },
        # msys2's, all behind __MINGW32__/_WIN32
        patches = [
            path("mingw-0001-sigwinch.patch"),
            path("mingw-0002-event-hook.patch"),
            path("mingw-0003-no-winsize.patch"),
            path("mingw-0004-locale.patch"),
        ],
        dependencies = [c.pkgs.ncurses],
    )
