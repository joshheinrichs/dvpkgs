# GLib for qemu: no introspection, docs, nls, sysprof, selinux, libmount
def package(c):
    pkgs = c.pkgs
    return c.package(
        name = "glib",
        uses = ["meson"],
        # charset.alias is the system's
        patches = [path("relocatable.patch")],
        meson = {"defs": {
            "tests": False,
            "nls": "disabled",
            "introspection": "disabled",
            "sysprof": "disabled",
            "selinux": "disabled",
            "libmount": "disabled",
            "documentation": False,
            "man-pages": "disabled",
            "dtrace": "disabled",
            "systemtap": "disabled",
            "wrap_mode": "nodownload",
            "localstatedir": "/var",
        }},
        dependencies = [
            pkgs.pcre2,
            pkgs.libffi,
            pkgs.zlib,
            pkgs.cpython,  # glib-mkenums, gdbus-codegen are python scripts
        ],
        # meson.build and the codegen tools run python3 with `packaging`
        buildDependencies = [c.buildPkgs.cpython, c.buildPkgs["python-packaging"]],
        tests = {"run": False},
        bin = ["glib-compile-resources", "gdbus"],
    )
