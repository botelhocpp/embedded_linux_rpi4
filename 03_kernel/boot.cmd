setenv bootargs 8250.nr_uarts=1 console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait rw
setenv ipaddr 10.4.1.2
setenv serverip 10.4.1.1
tftp ${kernel_addr_r} Image
tftp ${fdt_addr_r} bcm2711-rpi-4-b.dtb
booti ${kernel_addr_r} - ${fdt_addr_r}

