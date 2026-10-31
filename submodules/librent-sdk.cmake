# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 Ahmed ARIF <arif.ing@outlook.com>
#
# Toolchain for the nested third-party builds (Mesa, FEX) against the LibreNT
# SDK headers, the LibreNT CRT and import libraries, and the tree's matching
# libc++ runtime.

set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR "${LIBRENT_SDK_ARCH}")
if(NOT DEFINED CMAKE_TRY_COMPILE_TARGET_TYPE)
    set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
endif()
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
    LIBRENT_SDK_ARCH LIBRENT_SDK_TRIPLE LIBRENT_SDK_ARCH_FLAGS LIBRENT_SDK_SOURCE_DIR
    LIBRENT_SDK_BUILD_DIR LIBRENT_SDK_LIBDIR LIBRENT_SDK_CXX_RUNTIME LIBRENT_SDK_CRT
    LIBRENT_CLANG_LLVM_MINGW_ROOT)
if(NOT DEFINED LIBRENT_SDK_CRT)
    set(LIBRENT_SDK_CRT full)
endif()

set(CMAKE_C_COMPILER "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/clang")
set(CMAKE_CXX_COMPILER "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/clang++")
set(CMAKE_ASM_COMPILER "${CMAKE_C_COMPILER}")
set(CMAKE_C_COMPILER_TARGET "${LIBRENT_SDK_TRIPLE}")
set(CMAKE_CXX_COMPILER_TARGET "${LIBRENT_SDK_TRIPLE}")
set(CMAKE_ASM_COMPILER_TARGET "${LIBRENT_SDK_TRIPLE}")
set(CMAKE_AR "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/llvm-ar")
set(CMAKE_RANLIB "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/llvm-ranlib")
set(CMAKE_LINKER "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/ld.lld")
set(CMAKE_RC_COMPILER "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/llvm-windres")
set(CMAKE_DLLTOOL "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/llvm-dlltool")
set(CMAKE_NM "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/llvm-nm")
set(CMAKE_OBJCOPY "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/llvm-objcopy")
set(CMAKE_STRIP "${LIBRENT_CLANG_LLVM_MINGW_ROOT}/bin/llvm-strip")

include("${CMAKE_CURRENT_LIST_DIR}/librent-sdk-flags.cmake")
librent_sdk_flags(_librent_sdk
    COMPILER "${CMAKE_C_COMPILER}"
    ARCH "${LIBRENT_SDK_ARCH}"
    ARCH_FLAGS "${LIBRENT_SDK_ARCH_FLAGS}"
    SOURCE_DIR "${LIBRENT_SDK_SOURCE_DIR}"
    BUILD_DIR "${LIBRENT_SDK_BUILD_DIR}"
    LIBDIR "${LIBRENT_SDK_LIBDIR}"
    CXX_RUNTIME "${LIBRENT_SDK_CXX_RUNTIME}"
    CRT "${LIBRENT_SDK_CRT}")

set(CMAKE_C_FLAGS "${_librent_sdk_C_FLAGS}" CACHE STRING "C flags" FORCE)
set(CMAKE_CXX_FLAGS "${_librent_sdk_CXX_FLAGS}" CACHE STRING "C++ flags" FORCE)
set(CMAKE_ASM_FLAGS "${_librent_sdk_ASM_FLAGS}" CACHE STRING "ASM flags" FORCE)
set(CMAKE_RC_FLAGS "--target=${LIBRENT_SDK_TRIPLE} ${_librent_sdk_RC_FLAGS}" CACHE STRING "RC flags" FORCE)
set(_librent_sdk_windows_libraries)
if(LIBRENT_SDK_CRT STREQUAL "full")
    set(_librent_sdk_windows_libraries "-lkernel32 -luser32 -lgdi32 -lwinspool -lshell32 -lole32 -loleaut32 -luuid -lcomdlg32 -ladvapi32 ")
endif()
set(CMAKE_C_STANDARD_LIBRARIES "${_librent_sdk_windows_libraries}${_librent_sdk_C_LIBRARIES}" CACHE STRING "Standard C libraries" FORCE)
set(CMAKE_CXX_STANDARD_LIBRARIES "${_librent_sdk_windows_libraries}${_librent_sdk_CXX_LIBRARIES}" CACHE STRING "Standard C++ libraries" FORCE)

set(_librent_sdk_link "${_librent_sdk_LINK_FLAGS}")
set(CMAKE_SHARED_LINKER_FLAGS_INIT "${_librent_sdk_link} -Wl,-entry,DllMainCRTStartup")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${_librent_sdk_link} -Wl,-entry,DllMainCRTStartup")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${_librent_sdk_link} -Wl,-entry,mainCRTStartup")

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
