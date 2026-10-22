# gn has no releases: Debian's snapshot tarball of gn.googlesource.com
def package(c):
    pin = from_toml(read_file("sources.toml"))["pin"]
    rev = pin["version"].rpartition(".")[2]
    return c.package(
        name = "gn",
        # gen.py picks posix sources unless the host is windows
        platforms = {"posix": True},
        buildDependencies = [c.buildPkgs.cpython, c.buildPkgs.ninja],
        phases = [{
            "name": "build",
            "run": c.lib.text(
                """
                cd $c.src
                x python3 build/gen.py --no-last-commit-position --no-strip --no-static-libstdc++ --allow-warnings $"--out-path=($c.build)"
                '#define LAST_COMMIT_POSITION_NUM ${position}
                #define LAST_COMMIT_POSITION "${position} (${rev})"
                ' | save $"($c.build)/last_commit_position.h"
                x ninja -C $c.build $"-j($c.njobs)" gn
                """,
                position = pin["position"],
                rev = rev,
            ),
        }],
        install = {"bin/gn": "../build/gn"},
        tests = {"version": False},  # prints the commit position, not a version
    )
