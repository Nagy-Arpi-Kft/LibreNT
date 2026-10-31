# Copyright 2026 Ahmed ARIF <arif.ing@outlook.com>
# SPDX-License-Identifier: GPL-3.0-or-later

include_directories(
    ${LIBRENT_SOURCE_DIR}/dll/win32/mmdevapi
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/libs/sound
    ${LIBRENT_SOURCE_DIR}/drivers/wdm/audio/legacy/wdmaud)

set_source_files_properties(
    sessionabi.c
    ${LIBRENT_SOURCE_DIR}/dll/win32/mmdevapi/reactos_session.c
    PROPERTIES COMPILE_DEFINITIONS __WINESRC__)

list(APPEND SESSION_SOURCE
    sessionabi.c
    sessionguid.c
    sessionharness.c
    ${LIBRENT_SOURCE_DIR}/dll/win32/mmdevapi/reactos_session.c)

add_executable(mmdevapi_child mmdevapi_child.c ${SESSION_SOURCE})
target_compile_definitions(mmdevapi_child PRIVATE _FORCENAMELESSUNION _FORCENAMELESSSTRUCT "CONST_VTABLE=")
set_module_type(mmdevapi_child win32cui)
target_link_libraries(mmdevapi_child uuid wine)
add_importlibs(mmdevapi_child ole32 setupapi advapi32 msvcrt kernel32 ntdll)
add_dependencies(mmdevapi_child dxsdk)

add_executable(mmdevapi_apitest
    deviceenum.c
    exclusivestream.c
    renderstream.c
    sandboxaudio.c
    sessionapi.c
    sessioncrossproc.c
    sessionpublic.c
    sessionregistry.c
    testlist.c
    wdmaudbroker.c
    ${SESSION_SOURCE})
target_compile_definitions(mmdevapi_apitest PRIVATE _FORCENAMELESSUNION _FORCENAMELESSSTRUCT "CONST_VTABLE=")
set_module_type(mmdevapi_apitest win32cui)
target_link_libraries(mmdevapi_apitest uuid wine)
add_importlibs(mmdevapi_apitest ole32 user32 advapi32 setupapi msvcrt kernel32 ntdll)
add_dependencies(mmdevapi_apitest dxsdk mmdevapi_child)

add_rostests_file(TARGET mmdevapi_apitest)
add_rostests_file(TARGET mmdevapi_child)
