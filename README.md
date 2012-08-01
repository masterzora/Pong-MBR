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

While this code should work on most modern x86 machines it has so far only been tested with QEMU and no guarantees are made about portability.
