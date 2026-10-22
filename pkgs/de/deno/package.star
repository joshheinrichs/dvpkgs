# Upstream's deno binary under our dynamic linker (`prebuilt`), the build tool of the deno build
# system, as bun and rust are. From source (cargo + rusty_v8) later.
def package(c):
    return c.package(
        name = "deno",
        prebuilt = True,
        dependencies = [c.pkgs["libgcc-shim"]],  # upstream links libgcc_s.so.1 for unwinding
        install = {"bin/deno": "deno"},
        tests = {"version": True},
    )
