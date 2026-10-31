
include_directories(${LIBRENT_SOURCE_DIR}/sdk/include/librent/drivers)

list(APPEND SOURCE
    blue.c
    font.c
    blue.h)

add_library(blue MODULE ${SOURCE} blue.rc)
set_module_type(blue kernelmodedriver)
add_importlibs(blue ntoskrnl hal)
add_pch(blue blue.h SOURCE)
add_cd_file(TARGET blue DESTINATION librent/system32/drivers NO_CAB FOR all)
add_registry_inf(blue_reg.inf)
