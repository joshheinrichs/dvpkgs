# the Erlang style reviewer as an escript (rebar3, hex deps from rebar.lock)
def package(c):
    return c.package(name = "elvis", uses = ["rebar3"])
