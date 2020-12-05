import os
import osproc

import build
import vcpkg
import generate

proc bundle*(build_type: string, osx_sdk_path: string, compiler_path: string) =
    generate_solution(build_type, osx_sdk_path, compiler_path)
    #build_atomic_qt(build_type, osx_sdk_path, compiler_path)
    #os.putEnv("NINJA_STATUS", "[%f/%t %e] ")
    when defined(osx):
        discard osproc.execCmd("ninja install")
    when defined(windows):
        discard osproc.execCmd("ninja install")
    when defined(linux):
        discard osproc.execCmd("ninja install")


