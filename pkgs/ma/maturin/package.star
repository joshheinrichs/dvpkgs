# PEP 517 backend for Rust extensions. Build tool only: no upload, sbom, completions, zig/xwin
def package(c):
    return c.package(
        name = "maturin",
        uses = ["cargo"],
        cargo = {"noDefaultFeatures": True},
        phases = {
            "remove": ["cargo.test"],
            # the backend `python -m build` imports is the pure Python part, which then runs bin/maturin
            "after": {"cargo.install": [{
                "name": "backend",
                "run": c.lib.text("""
                    let sp = $"($c.out)/lib/python3/site-packages"
                    mkdir $sp
                    cp -r $"($c.src)/maturin" $sp
                """),
            }]},
        },
    )
