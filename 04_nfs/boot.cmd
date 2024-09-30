setenv ipaddr 10.4.1.2
setenv serverip 10.4.1.1
tftp ${kernel_addr_r} Image
tftp ${fdt_addr_r} bcm2711-rpi-4-b.dtb
setenv argsnfs root=/dev/nfs nfsroot=${serverip}:/home/boltragons/rpi4/root,nfsvers=3,tcp rw rootwait
setenv consolecfg console=ttyS0,115200,n8 8250.nr_uarts=1
setenv ipcfg ip=10.4.1.2:::255.255.255.0:myboard:eth0:on
setenv bootargs ${consolecfg} ${ipcfg} ${argsnfs}
booti ${kernel_addr_r} - ${fdt_addr_r};
