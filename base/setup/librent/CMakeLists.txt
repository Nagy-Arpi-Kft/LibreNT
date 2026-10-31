
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/../lib
#    ${LIBRENT_SOURCE_DIR}/base/setup/lib
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/drivers
    ${LIBRENT_SOURCE_DIR}/sdk/lib/tzlib)

list(APPEND SOURCE
    spapisup/fileqsup.c
    spapisup/infsupp.c
    account.c
    alongside.c
    diskinfo.c
    diskpage.c
    frame.c
    langpage.c
    librent.c
    selftest.c
    wizard.c
    librent.h)

file(GLOB librent_rc_deps res/*.*)
list(APPEND librent_rc_deps
    ${LIBRENT_SOURCE_DIR}/base/system/userinit/res/rosbitmap.bmp
    ${LIBRENT_SOURCE_DIR}/base/system/userinit/res/rosbitmap_mask.bmp)
add_rc_deps(librent.rc ${librent_rc_deps})
add_executable(librent ${SOURCE} librent.rc)

add_pch(librent librent.h SOURCE)
set_module_type(librent win32gui UNICODE)
target_link_libraries(librent uuid tzlib volresize)
add_delay_importlibs(librent setuplib)
add_importlibs(librent advapi32 gdi32 user32 comctl32 dwmapi shlwapi setupapi ole32 oleaut32 version msvcrt kernel32 ntdll)
add_cd_file(TARGET librent DESTINATION librent NO_CAB FOR bootcd livecd)
add_cd_file(TARGET librent DESTINATION ${ARCH} FOR preinstall)

list(APPEND OOBE_SOURCE
    account.c
    apps.c
    frame.c
    langpage.c
    oobe.c
    librent.h)

add_rc_deps(oobe.rc ${librent_rc_deps})
add_executable(oobe ${OOBE_SOURCE} oobe.rc)
add_pch(oobe librent.h OOBE_SOURCE)
set_module_type(oobe win32gui UNICODE)
target_link_libraries(oobe uuid tzlib)
add_importlibs(oobe advapi32 gdi32 user32 comctl32 dwmapi setupapi ole32 oleaut32 msi wintrust crypt32 bcrypt netapi32 samlib userenv syssetup msvcrt kernel32 ntdll)
add_cd_file(TARGET oobe DESTINATION librent/system32/oobe FOR all)
add_cd_file(FILE ${CMAKE_CURRENT_SOURCE_DIR}/oobeapps.inf DESTINATION librent/system32/oobe FOR all)
