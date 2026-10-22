# yarn classic's registry tarball is a bundled lib/cli.js with no dependencies: copied, bin/yarn
# onto our node. A build tool (buildPkgs.yarn in the yarn build system).
def package(c):
    return c.package(
        name = "yarn",
        dependencies = [c.pkgs.nodejs],
        install = {"lib/node_modules/yarn": "."},
        links = {
            "bin/yarn": "../lib/node_modules/yarn/bin/yarn.js",
            "bin/yarnpkg": "../lib/node_modules/yarn/bin/yarn.js",
        },
    )
