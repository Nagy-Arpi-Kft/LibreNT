
set(MODULE_HEADER ${CMAKE_CURRENT_LIST_DIR}/arm.h) # For precomp.h
list(APPEND SOURCE
    ${MODULE_HEADER}
    ${CMAKE_CURRENT_LIST_DIR}/bootvid.c)

set(LIBRENT_STR_FILE_DESCRIPTION "ARM Versatile Boot Video Driver")
