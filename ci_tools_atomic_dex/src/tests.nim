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
        echo "CURRENT OSX FOLDER"
        echo os.getCurrentDir()
        discard osproc.execCmd("ls")
        os.setCurrentDir(os.getCurrentDir().joinPath("bin"))
        echo "CURRENT OSX FOLDER"
        echo os.getCurrentDir()
        discard osproc.execCmd("ls")
        os.setCurrentDir(os.getCurrentDir().joinPath(os.getEnv("DEX_PROJECT_NAME") & "_tests.app"))
        echo "CURRENT OSX FOLDER"
        echo os.getCurrentDir()
        discard osproc.execCmd("ls")
        os.setCurrentDir(os.getCurrentDir().joinPath("Contents"))
        echo "CURRENT OSX FOLDER"
        echo os.getCurrentDir()
        discard osproc.execCmd("ls")
        os.setCurrentDir(os.getCurrentDir().joinPath("MacOS"))
        echo "CURRENT OSX FOLDER"
        echo os.getCurrentDir()
        discard osproc.execCmd("ls")
        # os.setCurrentDir(os.getCurrentDir().joinPath("bin").joinPath(os.getEnv("DEX_PROJECT_NAME") & "_tests.app").joinPath("Contents").joinPath("MacOS"))
        echo "Running Komodo Wallet Pro Unit tests"
        discard osproc.execCmd("./" & os.getEnv("DEX_PROJECT_NAME") & "_tests --reporters=xml --out=" & os.getEnv("DEX_PROJECT_NAME") & "-tests-result.xml -s")
        echo "Successfully Generated", os.getEnv("DEX_PROJECT_NAME"), "-tests-result.xml"
   
     when defined(linux):
        echo os.getCurrentDir()
        os.setCurrentDir(os.getCurrentDir().joinPath("bin").joinPath("AntaraAtomicDexTestsAppDir").joinPath("usr").joinPath("bin"))
        echo "Running Komodo Wallet Pro Unit tests"
        discard osproc.execCmd("./" & os.getEnv("DEX_PROJECT_NAME") & "_tests --reporters=xml --out=" & os.getEnv("DEX_PROJECT_NAME") & "-tests-result.xml -s")
        echo "Successfully Generated", os.getEnv("DEX_PROJECT_NAME"), "-tests-result.xml"
     
     when defined(windows):
        echo os.getCurrentDir()
        os.setCurrentDir(os.getCurrentDir().joinPath("bin"))
        echo "Running Komodo Wallet Pro Unit tests"
        discard osproc.execCmd(".\\" & os.getEnv("DEX_PROJECT_NAME") & "_tests --reporters=xml --out=" & os.getEnv("DEX_PROJECT_NAME") & "-tests-result.xml -s")
        echo "Successfully Generated", os.getEnv("DEX_PROJECT_NAME"), "-tests-result.xml"
