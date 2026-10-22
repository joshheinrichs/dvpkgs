def package(c):
    return c.package(
        name = "nushell",
        uses = ["cargo"],
        # default features minus plugin + system-clipboard (x11/wayland)
        cargo = {"noDefaultFeatures": True, "features": ["sqlite", "trash-support", "rustls-tls"]},
        tests = {"run": False},  # the suite spawns `nu` against a home directory and a tty
        bin = ["nu"],
    )
