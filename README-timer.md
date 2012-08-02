Pong-MBR
========

I haven't played with x86 asm for a while so why not see if I can make an MBR that plays Pong?

For two human players, first to 9 points wins.

Controls:
- Player 1
 - W: move paddle up
 - S: move paddle down
- Player 2
 - O: move paddle up
 - L: move paddle down

Compile with NASM (`nasm pongmbr.nasm`).  Either install to the boot sector (`dd if=pongmbr of=/path/to/disk bs=512 count=1`) and boot or test with QEMU (`qemu-system-i386 pongmbr`).  Note that installing the MBR will destroy what is currently there including the partition table so beware.

Speed is controlled via the TIMER macro.  Larger numbers slow the game down, smaller numbers speed the game up between 1 and 65535.  Zero is also a valid number but it actually means 65536 because division by zero is bad.  This speed should be (routhly) platform-independent though it isn't rigorously strict so I could save a few more bytes.

While this code should work on most modern x86 machines it has so far only been tested with QEMU and VirtualBox. No guarantees are made about portability.
