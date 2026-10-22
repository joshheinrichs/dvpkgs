# bin/{elixir,elixirc,iex} are sh scripts (dirname, readlink, sed) that exec erl: those are
# the dependencies
def package(c):
    return c.package(
        name = "elixir",
        uses = ["make"],
        make = {"testTarget": ["test_stdlib"]},  # test_mix wants git and network
        buildDependencies = [c.buildPkgs.erlang],
        dependencies = [c.pkgs.erlang, c.pkgs.coreutils, c.pkgs.sed],
        exports = False,
        # yecc wrote the build erlang's include path into the parser beams
        env = {"ERL_COMPILER_OPTIONS": "deterministic"},
        bin = ["elixir", "elixirc", "mix", "iex"],
    )
