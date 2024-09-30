# Building the Linux Kernel

A simple manual on how to setup the Linux kernel for the RPi 4.

# Fetching the repository

To begin working with the Linux kernel sources, we need to clone its reference git tree, the one managed by Linus Torvalds.

```
git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux
cd linux
```

The Linux kernel repository from Linus Torvalds contains all the main releases of Linux, but not the stable versions: they are maintained by a separate team, and hosted in a separate repository. We will add this separate repository as another remote to be able to use the stable releases:

```
git remote add stable https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux
git fetch stable
```

Alternatively, you can clone the Raspberry fork of the Linux. We will use the other repository, but if you want, just clone from their repository:

```
git clone  https://github.com/raspberrypi/linux.git
```

We will use linux-6.6.x, which corresponds to an LTS release. First, let’s get the list of branches we have available:

```
cd linux
git branch -a
```

The remote branch we are interested in is

```
remotes/stable/linux-6.6.y.
```

First, execute the following command to check which version you currently have:

```
make kernelversion
```

You can also open the Makefile and look at the beginning of it to check this information. Now, let’s create a local branch starting from that remote branch:

```
git checkout stable/linux-6.6.y
```

If you're not using the Raspberry fork, you have to also download the default config for the RPi 4 to the configs folder:

```
wget https://raw.githubusercontent.com/raspberrypi/linux/refs/heads/rpi-6.6.y/arch/arm64/configs/bcm2711_defconfig -P arch/arm64/configs/
```

## Building the Kernel

To cross-compile Linux, you need to have a cross-compiling toolchain. We will use the cross-compiling toolchain that we previously produced, so we just need to make it available in the PATH (via export or via .bashrc).

Also, don’t forget to either:
- Define the value of the ARCH and CROSS_COMPILE variables in your environment (using export or .bashrc)
- Or specify them on the command line at every invocation of make:

```
make ARCH=... CROSS_COMPILE=... <target>
```

To be easier, we will export right away>

```
export ARCH=arm64 CROSS_COMPILE=arm-linux-
```

Then, load the default config and build the kernel (-j set the number of parallel jobs):

```
make bcm2711_defconfig
make -j$(nproc)
```

To generate the Device Tree, do this;

```
make dtbs
```

The **Image** binary will be located in "arch/arm64/boot/", and the .dtb in the "arch/arm64/boot/dts/broadcom" under the name "bcm2711-rpi-4-b.dtb".

## Setup a TFTP Server

The TFTP (Trivial File Transfer Protocol) provides a minimalist way of transfering files. We have the u-boot in the SD card and will send the kernel via ethernet.

To install it in your system:

```
sudo apt-get install xinetd tftpd tftp
```

Create a "tftp" file in /etc/xinetd.d with the following contents:

```
service tftp
{
protocol =      udp
port =          69
socket_type =   dgram
wait =          yes
user =          nobody
server =        /usr/sbin/in.tftpd
server_args =   /tftpboot
disable =       no
}
```

Create a "tftpboot" directory in the root (/):

```
sudo mkdir /tftpboot
sudo chmod -R 777 /tftpboot
sudo chown -R nobody /tftpboot
```

Initialize the TFTP service:

```
sudo /etc/init.d/xinetd start
```

To test the TFTP server:

```
$ cd Downloads
$ touch /tftpboot/hda.txt
$ echo "this is only a test" > /tftpboot/hda.txt
$ chmod 777 /tftpboot/hda.txt
$ ls -l /tftpboot/
-rwxrwxrwx 1 botelhocpp botelhocpp 0 2024-09-30 12:04 hda.txt
$ tftp 127.0.0.1
tftp> get hda.txt
Sent 722 bytes in 0.0 seconds
tftp> quit
$ ls -l
-rwxrwxrwx 1 botelhocpp botelhocpp 707 2024-09-30 12:04 hda.txt
```

## Pro-Tip: Assigning an IP Address to the Ethernet

Verify the name of the ethernet interface:

```
ip link show
```

Assign an IP address to the ethernet interface:

```
sudo ip addr add <ip_address>/<subnet_mask> dev <interface>
```

For example:

```
sudo ip addr add 10.4.1.1/24 dev eth0
```

Enable the interface: 

```
sudo ip link set dev eth0 up
```

## Boot the Board via TFTP

In the U-Boot interface in the board, let’s configure networking.

First, let's set the IPs used in the communication:

- ipaddr: IP address of the board
- serverip: IP address of the PC host

```
setenv ipaddr 10.4.1.2
setenv serverip 10.4.1.1
```

The arguments passed to the Linux:

- 8250.nr_uarts=1: Specifies the number of serial ports supported. In our case, it's one serial port ttyS0.
- root=/dev/mmcblk0p2: Specify the partition of the root filesystem.
- rootwait: Wait (indefinitely) for the root device to show up. Useful for devices that are detected asynchronously (e.g. USB and MMC devices).
- console=ttyS0,115200n8: Tells the kernel to start a console for us on the serial port ttyS0 with the baudrate of 115200 with no parity and the data size is 8 bytes.

```
setenv bootargs 8250.nr_uarts=1 console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait rw
```

The FDT is prepared by the RPi's GPU firmware (start4.elf) and stored in the variable \${fdt_addr} prior to calling U-Boot. That's why the .dtb file is located in the boot section of the SD card. In the RPi, there are some others variables already preset: \${fdt_addr_r} gives the location of the FDT in RAM, whereas \${fdt_addr} give the fdt's address in Flash.

Therefore, we don't need to load the Device Tree, as it is already located in \${fdt_addr}.

```
The following image location variables contain the location of images
used in booting. The "Image" column gives the role of the image and is
not an environment variable name. The other columns are environment
variable names. "File Name" gives the name of the file on a TFTP
server, "RAM Address" gives the location in RAM the image will be
loaded to, and "Flash Location" gives the image's address in NOR
flash or offset in NAND flash.

*Note* - these variables don't have to be defined for all boards, some
boards currently use other variables for these purposes, and some
boards use these variables for other purposes.

Image            File Name       RAM Address       Flash Location
-----            ---------       -----------       --------------
u-boot           u-boot          u-boot_addr_r     u-boot_addr
Linux kernel     bootfile        kernel_addr_r     kernel_addr
device tree blob fdtfile         fdt_addr_r        fdt_addr
ramdisk          ramdiskfile     ramdisk_addr_r    ramdisk_addr
```

Load the kernel in the address defined by **kernel_addr_r**, as it is the address reserved for the kernel:

```
tftp ${kernel_addr_r} Image
```

If you want to upload the device tree, upload it in \${fdt_addr_r} (we can't touch the \${fdt_addr} address).

```
tftp ${fdt_addr_r} bcm2711-rpi-4-b.dtb
```

You can save the environment variables if you want: 

```
saveenv
```

At last, boot the kernel with **booti** (boot Image), informing the kernel and DTB addresses:

```
booti ${kernel_addr_r} - ${fdt_addr} # To use the DTB prepared by RPi
booti ${kernel_addr_r} - ${fdt_addr_r} # If you uploaded a DTB
```

Without the filesystem a kernel panic will arise:

```
end Kernel panic - not syncing: VFS: Unable to mount root fs
```

To fix this, setup a root or NFS filesystem. 
