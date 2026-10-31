
include_directories(
    ${LIBRENT_SOURCE_DIR}/subsystems/win32/csrsrv/include
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/subsys)

add_executable(csrss csrss.c csrss.rc)
set_module_type(csrss nativecui)
target_link_libraries(csrss nt)
add_importlibs(csrss csrsrv ntdll)
add_dependencies(csrss psdk bugcodes)
add_cd_file(TARGET csrss DESTINATION librent/system32 FOR all)
