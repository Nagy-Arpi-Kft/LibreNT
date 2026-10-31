
include_directories(${LIBRENT_SOURCE_DIR}/sdk/include/librent/subsys)
add_executable(lsass lsass.c lsass.rc)
set_module_type(lsass win32gui UNICODE)
add_importlibs(lsass advapi32 lsasrv samsrv msvcrt kernel32 ntdll)
add_cd_file(TARGET lsass DESTINATION librent/system32 FOR all)
