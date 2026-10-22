def package(c):
    return c.package(
        # fork, signals, job control
        platforms = {"posix": True},
        name = "bash",
        uses = ["autotools"],
        bootstrapTools = True,
        # locale dir, bashdb and the loadables kit relative to where bash is
        patches = [path("relocatable.patch")],
        autotools = {"flags": [
            "--without-bash-malloc",
            "--disable-readline",  # build-machine shell for configure scripts, not for people
            "bash_cv_func_strtoimax=y",
            "bash_cv_getcwd_malloc=yes",
            "bash_cv_job_control_missing=nomissing",
            "bash_cv_sys_named_pipes=nomissing",
        ]},
        tests = {"run": False},  # interactive/tty
        links = {"bin/sh": "bash"},
        bin = ["bash", "sh"],
    )
