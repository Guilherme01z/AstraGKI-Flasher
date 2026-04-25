### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers
## AstraGKI-Flasher customization for AstraGKI

### AnyKernel setup
# global properties
properties() { '
kernel.string=AstraGKI Android 12 5.10 LTS
do.devicecheck=0
do.modules=0
do.systemless=0
do.cleanup=1
do.cleanuponabort=0
do.check_boot_version=0
device.name1=
device.name2=
device.name3=
device.name4=
device.name5=
supported.versions=
supported.patchlevels=
supported.vendorpatchlevels=
'; } # end properties


### AnyKernel install
## boot shell variables
block=boot
is_slot_device=auto
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

ui_print " "
ui_print "AstraGKI-Flasher"
ui_print "Custom AnyKernel3-based flasher for AstraGKI"
ui_print "Target: Android 12 / Linux 5.10 LTS / GKI boot image"
ui_print " "
ui_print "Preparing AstraGKI package"

[ -f "$AKHOME/Image" ] || abort "AstraGKI kernel Image is missing. Aborting."
[ -f "$AKHOME/anykernel.sh" ] || abort "anykernel.sh is missing. Aborting."
[ -d "$AKHOME/META-INF/com/google/android" ] || abort "META-INF installer files are missing. Aborting."
[ -f "$AKHOME/tools/ak3-core.sh" ] || abort "AK3 core script is missing. Aborting."
[ -f "$AKHOME/tools/busybox" ] || abort "busybox tool is missing. Aborting."
[ -f "$AKHOME/tools/magiskboot" ] || abort "magiskboot tool is missing. Aborting."

for forbidden_img in boot.img dtbo.img vendor_boot.img vendor_kernel_boot.img init_boot.img recovery.img; do
  [ ! -e "$AKHOME/$forbidden_img" ] || abort "Forbidden image found in package: $forbidden_img"
done

ui_print "Checking slot/device environment"
if [ "$SLOT" ]; then
  ui_print "Active slot: $SLOT"
else
  ui_print "Active slot: not reported"
fi

ui_print "Flashing AstraGKI kernel Image"

# Image-only GKI flow: split the current boot image, replace the kernel Image,
# rebuild/write boot, and leave dtbo/vendor_boot/init_boot style partitions alone.
split_boot
flash_boot

ui_print " "
ui_print "Flash complete"
ui_print "Reboot recommended"
