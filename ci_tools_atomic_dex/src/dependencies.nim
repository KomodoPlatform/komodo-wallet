import osproc
import os
import vcpkg

proc download_packages*() =
    echo "Downloading packages ... please wait"
    #let response_file_directory = g_vcpkg_local_path.parentDir().parentDir().parentDir().joinPath(".github").joinPath("workflows")
    #let custom_ports_path = g_vcpkg_local_path.parentDir().parentDir().joinPath("vcpkg-custom-ports").joinPath("ports")
    #when defined(windows):
    #    let cmd = g_vcpkg_local_path & " install @" & response_file_directory.joinPath("windows_response_file.txt") & " --overlay-ports=" & custom_ports_path
    #    echo "vcpkg cmd [" & cmd & "]"
    #    discard execCmd(cmd)
    #when defined(linux):
    #    let cmd = g_vcpkg_local_path & " install @" & response_file_directory.joinPath("linux_response_file.txt") & " --overlay-ports=" & custom_ports_path
    #    echo "vcpkg cmd [" & cmd & "]"
    #    discard execCmd(cmd)
    #when defined(osx):
    #    let cmd = g_vcpkg_local_path & " install @" & response_file_directory.joinPath("osx_response_file.txt") & " --overlay-ports=" & custom_ports_path
    #    echo "vcpkg cmd [" & cmd & "]"
    #    discard execCmd(cmd)
    echo "Downloading packages finished"
