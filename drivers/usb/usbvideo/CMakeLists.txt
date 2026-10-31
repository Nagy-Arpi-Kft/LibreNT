list(APPEND SOURCE
    usbvideo.c)

add_library(usbvideo MODULE
    ${SOURCE})

set_module_type(usbvideo kernelmodedriver)
add_importlibs(usbvideo ntoskrnl hal usbd)
add_cd_file(TARGET usbvideo DESTINATION librent/system32/drivers NO_CAB FOR all)
