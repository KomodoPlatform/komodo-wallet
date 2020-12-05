import os
import osproc

import build
import generate

proc run_tests*(build_type: string, osx_sdk_path: string, compiler_path: string) =
     when defined(linux) or defined(osx):
        generate_solution(build_type, osx_sdk_path, compiler_path)
     when defined(windows):
        # build first and then generate to scan for missing dll
        generate_solution(build_type, osx_sdk_path, compiler_path)
    
     when defined(osx):
        echo os.getCurrentDir()
        os.setCurrentDir(os.getCurrentDir().joinPath("bin").joinPath("atomicdex-desktop_tests.app").joinPath("Contents").joinPath("MacOS"))
        echo "Running AtomicDex Pro Unit tests"
        discard osproc.execCmd("./atomicdex-desktop_tests --reporters=xml --out=atomic-dex-tests-result.xml -s")
        echo "Successfully Generated atomic-dex-tests-result.xml"
   
     when defined(linux):
        echo os.getCurrentDir()
        os.setCurrentDir(os.getCurrentDir().joinPath("bin").joinPath("AntaraAtomicDexTestsAppDir").joinPath("usr").joinPath("bin"))
        echo "Running AtomicDex Pro Unit tests"
        discard osproc.execCmd("./atomicdex-desktop_tests --reporters=xml --out=atomic-dex-tests-result.xml -s")
        echo "Successfully Generated atomic-dex-tests-result.xml"
     
     when defined(windows):
        echo os.getCurrentDir()
        os.setCurrentDir(os.getCurrentDir().joinPath("bin"))
        echo "Running AtomicDex Pro Unit tests"
        discard osproc.execCmd(".\\atomicdex-desktop_tests.exe --reporters=xml --out=atomic-dex-tests-result.xml -s")
        echo "Successfully Generated atomic-dex-tests-result.xml"
