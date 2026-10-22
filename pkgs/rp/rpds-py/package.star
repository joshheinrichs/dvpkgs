# mixed: python (maturin backend) + cargo in one tree
def package(c):
    return c.package(
        name = "rpds-py",
        uses = ["python", "cargo"],
        python = {"backend": "maturin", "module": "rpds"},
        phases = ["python.build", "python.install", "python.test"],
        buildDependencies = [c.buildPkgs.maturin],
    )
