# Hacking Huawei HG8012H ONT
## Steps to hack a HG8012H, access it and mod the firmware


Due to the change Pepephone ISP made last year migrating from Vodafone to Masmóvil's network, it was necessary for me to obtain an 802.1q-protocol compatible DSL router to be able to use the internet connection. This caused me to retire my Asus DSL-N55u router--which had a stability, configuration and WIFI coverage I was very happy with. So I purchased a Huawei HG556a DSL router and, since this router had a 10/100 switch and pretty mediocre WIFI speed, I also purchased a Linksys EA8500 router that would provide me with the WIFI coverage and gigabit connectivity for my devices. So I configured the Huawei HG556a router in WAN Bridge mode and connected it to the WAN port of the Linksys' router. This configuration gave me excellent performance, even more after flashing DD-WRT on the Linksys router.


Now, I have changed the internet operator, moving to a FTTH connection of 500/300 MB with Cableworld, and they installed a Huawei HG8245U router and an optical splitter whose coaxial output, connected to the house's main TV splitter, distributes the TV channels of the service. As I was very satisfied with the operation and WIFI coverage of the Linksys Ea8500 router, I configured the HG8245U router again in WAN bridge mode, and this is the way in which I have been working.

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/1spliiter.jpg)

At that point several problems arised: the cableworld's HUWAEI router was huge and I lost some space in the living room furniture; the use of two devices (HUAWEI router and optical splitter) forced me to use two power plugs, which increased the entanglement of cables in general. In addition, this router had a high power consumption, which was a waste of resources, since I was not using any of its ethernet outputs (except 1 connected to the Linksys WAN router), its Wi-Fi, nor 90% of its features. So I started looking for an optical router/ONT with the following features: small sized, integrated CATV output, low power consumption and within the Huawei brand so it would be compatible with Cableworld's OLT. The perfect candidate was the Huawei HG8012H ,and in one of my trips to Portugal I was lucky enough to find one for 5€ in Cashconverters (shop price is about 80€).


![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/2HG8012h.jpg)


### Hostility level 0

I got down to work configuring this ONT with my ISP parameters, so I connected an ethernet cable between the ONT and my PC and tried to open http://192.168.1.1 in browser, but I got no response. Then I searched the internet for Huawei documents and technical files and found that for this model, the default IP address is 192.168.100.1 and the access users are telecomadmin:admintelecom and root:admin. After making the relevant IP and subnet changes in the network card of my PC, I went to http://192.168.100.1 in the browser and 'voilà', the WebUi showed and, supposedly, I would be able to start configuring my brand new ONT:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/3login.png)

Unfortunately, none of the two access users I had found in the documentation worked. So it occurred to me pressing the reset button for 30 seconds with a paper clip with the total certainty that this would cause the default access users to be functional again. But I was wrong. After a long time trying to search the internet for a login that would allow me access to the ONT, not only did I not find it but I verified that there is very little information about this device available. As if that were not enough, I discovered that when this ONT comes directly from an ISP, it is usually blocked by them as to not allow access to the configuration, and that way the user can not reuse it with another ISP. In this case, it appeared that the ONT that I bought in Cashconverters had not been purchased directly from HUAWEI, but instead had been installed by a supplier. Things started to get complicated.


### Hostility level 1

I could see that by entering 3 incorrect passwords, the router did not allow retry the login until 1 minute after, so the option of dictionaries and brute force attacks to access was discarded by the amount of time the entire process would take.

Normally many routers allow telnet access to the device as an alternative way of configuration, but in this case it was impossible and the connection closed due to lack of response from the ONT.

Trying to find some weak point in the ONT that allowed me access, I did a port scanner from my PC, with the following command:

nmap -Pn -n -p0- 192.168.100.1


It did not help much, all ports were closed except port 80 (webUi). Port 23 (telnet) was not only not open but was being filtered by the integrated firewall to further complicate things. There was nothing else I could do externally to solve this, so screwdriver in hand I ventured to examine the bowels of the bug.

### Hostility level 2

Once the cover was opened and after a component identification phase, this is what I found:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/4bottom_PCB.jpg)


![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/5spec.jpg)

Of all these components the ones that caught my attention were the serial port pads, the JTAG port and the flash memory. After a search on the internet, I deduced the pinout of both the serial port and the JTAG. They are quite common among HUAWEI router devices.

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/6jtag.png)

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/7serial.jpg)

I tested JTAG port using the parallel port cable that can be seen in the previous photo but I did not get response, so I focused my efforts on the serial port. After connecting a TTL-USB converter and connecting to the virtual COM port using PutTy with a rate of 115200 symbols, I started to see the following bootlog on the screen:

```console
HuaWei StartCode 2012.02 (Mar 25 2014 - 01:04:34)

SPI:
startcode select the uboot to load
the high RAM is :8080103c
startcode uboot boot count:0
Boot load address :0x80000
Use the UbootB to load success


U-Boot 2010.03 (R13C10 Jul 31 2015 - 14:38:54)

DRAM:  128 MB
Boot From SPI flash
Chip Type is SD5115S
SFC : cs0 unrecognized JEDEC id 00ffffff, extended id 00000000
SFC: extend id 0x300
SFC: cs1 s25sl12800 (16384 Kbytes)
SFC: Detected s25sl12800 with page size 262144, total 16777216 bytes
SFC: already protect ON !
SFC: sfc_read flash offset 0x80000, len 0x40000, memory buf 0x81fa0008
*** Warning - bad CRC, using default environment

In:    serial
Out:   serial
Err:   serial
PHY power down !!!
[main.c__5566]::CRC:0x6a8fe445, Magic1:0x5a5a5a5a, Magic2:0xa5a5a5a5, count:0, CommitedArea:0x1, Active:0x1, RunFlag:0x0
SFC : cs0 unrecognized JEDEC id 00ffffff, extended id 00000000
SFC: extend id 0x300
SFC: cs1 s25sl12800 (16384 Kbytes)
SFC: Detected s25sl12800 with page size 262144, total 16777216 bytes
initialize flash success
Start from main system(0x1)!
CRC:0x6a8fe445, Magic1:0x5a5a5a5a, Magic2:0xa5a5a5a5, count:1, CommitedArea:0x1, Active:0x1, RunFlag:0x0
Main area (B) is OK!
CRC:0xc4e775d4, Magic1:0x5a5a5a5a, Magic2:0xa5a5a5a5, count:1, CommitedArea:0x1, Active:0x1, RunFlag:0x0
iRootfsSize to 0x47c1d4
Start copy data from 0x1c9c0054 to 0x86000000 with sizeof 0x0047c1d4 ............Done!
Bootcmd:bootm 0x1c340054 0x86000000
BootArgs:noalign mem=114M console=ttyAMA1,115200 initrd=0x86000040,0x47c194 rdinit=/linuxrc mtdparts=hi_sfc:0x40000(startcode),0x40000(bootA)ro,0x40000(bootB)ro,0x40000(flashcfg)ro,0x40000(slave_param)ro,0x200000(kernelA)ro,0x200000(kernelB)ro,0x480000(rootfsA)ro,0x480000(rootfsB)ro,0x180000(file_system),-(reserved)pcie1_sel=x1 maxcpus=0 user_debug=0x1f panic=1
U-boot Start from NORMAL Mode!

## Booting kernel from Legacy Image at 1c340054 ...
   Image Name:   Linux-2.6.34.10_sd5115v100_wr4.3
   Image Type:   ARM Linux Kernel Image (uncompressed)
   Data Size:    2025204 Bytes =  1.9 MB
   Load Address: 81000000
   Entry Point:  81000000
## Loading init Ramdisk from Legacy Image at 86000000 ...
   Image Name:   cpio
   Image Type:   ARM Linux RAMDisk Image (uncompressed)
   Data Size:    4702612 Bytes =  4.5 MB
   Load Address: 00000000
   Entry Point:  00000000
SFC : cs0 unrecognized JEDEC id 00ffffff, extended id 00000000
SFC: extend id 0x300
SFC: cs1 s25sl12800 (16384 Kbytes)
SFC: Detected s25sl12800 with page size 262144, total 16777216 bytes
   Loading Kernel Image ... SFC: sfc_read flash offset 0x340094, len 0x1ee6f4, memory buf 0x81000000
OK
OK

Starting kernel ...

Uncompressing Linux... done, booting the kernel.
Kernel Early-Debug on Level 0
 V: 0xF1100000 P: 0x00010100 S: 0x00001000 T: 0
 V: 0xF110E000 P: 0x0001010E S: 0x00001000 T: 0
 V: 0xF110F000 P: 0x0001010F S: 0x00001000 T: 0
 V: 0xF1104000 P: 0x00010104 S: 0x00001000 T: 0
 V: 0xF1180000 P: 0x00010180 S: 0x00002000 T: 0
 V: 0xF1400000 P: 0x00010400 S: 0x00001000 T: 12
early_init      72      [arch/arm/mach-sd5115h-v100f/core.c]
sd5115_map_io   223     [arch/arm/mach-sd5115h-v100f/core.c]
smp_init_cpus   163     [arch/arm/mach-sd5115h-v100f/platsmp.c]
sd5115_gic_init_irq     88      [arch/arm/mach-sd5115h-v100f/core.c]
sd5115_timer_init       471     [arch/arm/mach-sd5115h-v100f/core.c]
sd5115_clocksource_init 451     [arch/arm/mach-sd5115h-v100f/core.c]
twd_base :
0xF1180600
sd5115_timer_init       491     [arch/arm/mach-sd5115h-v100f/core.c]
smp_prepare_cpus        174     [arch/arm/mach-sd5115h-v100f/platsmp.c]
hi_kernel_wdt_init      207     [arch/arm/mach-sd5115h-v100f/hi_drv_wdt.c]
sd5115_init     314     [arch/arm/mach-sd5115h-v100f/core.c]
sd5115_init     320     [arch/arm/mach-sd5115h-v100f/core.c]
sd5115_init     320     [arch/arm/mach-sd5115h-v100f/core.c]
sd5115_init     327     [arch/arm/mach-sd5115h-v100f/core.c]
sd5115_init     330     [arch/arm/mach-sd5115h-v100f/core.c]
Linux version 2.6.34.10_sd5115v100_wr4.3 (root@wuhci2lslx00096) (gcc version 4.4.6 (GCC) ) #1 SMP Fri Jul 31 14:38:51 CST 2015
CPU: ARMv7 Processor [413fc090] revision 0 (ARMv7), cr=10c53c7f
CPU: VIPT nonaliasing data cache, VIPT nonaliasing instruction cache
Machine: sd5115
Memory policy: ECC disabled, Data cache writealloc
sd5115 apb bus clk is 100000000
PERCPU: Embedded 7 pages/cpu @c04d9000 s4448 r8192 d16032 u65536
pcpu-alloc: s4448 r8192 d16032 u65536 alloc=16*4096
pcpu-alloc: [0] 0
Built 1 zonelists in Zone order, mobility grouping on.  Total pages: 28956
Kernel command line: noalign mem=114M console=ttyAMA1,115200 initrd=0x86000040,0x47c194 rdinit=/linuxrc mtdparts=hi_sfc:0x40000(startcode),0x40000(bootA)ro,0x40000(bootB)ro,0x40000(flashcfg)ro,0x40000(slave_param)ro,0x200000(kernelA)ro,0x200000(kernelB)ro,0x480000(rootfsA)ro,0x480000(rootfsB)ro,0x180000(file_system),-(reserved)pcie1_sel=x1 maxcpus=0 user_debug=0x1f panic=1
PID hash table entries: 512 (order: -1, 2048 bytes)
Dentry cache hash table entries: 16384 (order: 4, 65536 bytes)
Inode-cache hash table entries: 8192 (order: 3, 32768 bytes)
Memory: 114MB = 114MB total
Memory: 107068k/107068k available, 9668k reserved, 0K highmem
Virtual kernel memory layout:
    vector  : 0xffff0000 - 0xffff1000   (   4 kB)
    fixmap  : 0xfff00000 - 0xfffe0000   ( 896 kB)
    DMA     : 0xffc00000 - 0xffe00000   (   2 MB)
    vmalloc : 0xc7800000 - 0xd0000000   ( 136 MB)
    lowmem  : 0xc0000000 - 0xc7200000   ( 114 MB)
    modules : 0xbf000000 - 0xc0000000   (  16 MB)
      .init : 0xc0008000 - 0xc002b000   ( 140 kB)
      .text : 0xc002b000 - 0xc0396000   (3500 kB)
      .data : 0xc03aa000 - 0xc03c6660   ( 114 kB)
SLUB: Genslabs=11, HWalign=32, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
Hierarchical RCU implementation.
RCU-based detection of stalled CPUs is enabled.
NR_IRQS:160
Calibrating delay loop... 747.11 BogoMIPS (lpj=3735552)
Security Framework initialized
Mount-cache hash table entries: 512
CPU: Testing write buffer coherency: ok
Init trace_clock_cyc2ns: precalc_mult = 312500, precalc_shift = 8
Brought up 1 CPUs
SMP: Total of 1 processors activated (747.11 BogoMIPS).
hi_wdt: User-Mode!
hi_wdt: Init sucessfull!
NET: Registered protocol family 16
id:0x51151100
check_res_of_trace_clock: sched_clock() high resolution
Serial: dw  uart driver
uart:0: ttyAMA0 at MMIO 0x1010e000 (irq = 77) is a AMBA/DW
uart:1: ttyAMA1 at MMIO 0x1010f000 (irq = 78) is a AMBA/DW
console [ttyAMA1] enabled
bio: create slab <bio-0> at 0
vgaarb: loaded
usbcore: registered new interface driver usbfs
usbcore: registered new interface driver hub
usbcore: registered new device driver usb
cfg80211: Calling CRDA to update world regulatory domain
Switching to clocksource timer1
NET: Registered protocol family 2
IP route cache hash table entries: 128 (order: -3, 512 bytes)
TCP established hash table entries: 4096 (order: 3, 32768 bytes)
TCP bind hash table entries: 4096 (order: 3, 32768 bytes)
TCP: Hash tables configured (established 4096 bind 4096)
TCP reno registered
UDP hash table entries: 128 (order: 0, 4096 bytes)
UDP-Lite hash table entries: 128 (order: 0, 4096 bytes)
NET: Registered protocol family 1
RPC: Registered udp transport module.
RPC: Registered tcp transport module.
RPC: Registered tcp NFSv4.1 backchannel transport module.
Trying to unpack rootfs image as initramfs...
Freeing initrd memory: 4592K
squashfs: version 4.0 (2009/01/31) Phillip Lougher
JFFS2 version 2.2. © 2001-2006 Red Hat, Inc.
msgmni has been set to 218
io scheduler noop registered
io scheduler deadline registered
io scheduler cfq registered (default)
brd: module loaded
mtdoops: mtd device (mtddev=name/number) must be supplied
Spi id table Version 1.22
Spi Flash Controller V300 Device Driver, Version 1.10
Spi(cs1) ID: 0x01 0x20 0x18 0x03 0x00 0x00
Spi(cs1): Block:256KB Chip:16MB (Name:S25FL128P-0)
Lock Spi Flash(cs1)!
Hisilicon flash: registering whole flash at once as master MTD
mtd: bad character after partition (p)
11 cmdlinepart partitions found on MTD device hi_sfc
Creating 11 MTD partitions on "hi_sfc":
0x000000000000-0x000000040000 : "startcode"
0x000000040000-0x000000080000 : "bootA"
0x000000080000-0x0000000c0000 : "bootB"
0x0000000c0000-0x000000100000 : "flashcfg"
0x000000100000-0x000000140000 : "slave_param"
0x000000140000-0x000000340000 : "kernelA"
0x000000340000-0x000000540000 : "kernelB"
0x000000540000-0x0000009c0000 : "rootfsA"
0x0000009c0000-0x000000e40000 : "rootfsB"
0x000000e40000-0x000000fc0000 : "file_system"
0x000000fc0000-0x000001000000 : "reserved"
Special nand id table Version 1.33
Hisilicon Nand Flash Controller V301 Device Driver, Version 1.10
PPP generic driver version 2.4.2
PPP Deflate Compression module registered
PPP BSD Compression module registered
PPP MPPE Compression module registered
NET: Registered protocol family 24
SLIP: version 0.8.4-NET3.019-NEWTTY (dynamic channels, max=256) (6 bit encapsulation enabled).
CSLIP: code copyright 1989 Regents of the University of California.
SLIP linefill/keepalive option.
Netfilter messages via NETLINK v0.30.
ip_tables: (C) 2000-2006 Netfilter Core Team
arp_tables: (C) 2002 David S. Miller
TCP cubic registered
NET: Registered protocol family 17
Freeing init memory: 140K

                        -=#  DOPRA LINUX 1.0  #=-
                        -=#  EchoLife WAP 0.1  #=-
                        -=#  Huawei Technologies Co., Ltd #=-

mount file system
Loading the kernel modules:
Loading module: rng-core
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: nf_conntrack
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: xt_mark
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: xt_connmark
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: xt_MARK
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: xt_limit
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: xt_state
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: xt_tcpmss
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: nf_nat
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: ipt_MASQUERADE
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: ipt_REDIRECT
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: ipt_NETMAP
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: nf_conntrack_ipv4.ko
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Loading module: iptable_nat.ko
modprobe: chdir(2.6.34.10_sd5115v100_wr4.3): No such file or directory
Making device instances:
Setting console log message level:
Setting hostname:
Settingup the sysctl configurations:
Setting up interface lo:
Running local startup scripts.

*******************************************
--==        Welcome To IAS WAP         ==--
--==   Huawei Technologies Co., Ltd.   ==--
*******************************************
IAS WAP Ver:V800R013C10SPC182B001
IAS WAP Timestamp:2015/07/30 00:08:53
*******************************************

Start init IAS WAP basic module ....
current lastword info:Add=0xc7a06000;max_num=300;Add1=0xc7a01000;Add2=0xc7a06000;Add3=0xc7a0b000;
Init IAS WAP basic module done!
soft lockup args:snap=150; release=50; dump flag=1;
Set kmsgread process pid to:92;
UBIFS error (pid 102): ubifs_get_sb: cannot open "/dev/ubi0_13", error -22
mount: mounting /dev/ubi0_13 on /mnt/jffs2/ failed: Invalid argument
umount /mnt/jffs2
umount: can't umount /mnt/jffs2: Invalid argument
UBIFS error (pid 105): ubifs_get_sb: cannot open "/dev/ubi0_13", error -22
mount: mounting /dev/ubi0_13 on /mnt/jffs2/ failed: Invalid argument
Mount nor jffs2 in 1.sdk_init...
fenghe.linux4.3
Get kernel version:2.6.34
Rootfs time stamp:2015-07-31_14:40:38
SVN label(ont):/etc/rc.d/rc.start/1.sdk_init.sh: line 50: can't create /proc/sys/vm/pagecache_ratio: nonexistent directory
User init start......
Loading the SD5115V100 modules:

 SYSCTL module is installed

 PIE module is installed

 GPIO module is installed

 SPI module is installed

 I2C module is installed

 DP module is installed

 MDIO module is installed

 TIMER module is installed

 UART module is installed

 HW module is installed
ifconfig eth0 hw ether 18:C5:8A:XX:XX:XX
Loading the EchoLife WAP modules: LDSP
COMMON For LDSP Install Successfully...
cut kernel config
major-minor:10-58
mknod: /dev/hlp: File exists
GPIO For LDSP Install Successfully...
sh: 0: unknown operand

 ------ SOC is 5115 S PILOT ------
<ldsp>board version is 5
<ldsp>pcb version is 0
<ldsp>orig board version is 5
CHIPADP-SD5115 BASIC For LDSP Install Successfully...
CHIPADP-SD5115 EXT For LDSP Install Successfully...
I2C For LDSP Install Successfully...
LSW L2 For LDSP Install Successfully...
LSW L3 For LDSP Install Successfully...
DEV For LDSP Install Successfully...
[DM]:ae_chip[0]=4,ae_chip[1]=255,ae_chip[2]=255,ae_chip[3]=0
[DM]:board_ver=5,pcb_ver=0
hw_dm_init_data successfully...

 [ /mnt/jffs2/boardinfocustom.cfg not exsit ! not need deal.]
hw_dm_pdt_init successfully...
hw_feature_init begin...
hw_feature_proc_init begin...
hw_feature_data_init begin...
ac_cfgpath is not null,acTmpBuf=/etc/wap/customize/ptvdfb_ft.cfg.....!
ac_hard_cfgpath is not null, acTmpBuf=/mnt/jffs2/hw_hardinfo_feature.bak.....!
ac_cfgpath is not null,acTmpBuf=/etc/wap/customize/spec_ptvdfb.cfg.....!
ac_hard_cfgpath is not null, acTmpBuf=/mnt/jffs2/hw_hardinfo_spec.bak.....!
hw_feature_init Successfully...
pots_num=0
ssid_num=0
 usb_num=0
hw_route=0
   l3_ex=1
    ipv6=0
Read MemInfo Des: 1118
SPI For LDSP Install Successfully...
UART For LDSP Install Successfully...
BATTERY For LDSP Install Successfully...
OPTIC For LDSP Install Successfully...
PLOAM For LDSP Install Successfully...
GMAC For LDSP Install Successfully...
KEY For LDSP Install Successfully...
LED For LDSP Install Successfully...
RF For LDSP Install Successfully...
Loading BBSP L2 modules:
PTP For BBSP Install Successfully...
hw_igmp_kernel Install Successfully...

 dhcp_module_init load success !

 pppoe_module_init load success !
hw_ringchk_kernel Install Successfully...
hw_portchk_kernel Install Successfully...
l2base For BBSP Install Successfully...
vbr_unicast_car:50
vbr_unicast_car:50
vbr_unicast_car:50
Pktdump init Install Successfully...

 hw_cpu_usage_install
[ker_L2M_CTP] for bbsp Install Successfully...
EMAC For LDSP Install Successfully...
MPCP For LDSP Install Successfully...
Loading BBSP L2_extended modules:
hw_ethoam_kernel Install Successfully...
l2ext For BBSP Install Successfully...
Dosflt For BBSP Install Successfully...

 vlanflt_module_init load success !
l3base for bbsp Install Successfully...
1.sdk_init.sh close core dump, flag=
Start ldsp_user...0
<LDSP> system has no slave space for bob
<LDSP_CFG> Set uiUpMode=1 [1:GPON,2:EPON,4:AUTO]
SD511X test self OK
Extern Lsw test self NoCheck
Optic test self OK
WIFI test self NoCheck
PHY[1] test self OK
PHY[2] test self OK
PHY[3] test self OK
PHY[4] test self OK
PHY[5] test self NoCheck
PHY[6] test self NoCheck

  LINE = 204, FUNC = hi_kernel_i2c_burst_read_bytes
 read data is over time
<LDSP> common optic,the last i2c error is normal,donot worry

<LDSP> uiRet = 2 pcNodeName = Cfg1 Cmd = 20005000 Length = 10 Value = be8406b2
 GPON init success !
ssmp bbsp igmp amp ethoam omci
Start start pid=252; uiProcNum=6;
InitFrame omci; PID=256; state=0; 15.084;
InitFrame omci; PID=256; in state=0; 15.084;
InitFrame omci; PID=256; out state=0; 15.085;
InitFrame ssmp; PID=253; state=0; 15.172;
InitFrame ssmp; PID=253; in state=0; 15.173;
uiCfgAddr:c0000
<db/hw_xml_dbmain.c:7713>acChooseWord:NOCHOOSE UserChoiceFlag:-1 Updateflag:-1

InitFrame bbsp; PID=254; state=0; 15.744;
InitFrame bbsp; PID=254; in state=0; 15.745;
InitFrame bbsp; PID=254; out state=0; 15.747;
InitFrame ethoam; PID=258; state=0; 15.750;
InitFrame ethoam; PID=258; in state=0; 15.750;
InitFrame ethoam; PID=258; out state=0; 15.752;
InitFrame igmp; PID=257; state=0; 15.759;
InitFrame igmp; PID=257; in state=0; 15.759;
InitFrame igmp; PID=257; out state=0; 15.759;
InitFrame amp; PID=255; state=0; 15.974;
InitFrame amp; PID=255; in state=0; 15.975;
InitFrame amp; PID=255; out state=0; 15.976;
<db/hw_xml_dbmain.c:8784>acFilePath:/etc/wap/hw_aes_tree.xml pstRoot:0x0
<db/hw_xml_dbmain.c:9068>acFilePath:/etc/wap/hw_aes_tree.xml pstRoot:0x3835ebc4
pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 pfFuncHandle ERR. uiRet:ffffffff;
 <db/hw_xml_dbmain.c:7100>[HW_XML_DBOnceSave] Set DB Auto Save in 12000 ticks.
Reset reason: unknown reason, except oom, watchdog and lossing power!
```

In many cases, this type of serial connection ends up in a login screen in which credentials are requested in order to operate and configure certain aspects of the device. However, this was not the case. No doubt this ONT was fortified so as not to alter its configuration in any way. In any case there was an information in the bootlog that caught my attention:

```console
Creating 11 MTD partitions on "hi_sfc":
0x000000000000-0x000000040000 : "startcode"
0x000000040000-0x000000080000 : "bootA"
0x000000080000-0x0000000c0000 : "bootB"
0x0000000c0000-0x000000100000 : "flashcfg"
0x000000100000-0x000000140000 : "slave_param"
0x000000140000-0x000000340000 : "kernelA"
0x000000340000-0x000000540000 : "kernelB"
0x000000540000-0x0000009c0000 : "rootfsA"
0x0000009c0000-0x000000e40000 : "rootfsB"
0x000000e40000-0x000000fc0000 : "file_system"
0x000000fc0000-0x000001000000 : "reserved"
```
Here you can see that the flash memory is subdivided into several partitions with different purposes. If in any of the partitions I could be able to locate the file with the current configuration of the router, I could modify it to suit my interests and even see the users enabled in the Webui, enable telnet or any other aspect. In many Huawei routers, the file in question is called 'hw_ctree.xml', which is precisely the file that is generated when exporting a configuration backup from the web administration. So, discarded the JTAG port and the serial port as access doors, there was only one option to focus all my attention: flash memory. I examined the serigraphed letters with a magnifying glass and I could see that it was a Spansion S25FL128P flash memory. So datasheet in hand I launched myself to scrutinize their interiors feeling that access to the router had already become a personal issue.

### Hostility level 3

To make a flash dump I found a specific utility for this type of flash chips called "Flashrom" that supports a large number of programmers. Luckily, I had one of them, a Microchip Pickit2 that I had forgotten in a drawer. So, with the pinout of the chip extracted from the datasheet, and the router completely disconnected from the power source (the programmer powers the chip itself) I started connecting the programmer to the chip with a SOIC16 clip (Pomona 5252). The connection schematic is as follows:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/8pickit2-pinout.jpg)

Once the programmer-chip connection was made, I connected the programmer to the USB port and made the flash dump by executing the command:
```console
logon@logonlap:~$sudo flashrom -p pickit2_spi -r flashdump.bin -c "S25FL128P......0"
```

with the parameter "-p" we specify the programmer we are using to read the flash memory, in my case as I mentioned it is a pickit2 and with the parameter "-c" we define the chip that we are going to read.
After about half an hour, the reading process ended and I already had the chip dump on my PC, ready to be examined.


![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/9connection.jpeg)

Once the flash memory has been dumped in a file, we must separate the file in their respective original partitions, in order to analyze each of them with greater precision. To do this, we first need to calculate the size of each partition, that is, subtract the offset from the end of the partition to the start offset of the partition. In this way, we obtain the following partition sizes:

```console
"startcode" : 0x000000000000-0x000000040000 =>  0x00040000 bytes
"bootA" : 0x000000040000-0x000000080000 => 0x00040000 bytes
"bootB" : 0x000000080000-0x0000000c0000 => 0x00040000 bytes
"flashcfg" : 0x0000000c0000-0x000000100000 => 0x00040000 bytes
"slave_param" : 0x000000100000-0x000000140000  => 0x00040000 bytes
"kernelA" : 0x000000140000-0x000000340000 => 0x00200000 bytes
"kernelB" : 0x000000340000-0x000000540000 => 0x00200000 bytes
“rootfsA" : 0x000000540000-0x0000009c0000 => 0x00480000 bytes
"rootfsB" : 0x0000009c0000-0x000000e40000 => 0x00480000 bytes
"file_system" : 0x000000e40000-0x000000fc0000 => 0x00180000 bytes
"reserved" : 0x000000fc0000-0x000001000000 => 0x00040000 bytes
```
And now we extract every partitión from the dump using the command:

```console
dd if=flashdump.bin bs=1 status=none skip=$((PARTITION_START)) count=$((PARTITION_SIZE)) of=PARTITION_NAME.bin
```

In my case, these are the commands I ran:

```console
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00000000)) count=$((0x00040000)) of=1startcode.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00040000)) count=$((0x00040000)) of=2bootA.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00080000)) count=$((0x00040000)) of=3bootB.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x000c0000)) count=$((0x00040000)) of=4flashcfg.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00100000)) count=$((0x00040000)) of=5slave_param.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00140000)) count=$((0x00200000)) of=6kernelA.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00340000)) count=$((0x00200000)) of=7kernelB.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00540000)) count=$((0x00480000)) of=8rootfsA.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x009c0000)) count=$((0x00480000)) of=9rootfsB.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00e40000)) count=$((0x00180000)) of=Afile_system.bin
logon@logonlap:~$dd if=flashdump.bin bs=1 status=none skip=$((0x00fc0000)) count=$((0x00040000)) of=Breserved.bin
```

Note that at the beginning of each partition name I have added a sequence in the form of hexadecimal numbers to maintain the order of the partitions and thereby facilitate the subsequent task of joining them in a single file.

The configuration files that I am interested into to access the router's web as well as to enable other functions such as access via telnet reside in "AFile System.bin" partition. It is the partition that the router has with read and write permissions at runtime precisely to be able to save changes. If we think of a generic router in which we change for example the name of the WIFI network, the partition where that name is stored must have read and write permissions, because otherwise we could not modify the name of the WIFI ever.

To analyze the content of said partition "A", we will use a powerful and recognized tool to examine firmwares and dumps called "Binwalk" that will be of great help to us. But before launching it personally I always prefer to take a look at the hexadecimal content of what I am going to try to analyze and build a visual map of the data and the empty spaces. After opening the file with a hexadecimal editor I discover that the structure is like this:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/10fs_map.jpg)

We will separate each of these areas into separate files to facilitate the subsequent identification of each of the two data blocks as well as the future task of rebuilding partition "A". For this we use the dd command again:

```console
logon@logonlap:~$dd if=Afile_system.bin bs=1 status=none skip=$((0x0)) count=12 of=Afile_system_trim1.bin
logon@logonlap:~$dd if=Afile_system.bin bs=1 status=none skip=$((0x100000)) count=493216 of=Afile_system_trim2.bin
```

At this point is when Binwalk comes into play, let's see what identifies in each of these two blocks that we just separated:

```console
logon@logonlap:~$binwalk Afile_system_trim1.bin

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             JFFS2 filesystem, little endian
```
```console
logon@logonlap:~$binwalk Afile_system_trim2.bin

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
80            0x50            Zlib compressed data, compressed
100           0x64            JFFS2 filesystem, little endian
220           0xDC            Zlib compressed data, compressed
336           0x150           Zlib compressed data, compressed
452           0x1C4           Zlib compressed data, compressed
568           0x238           Zlib compressed data, compressed
684           0x2AC           Zlib compressed data, compressed
800           0x320           Zlib compressed data, compressed
916           0x394           Zlib compressed data, compressed
1032          0x408           Zlib compressed data, compressed
1148          0x47C           Zlib compressed data, compressed
1264          0x4F0           Zlib compressed data, compressed
1380          0x564           Zlib compressed data, compressed
1496          0x5D8           Zlib compressed data, compressed
1612          0x64C           Zlib compressed data, compressed
1728          0x6C0           Zlib compressed data, compressed
1844          0x734           Zlib compressed data, compressed
1960          0x7A8           Zlib compressed data, compressed
2076          0x81C           Zlib compressed data, compressed
2192          0x890           Zlib compressed data, compressed
2308          0x904           Zlib compressed data, compressed
2424          0x978           Zlib compressed data, compressed
2540          0x9EC           Zlib compressed data, compressed
2656          0xA60           Zlib compressed data, compressed
2752          0xAC0           Zlib compressed data, compressed
2780          0xADC           JFFS2 filesystem, little endian
3168          0xC60           Zlib compressed data, compressed
3692          0xE6C           Zlib compressed data, compressed
4436          0x1154          Zlib compressed data, compressed
37800         0x93A8          Zlib compressed data, compressed
38220         0x954C          Zlib compressed data, compressed
38800         0x9790          Zlib compressed data, compressed
39180         0x990C          Zlib compressed data, compressed
39628         0x9ACC          Zlib compressed data, compressed
40076         0x9C8C          Zlib compressed data, compressed
40488         0x9E28          Zlib compressed data, compressed
40992         0xA020          Zlib compressed data, compressed
41460         0xA1F4          Zlib compressed data, compressed
41864         0xA388          Zlib compressed data, compressed
42264         0xA518          Zlib compressed data, compressed
42692         0xA6C4          Zlib compressed data, compressed
42808         0xA738          Zlib compressed data, compressed
42924         0xA7AC          Zlib compressed data, compressed
43040         0xA820          Zlib compressed data, compressed
43156         0xA894          Zlib compressed data, compressed
43272         0xA908          Zlib compressed data, compressed
43388         0xA97C          Zlib compressed data, compressed
43504         0xA9F0          Zlib compressed data, compressed
43620         0xAA64          Zlib compressed data, compressed
43736         0xAAD8          Zlib compressed data, compressed
43852         0xAB4C          Zlib compressed data, compressed
43968         0xABC0          Zlib compressed data, compressed
44084         0xAC34          Zlib compressed data, compressed
44200         0xACA8          Zlib compressed data, compressed
44316         0xAD1C          Zlib compressed data, compressed
44432         0xAD90          Zlib compressed data, compressed
44548         0xAE04          Zlib compressed data, compressed
44664         0xAE78          Zlib compressed data, compressed
44780         0xAEEC          Zlib compressed data, compressed
44896         0xAF60          Zlib compressed data, compressed
45012         0xAFD4          Zlib compressed data, compressed
45128         0xB048          Zlib compressed data, compressed
45224         0xB0A8          Zlib compressed data, compressed
45320         0xB108          JFFS2 filesystem, little endian
46884         0xB724          Zlib compressed data, compressed
47168         0xB840          JFFS2 filesystem, little endian
47568         0xB9D0          Zlib compressed data, compressed
47712         0xBA60          JFFS2 filesystem, little endian
64832         0xFD40          Zlib compressed data, compressed
65252         0xFEE4          Zlib compressed data, compressed
65832         0x10128         Zlib compressed data, compressed
66212         0x102A4         Zlib compressed data, compressed
66660         0x10464         Zlib compressed data, compressed
67108         0x10624         Zlib compressed data, compressed
67520         0x107C0         Zlib compressed data, compressed
68024         0x109B8         Zlib compressed data, compressed
68492         0x10B8C         Zlib compressed data, compressed
68896         0x10D20         Zlib compressed data, compressed
69296         0x10EB0         Zlib compressed data, compressed
69820         0x110BC         Zlib compressed data, compressed
70024         0x11188         Zlib compressed data, compressed
70140         0x111FC         Zlib compressed data, compressed
70256         0x11270         Zlib compressed data, compressed
70372         0x112E4         Zlib compressed data, compressed
70488         0x11358         Zlib compressed data, compressed
70604         0x113CC         Zlib compressed data, compressed
70720         0x11440         Zlib compressed data, compressed
70836         0x114B4         Zlib compressed data, compressed
70952         0x11528         Zlib compressed data, compressed
71068         0x1159C         Zlib compressed data, compressed
71184         0x11610         Zlib compressed data, compressed
71300         0x11684         Zlib compressed data, compressed
71416         0x116F8         Zlib compressed data, compressed
71532         0x1176C         Zlib compressed data, compressed
71648         0x117E0         Zlib compressed data, compressed
71764         0x11854         Zlib compressed data, compressed
71880         0x118C8         Zlib compressed data, compressed
71996         0x1193C         Zlib compressed data, compressed
72112         0x119B0         Zlib compressed data, compressed
72228         0x11A24         Zlib compressed data, compressed
72276         0x11A54         JFFS2 filesystem, little endian
105808        0x19D50         Zlib compressed data, compressed
106228        0x19EF4         Zlib compressed data, compressed
106808        0x1A138         Zlib compressed data, compressed
107188        0x1A2B4         Zlib compressed data, compressed
107636        0x1A474         Zlib compressed data, compressed
108084        0x1A634         Zlib compressed data, compressed
108496        0x1A7D0         Zlib compressed data, compressed
109000        0x1A9C8         Zlib compressed data, compressed
109468        0x1AB9C         Zlib compressed data, compressed
109872        0x1AD30         Zlib compressed data, compressed
110272        0x1AEC0         Zlib compressed data, compressed
110796        0x1B0CC         Zlib compressed data, compressed
111080        0x1B1E8         Zlib compressed data, compressed
111196        0x1B25C         Zlib compressed data, compressed
111312        0x1B2D0         Zlib compressed data, compressed
111428        0x1B344         Zlib compressed data, compressed
111544        0x1B3B8         Zlib compressed data, compressed
111660        0x1B42C         Zlib compressed data, compressed
111776        0x1B4A0         Zlib compressed data, compressed
111892        0x1B514         Zlib compressed data, compressed
112008        0x1B588         Zlib compressed data, compressed
112124        0x1B5FC         Zlib compressed data, compressed
112240        0x1B670         Zlib compressed data, compressed
112356        0x1B6E4         Zlib compressed data, compressed
112472        0x1B758         Zlib compressed data, compressed
112588        0x1B7CC         Zlib compressed data, compressed
112704        0x1B840         Zlib compressed data, compressed
112820        0x1B8B4         Zlib compressed data, compressed
112936        0x1B928         Zlib compressed data, compressed
113052        0x1B99C         Zlib compressed data, compressed
113168        0x1BA10         Zlib compressed data, compressed
113284        0x1BA84         Zlib compressed data, compressed
130260        0x1FCD4         Zlib compressed data, compressed
132004        0x203A4         Zlib compressed data, compressed
133828        0x20AC4         Zlib compressed data, compressed
134724        0x20E44         Zlib compressed data, compressed
135616        0x211C0         Zlib compressed data, compressed
136548        0x21564         Zlib compressed data, compressed
137220        0x21804         Zlib compressed data, compressed
137496        0x21918         Zlib compressed data, compressed
138132        0x21B94         Zlib compressed data, compressed
138428        0x21CBC         Zlib compressed data, compressed
139108        0x21F64         Zlib compressed data, compressed
139380        0x22074         Zlib compressed data, compressed
140348        0x2243C         Zlib compressed data, compressed
141020        0x226DC         Zlib compressed data, compressed
141288        0x227E8         Zlib compressed data, compressed
141976        0x22A98         Zlib compressed data, compressed
142304        0x22BE0         Zlib compressed data, compressed
142992        0x22E90         Zlib compressed data, compressed
143356        0x22FFC         Zlib compressed data, compressed
143992        0x23278         Zlib compressed data, compressed
144300        0x233AC         Zlib compressed data, compressed
144992        0x23660         Zlib compressed data, compressed
145364        0x237D4         Zlib compressed data, compressed
146028        0x23A6C         Zlib compressed data, compressed
146376        0x23BC8         Zlib compressed data, compressed
147076        0x23E84         Zlib compressed data, compressed
147444        0x23FF4         Zlib compressed data, compressed
148128        0x242A0         Zlib compressed data, compressed
148432        0x243D0         Zlib compressed data, compressed
149144        0x24698         Zlib compressed data, compressed
149516        0x2480C         Zlib compressed data, compressed
150216        0x24AC8         Zlib compressed data, compressed
150624        0x24C60         Zlib compressed data, compressed
151344        0x24F30         Zlib compressed data, compressed
151708        0x2509C         Zlib compressed data, compressed
152972        0x2558C         Zlib compressed data, compressed
153412        0x25744         Zlib compressed data, compressed
155048        0x25DA8         Zlib compressed data, compressed
155364        0x25EE4         Zlib compressed data, compressed
156620        0x263CC         Zlib compressed data, compressed
157068        0x2658C         Zlib compressed data, compressed
158276        0x26A44         Zlib compressed data, compressed
158764        0x26C2C         Zlib compressed data, compressed
160520        0x27308         Zlib compressed data, compressed
160928        0x274A0         Zlib compressed data, compressed
162440        0x27A88         Zlib compressed data, compressed
162912        0x27C60         Zlib compressed data, compressed
164708        0x28364         Zlib compressed data, compressed
165164        0x2852C         Zlib compressed data, compressed
166436        0x28A24         Zlib compressed data, compressed
166828        0x28BAC         Zlib compressed data, compressed
167984        0x29030         Zlib compressed data, compressed
169728        0x29700         Zlib compressed data, compressed
170452        0x299D4         Zlib compressed data, compressed
171116        0x29C6C         Zlib compressed data, compressed
171756        0x29EEC         Zlib compressed data, compressed
172428        0x2A18C         Zlib compressed data, compressed
173064        0x2A408         Zlib compressed data, compressed
173748        0x2A6B4         Zlib compressed data, compressed
174396        0x2A93C         Zlib compressed data, compressed
175072        0x2ABE0         Zlib compressed data, compressed
175760        0x2AE90         Zlib compressed data, compressed
176448        0x2B140         Zlib compressed data, compressed
177084        0x2B3BC         Zlib compressed data, compressed
177780        0x2B674         Zlib compressed data, compressed
178444        0x2B90C         Zlib compressed data, compressed
179144        0x2BBC8         Zlib compressed data, compressed
179828        0x2BE74         Zlib compressed data, compressed
180536        0x2C138         Zlib compressed data, compressed
181236        0x2C3F4         Zlib compressed data, compressed
181960        0x2C6C8         Zlib compressed data, compressed
183228        0x2CBBC         Zlib compressed data, compressed
184864        0x2D220         Zlib compressed data, compressed
186124        0x2D70C         Zlib compressed data, compressed
187332        0x2DBC4         Zlib compressed data, compressed
189088        0x2E2A0         Zlib compressed data, compressed
190596        0x2E884         Zlib compressed data, compressed
192388        0x2EF84         Zlib compressed data, compressed
193664        0x2F480         Zlib compressed data, compressed
211468        0x33A0C         JFFS2 filesystem, little endian
228192        0x37B60         Zlib compressed data, compressed
228612        0x37D04         Zlib compressed data, compressed
229192        0x37F48         Zlib compressed data, compressed
229572        0x380C4         Zlib compressed data, compressed
230020        0x38284         Zlib compressed data, compressed
230468        0x38444         Zlib compressed data, compressed
230880        0x385E0         Zlib compressed data, compressed
231384        0x387D8         Zlib compressed data, compressed
231852        0x389AC         Zlib compressed data, compressed
232256        0x38B40         Zlib compressed data, compressed
232656        0x38CD0         Zlib compressed data, compressed
233180        0x38EDC         Zlib compressed data, compressed
233520        0x39030         Zlib compressed data, compressed
233636        0x390A4         Zlib compressed data, compressed
233752        0x39118         Zlib compressed data, compressed
233868        0x3918C         Zlib compressed data, compressed
233984        0x39200         Zlib compressed data, compressed
234100        0x39274         Zlib compressed data, compressed
234216        0x392E8         Zlib compressed data, compressed
234332        0x3935C         Zlib compressed data, compressed
234448        0x393D0         Zlib compressed data, compressed
234564        0x39444         Zlib compressed data, compressed
234680        0x394B8         Zlib compressed data, compressed
234796        0x3952C         Zlib compressed data, compressed
234912        0x395A0         Zlib compressed data, compressed
235028        0x39614         Zlib compressed data, compressed
235144        0x39688         Zlib compressed data, compressed
235260        0x396FC         Zlib compressed data, compressed
235376        0x39770         Zlib compressed data, compressed
235492        0x397E4         Zlib compressed data, compressed
235608        0x39858         Zlib compressed data, compressed
235724        0x398CC         Zlib compressed data, compressed
265148        0x40BBC         JFFS2 filesystem, little endian
269380        0x41C44         Zlib compressed data, compressed
269800        0x41DE8         Zlib compressed data, compressed
270380        0x4202C         Zlib compressed data, compressed
270760        0x421A8         Zlib compressed data, compressed
271208        0x42368         Zlib compressed data, compressed
271656        0x42528         Zlib compressed data, compressed
272068        0x426C4         Zlib compressed data, compressed
272572        0x428BC         Zlib compressed data, compressed
273040        0x42A90         Zlib compressed data, compressed
273444        0x42C24         Zlib compressed data, compressed
273844        0x42DB4         Zlib compressed data, compressed
274368        0x42FC0         Zlib compressed data, compressed
274724        0x43124         Zlib compressed data, compressed
274840        0x43198         Zlib compressed data, compressed
274956        0x4320C         Zlib compressed data, compressed
275072        0x43280         Zlib compressed data, compressed
275188        0x432F4         Zlib compressed data, compressed
275304        0x43368         Zlib compressed data, compressed
275420        0x433DC         Zlib compressed data, compressed
275536        0x43450         Zlib compressed data, compressed
275652        0x434C4         Zlib compressed data, compressed
275768        0x43538         Zlib compressed data, compressed
275884        0x435AC         Zlib compressed data, compressed
276000        0x43620         Zlib compressed data, compressed
276116        0x43694         Zlib compressed data, compressed
276232        0x43708         Zlib compressed data, compressed
276348        0x4377C         Zlib compressed data, compressed
276464        0x437F0         Zlib compressed data, compressed
276580        0x43864         Zlib compressed data, compressed
276696        0x438D8         Zlib compressed data, compressed
276812        0x4394C         Zlib compressed data, compressed
276928        0x439C0         Zlib compressed data, compressed
277044        0x43A34         JFFS2 filesystem, little endian
312540        0x4C4DC         gzip compressed data, maximum compression, from Unix, last modified: 1970-01-01 00:02:32 (bogus date)
329572        0x50764         JFFS2 filesystem, little endian
329692        0x507DC         Zlib compressed data, compressed
331436        0x50EAC         Zlib compressed data, compressed
332160        0x51180         Zlib compressed data, compressed
332824        0x51418         Zlib compressed data, compressed
333464        0x51698         Zlib compressed data, compressed
334136        0x51938         Zlib compressed data, compressed
334772        0x51BB4         Zlib compressed data, compressed
335456        0x51E60         Zlib compressed data, compressed
336104        0x520E8         Zlib compressed data, compressed
336780        0x5238C         Zlib compressed data, compressed
337468        0x5263C         Zlib compressed data, compressed
338156        0x528EC         Zlib compressed data, compressed
338792        0x52B68         Zlib compressed data, compressed
339488        0x52E20         Zlib compressed data, compressed
340152        0x530B8         Zlib compressed data, compressed
340852        0x53374         Zlib compressed data, compressed
341536        0x53620         Zlib compressed data, compressed
342244        0x538E4         Zlib compressed data, compressed
342944        0x53BA0         Zlib compressed data, compressed
343668        0x53E74         Zlib compressed data, compressed
344936        0x54368         Zlib compressed data, compressed
346572        0x549CC         Zlib compressed data, compressed
347832        0x54EB8         Zlib compressed data, compressed
349040        0x55370         Zlib compressed data, compressed
350796        0x55A4C         Zlib compressed data, compressed
352304        0x56030         Zlib compressed data, compressed
354096        0x56730         Zlib compressed data, compressed
355372        0x56C2C         Zlib compressed data, compressed
356592        0x570F0         Zlib compressed data, compressed
358336        0x577C0         Zlib compressed data, compressed
360164        0x57EE4         Zlib compressed data, compressed
360892        0x581BC         Zlib compressed data, compressed
361700        0x584E4         Zlib compressed data, compressed
362580        0x58854         Zlib compressed data, compressed
363500        0x58BEC         Zlib compressed data, compressed
364448        0x58FA0         Zlib compressed data, compressed
365084        0x5921C         Zlib compressed data, compressed
365376        0x59340         Zlib compressed data, compressed
366060        0x595EC         Zlib compressed data, compressed
366336        0x59700         Zlib compressed data, compressed
367288        0x59AB8         Zlib compressed data, compressed
367960        0x59D58         Zlib compressed data, compressed
368228        0x59E64         Zlib compressed data, compressed
368916        0x5A114         Zlib compressed data, compressed
369244        0x5A25C         Zlib compressed data, compressed
369940        0x5A514         Zlib compressed data, compressed
370292        0x5A674         Zlib compressed data, compressed
370932        0x5A8F4         Zlib compressed data, compressed
371240        0x5AA28         Zlib compressed data, compressed
371928        0x5ACD8         Zlib compressed data, compressed
372300        0x5AE4C         Zlib compressed data, compressed
372960        0x5B0E0         Zlib compressed data, compressed
373308        0x5B23C         Zlib compressed data, compressed
374012        0x5B4FC         Zlib compressed data, compressed
374384        0x5B670         Zlib compressed data, compressed
375068        0x5B91C         Zlib compressed data, compressed
375368        0x5BA48         Zlib compressed data, compressed
376076        0x5BD0C         Zlib compressed data, compressed
376444        0x5BE7C         Zlib compressed data, compressed
377140        0x5C134         Zlib compressed data, compressed
377540        0x5C2C4         Zlib compressed data, compressed
378260        0x5C594         Zlib compressed data, compressed
378624        0x5C700         Zlib compressed data, compressed
379900        0x5CBFC         Zlib compressed data, compressed
380332        0x5CDAC         Zlib compressed data, compressed
381964        0x5D40C         Zlib compressed data, compressed
382280        0x5D548         Zlib compressed data, compressed
383540        0x5DA34         Zlib compressed data, compressed
383988        0x5DBF4         Zlib compressed data, compressed
385200        0x5E0B0         Zlib compressed data, compressed
385676        0x5E28C         Zlib compressed data, compressed
387392        0x5E940         Zlib compressed data, compressed
387812        0x5EAE4         Zlib compressed data, compressed
389308        0x5F0BC         Zlib compressed data, compressed
389748        0x5F274         Zlib compressed data, compressed
391420        0x5F8FC         Zlib compressed data, compressed
391804        0x5FA7C         Zlib compressed data, compressed
392736        0x5FE20         Zlib compressed data, compressed
393092        0x5FF84         Zlib compressed data, compressed
394088        0x60368         Zlib compressed data, compressed
394508        0x6050C         Zlib compressed data, compressed
395088        0x60750         Zlib compressed data, compressed
395468        0x608CC         Zlib compressed data, compressed
395916        0x60A8C         Zlib compressed data, compressed
396364        0x60C4C         Zlib compressed data, compressed
396776        0x60DE8         Zlib compressed data, compressed
397280        0x60FE0         Zlib compressed data, compressed
397748        0x611B4         Zlib compressed data, compressed
398152        0x61348         Zlib compressed data, compressed
398552        0x614D8         Zlib compressed data, compressed
399076        0x616E4         Zlib compressed data, compressed
399472        0x61870         Zlib compressed data, compressed
399588        0x618E4         Zlib compressed data, compressed
399704        0x61958         Zlib compressed data, compressed
399820        0x619CC         Zlib compressed data, compressed
399936        0x61A40         Zlib compressed data, compressed
400052        0x61AB4         Zlib compressed data, compressed
400168        0x61B28         Zlib compressed data, compressed
400284        0x61B9C         Zlib compressed data, compressed
400400        0x61C10         Zlib compressed data, compressed
400516        0x61C84         Zlib compressed data, compressed
400632        0x61CF8         Zlib compressed data, compressed
400748        0x61D6C         Zlib compressed data, compressed
400864        0x61DE0         Zlib compressed data, compressed
400980        0x61E54         Zlib compressed data, compressed
401096        0x61EC8         Zlib compressed data, compressed
401212        0x61F3C         Zlib compressed data, compressed
401328        0x61FB0         Zlib compressed data, compressed
401444        0x62024         Zlib compressed data, compressed
401560        0x62098         Zlib compressed data, compressed
401676        0x6210C         Zlib compressed data, compressed
401860        0x621C4         Zlib compressed data, compressed
402280        0x62368         Zlib compressed data, compressed
402860        0x625AC         Zlib compressed data, compressed
403240        0x62728         Zlib compressed data, compressed
403688        0x628E8         Zlib compressed data, compressed
404136        0x62AA8         Zlib compressed data, compressed
404548        0x62C44         Zlib compressed data, compressed
405052        0x62E3C         Zlib compressed data, compressed
405520        0x63010         Zlib compressed data, compressed
405924        0x631A4         Zlib compressed data, compressed
406324        0x63334         Zlib compressed data, compressed
406848        0x63540         Zlib compressed data, compressed
407268        0x636E4         Zlib compressed data, compressed
407384        0x63758         Zlib compressed data, compressed
407500        0x637CC         Zlib compressed data, compressed
407616        0x63840         Zlib compressed data, compressed
407732        0x638B4         Zlib compressed data, compressed
407848        0x63928         Zlib compressed data, compressed
407964        0x6399C         Zlib compressed data, compressed
408080        0x63A10         Zlib compressed data, compressed
408196        0x63A84         Zlib compressed data, compressed
408312        0x63AF8         Zlib compressed data, compressed
408428        0x63B6C         Zlib compressed data, compressed
408544        0x63BE0         Zlib compressed data, compressed
408660        0x63C54         Zlib compressed data, compressed
408776        0x63CC8         Zlib compressed data, compressed
408892        0x63D3C         Zlib compressed data, compressed
409008        0x63DB0         Zlib compressed data, compressed
409124        0x63E24         Zlib compressed data, compressed
409240        0x63E98         Zlib compressed data, compressed
409356        0x63F0C         Zlib compressed data, compressed
409472        0x63F80         Zlib compressed data, compressed
409588        0x63FF4         JFFS2 filesystem, little endian
409964        0x6416C         Zlib compressed data, compressed
411708        0x6483C         Zlib compressed data, compressed
412432        0x64B10         Zlib compressed data, compressed
413096        0x64DA8         Zlib compressed data, compressed
413740        0x6502C         Zlib compressed data, compressed
414412        0x652CC         Zlib compressed data, compressed
415048        0x65548         Zlib compressed data, compressed
415732        0x657F4         Zlib compressed data, compressed
416380        0x65A7C         Zlib compressed data, compressed
417052        0x65D1C         Zlib compressed data, compressed
417740        0x65FCC         Zlib compressed data, compressed
418436        0x66284         Zlib compressed data, compressed
419076        0x66504         Zlib compressed data, compressed
419764        0x667B4         Zlib compressed data, compressed
420424        0x66A48         Zlib compressed data, compressed
421128        0x66D08         Zlib compressed data, compressed
421812        0x66FB4         Zlib compressed data, compressed
422520        0x67278         Zlib compressed data, compressed
423216        0x67530         Zlib compressed data, compressed
423936        0x67800         Zlib compressed data, compressed
425212        0x67CFC         Zlib compressed data, compressed
426844        0x6835C         Zlib compressed data, compressed
428104        0x68848         Zlib compressed data, compressed
429316        0x68D04         Zlib compressed data, compressed
431032        0x693B8         Zlib compressed data, compressed
432528        0x69990         Zlib compressed data, compressed
434200        0x6A018         Zlib compressed data, compressed
435132        0x6A3BC         Zlib compressed data, compressed
452312        0x6E6D8         JFFS2 filesystem, little endian
460200        0x705A8         JFFS2 filesystem, little endian
493096        0x78628         JFFS2 filesystem, little endian
```

First file seems to be used only as an "identifier" of the format of the second one, because if I extract the file trim1 with the "-e" modifier of binwalk, no content appears. Certainly we can not expect many compressed files within a file of only 12 bytes in size. So for the moment we ignore that identifier.

Regarding the second file, binwalk identifies a chaos mixture of compressed files and JFFS2 file systems. This type of output is a clear indication that false positives are being detected. Let's help Binwalk a bit telling him to just try to identify JFFS2 file systems in Afile_system_trim2.bin, since I suspect that Zlib compressed files are included within the JFFS2 system itself:

```console
logon@logonlap:~$binwalk -y jffs2 Afile_system_trim2.bin

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
0             0x0             JFFS2 filesystem, little endian
```

Bingo!. This way Binwalk identifies the entire area as a single file system, so we can proceed to extract it and expect consistent results. We add the parameter "-e" to extract:

```console
logon@logonlap:~$sudo binwalk -y jffs2 -e Afile_system_trim2.bin
```

I have extracted the file system as superuser to make sure I don't lose sensible data like file permissions or symbolic links. IMPORTANT: Binwalk needs the 'jefferson' utility installed (https://github.com/sviehb/jefferson) in order to be able to extract this kind of file system. 
Inside the directory ./Afile_system_trim2.bin.extracted/jffs2-root we find the extracted files:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/11fs_tree.png)

You can check highlighted in blue the necessary files needed to edit to vary webUi access parameters and router services while the files that must be edited to convert the ONT into a universal device, without personalization of the ISP are highlighted in pink. The problem with the firsts is that, in my case, if I open them with a text editor they turn out to be encrypted and their content is not understandable. Luckily this type of encryption has already been hacked by the community and there is a utility called "aescrypt2_huawei" that allows decryption and encryption of these file. We execute the following command on each of the files highlighted in blue to decrypt them:
```console
logon@logonlap:~$aescrypt2_huawei 1 INPUT_FILE OUTPUT_FILE
```

The changes we need to make to the files after decrypting them are the following:

### Enable telnet access  
Before:
```console
TELNETLanEnable="0"
```
After:
```console
TELNETLanEnable="1"
```
### Set default Huawei routers users (root:admin and telecomadmin:admintelecom). Here we can see the credentials that the router was using until now (root:80%V0d@%W31%12)  
Before:
```console
<X_HW_WebUserInfo NumberOfInstances="1">
<X_HW_WebUserInfoInstance InstanceID="1" UserName="root" Password="80%V0d@%W31%12" UserLevel="1" Enable="1" ModifyPasswordFlag="1"/>
</X_HW_WebUserInfo>
```
After:
```console
<X_HW_WebUserInfo NumberOfInstances="2">
<X_HW_WebUserInfoInstance InstanceID="1" UserName="root" Password="admin" UserLevel="1" Enable="1" ModifyPasswordFlag="1"/>
<X_HW_WebUserInfoInstance InstanceID="2" UserName="telecomadmin" Password="admintelecom" UserLevel="0" Enable="1" ModifyPasswordFlag="0"/>
</X_HW_WebUserInfo>
```
In case that the password field is a string composed of hexadecimal characters it means that what is shown is not a clear password, but the result of applying a HASH function to it. To generate a hash with the desired password we must apply the function MD5 (PASSWORD) if the length of the original field is 28 bytes or the function SHA256 (MD5 (PASSWORD)) if the length of the field is 64 bytes. The file ./fs_1/CfgFile_Backup/V300R013C10SPC128B217.xml had the passwords in HASH format with 64 bytes in length in my ONT, so the access users section in that particular file was edited as follows:
After:
```console
<X_HW_WebUserInfo NumberOfInstances="2">
<X_HW_WebUserInfoInstance InstanceID="1" UserName="root" Password="465c194afb65670f38322df087f0a9bb225cc257e43eb4ac5a0c98ef5b3173ac" UserLevel="1" Enable="1" ModifyPasswordFlag="1" PassMode="2"/>
<X_HW_WebUserInfoInstance InstanceID="2" UserName="telecomadmin" Password="402931e04c03e24d360477a9f90b9eb15777e154360f06228be15c37679016ef" UserLevel="0" Enable="1" ModifyPasswordFlag="1" PassMode="2"/>
</X_HW_WebUserInfo>
```
If we want to the edit credentials for the Telnet user, we have to edit them in the "<X_HW_CLIUserInfoInstance" part of the XML file.

### Set local ONT's IP according to my LAN
Before:
```console
IPInterfaceIPAddress="192.168.100.1"
```
After:
```console
IPInterfaceIPAddress="192.168.1.1"
```

### Debranded configuration, from "Vodafone Portugal" (PTVDFB) to "Universal device"
Before:
```console
<X_HW_ProductInfo originalVersion="V300R013C10SPC128C0009150076" currentVersion="V300R013" customInfo="PTVDFB" customInfoDetail="PTVDFB"/>
```
After:
```console
<X_HW_ProductInfo originalVersion="V300R013C10SPC128C0009150076" currentVersion="V300R013" customInfo="COMMON" customInfoDetail="COMMON"/>
```

### Disable DHCP LAN Server. This was caussing issues in the WAN port of my Linksys EA8500
Before:
```console
<LANHostConfigManagement DHCPServerConfigurable="1" DHCPServerEnable="1"
```
After:
```console
<LANHostConfigManagement DHCPServerConfigurable="1" DHCPServerEnable="0"
```

Now we have to do the reverse step with these files, that is, re-encrypt them and replace the original files with the new ones that we have modified. To re-encrypt the modified files we use the command:
```console
aescrypt2_huawei 0 INPUT_FILE OUTPUT_FILE
```

Now we focus on the files we marked in pink on the JFFS2 file system tree. These files are not encrypted, so its modification is much easier. As I explained previously, what we are looking for by editing them is to establish with it the ONT as universal without the personalization, in this case, of Vodafone Portugal. These are the changes we need to make:

hw_boardinfo BEFORE:
```console
obj.id = "0x0000001b" ; obj.value = "PTVDFB";
```
hw_boardinfo AFTER:
```console
obj.id = "0x0000001b" ; obj.value = "COMMON";
```
hw_boardinfo.bak BEFORE:
```console
obj.id = "0x0000001b" ; obj.value = "PTVDFB";
```
hw_boardinfo.bak AFTER:
```console
obj.id = "0x0000001b" ; obj.value = "COMMON";
```
customize.txt BEFORE:
```console
COMMON PTVDFB
```
customize.txt AFTER:
```console
COMMON COMMON
```
recovername BEFORE:
```console
recover_common.sh
```
recovername AFTER:
```console
recover_common.sh
```
The script pointed by "recovername" is used when pressing the reset button for 30 seconds. In my case PTVDFB uses the same reset script as the universal ONT, but other ONTs with different customizations from other ISPs may use a different script (Ex: recover_claro.sh). If that's the case, we should modify the "recovername" file to set "recover_common.sh" as reset script.

Here we have finished all the modifications of the JFFS2 file system, what we have to do now is to repack everything again. The commands that we need to execute are:     
Pack the JFFS2 file system:
```console
logon@logonlap:~$mkfs.jffs2 -l -q --root=./Afile_system_trim2.bin.extracted/jffs2-root/fs_1 -o new_jffs2.bin
```
Create an 'empty' container filled with "FF" to build a new "Afile_system_MODDED.bin" with our changes, keeping the original size of Afile_system.bin:
```console
logon@logonlap:~$dd if=/dev/zero bs=1 count=$((0x00180000)) | tr "\000" "\377" > Afile_system_MODDED.bin
```
Insert the "identifier" we split before in the new container in its original offset (0):
```console
logon@logonlap:~$dd if=Afile_system_trim1.bin bs=1 status=none of=Afile_system_MODDED.bin conv=notrunc
```
Insert the new JFFS2 file system in the new container in its original offset (0x100000):
```console
logon@logonlap:~$dd if=new_jffs2.bin bs=1 status=none seek=$((0x100000)) of=Afile_system_MODDED.bin conv=notrunc
```
Rebuild the whole flash, using our Afile_system_MODDED.bin instead of the original "A" partition:
```console
logon@logonlap:~$cat 1startcode.bin 2bootA.bin 3bootB.bin 4flashcfg.bin 5slave_param.bin 6kernelA.bin 7kernelB.bin 8rootfsA.bin 9rootfsB.bin Afile_system_MODDED.bin Breserved.bin > fullflash_MODDED.bin
```

With this we have created the file "fullflash_MODDED.bin" that contains all the partitions that the Huawei ONT needs to work. What we have to do with it is to burn it into the ONT's flash and check if the modifications we made do work. So, we reconnect the programmer (Pickit2 in my case) to the flash chip using the SOIC16 clip and execute:
```console
logon@logonlap:~$sudo flashrom -p pickit2_spi -w fullflash_MODDED.bin -c "S25FL128P......0"
flashrom p1.0-62-ga3ab6c6 on Linux 4.13.0-37-generic (x86_64)
flashrom is free software, get the source code at https://flashrom.org

Using clock_gettime for delay loops (clk_id: 1, resolution: 1ns).
Found Spansion flash chip "S25FL128P......0" (16384 kB, SPI) on pickit2_spi.
===
This flash part has status UNTESTED for operations: PROBE READ ERASE WRITE
The test status of this chip may have been updated in the latest development
version of flashrom. If you are running the latest development version,
please email a report to flashrom@flashrom.org if any of the above operations
work correctly for you with this flash chip. Please include the flashrom log
file for all operations you tested (see the man page for details), and mention
which mainboard or programmer you tested in the subject line.
Thanks for your help!
Reading old flash chip contents... done.
Erasing and writing flash chip... Erase/write done.
Verifying flash... VERIFIED.
```

## Time for truth

We connect the router to the power source, the ONT to our LAN and we go to the address http://192.168.1.1:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/12login.png)

Enter the superuser credentials we established in config files (telecomadmin / admintelecom) and click "LOGIN":

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/13welcome.png)

We did it !!! We have managed to access the webui starting from a completely unknown user access and password situation (which was not re-established even with a hard-reset of the device) and with blocked telnet access. Will we be able to connect also via telnet? Let's see:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/14telnet.png)

Yes! I used root:admin credentials for Telnet access, if we wanted to modify these credentials, we could have done it by editing the section <X_HW_CLIUserInfoInstance in the XML files. The Telnet console gives us access to the Huawei WAP console, which is a console with custom commands to set different configurations. Not to be confused with a standard BASH console in linux, here we can not use "dir", "mkdir" or any linux console command.

At this point I only need to configure the SN of the router HG8245U that my ISP installed, in this hacked HG8012H ONT. The SN of the router is used as an identification parameter and access restriction to the Internet network of the ISP. With an SN that is not previously registered in the whitelist of the internet operator's OLT, the router will never do synchronize with ISP. So we must configure the SN of the router HG8245U in the ONT HG8012H going to the menu "System Tools"> "ONT Authentication" and clicking "Apply" after entering the SN.


After this, I notice that the LED PON flashes in green a few seconds and finally remains fixed in that same color, that is, the ONT has managed to authenticate in ISP's OLT. At the same time, I observe that on my Linksys EA8500 router I get a public IP, so finally I have my Internet connection working, occupying much less space in the furniture and consuming less energy.

## ¿THE END?

Not yet. When I turn on my TV I realise no TV channels are visible at all and the CATV LED on the ONT remains off. At first I imagined that connecting a coaxial cable to the CATV output will turn on the CATV LED, but it was not like this. I also I did not see any option in the web interface to activate said television output. Why? It seems that the system is designed in this way: just after the ONT synchronizes with the OLT, the OLT sends the order to activate the TV module in the routers of clients that have contracted that TV service. If a client has not contracted the TV service, then the OLT will not send the instruction to activate said CATV module and therefore the client will not be able to see the TV through said output. In my case, I have contracted the TV service with ISP, but they use a passive device to extract the television channels from the optical fiber (Mininode SR2020AW, see first pic in top of this article) so the OLT sends by default the CATV = Off instruction to the subscribers, as in this ISP there's no client with an ONT with CATV integrated in.

After colliding with the wall of lack of information about the CATV module integrated in some of the Huawei devices and multiple tests, I finally discovered a way to activate the TV in the ONT:

```console
telnet 192.168.1.1
Login: root
Password: admin
WAP> su
SU_WAP> set rf switch on
```

These commands must be entered AFTER the ONT synchronizes with the OLT. If we execute it before the synchronization, the CATV module will turn off again after synchronization since as we said, the OLT of my ISP sends the instruction CATV = Off by default.

The disadvantages of activating the CATV module in this way are clear: each time the ONT power source turns off, voluntarily or involuntarily, the CATV module will remain OFF until the Ethernet cable that goes from the ONT to the WAN port of the Linksys router is disconnected, and the cable coming from my PC is connected to the ONT and then the previous Telnet commands are run. And after this, all the cables should be connected as they were to be able to have an internet connection again. Not very practical, we have to somehow automate the activation of the television output, and this involves modifying the firmware even more.

What we now want to achieve is not to edit the configuration of the device (as we did with the partition "A"), but modify the internal operation of the device itself. This will be achieved by editing the root file system (ROOTFS), that is partition "8" and "9" according to the map initially shown. With a simple comparison of crc32 I verify that 8rootfsA.bin is identical to 9rootfsB.bin, so I will focus on 8rootfsA.bin. As we did in the past, I now make a data map of partition "8":

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/15rootfs_map.jpg)


It seems that all the information in this partition is condensed in the upper part, without intermediate gaps, so in principle we are not going to perform additional separations. Let's see what binwalk detects:

```console
logon@logonlap:~$binwalk  8rootfsA.bin
DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
84            0x54             uImage header, header size: 64 bytes, header CRC: 0xEADB737A, created: 2016-04-18 13:19:13, image size: 3805184 bytes, Data Address: 0x0, Entry Point: 0x0,data CRC: 0xE731B6C3, OS: Linux, CPU: ARM, image type: RAMDisk Image, compression type: none, image name: "squashfs"
148           0x94             Squashfs filesystem, little endian, version 4.0, compression:lzma, size: 3802857 bytes, 1005 inodes, blocksize: 131072 bytes, created: 2016-04-18 13:19:13
4504532       0x44BBD4         MySQL ISAM index file Version 6
```
From here we can deduce several things with very simple calculations. First Binwalk detected a header of type Uimage at offset 0x54, but the data according to the previous map started directly at offset 0. This means that before the uimage header we have some type of header not identified by Binwalk. We will call that piece between offset 0x00 and 0x54 "Huawei_header". Then there is an lzma compressed Squashfs v4.0 file system. Third, there is a structure of MySQL type ISAM at offset 0x44BBD4. If we observe the data detected by Binwalk in the Uimage header, one of them tells us that the squashfs system with which this header is associated has a size of 3805184 bytes, while the size that Binwalk has detected in the squashfs system itself is 3802857 bytes. This means that Binwalk has incorrectly identified the squashfs system length: the squashfs system does not end at 0x3A077D (0x94 + 3802857 = 0x94 + 0x3A06E9 = 0x3A077D) but at offset 0x3A1094 (0x94 + 3805184 = 0x94 + 0x3A1000 = 0x3A1094). Next there are unidentified data that ends at offset 0x47C228. Binwalk is not able to identify it even after extracting the section [0x3A1094 0x47C228]. We will call this part "Huawei_footer.bin" and will add it at the end of the 8rootfsA_MODDED.bin repackage process. With all this, we can fine-tune the initial map of 8rootfsA.bin and it would look like this:


![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/16rootfs_map2.jpg)


UPDATE: After some tests updating HG8012H firmware I understood that there's no "Huawei_footer" at all in partition "8", this data was in fact remains of older and bigger squahfs file systems. When one rootfs update takes place via an official firmware update, the unused space that goes from squashfs end to partition "8" end doesn't get formatted to "FF....", so we can assume that this Huawei_footer garbage is empty space like the next area is. Then we can show partition "8" structure as:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/21rootfs_map3.jpg)

We proceed to split each area using dd:

```console
logon@logonlap:~$dd if=8rootfsA.bin bs=1 status=none skip=$((0x0)) count=84 of=8rootfsA_Huawei_header.bin
logon@logonlap:~$dd if=8rootfsA.bin bs=1 status=none skip=$((0x54)) count=64 of=8rootfsA_Uimage_header.bin
logon@logonlap:~$dd if=8rootfsA.bin bs=1 status=none skip=$((0x94)) count=3805184 of=8rootfsA_squashfs.bin
```
And we extract the squashfs file system with binwalk:

```console
logon@logonlap:~$binwalk -e 8rootfsA_squashfs.bin
```

The directory tree extracted at./8rootfsA.bin.extracted/squashfs-root is the following: (IMPORTANT: in order for binwalk to extract this type of file system we need to have 'squashfs-tools' package installed in our system)

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/17squashfs_tree.png)

We are going to edit the file ./8rootfsA.bin.extracted/squashfs-root/etc/rc.d/rc.start/1.sdk_init.sh, which is the last script that is executed during the boot of the device, to invoke a new script that will allow us to invoke the process that will activate the CATV output as well as execute other commands that we may need in the future, without risk of breaking the 1.sdk_init.sh file in future editions. So I insert the following two lines in the final part, just before the infinite processes:

```bash
#echo -n "Activate CATV output"
/bin/start_CATV.sh &
```
![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/18editrc.png)

Then we create a file called "start_CATV.sh" in "/bin/" and insert the following lines inside:

```bash
#/bin/sh

#wait to boot
sleep 80

#set catv output on
{ sleep 1; echo ""; sleep 3; echo "root"; sleep 3; echo "admin"; sleep 3; echo "su"; sleep 3; echo "set rf switch on"; sleep 3; echo "quit"; sleep 3; echo "quit"; } | console.sh
```

The 80-second timeout is to make sure that the ONT has finished booting and synchronizing with the ISP. The next line launches a local telnet session, which connects to the Huawei WAP console and writes line by line the necessary text to activate the CATV output.

Set exec permissions to "start_CATV.sh":
```console
logon@logonlap:~$chmod +x start_CATV.sh
```

Once this is done, it's time to repack the squashfs system. For this we will need the mksquashfs utility with support for LZMA compression compiled in (mksquashfs belongs to the squashfs-tools package, but in ubuntu repositories this utility is not compiled with LZMA compression enabled. You can locate the binary with the LZMA compression enabled in the "Files" section of this project). We pack with the command:

```console
logon@logonlap:~$sudo mksquashfs ./8rootfsA.bin.extracted/squashfs-root/ new_squashfs.bin -comp lzma -all-root
```

Both the Uimage header and the Huawei header have some CRC32 checks that we must patch so that the file system is recognized as valid by the router, so we will need to execute the following commands and write down the output generated:  

new_squashfs.bin CRC32:
```console
logon@logonlap:~$crc32  new_squashfs.bin
```

new_squashfs.bin length (4 bytes format):
```console
logon@logonlap:~$printf '%08x\n' $(stat -c '%s' new_squashfs.bin)
```
Open the file 8rootfsA_Uimage_header.bin with an hexadecimal editor and search for the sequence "27 05 19 56 UU UU UU UU VV VV VV VV WW WW WW WW XX XX XX XX YY YY YY YY ZZ ZZ ZZ ZZ". We must replace "ZZ ZZ ZZ ZZ" with the CRC32 of new_squashfs.bin and "WW WW WW WW" with the length of the new_squashfs.bin file. Once this is done, we modify the sequence "UU UU UU UU" with "00 00 00 00" and save the file.  


8rootfsA_Uimage_header.bin CRC32:
```console
logon@logonlap:~$crc32 8rootfsA_Uimage_header.bin
```
Now we reopen 8rootfsA_Uimage_header.bin and replace again the last sequence "00 00 00 00" that we added to replace "UU UU UU UU" with the CRC32 obtained in the last command.  

Join  8rootfsA_Uimage_header.bin and new_squashfs.bin:
```console
logon@logonlap:~$cat 8rootfsA_Uimage_header.bin new_squashfs.bin > 8rootfsA_UH_SFS.bin
```

Now we create a 8-byte sequence concatenating the output of the following two comands:  
8rootfsA_UH_SFS.bin length (4 bytes format) reversed by 2:
```console
logon@logonlap:~$printf '%08x\n' $(stat -c '%s' 8rootfsA_UH_SFS.bin) | fold -w2 | tac | tr -d "\n"; echo ""
```

8rootfsA_UH_SFS.bin CRC32 reversed by 2:
```console
logon@logonlap:~$crc32 8rootfsA_UH_SFS.bin | fold -w2 | tac | tr -d "\n"; echo ""
```


We now open the file 8rootfsA_Huawei_header.bin with an hexadecimal editor and modify exactly its last 8 bytes with the concatenated string we just created.  

Join 8rootfsA_Huawei_header.bin and 8rootfsA_UH_SFS.bin into a single file:
```console
logon@logonlap:~$cat 8rootfsA_Huawei_header.bin 8rootfsA_UH_SFS.bin > 8rootfsA_nopad.bin
```

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/19checks.png)

We already have the partition almost rebuilt, we just have to add "FF..." to complete all the size the partition "8" had initially. Create the FF container with all the required size:
```console
logon@logonlap:~$dd if=/dev/zero bs=1 count=$((0x00480000)) | tr "\000" "\377" > 8rootfsA_MODDED.bin
```

Insert our modded "8" partition in the container in the original position (offset 0):
```console
logon@logonlap:~$dd if=8rootfsA_nopad.bin bs=1 status=none of=8rootfsA_MODDED.bin conv=notrunc
```
The last step of reconstruction is to merge all the partitions into a single file. As we said at the beginning that "8rootfsA.bin" was a 1:1 copy of "9rootfsB.bin", I add the first twice:
```console
logon@logonlap:~$cat 1startcode.bin 2bootA.bin 3bootB.bin 4flashcfg.bin 5slave_param.bin 6kernelA.bin 7kernelB.bin 8rootfsA_MODDED.bin 8rootfsA_MODDED.bin Afile_system_MODDED.bin Breserved.bin > fullflash_MODDED.bin
```
Repeat the process of programming this dump in the flash chip using Flashrom (as we did with the first modification of the partition "A"). Turn on the router and:

![GitHub Logo](https://github.com/logon84/Hacking_Huawei_HG8012H_ONT/blob/master/pics/20catvon.jpg)

The CATV module starts automatically and I can see the channels on TV.

This is all, I suppose that this whole process can be easily adapted to other router models to carry out certain modifications. I hope you found the tutorial interesting. Thanks for reading. Logon       

[![Donate](https://www.paypalobjects.com/es_ES/ES/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ER2LTNM5LZDTY)
