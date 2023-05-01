XVENDOR=myir
XBOARD=zturnlite
XCHIP=xc7z007s
XARCH=arm

KERNEL_DEFCONFIG=xilinx_zynq_defconfig
UBOOT_DEFCONFIG=zynq_zturnlite_defconfig

KERNEL_TARGET=LOADADDR=8000 uImage dtbs modules
UBOOT_TARGET=

