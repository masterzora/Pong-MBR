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

Speed is controlled via the THROTTLE macro.  The default is set to 0x2f22 because this arbitrarily seemed a good speed on my test setup (QEMU on a fairly minimal Arch install on an Eee PC 901).  Different computers are different so I suggest adjusting the throttle and recompiling if the game runs too fast or too slow for your computer.  Larger throttles slow down the game; smaller throttles speed it up.

An experimental alternate version (pongmbr-timer.nasm) replaces the cpu-speed-dependent throttle with a timer-based approach based on real time rather than CPU cycles.  It works in QEMU but it failed my VirtualBox test so I am providing it as an alternate alongside the usable version until I determine the error.  See README-timer.md for more information about that version.

While this code should work on most modern x86 machines it has so far only been tested with QEMU and VirtualBox no guarantees are made about portability.
