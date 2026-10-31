
include_directories(
    ${LIBRENT_SOURCE_DIR}
    ${LIBRENT_SOURCE_DIR}/sdk/lib/drivers/arblib
    ${LIBRENT_SOURCE_DIR}/sdk/lib/cmlib
    include
    ${CMAKE_CURRENT_BINARY_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/include/internal
    ${LIBRENT_SOURCE_DIR}/sdk/include/librent/drivers)

add_definitions(
    -D_NTOSKRNL_
    -D_NTSYSTEM_
    -DEX_LEGACY_PUSH_LOCKS
    -DNTDDI_VERSION=${LIBRENT_TARGET_NTDDI})
set_source_files_properties(${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdwatchdog.c PROPERTIES COMPILE_DEFINITIONS "KD_LOG_WATCHDOG_DEFAULT_SECONDS=${_KD_LOG_WATCHDOG_DEFAULT_SECONDS}")

# KiBugCheckDebugBreak relies on native SEH catching the deliberate breakpoint.
# Clang otherwise only models synchronous exceptions at selected instructions.
if((ARCH STREQUAL "amd64" OR ARCH STREQUAL "arm64") AND CMAKE_C_COMPILER_ID STREQUAL "Clang" AND NOT USE_DUMMY_PSEH)
    set_property(SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/bug.c PROPERTY SKIP_PRECOMPILE_HEADERS ON)
    set_property(SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/bug.c APPEND PROPERTY COMPILE_OPTIONS -Xclang -fasync-exceptions)
endif()

if(ARCH STREQUAL "arm64")
    set_property(SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/irql.c ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/spinlock.c PROPERTY SKIP_PRECOMPILE_HEADERS ON)
    set_property(SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/irql.c ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/spinlock.c APPEND PROPERTY COMPILE_DEFINITIONS _NTHALDLL_)
endif()

list(APPEND SOURCE
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmalloc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmapi.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmboot.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmconfig.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmcontrl.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmdata.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmdelay.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmhook.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmhvlist.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cminit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmkcbncb.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmlazy.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmmapvw.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmnotify.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmparse.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmquota.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmse.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmsecach.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmsysini.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmtrans.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmvalche.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/cmwraprs.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/ntapi.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/dbgk/dbgkobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/dbgk/dbgkutil.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/atom.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/callback.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/dbgctrl.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/efi.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/event.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/evtpair.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/exintrin.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/fmutex.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/handle.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/harderr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/hdlsterm.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/init.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/interlocked.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/keyedevt.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/license.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/locale.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/lookas.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/mutant.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/partition.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/profile.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/pushlock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/resource.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/reserve.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/rundown.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/sem.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/shutdown.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/spinlock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/sysinfo.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/time.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/timer.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/uuid.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/wddm.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/win32k.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/wnf.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/work.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/xipdisp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/zone.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/dbcsname.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/fastio.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/faulttol.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/bytelock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/cancelwait.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/filter.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/filtrctx.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/fsfilter.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/fsrtlpc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/largemcb.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/mcb.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/name.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/notify.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/oplock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/pnp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/stackovf.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/tunnel.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fsrtl/unc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fstub/disksup.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fstub/fstubex.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fstub/halstub.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/fstub/translate.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/inbv/bootanim.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/inbv/inbv.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/inbv/inbvgop.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/inbv/inbvport.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/adapter.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/arcname.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/bootlog.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/controller.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/device.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/deviface.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/bootcb.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/driver.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/error.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/file.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iocomp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/waitcomp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/ioevent.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iofunc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iommu.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/ksr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iomdl.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iomgr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iorsrce.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iotimer.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/iowork.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/irp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/irq.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/ramdisk.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/rawfs.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/remlock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/symlink.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/util.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/iomgr/volume.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/rootarb.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/dif.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/devaction.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/devnode.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/plugplay.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpdma.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpinit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpirp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpmap.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpmgr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpnotify.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpreport.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnppar.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpres.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnpresdb.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnproot.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/pnpmgr/pnputil.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/io/debug.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdapi.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdbreak.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kddata.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kddump.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdinit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdlock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdprint.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdtrap.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/apc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/balmgr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/bug.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/clock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/config.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/devqueue.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/dpc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/eventobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/except.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/freeze.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/gate.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/gmutex.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/ipi.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/passint.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/krnlinit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/mutex.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/procgrp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/processor.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/procinfo.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/procobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/profobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/queue.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/semphobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/smpdbg.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/spinlock.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/thrdobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/thrdschd.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/time.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/timerobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/wait.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/kse/kse.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/va/varegion.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/heap/heapcore.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/heap/heapseg.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/heap/heaplfh.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/heap/heapvs.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/heap/heaplarge.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/heap/heapdebug.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/track/tagtable.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/ex/exinit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/ex/exalloc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/ex/exfree.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/ex/exquota.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/ex/exquery.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/devicemap.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obcallback.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obdir.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obhandle.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obinit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/oblife.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/oblink.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obns.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obname.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obref.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obsdcach.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obsecure.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ob/obwait.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/events.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/poshtdwn.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/povolume.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/pep.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/pofx.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/power.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/powerlimit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/hiber.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/sleep.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/standby.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/thermal.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/po/ttm.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/apiset.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/apphelp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/debug.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/energy.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/job.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/kill.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/pico.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/process.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/property.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/psmgr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/psnotify.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/query.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/quota.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/security.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/state.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/thread.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/tls.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/win32.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/avltree.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/rbtree.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/cmresource.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/guid.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/libsupp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/locale.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/misc.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/security.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/system.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/time.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/unicode.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/wddm.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/access.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/accesschk.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/acl.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/audit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/client.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/objtype.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/priv.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/sd.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/sddl.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/semgr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/sid.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/sqos.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/srm.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/subject.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/token.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/tokenadj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/tokencls.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/tokenlif.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/tm/enlist.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/tm/rm.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/tm/tm.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/tm/tx.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/vf/driver.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/wmi/etwlog.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/wmi/guidobj.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/wmi/pcw.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/wmi/provider.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/wmi/smbios.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/wmi/wmi.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/wmi/wmidrv.c)

list(APPEND SOURCE
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpchelp.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpcinit.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpcport.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpcconn.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpcsend.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpcattr.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpccompl.c
    ${LIBRENT_SOURCE_DIR}/ntoskrnl/alpc/alpclpc.c)

if(DBG)
    list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/se/debug.c)
    if(KDBG)
        list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdwatchdog.c)
    endif()
endif()

list(APPEND ASM_SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/zw.S)

if(ARCH STREQUAL "i386")
    list(APPEND ASM_SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/i386/fastinterlck_asm.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/i386/ioport.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/ctxswitch.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/trap.s
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/usercall_asm.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/zeropage.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/i386/prefetch.S)
    list(APPEND SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/i386/cmhardwr.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/i386/kdx86.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/abios.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/cpu.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/context.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/exp.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/freeze.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/irqobj.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/kiinit.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/ldt.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/mtrr.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/patpge.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/thrdini.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/traphdlr.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/usercall.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/i386/v86vdm.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/i386/psctx.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/i386/psldt.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/vdm/vdmmain.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/vdm/vdmexec.c)
elseif(ARCH STREQUAL "amd64")
    list(APPEND ASM_SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/boot.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/ctxswitch.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/trap.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/usercall_asm.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/zeropage.S)
    list(APPEND SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/i386/cmhardwr.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdcontrol.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/amd64/kdx64.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/context.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/cpu.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/except.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/freeze.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/interrupt.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/ipi.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/irql.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/kiinit.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/krnlinit.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/spinlock.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/thrdini.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/amd64/psctx.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/stubs.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/traphandler.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/usercall.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/amd64/xstate.c)
elseif(ARCH STREQUAL "arm")
    list(APPEND ASM_SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/arm/ioport.s
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/boot.s
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/ctxswtch.s
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/stubs_asm.s
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/trap.s)
    list(APPEND SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/arm/cmhardwr.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/arm/kdarm.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/cpu.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/exp.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/interrupt.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/kiinit.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/thrdini.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/trapc.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm/usercall.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/arm/psctx.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/arm/rtlexcpt.c)
elseif(ARCH STREQUAL "arm64")
    include_directories(${LIBRENT_SOURCE_DIR}/ntoskrnl/arch/arm64/include)
    list(REMOVE_ITEM SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/ipi.c)
    list(APPEND ASM_SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/chkstk.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/earlyvec.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/fpstate_asm.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/trapvec.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/trapret.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/ctxswitch.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/usercall_asm.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/bootstack.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/zeropage.S
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/arm64/ehandler_asm.S
        ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/string/arm64/strcpy.S
        ${LIBRENT_SOURCE_DIR}/sdk/lib/crt/string/arm64/wcscmp.S)
    if(MSVC)
        list(APPEND ASM_SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/msvc.S)
    endif()
    list(APPEND SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/config/arm64/cmhardwr.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/arm64/init.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/arm64/probe.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ex/arm64/ioport.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/kdcontrol.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd64/arm64/kdarm64.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/atomics.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/boot.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/context.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/cpu.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/cpuaudit.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/early_uart.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/hypervisor.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/exceptinit.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/exp.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/floatstubs.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/freeze.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/interrupt.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/ipi.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/irql.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/kiinit.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/rtlshim.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/smpdbg.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/spinlock.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/stubs.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/thrdini.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/topology.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/trapc.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/trapdump.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ke/arm64/usercall.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/ps/arm64/psctx.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/arm64/ehandler.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/arm64/rtlexcpt.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/rtl/arm64/rtlstubs.c)
endif()

if(NOT _WINKD_)
if(KDBG)
    add_definitions(-DKDBG)
endif()

    if(ARCH STREQUAL "i386")
        list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/i386/kdserial.c)
        if(KDBG)
            list(APPEND ASM_SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/i386/kdb_help.S)
            list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/i386/i386-dis.c)
        endif()
    elseif(ARCH STREQUAL "amd64")
        list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/i386/kdserial.c)
        if(KDBG)
            list(APPEND ASM_SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/amd64/kdb_help.S)
            list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/i386/i386-dis.c)
        endif()
    elseif(ARCH STREQUAL "arm")
        list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/arm/kdserial.c)
    elseif(ARCH STREQUAL "arm64")
        list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/arm64/kdserial.c)
        if(KDBG)
            list(APPEND ASM_SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/arm64/kdb_help.S)
            list(APPEND SOURCE ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/arm64/arm64-dis.c)
        endif()
    endif()

    if(KDBG)
        list(APPEND SOURCE
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdbg.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/nvs/pool/debug/poolkdbg.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdb.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdb_cli.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdb_cmdhist.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdb_expr.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdb_print.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdb_symbols.c
            ${LIBRENT_SOURCE_DIR}/ntoskrnl/kdbg/kdb_symz.c)
    endif()

    list(APPEND SOURCE
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdinfo.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdio.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdmain.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdnetio.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdprompt.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdps2kbd.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdserial.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdterminal.c
        ${LIBRENT_SOURCE_DIR}/ntoskrnl/kd/kdusbkbd.c)

else()
    add_definitions(-D_WINKD_)
endif()
