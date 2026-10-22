# The JDK dlopens libcups at run time and only needs <cups/*.h> to build. Full cups (daemon,
# gnutls, avahi …) is not worth it for that.
def package(c):
    return c.package(
        name = "cups-headers",
        install = {"include/cups/": "cups/*.h"},
    )
