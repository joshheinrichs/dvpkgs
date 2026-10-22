def package(c):
    return c.package(
        name = "acl",
        uses = ["autotools"],
        dependencies = [c.pkgs.attr],
        tests = {"run": False},  # want users bin and daemon in /etc/passwd
        platforms = {"os": ["linux"]},
    )
