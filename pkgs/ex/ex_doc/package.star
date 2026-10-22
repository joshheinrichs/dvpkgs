# ExDoc as an escript (mix, hex deps from mix.lock)
def package(c):
    return c.package(name = "ex_doc", uses = ["mix"], mix = {"escript": ["ex_doc"]})
