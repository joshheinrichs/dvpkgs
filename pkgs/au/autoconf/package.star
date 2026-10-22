def package(c):
    return c.package(
        name = "autoconf",
        uses = ["autotools"],
        patches = [path("relocatable.patch")],
        phases = {
            "before": {"autotools.configure": [{
                "name": "man-uptodate",  # no help2man
                "run": '^touch ...(files $"($c.src)/man/*.1")',
            }]},
            "after": {"autotools.install": [{
                "name": "retarget",
                "run": c.lib.text("""
                    let map = ([m4 perl bash] | each {|t| {from: (tool $t), to: $"(dep-root $t 'the scripts run it')/bin/($t)"} })
                    for f in (glob $"($c.out)/bin/*") {
                      edit $f {|| let t = $in; $map | reduce --fold $t {|m, acc| $acc | str replace -a $m.from $m.to } }
                    }
                """),
            }]},
        },
        buildDependencies = [c.buildPkgs.m4, c.buildPkgs.perl],
        # autoconf, autom4te… are perl and sh scripts that exec m4. configure records whichever it
        # finds on PATH, the build machine's when cross: name the target's after install
        dependencies = [c.pkgs.m4, c.pkgs.perl, c.pkgs.bash],
        # 555/557 pass in 20 min. AS_DIRNAME and AC_FUNC_GETGROUPS probe host behaviour (toybox
        # dirname corner cases, no supplementary groups in the sandbox)
        tests = {"run": False},
    )
