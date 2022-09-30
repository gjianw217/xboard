include .config

TOP_DIR=$(shell pwd)
KERNEL_BUILD_DIR=${TOP_DIR}/build/kernel/${XVENDOR}-${XBOARD}-${XCHIP}
KERNEL_CODE_DIR=${TOP_DIR}/kernel/${XVENDOR}-${XBOARD}-${XCHIP}-kernel

UBOOT_BUILD_DIR=${TOP_DIR}/build/uboot/${XVENDOR}-${XBOARD}-${XCHIP}
UBOOT_CODE_DIR=${TOP_DIR}/uboot/${XVENDOR}-${XBOARD}-${XCHIP}-uboot

XBOARD_OUT=${TOP_DIR}/output
XBOARD_UBOOT_OUT=${XBOARD_OUT}/uboot
XBOARD_KERNEL_OUT=${XBOARD_OUT}/kernel
DATE_STR=$(shell date +%y%m%d)
FW_NAME=$(XVENDOR)_$(XBOARD)_$(XCHIP)_$(DATE_STR)

.PHONY: all clean kernel uboot uboot-clean linux-mrproper uboot-mrproper

all:xboard

xboard:kernel uboot
	$(Q)sudo chown -R root:root $(XBOARD_OUT)/*
	cd $(XBOARD_OUT) && sudo tar -Jcf $(FW_NAME).tar.xz uboot kernel --remove-files
	cd $(XBOARD_OUT) && sudo md5sum *.* > $(FW_NAME).md5
kernel:
	$(Q)mkdir -vp $(KERNEL_BUILD_DIR) ${XBOARD_KERNEL_OUT}
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(KERNEL_BUILD_DIR) udoo_neo_defconfig
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(KERNEL_BUILD_DIR) zImage
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(KERNEL_BUILD_DIR) dtbs
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(KERNEL_BUILD_DIR) modules
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(KERNEL_BUILD_DIR) firmware_install modules_install INSTALL_MOD_PATH=$(KERNEL_BUILD_DIR) 	
	
uboot:
	$(Q)mkdir -vp $(UBOOT_BUILD_DIR) ${XBOARD_UBOOT_OUT}
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(UBOOT_BUILD_DIR) udoo_neo_defconfig
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(UBOOT_BUILD_DIR) 
	$(Q)cp $(UBOOT_BUILD_DIR)/SPL $(XBOARD_UBOOT_OUT)/
	$(Q)cp $(UBOOT_BUILD_DIR)/u-boot.img $(XBOARD_UBOOT_OUT)/
	
#clean  - Remove most generated files but keep the config and enough build support to build external modules
linux-clean:
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(KERNEL_BUILD_DIR) clean
	
uboot-clean:
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) O=$(UBOOT_BUILD_DIR) clean
	
	
clean:
	rm -rf 	$(UBOOT_CODE_DIR)/output
	rm -rf  $(UBOOT_CODE_DIR)/build	
	
#mrproper  - Remove all generated files + config + various backup files		
linux-mrproper:
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) O=$(KERNEL_BUILD_DIR) mrproper
	$(Q)$(MAKE) -C $(KERNEL_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) ARCH=$(XARCH) mrproper

uboot-mrproper:
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) O=$(UBOOT_BUILD_DIR) mrproper
	$(Q)$(MAKE) -C $(UBOOT_CODE_DIR) CROSS_COMPILE=$(XCROSS_COMPILE) mrproper
	
	
	