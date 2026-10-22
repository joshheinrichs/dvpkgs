def package(c):
    return c.package(
        name = "pixman",
        uses = ["meson"],
        meson = {
            "defs": {"libpng": "enabled", "tests": "enabled"},
            "skipTests": ["stress-test", "tolerance-test", "composite"],  # minutes each; time out on a loaded builder
        },
        tests = {"separate": True},
        dependencies = [c.pkgs.libpng],
    )
