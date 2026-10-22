# header-only. `default` is the single json.hpp the bootstrap compiles jig with, `tree` the
# release with the cmake package
def package(c):
    return c.package(
        name = "nlohmann-json",
        source = "tree",
        uses = ["cmake"],
        cmake = {
            "tool": c.buildPkgs["cmake-bootstrap"],  # cmake links cppdap, which wants this
            "defs": {"JSON_BuildTests": False, "JSON_MultipleHeaders": True},
        },
    )
