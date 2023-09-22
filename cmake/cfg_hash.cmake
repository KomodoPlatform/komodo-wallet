#if (UNIX)
#    execute_process(COMMAND bash -c "git ls-remote https://github.com/KomodoPlatform/komodo-wallet-desktop-generics refs/heads/main | cut -f 1 | tr -d '\n'"
#            OUTPUT_VARIABLE GENERICS_VERSION_ID
#            )
#    if (NOT EXISTS ${GENERICS_VERSION_ID}.cfg_hash)
#        file(WRITE ${CMAKE_SOURCE_DIR}/assets/config/${GENERICS_VERSION_ID}.remote_last_cfg_hash)
#    endif ()
#endif ()