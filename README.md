# Embedded Linux RPi4

Embedded Linux practices using Raspberry Pi 4.

## Contents

Things I want to do in this repository:

- [X] Toolchain
- [X] Bootloader
- [X] Kernel
- [X] NFS Filesystem
- [ ] Root Filesystem
- [ ] Buildroot
- [ ] Yocto

## Support Material

- [Mastering Embedded Linux Programming - Third Edition](https://www.amazon.com.br/Mastering-Embedded-Linux-Programming-potential/dp/1789530385)
- [Bootlin Embedded Linux Material](https://bootlin.com/doc/training/embedded-linux-bbb/)

## Useful Articles

- [Boot a Raspberry Pi 4 using u-boot and Initramfs](https://hechao.li/2021/12/20/Boot-Raspberry-Pi-4-Using-uboot-and-Initramfs/)
- [Creating a Cross-Platform Toolchain for Raspberry Pi 4](https://ilyas-hamadouche.medium.com/creating-a-cross-platform-toolchain-for-raspberry-pi-4-5c626d908b9d)
- [Utilizando o U-Boot na Raspberry Pi](https://sergioprado.org/utilizando-o-u-boot-na-raspberry-pi/)
- [Raspberry Pi e o processo de boot](https://sergioprado.org/raspberry-pi-e-o-processo-de-boot/)
- [Como desenvolver um sistema Linux do zero para a Raspberry Pi](https://sergioprado.org/como-desenvolver-um-sistema-linux-do-zero-para-a-raspberry-pi/)

# How to Setup U-Boot

Type the mount command to check your currently mounted partitions. If SD partitions are mounted, unmount them:

```
sudo umount /dev/mmcblk0p*
```

We will erase the existing partition table by simply zero-ing the first 16 MiB of the SD card:

```
sudo dd if=/dev/zero of=/dev/mmcblk0 bs=1M count=16
```

Now, let’s use the cfdisk command to create the first partition that we need to boot the board: we are going to use:

```
sudo cfdisk /dev/mmcblk0
```

If cfdisk asks you to Select a label type, choose dos. This corresponds to traditional partitions tables that DOS/Windows would understand. gpt partition tables are needed for disks bigger than 2 TB. In the cfdisk interface, delete existing partitions, then create only one primary partition, starting from the beginning, with the following properties:

- Size: 100MB
- Type: W95 FAT32 (LBA) (c choice)
- Bootable flag enabled

Press Write when you are done.

Now create a FAT32 filesystem on this new partition

```
sudo mkfs.vfat -F 32 -n boot /dev/mmcblk0p1
```

Now, copy the boot folder files to the SD card:

- u-boot.bin: The DAS U-Boot bootloader.
- bcm2711-rpi-4-b.dtb: The Device Tree (since U-Boot is loaded by the de-facto RPi4 bootloader as the "kernel", it is needed).
- config.txt: Enables UART, 64-bit mode and sets the "kernel" name (u-boot.txt).
- start4.elf: The firmware of the GPU.

To learn how to build U-Boot, see the Bootlin labs. Some sites say to upload the "bootcode.bin" file as well, but this is only needed in versions prior to RPi 4, since it contains it's bootloader. The bootloader of RPi 4 is in the SPI EEPROM.


