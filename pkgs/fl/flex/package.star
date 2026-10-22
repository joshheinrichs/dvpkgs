def package(c):
    return c.package(
        name = "flex",
        # needs <regex.h>
        platforms = {"posix": True},
        uses = ["autotools"],
        bootstrapTools = True,
        buildDependencies = [c.buildPkgs.m4],
        dependencies = [c.pkgs.m4],
        autotools = {"flags": [
            "ac_cv_path_M4=%s/bin/m4" % c.pkgs.m4,
            # skip the stage1flex bootstrap dance, scan.c ships in the tarball
            "--disable-bootstrap",
        ]},
        tests = {"run": False},  # bison + full autotools
    )
