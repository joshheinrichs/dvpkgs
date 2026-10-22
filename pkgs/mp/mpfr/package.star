def package(c):
    return c.package(name = "mpfr", uses = ["autotools"], dependencies = [c.pkgs.gmp])
