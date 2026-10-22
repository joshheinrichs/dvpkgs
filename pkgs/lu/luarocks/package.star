# the Lua package manager, a build tool here (builder/systems/luarocks.nu, `uptrack lock`): pure Lua,
# its hand-written configure takes only --prefix and --with-lua. It unpacks .src.rock with unzip
# and would compile C modules with a literal `gcc`: the installed config says cc.
def package(c):
    return c.package(
        name = "luarocks",
        uses = ["make"],
        dependencies = [c.pkgs.lua, c.pkgs.unzip],
        buildDependencies = [c.buildPkgs.unzip],
        # bin/luarocks finds its modules from arg[0], sysconfdir from where cfg.lua is (upstream),
        # and the system tree defaults to that prefix
        patches = [path("relocatable.patch")],
        make = {"configureFlags": ["--with-lua=%s" % c.pkgs.lua]},
        phases = {"after": {"make.install": [{
            "name": "cc",
            "run": c.lib.text("""
                for f in (files $"($c.out)/etc/luarocks/config-*.lua") {
                  "\\nvariables.CC = \\"cc\\"\\nvariables.LD = \\"cc\\"\\n" | save -a $f
                }
            """),
        }]}},
        tests = {"run": False},
        bin = ["luarocks", "luarocks-admin"],
    )
