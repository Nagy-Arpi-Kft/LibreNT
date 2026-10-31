
add_subdirectory(fonts)
add_subdirectory(inf)
add_subdirectory(nls)
add_subdirectory(sdb)
add_subdirectory(sounds)
add_subdirectory(themes)
add_subdirectory(winmetadata)

add_cd_file(FILE ${CMAKE_CURRENT_SOURCE_DIR}/drivers/etc/hosts DESTINATION librent/system32/drivers/etc FOR all)
add_cd_file(FILE ${CMAKE_CURRENT_SOURCE_DIR}/drivers/etc/KDBinit DESTINATION librent/system32/drivers/etc FOR all)
add_cd_file(FILE ${CMAKE_CURRENT_SOURCE_DIR}/drivers/etc/networks DESTINATION librent/system32/drivers/etc FOR all)
add_cd_file(FILE ${CMAKE_CURRENT_SOURCE_DIR}/drivers/etc/protocol DESTINATION librent/system32/drivers/etc FOR all)
add_cd_file(FILE ${CMAKE_CURRENT_SOURCE_DIR}/drivers/etc/services DESTINATION librent/system32/drivers/etc FOR all)

add_cd_file(FILE ${CMAKE_CURRENT_SOURCE_DIR}/systemcompatible.manifest DESTINATION librent/winsxs/manifests FOR all)
