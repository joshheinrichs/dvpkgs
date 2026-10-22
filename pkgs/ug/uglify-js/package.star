def package(c):
    return c.package(
        name = "uglify-js",
        uses = ["npm"],
        # upstream ships no lockfile
        npm = {"deps": c.fetch.npmDeps(source = c.sources.fetch("default"), lockFile = path("package-lock.json"))},
        phases = ["npm.install"],  # plain JS, nothing to build; its tests take minutes
        bin = ["uglifyjs"],
    )
