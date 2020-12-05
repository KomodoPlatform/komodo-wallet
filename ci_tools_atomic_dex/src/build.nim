import osproc

import vcpkg
import generate

proc build_atomic_qt*(config_type: string, osx_type: string, compiler_path: string) =
    generate_solution(config_type, osx_type, compiler_path)
    when not defined(osx):
        let cmd_line = "cmake --build . --config " & config_type
        discard osproc.execCmd(cmd_line)
    when defined(osx):
        let cmd_line = "LIBRARY_PATH=/usr/local/lib cmake --build . --config " & config_type
        echo "OSX build cmd line: " & cmd_line
        discard osproc.execCmd(cmd_line)