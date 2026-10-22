# a luarocks application: argparse (pure Lua) and luafilesystem (a C module) from the set
def package(c):
    return c.package(
        name = "luacheck",
        # luafilesystem's rockspec builds lfs.c the unix way
        platforms = {"posix": True},
        uses = ["luarocks"],
        dependencies = [c.pkgs.lua],
        tests = {"version": True},
    )
