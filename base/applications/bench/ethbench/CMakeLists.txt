add_executable(ethbench ethbench.c)
set_module_type(ethbench win32cui)
add_importlibs(ethbench ws2_32 msvcrt kernel32 ntdll)
add_cd_file(TARGET ethbench DESTINATION librent/system32 FOR all)
