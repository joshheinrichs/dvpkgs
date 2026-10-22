# Deno Deploy's CLI; first user of the deno build system (jsr, npm and https: modules in its lock)
def package(c):
    return c.package(
        name = "deployctl",
        uses = ["deno"],
        deno = {
            "entry": {"deployctl": "deployctl.ts"},
            # 1.x sources against deno 2 lib typings (Timeout, Uint8Array<ArrayBufferLike>)
            "check": False,
        },
        tests = {"run": False, "version": True},  # talks to dash.deno.com
        dependencies = [c.pkgs.deno],
    )
