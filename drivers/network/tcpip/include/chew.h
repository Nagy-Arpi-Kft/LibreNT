/*
 * COPYRIGHT:       See COPYING in the top level directory
 * PROJECT:         LibreNT kernel
 * FILE:            include/librent/chew/chew.h
 * PURPOSE:         Common Highlevel Executive Worker
 *
 * PROGRAMMERS:     arty (ayerkes@speakeasy.net)
 */

#ifndef _LIBRENT_CHEW_H
#define _LIBRENT_CHEW_H

/**
 * Initialize CHEW, given a device object (since IoAllocateWorkItem relies on
 * it).
 */
VOID ChewInit(PDEVICE_OBJECT DeviceObject);

/**
 * Shutdown CHEW, waits for remaining work items.
 */
VOID ChewShutdown(VOID);

/**
 * Creates and queues a work item.
 */
BOOLEAN ChewCreate(VOID (*Worker)(PVOID), PVOID WorkerContext);
BOOLEAN ChewCreateHighPriority(VOID (*Worker)(PVOID), PVOID WorkerContext);

#endif/*_LIBRENT_CHEW_H*/
