
include_directories(${LIBRENT_SOURCE_DIR}/sdk/include/librent/dll/devmgr)

add_executable(devmgmt devmgmt.c devmgmt.rc)
add_rc_deps(devmgmt.rc ${CMAKE_CURRENT_SOURCE_DIR}/devmgmt.ico)
set_module_type(devmgmt win32gui UNICODE)
add_importlibs(devmgmt devmgr msvcrt kernel32)
add_cd_file(TARGET devmgmt DESTINATION librent/system32 FOR all)
