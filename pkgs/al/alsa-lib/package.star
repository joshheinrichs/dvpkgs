def package(c):
    return c.package(
        name = "alsa-lib",
        platforms = {"os": ["linux"]},
        uses = ["autotools"],
        # plugins are the system's
        patches = [path("relocatable.patch")],
        autotools = {"flags": [
            "--with-plugindir=/usr/lib/alsa-lib",
            "--disable-python",
            "--disable-topology",
        ]},
    )
