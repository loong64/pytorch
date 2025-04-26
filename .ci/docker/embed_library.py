#!/usr/bin/env python3

import os
import shutil
import sys
from subprocess import check_call
from tempfile import TemporaryDirectory

from auditwheel.elfutils import elf_file_filter
from auditwheel.lddtree import lddtree
from auditwheel.patcher import Patchelf
from auditwheel.repair import copylib
from auditwheel.wheeltools import InWheelCtx

COMMON_LIB_PATHS = [
    "/usr/lib",
    "/usr/lib64",
    "/usr/local/lib",
    "/usr/local/lib64",
]

class AlignedPatchelf(Patchelf):
    def set_soname(self, file_name: str, new_soname: str) -> None:
        check_call(
            ["patchelf", "--page-size", "65536", "--set-soname", new_soname, file_name]
        )

    def replace_needed(self, file_name: str, soname: str, new_soname: str) -> None:
        check_call(
            [
                "patchelf",
                "--page-size",
                "65536",
                "--replace-needed",
                soname,
                new_soname,
                file_name,
            ]
        )

def find_library_in_paths(libname, search_paths):
    for path in search_paths:
        full_path = os.path.join(path, libname)
        if os.path.isfile(full_path):
            return full_path
    return None

def embed_library(whl_path, lib_soname):
    patcher = AlignedPatchelf()
    out_dir = TemporaryDirectory()
    whl_name = os.path.basename(whl_path)
    tmp_whl_name = os.path.join(out_dir.name, whl_name)

    with InWheelCtx(whl_path) as ctx:
        torchlib_path = os.path.join(ctx._tmpdir.name, "torch", "lib")
        ctx.out_wheel = tmp_whl_name
        new_lib_path, new_lib_soname = None, None

        for filename, _ in elf_file_filter(ctx.iter_files()):
            if not filename.startswith("torch/lib"):
                continue

            libtree = lddtree(filename)

            if lib_soname not in libtree["needed"]:
                continue

            lib_info = libtree["libs"].get(lib_soname)
            lib_path = lib_info["path"] if lib_info else None

            if lib_path is None:
                lib_path = find_library_in_paths(lib_soname, COMMON_LIB_PATHS)
                if lib_path:
                    print(f"Found {lib_soname} manually at {lib_path}")

            if lib_path is None:
                print(f"Can't embed {lib_soname} as it could not be found")
                break

            if lib_path.startswith(torchlib_path):
                continue

            if new_lib_path is None:
                new_lib_soname, new_lib_path = copylib(lib_path, torchlib_path, patcher)

            patcher.replace_needed(filename, lib_soname, new_lib_soname)
            print(f"Replacing {lib_soname} with {new_lib_soname} for {filename}")

    shutil.move(tmp_whl_name, whl_path)

if __name__ == "__main__":
    embed_library(sys.argv[1], "libgomp.so.1")
