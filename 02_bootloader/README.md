# How to Setup U-Boot

A simple manual on how to setup the DAS U-Boot in the RPi 4.

## Build U-Boot

Install the following packages which should be needed to compile U-Boot for your board:

```
sudo apt install libssl-dev device-tree-compiler swig python3-distutils python3-dev python3-setuptools
```

Download U-Boot:

```
git clone https://gitlab.denx.de/u-boot/u-boot
cd u-boot
git checkout v2020.10-rc5
```

Specify the cross-compiler prefix (the part before gcc in the cross-compiler executable name):

```
export CROSS_COMPILE=arm-linux-
```

Load the default configuration for RPi 4:

```
make rpi_4_defconfig
```

Configure the bootloader as you please.

```
make menuconfig
```

I recommend enabling the booti command, in:

```
Command line interface > Boot commands > booti
```

## Flash in SD Card

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
- bcm2711-rpi-4-b.dtb: The Device Tree (since U-Boot is loaded by the firmware as the "kernel", it is needed).
- config.txt: Enables UART, 64-bit mode and sets the "kernel" name (u-boot.txt).
- start4.elf: The firmware of the GPU that calls U-Boot, passing the .dtb.

Finally, umount the SD card:

```
sudo umount /media/$USER/boot/
```

## What about the bootcode.bin?

Some sites say to upload the "bootcode.bin" file as well, but this is only needed in versions prior to RPi 4, since it contains it's second stage bootloader. Instead, the second stage bootloader of RPi 4 is in the SPI EEPROM.

First, the ROM bootloader (first stage) starts and executes the second stage bootloader (SPI EEPROM) after a preliminary setup, which enables the SDRAM and loads start4.elf. After that, start4.elf starts and makes a Flattened Device Tree (FDT) using the device tree binary .dtb in the boot folder (applies overlays written in config.txt). Then, it passes the FDT to U-Boot and loads U-Boot.

At last, U-Boot starts and loads the kernel into RAM, then it passes the same FDT passed by start4.elf to the kernel and starts the kernel. Finally, the kernel starts, mounts the filesystem, and executes /sbin/init.
