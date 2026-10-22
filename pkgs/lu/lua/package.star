# PUC Lua, the interpreter luarocks packages run on. 5.4 while most rocks still cap `lua < 5.5`.
# The Makefile knows linux, macosx and mingw. msvc is lua.nu (what etc/luavs.bat did)
def package(c):
    platform = c.platform
    on, per = c.lib.on, c.lib.per
    msvc = platform.abi == "msvc"
    programs = ["lua", "luac"]
    return c.package(
        name = "lua",
        # package.path and cpath default to the prefix of the running lua or liblua ("!/", as on Windows)
        patches = [path("relocatable.patch")],
        bin = programs,
        tests = {"version": "-v"},
        uses = on(not msvc, ["make"]),
        phases = on(msvc, ["lua.msvc"]),
        make = on(not msvc, {
            "buildTarget": [per(platform.os, {"linux": "linux", "macos": "macosx", "windows": "mingw"})],
            # -Wl,-E is in the linux target: C modules luarocks builds resolve the Lua API against the binary
            "flags": ["MYCFLAGS=-fPIC", "INSTALL_TOP=$(prefix)"],
            "testTarget": ["test"],
            "programs": programs,
        }),
        # the Makefile installs no DLL, msvc has no install step at all
        install = per(platform.abi, {
            "gnu": on(platform.os == "windows", {"bin/": ["src/lua54.dll"]}),
            "apple": {},
            "msvc": {
                "bin/": ["src/%s.exe" % p for p in programs] + ["src/lua54.dll"],
                "lib/lua54.lib": "src/lua54.lib",
                "include/": ["src/" + h for h in ["lua.h", "luaconf.h", "lualib.h", "lauxlib.h", "lua.hpp"]],
            },
        }),
    )
