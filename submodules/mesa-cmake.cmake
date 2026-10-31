# SPDX-License-Identifier: GPL-3.0-or-later
# Common arguments for the Mesa CMake build against the LibreNT SDK.
# Homebrew's bison is keg-only; Apple's /usr/bin/bison is too old for Mesa.
set(_mesa_bison_hints)
if(CMAKE_HOST_APPLE)
    list(APPEND _mesa_bison_hints /opt/homebrew/opt/bison/bin /usr/local/opt/bison/bin)
endif()
find_program(MESA_BISON NAMES bison HINTS ${_mesa_bison_hints} REQUIRED)
find_program(MESA_FLEX NAMES flex REQUIRED)
find_program(MESA_NINJA NAMES ninja REQUIRED)
find_program(MESA_PYTHON NAMES python3 python REQUIRED)
set(MESA_CMAKE_ARGS
    -DCMAKE_TOOLCHAIN_FILE:FILEPATH=${LIBRENT_SOURCE_DIR}/submodules/librent-sdk.cmake
    -DCMAKE_MAKE_PROGRAM:FILEPATH=${MESA_NINJA}
    -DCMAKE_BUILD_TYPE:STRING=Release
    -DLIBRENT_CLANG_LLVM_MINGW_ROOT:PATH=${LIBRENT_CLANG_LLVM_MINGW_ROOT}
    -DMESA_LIBRENT_SDK:BOOL=ON
    -DPython3_EXECUTABLE:FILEPATH=${MESA_PYTHON}
    -DBISON_EXECUTABLE:FILEPATH=${MESA_BISON}
    -DFLEX_EXECUTABLE:FILEPATH=${MESA_FLEX})
