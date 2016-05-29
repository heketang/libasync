﻿module libasync.internals.kqueue;
nothrow:
import core.stdc.stdint : intptr_t, uintptr_t;
version(Posix)
	public import core.sys.posix.signal : timespec;

version (FreeBSD) {
	public import core.sys.freebsd.sys.event;
	immutable HasKqueue = true;
}
version (OSX) immutable HasKqueue = true;
else immutable HasKqueue = false;

extern(C):
@nogc:

enum O_EVTONLY = 0x8000;

/* While these are in druntime, they are - as of 2.071 - not marked as @nogc.
 * So declare them here as such for platforms with kqueue. */
static if (HasKqueue) {
	int kqueue();
	int kevent(int kq, const kevent_t *changelist, int nchanges,
	           kevent_t *eventlist, int nevents,
	           const timespec *timeout);
}

version(OSX):

enum : short
{
	EVFILT_READ     =  -1,
	EVFILT_WRITE    =  -2,
	EVFILT_AIO      =  -3, /* attached to aio requests */
	EVFILT_VNODE    =  -4, /* attached to vnodes */
	EVFILT_PROC     =  -5, /* attached to struct proc */
	EVFILT_SIGNAL   =  -6, /* attached to struct proc */
	EVFILT_TIMER    =  -7, /* timers */
	EVFILT_MACHPORT   =  -8, /* Mach portsets */
	EVFILT_FS       =  -9, /* filesystem events */
	EVFILT_USER      = -10, /* User events */
	EVFILT_VM		= -12, /* virtual memory events */
	EVFILT_SYSCOUNT =  11
}

extern(D) void EV_SET(kevent_t* kevp, typeof(kevent_t.tupleof) args)
{
	*kevp = kevent_t(args);
}

struct kevent_t
{
	uintptr_t    ident; /* identifier for this event */
	short       filter; /* filter for event */
	ushort       flags;
	uint        fflags;
	intptr_t      data;
	void        *udata; /* opaque user data identifier */
}

enum : ushort
{
	/* actions */
	EV_ADD      = 0x0001, /* add event to kq (implies enable) */
	EV_DELETE   = 0x0002, /* delete event from kq */
	EV_ENABLE   = 0x0004, /* enable event */
	EV_DISABLE  = 0x0008, /* disable event (not reported) */
	
	/* flags */
	EV_ONESHOT  = 0x0010, /* only report one occurrence */
	EV_CLEAR    = 0x0020, /* clear event state after reporting */
	EV_RECEIPT  = 0x0040, /* force EV_ERROR on success, data=0 */
	EV_DISPATCH = 0x0080, /* disable event after reporting */
	
	EV_SYSFLAGS = 0xF000, /* reserved by system */
	EV_FLAG1    = 0x2000, /* filter-specific flag */
	
	/* returned values */
	EV_EOF      = 0x8000, /* EOF detected */
	EV_ERROR    = 0x4000, /* error, data contains errno */
}

enum : uint
{
	/*
	 * data/hint flags/masks for EVFILT_USER, shared with userspace
	 *
	 * On input, the top two bits of fflags specifies how the lower twenty four
	 * bits should be applied to the stored value of fflags.
	 *
	 * On output, the top two bits will always be set to NOTE_FFNOP and the
	 * remaining twenty four bits will contain the stored fflags value.
	 */
	NOTE_FFNOP      = 0x00000000, /* ignore input fflags */
	NOTE_FFAND      = 0x40000000, /* AND fflags */
	NOTE_FFOR       = 0x80000000, /* OR fflags */
	NOTE_FFCOPY     = 0xc0000000, /* copy fflags */
	NOTE_FFCTRLMASK = 0xc0000000, /* masks for operations */
	NOTE_FFLAGSMASK = 0x00ffffff,
	
	NOTE_TRIGGER    = 0x01000000, /* Cause the event to be
								  triggered for output. */
	
	/*
	 * data/hint flags for EVFILT_{READ|WRITE}, shared with userspace
	 */
	NOTE_LOWAT      = 0x0001, /* low water mark */
	
	/*
	 * data/hint flags for EVFILT_VNODE, shared with userspace
	 */
	NOTE_DELETE     = 0x0001, /* vnode was removed */
	NOTE_WRITE      = 0x0002, /* data contents changed */
	NOTE_EXTEND     = 0x0004, /* size increased */
	NOTE_ATTRIB     = 0x0008, /* attributes changed */
	NOTE_LINK       = 0x0010, /* link count changed */
	NOTE_RENAME     = 0x0020, /* vnode was renamed */
	NOTE_REVOKE     = 0x0040, /* vnode access was revoked */
	
	/*
	 * data/hint flags for EVFILT_PROC, shared with userspace
	 */
	NOTE_EXIT       = 0x80000000, /* process exited */
	NOTE_FORK       = 0x40000000, /* process forked */
	NOTE_EXEC       = 0x20000000, /* process exec'd */
	NOTE_PCTRLMASK  = 0xf0000000, /* mask for hint bits */
	NOTE_PDATAMASK  = 0x000fffff, /* mask for pid */
	
	/* additional flags for EVFILT_PROC */
	NOTE_TRACK      = 0x00000001, /* follow across forks */
	NOTE_TRACKERR   = 0x00000002, /* could not track child */
	NOTE_CHILD      = 0x00000004, /* am a child process */
}
