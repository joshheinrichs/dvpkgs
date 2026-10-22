def package(c):
    return c.package(
        name = "libwebp",
        uses = ["cmake"],
        # cwebp/dwebp read png, jpeg, gif. tiff would be a cycle (libtiff links libwebp)
        cmake = {"defs": {"WEBP_BUILD_EXTRAS": False}},
        dependencies = [c.pkgs["libjpeg-turbo"], c.pkgs.libpng, c.pkgs.giflib],
    )
