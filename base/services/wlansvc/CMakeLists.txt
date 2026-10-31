
include_directories(${LIBRENT_SOURCE_DIR}/sdk/include/librent/idl)
add_rpc_files(server ${LIBRENT_SOURCE_DIR}/sdk/include/librent/idl/wlansvc.idl)

list(APPEND SOURCE
    wlansvc.c
    rpcserver.c
    core.c
    scan.c
    connect.c
    profile.c
    notify.c
    nwifi_ioctl.c
    precomp.h
    wlansvc.h
    ${CMAKE_CURRENT_BINARY_DIR}/wlansvc_s.c)

add_executable(wlansvc ${SOURCE} ifdesc.c wlansvc.rc)

if(NOT MSVC)
    target_link_libraries(wlansvc ${PSEH_LIB})
endif()

set_module_type(wlansvc win32cui UNICODE)
add_importlibs(wlansvc advapi32 crypt32 rpcrt4 iphlpapi msvcrt kernel32 ntdll)
add_pch(wlansvc precomp.h SOURCE)
add_cd_file(TARGET wlansvc DESTINATION librent/system32 FOR all)
