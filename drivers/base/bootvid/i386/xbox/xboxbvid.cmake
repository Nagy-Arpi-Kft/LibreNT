
set(MODULE_HEADER ${CMAKE_CURRENT_LIST_DIR}/xbox.h) # For precomp.h
list(APPEND SOURCE
    ${MODULE_HEADER}
    ${CMAKE_CURRENT_LIST_DIR}/bootvid.c)

set(LIBRENT_STR_FILE_DESCRIPTION "Original Xbox Boot Video Driver")
