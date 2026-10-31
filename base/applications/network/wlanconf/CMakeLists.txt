
include_directories(
    BEFORE include
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/drivers/ndisuio)

add_executable(wlanconf wlanconf.c wlanconf.rc)
set_module_type(wlanconf win32cui UNICODE)
target_link_libraries(wlanconf conutils)
add_importlibs(wlanconf iphlpapi msvcrt kernel32)
add_cd_file(TARGET wlanconf DESTINATION librent/system32 FOR all)
