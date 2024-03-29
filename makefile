include  config/config.mk
include  $(XBOARD_CONFIG_FILE)

TOP_DIR=$(shell pwd)

KERNEL_CODE_DIR=${TOP_DIR}/kernel/${XVENDOR}-${XBOARD}-${XCHIP}-kernel
UBOOT_CODE_DIR=${TOP_DIR}/uboot/${XVENDOR}-${XBOARD}-${XCHIP}-uboot

XBOARD_OUT=${TOP_DIR}/output/${XBOARD}
XBOARD_UBOOT_OUT=${XBOARD_OUT}/uboot
XBOARD_KERNEL_OUT=${XBOARD_OUT}/kernel

ROOTFS_CODE_DIR=${TOP_DIR}/rootfs/${XVENDOR}-${XBOARD}-${XCHIP}-rootfs
DATE_STR=$(shell date +%y%m%d)
FW_NAME=$(XVENDOR)_$(XBOARD)_$(XCHIP)_$(DATE_STR)

.PHONY: all kernel uboot rootfs clean kernel-clean uboot-clean kernel-mrproper uboot-mrproper mrproper

all:xboard

xboard:kernel uboot rootfs
	cd $(XBOARD_OUT) && tar -Jcf $(FW_NAME).tar.xz uboot kernel --remove-files
	cd $(XBOARD_OUT) && md5sum *.* > $(FW_NAME).md5
kernel:
	$(Q)mkdir -vp ${XBOARD_KERNEL_OUT}
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  $(KERNEL_DEFCONFIG)
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  $(KERNEL_TARGET)
ifeq ($(XBOARD),neo)
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  modules_install INSTALL_MOD_PATH=$(XBOARD_KERNEL_OUT)
	$(Q)cp $(KERNEL_CODE_DIR)/arch/arm/boot/zImage $(XBOARD_KERNEL_OUT)/
	$(Q)cp $(KERNEL_CODE_DIR)/arch/arm/boot/dts/imx6sx-udoo-neo-full.dtb $(XBOARD_KERNEL_OUT)/
else ifeq ($(XBOARD),aio3128c)
	cp ${KERNEL_CODE_DIR}/kernel.img $(XBOARD_KERNEL_OUT)
	cp ${KERNEL_CODE_DIR}/resource.img $(XBOARD_KERNEL_OUT)
	cp ${KERNEL_CODE_DIR}/arch/arm/boot/zImage $(XBOARD_KERNEL_OUT)
else ifeq ($(XBOARD),ok210)
	cp ${KERNEL_CODE_DIR}/arch/arm/boot/uImage $(XBOARD_KERNEL_OUT)/
	cp ${KERNEL_CODE_DIR}/arch/arm/boot/dts/s5pv210-gblw210.dtb $(XBOARD_KERNEL_OUT)/s5pv210-ok210.dtb
else ifeq ($(XBOARD),guitar)
	cp ${KERNEL_CODE_DIR}/arch/arm/boot/uImage $(XBOARD_KERNEL_OUT)/
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  modules_install INSTALL_MOD_PATH=$(XBOARD_KERNEL_OUT)
	cp ${KERNEL_CODE_DIR}/arch/arm/boot/dts/lemaker_guitar_bba.dtb $(XBOARD_KERNEL_OUT)/kernel.dtb
	$(Q)cp ${TOP_DIR}/config/${XBOARD}/uEnv.txt $(XBOARD_KERNEL_OUT)/
else ifeq ($(XBOARD),zturnlite)
	cp ${KERNEL_CODE_DIR}/arch/arm/boot/uImage $(XBOARD_KERNEL_OUT)/
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  modules_install INSTALL_MOD_PATH=$(XBOARD_KERNEL_OUT)
	cp ${KERNEL_CODE_DIR}/arch/arm/boot/dts/zynq-zturn-lite.dtb $(XBOARD_KERNEL_OUT)/devicetree.dtb
	$(Q)cp ${TOP_DIR}/config/${XBOARD}/uEnv.txt $(XBOARD_KERNEL_OUT)/
endif 

uboot:
	$(Q)mkdir -vp  ${XBOARD_UBOOT_OUT}
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  $(UBOOT_DEFCONFIG)
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  $(UBOOT_TARGET)
ifeq ($(XBOARD),neo)
	$(Q)cp $(UBOOT_CODE_DIR)/SPL $(XBOARD_UBOOT_OUT)/
	$(Q)cp $(UBOOT_CODE_DIR)/u-boot.img $(XBOARD_UBOOT_OUT)/
else ifeq ($(XBOARD),aio3128c)
	$(Q)cp $(UBOOT_CODE_DIR)/RK3128MiniLoaderAll_V2.25.bin $(XBOARD_UBOOT_OUT)/
	$(Q)cp $(UBOOT_CODE_DIR)/uboot.img $(XBOARD_UBOOT_OUT)/
	$(Q)cp $(UBOOT_CODE_DIR)/u-boot.bin $(XBOARD_UBOOT_OUT)/
else ifeq ($(XBOARD),ok210)
	$(Q)$(UBOOT_CODE_DIR)/mkmini210 $(UBOOT_CODE_DIR)/u-boot.bin $(XBOARD_UBOOT_OUT)/ok210.bin
	$(Q)cp $(UBOOT_CODE_DIR)/u-boot.bin $(XBOARD_UBOOT_OUT)/
else ifeq ($(XBOARD),guitar)
	$(Q)${TOP_DIR}/config/${XBOARD}/padbootloader $(UBOOT_CODE_DIR)/u-boot-dtb.img
	$(Q)cp $(UBOOT_CODE_DIR)/u-boot-dtb.img $(XBOARD_UBOOT_OUT)/
	$(Q)${TOP_DIR}/config/${XBOARD}/bootloader_pack /${TOP_DIR}/config/${XBOARD}/bootloader.bin /${TOP_DIR}/config/${XBOARD}/bootloader.ini $(UBOOT_CODE_DIR)/bootloader.bin
	$(Q)cp $(UBOOT_CODE_DIR)/bootloader.bin $(XBOARD_UBOOT_OUT)/
else ifeq ($(XBOARD),zturnlite)
	$(Q)cp -rf ${TOP_DIR}/config/${XBOARD}/mkbootbin $(XBOARD_UBOOT_OUT)/
	$(Q)cp $(UBOOT_CODE_DIR)/u-boot $(XBOARD_UBOOT_OUT)/mkbootbin/u-boot.elf
	$(Q)$(MAKE) -C $(XBOARD_UBOOT_OUT)/mkbootbin
	$(Q)cp $(XBOARD_UBOOT_OUT)/mkbootbin/BOOT.bin $(XBOARD_UBOOT_OUT)
#	$(Q)rm -rf $(XBOARD_UBOOT_OUT)/mkbootbin
endif

rootfs:
ifeq ($(XBOARD),aio3128c)
	$(Q)$(MAKE) -C $(ROOTFS_CODE_DIR)
	$(Q)cp $(ROOTFS_CODE_DIR)/../initrd.img $(XBOARD_KERNEL_OUT)/
	truncate -s "%4" $(XBOARD_KERNEL_OUT)/initrd.img
	mkbootimg --kernel $(XBOARD_KERNEL_OUT)/zImage --ramdisk $(XBOARD_KERNEL_OUT)/initrd.img -o $(XBOARD_KERNEL_OUT)/linux-boot.img
endif

#clean  - Remove most generated files but keep the config and enough build support to build external modules
kernel-clean:
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  clean
uboot-clean:
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE)  clean
clean:uboot-clean kernel-clean
	echo "it has cleaned the kernel and uboot"

#mrproper  - Remove all generated files + config + various backup files		
kernel-mrproper:
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) mrproper
uboot-mrproper:
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) mrproper
mrproper:uboot-mrproper kernel-mrproper
	echo "it has mrpropered the kernel and uboot"
	
	
