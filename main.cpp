#include "atomicdex/main.prerequisites.hpp"

#if defined(WINDOWS_RELEASE_MAIN)
INT WINAPI
WinMain([[maybe_unused]] HINSTANCE hInst, HINSTANCE, [[maybe_unused]] LPSTR strCmdLine, INT)
#else
int
main([[maybe_unused]] int argc, [[maybe_unused]] char* argv[])
#endif
{
#if defined(WINDOWS_RELEASE_MAIN)
    int    argc = __argc;
    char** argv = __argv;
#endif

    //! run app
    int res = run_app(argc, argv);
    SPDLOG_INFO("Shutdown all loggers");
    spdlog::drop_all();
    return res;
}
