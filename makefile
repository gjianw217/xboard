include  config/config.mk
include  $(XBOARD_CONFIG_FILE)

TOP_DIR=$(shell pwd)

KERNEL_CODE_DIR=${TOP_DIR}/kernel/${XVENDOR}-${XBOARD}-${XCHIP}-kernel
UBOOT_CODE_DIR=${TOP_DIR}/uboot/${XVENDOR}-${XBOARD}-${XCHIP}-uboot

XBOARD_OUT=${TOP_DIR}/output
XBOARD_UBOOT_OUT=${XBOARD_OUT}/uboot
XBOARD_KERNEL_OUT=${XBOARD_OUT}/kernel
DATE_STR=$(shell date +%y%m%d)
FW_NAME=$(XVENDOR)_$(XBOARD)_$(XCHIP)_$(DATE_STR)

.PHONY: all kernel uboot clean kernel-clean uboot-clean kernel-mrproper uboot-mrproper mrproper

all:xboard

xboard:kernel uboot
	$(Q)sudo chown -R root:root $(XBOARD_OUT)/*
	cd $(XBOARD_OUT) && sudo tar -Jcf $(FW_NAME).tar.xz uboot kernel --remove-files
	cd $(XBOARD_OUT) && sudo md5sum *.* > $(FW_NAME).md5
kernel:
	$(Q)mkdir -vp ${XBOARD_KERNEL_OUT}
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  $(KERNEL_DEFCONFIG)
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  $(KERNEL_TARGET)
ifeq ($(XBOARD),neo)	
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  firmware_install modules_install INSTALL_MOD_PATH=$(XBOARD_KERNEL_OUT)
	$(Q)cp $(KERNEL_CODE_DIR)/arch/arm/boot/zImage $(XBOARD_KERNEL_OUT)/
	$(Q)cp $(KERNEL_CODE_DIR)/arch/arm/boot/dts/imx6sx-udoo-neo-full-hdmi.dtb $(XBOARD_KERNEL_OUT)/
endif 

uboot:
	$(Q)mkdir -vp  ${XBOARD_UBOOT_OUT}
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH)  $(UBOOT_DEFCONFIG)
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) 
ifeq ($(XBOARD),neo)
	$(Q)cp $(UBOOT_CODE_DIR)/SPL $(XBOARD_UBOOT_OUT)/
	$(Q)cp $(UBOOT_CODE_DIR)/u-boot.img $(XBOARD_UBOOT_OUT)/
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
	
	
