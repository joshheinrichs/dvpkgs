def package(c):
    return c.package(
        name = "cppdap",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links this
            "defs": {"CPPDAP_USE_EXTERNAL_NLOHMANN_JSON_PACKAGE": True},
        },
        dependencies = [c.pkgs["nlohmann-json"]],
    )
