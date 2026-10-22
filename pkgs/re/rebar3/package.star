# rebar3 bootstraps itself offline from its vendored dependencies into one escript
def package(c):
    return c.package(
        name = "rebar3",
        buildDependencies = [c.buildPkgs.erlang],
        dependencies = [c.pkgs.erlang],
        phases = [{
            "name": "bootstrap",
            "run": c.lib.text("""
                use beam.nu
                with-env {HOME: $c.build, REBAR_OFFLINE: "1"} { x escript bootstrap }
                beam install-escript _build/prod/bin/rebar3
            """),
        }],
    )
