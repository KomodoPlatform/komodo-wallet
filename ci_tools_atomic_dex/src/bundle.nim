import os
import osproc

import build
import vcpkg

proc bundle*(build_type: string, osx_sdk_path: string, compiler_path: string) =
    build_atomic_qt(build_type, osx_sdk_path, compiler_path)
    when defined(osx):
        discard osproc.execCmd("ninja install")
    when defined(windows):
        discard osproc.execCmd("ninja install")
    when defined(linux):
        discard osproc.execCmd("ninja install")


