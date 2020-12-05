add_library(antara_error_settings INTERFACE)


# Using namespaces causes CMake to error our in case of typos on the
# consuming side, very important.
add_library(antara::error_settings ALIAS antara_error_settings)

##! We use only clang for simplicity
target_compile_options(
        antara_error_settings
        INTERFACE
        $<$<AND:$<PLATFORM_ID:Linux>,$<CXX_COMPILER_ID:Clang>>:-Wall -Wextra -Wfatal-errors>
        $<$<AND:$<PLATFORM_ID:Darwin>,$<CXX_COMPILER_ID:Clang>>:-Wall -Wextra -Wfatal-errors>
        $<$<AND:$<PLATFORM_ID:Darwin>,$<CXX_COMPILER_ID:AppleClang>>:-Wall -Wextra -Wfatal-errors>
        $<$<AND:$<PLATFORM_ID:Windows>,$<NOT:$<BOOL:${ClangCL}>>,$<CXX_COMPILER_ID:Clang>>:-Wall -Wextra -Wfatal-errors>
        $<$<AND:$<PLATFORM_ID:Windows>,$<BOOL:${ClangCL}>,$<CXX_COMPILER_ID:Clang>>:/W4 /permissive->
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:MSVC>>:/W4 /permissive- /std:c++latest>)

# $<$<AND:$<PLATFORM_ID:Windows>,$<NOT:$<BOOL:${ClangCL}>>,$<CXX_COMPILER_ID:Clang>>:-Wall -Wextra -Wfatal-errors>
# $<$<AND:$<PLATFORM_ID:Windows>,$<BOOL:${ClangCL}>,$<CXX_COMPILER_ID:Clang>>:/W4 /permissive->
##! We are using C++ 17 for all of our targets
add_library(antara_defaults_features INTERFACE)
add_library(antara::defaults_features ALIAS antara_defaults_features)
target_compile_features(antara_defaults_features INTERFACE cxx_std_17)

add_library(antara_optimize_settings INTERFACE)
add_library(antara::optimize_settings ALIAS antara_optimize_settings)

##! Msvc flags info
# /Zi - Produces a program database (PDB) that contains type information and symbolic debugging information for use with the debugger.
# /FS - Allows multiple cl.exe processes to write to the same .pdb file
# /DEBUG - Enable debug during linking
# /Od - Disables optimization
# /Ox - Full optimization
# /Oy- do not suppress frame pointers (recommended for debugging)

target_compile_options(antara_optimize_settings INTERFACE
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Linux>>:-O0 -g>
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Linux>>:-O3 --target=x86_64-unknown-linux-gui -ffast-math>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Darwin>>:-O0 -g>
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Darwin>>:-O3 -ffast-math>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:AppleClang>,$<PLATFORM_ID:Darwin>>:-O0 -g>
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:AppleClang>,$<PLATFORM_ID:Darwin>>:-O3 -ffast-math>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Windows>,$<NOT:$<BOOL:${ClangCL}>>>:-O0 -g>
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Windows>,$<NOT:$<BOOL:${ClangCL}>>>:-O1>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Windows>,$<BOOL:${ClangCL}>>:/Zi /FS /DEBUG /Od /MDd /Oy->
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:MSVC>>:/Zi /FS /DEBUG /Od /MDd /Oy->
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:MSVC>>:/Ox -DNDEBUG>
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Windows>,$<BOOL:${ClangCL}>>:/Ox -DNDEBUG>
        )
target_compile_definitions(antara_optimize_settings INTERFACE
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Linux>>:NDEBUG>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Linux>>:DEBUG>
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Darwin>>:NDEBUG>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:Clang>,$<PLATFORM_ID:Darwin>>:-DEBUG>
        $<$<AND:$<CONFIG:Release>,$<CXX_COMPILER_ID:AppleClang>,$<PLATFORM_ID:Darwin>>:NDEBUG>
        $<$<AND:$<CONFIG:Debug>,$<CXX_COMPILER_ID:AppleClang>,$<PLATFORM_ID:Darwin>>:DEBUG>
        )

add_library(antara_default_settings INTERFACE)
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)
target_link_libraries(antara_default_settings INTERFACE antara::error_settings antara::optimize_settings antara::defaults_features Threads::Threads)
add_library(antara::default_settings ALIAS antara_default_settings)
