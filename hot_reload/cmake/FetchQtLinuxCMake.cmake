include(FetchContent)

set(QLINUXCMAKE_REPOSITORY "https://github.com/OlivierLDff/QtLinuxCMake.git" CACHE STRING "QtLinuxCMake repository, can be a local URL")
set(QLINUXCMAKE_TAG "main" CACHE STRING "QtLinuxCMake git tag")

FetchContent_Declare(
  QtLinuxCMake
  GIT_REPOSITORY ${QLINUXCMAKE_REPOSITORY}
  GIT_TAG        ${QLINUXCMAKE_TAG}
)

FetchContent_MakeAvailable(QtLinuxCMake)