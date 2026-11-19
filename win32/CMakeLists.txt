cmake_minimum_required(VERSION 3.20)
project(dvtm_win32 C)

# Native Windows (MSVC) build of dvtm. Sources stay at the repository root,
# patched under #ifdef _WIN32; the POSIX-on-Win32 layer lives in compat/.
#   cmake -S win32 -B win32/build -A x64 && cmake --build win32/build --config Release

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
if(NOT MSVC)
    message(FATAL_ERROR "win32/ targets MSVC (cl.exe); on Unix use the upstream Makefile.")
endif()

set(SRC ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(COMMON_FLAGS /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS /D_CRT_NONSTDC_NO_DEPRECATE)

# posix_compat: OBJECT library, never STATIC: compat/src/init.c registers a
# CRT initializer that nothing references by name; a .lib would drop it.
file(GLOB COMPAT_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/compat/src/*.c)
add_library(posix_compat OBJECT ${COMPAT_SOURCES})
target_compile_options(posix_compat PRIVATE ${COMMON_FLAGS})
target_include_directories(posix_compat PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/compat/include)
target_link_libraries(posix_compat PUBLIC ws2_32 advapi32)

function(posix_port target)
    target_link_libraries(${target} PRIVATE posix_compat)
    target_include_directories(${target} BEFORE PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/compat/include)
    target_compile_options(${target} PRIVATE ${COMMON_FLAGS}
        /FI${CMAKE_CURRENT_SOURCE_DIR}/compat/include/compat.h)
    target_sources(${target} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/compat/utf8.manifest)
endfunction()

# config.h: like `make`, copy config.def.h on the first build; edit the copy.
if(NOT EXISTS ${SRC}/config.h)
    configure_file(${SRC}/config.def.h ${CMAKE_CURRENT_BINARY_DIR}/config.h COPYONLY)
endif()

# PDCursesMod (public domain), wincon backend, pinned. -DPDCURSES_DIR=... to
# use a local checkout instead of downloading.
include(FetchContent)
if(NOT PDCURSES_DIR)
    FetchContent_Declare(pdcursesmod
        GIT_REPOSITORY https://github.com/Bill-Gray/PDCursesMod.git
        GIT_TAG        8df2949d368f21e290a25280bdd5f826f6c9f648
        SOURCE_SUBDIR  do-not-add-subdirectory)
    FetchContent_MakeAvailable(pdcursesmod)
    set(PDCURSES_DIR ${pdcursesmod_SOURCE_DIR})
endif()
file(GLOB PDC_CORE ${PDCURSES_DIR}/pdcurses/*.c)
file(GLOB PDC_PORT ${PDCURSES_DIR}/wincon/*.c)
add_library(pdcurses STATIC ${PDC_CORE} ${PDC_PORT})
target_include_directories(pdcurses PUBLIC ${PDCURSES_DIR})
# PDC_NCMOUSE is application-only: the library defines both mouse APIs.
target_compile_definitions(pdcurses PUBLIC PDC_WIDE PDC_FORCE_UTF8)
target_compile_options(pdcurses PRIVATE /W1 /utf-8 /D_CRT_SECURE_NO_WARNINGS)
target_link_libraries(pdcurses PUBLIC user32 advapi32 winmm)

add_executable(dvtm ${SRC}/dvtm.c ${SRC}/vt.c)
target_include_directories(dvtm PRIVATE ${SRC} ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(dvtm PRIVATE VERSION="0.15-win32" NDEBUG PDC_NCMOUSE)
target_link_libraries(dvtm PRIVATE pdcurses)
posix_port(dvtm)

# Test driver: a scripted ConPTY "terminal" (see tests/run-tests.ps1).
add_executable(ptyrun tests/ptyrun.c)
target_compile_options(ptyrun PRIVATE /W3 /utf-8 /D_CRT_SECURE_NO_WARNINGS)
