include_directories(${LIBRENT_SOURCE_DIR}/drivers/bus/vmbus)

add_library(dmvsc MODULE dmvsc.c dmvsc.rc)
set_module_type(dmvsc kernelmodedriver)
add_importlibs(dmvsc vmbus ntoskrnl hal)
add_cd_file(TARGET dmvsc DESTINATION librent/system32/drivers FOR all)
add_driver_inf(dmvsc dmvsc.inf)
