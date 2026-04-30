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
slot_select=active
ramdisk_compression=auto
patch_vbmeta_flag=auto
no_magisk_check=1

# import functions/variables and setup patching - see for reference (DO NOT REMOVE)
. tools/ak3-core.sh

ak3_strings() {
  if command -v strings >/dev/null 2>&1; then
    strings "$1"
  elif [ -x "$BIN/busybox" ]; then
    "$BIN/busybox" strings "$1"
  else
    return 1
  fi
}

extract_linux_version() {
  ak3_strings "$1" 2>/dev/null | grep -m1 'Linux version [0-9]' | sed 's/^.*Linux version //' | cut -d' ' -f1
}

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
ui_print "Target block: $BLOCK"

EXPECTED_KERNEL_VERSION="$(extract_linux_version "$AKHOME/Image")"
[ "$EXPECTED_KERNEL_VERSION" ] || abort "Unable to read Linux version from package Image. Aborting."
ui_print "Package kernel: $EXPECTED_KERNEL_VERSION"

ui_print "Flashing AstraGKI kernel Image"

# Image-only GKI flow: split the current boot image, replace the kernel Image,
# rebuild/write boot, and leave dtbo/vendor_boot/init_boot style partitions alone.
split_boot
flash_boot

WRITTEN_KERNEL_VERSION="$(extract_linux_version "$BLOCK")"
[ "$WRITTEN_KERNEL_VERSION" ] || abort "Unable to verify written boot kernel version. Aborting."
ui_print "Written kernel: $WRITTEN_KERNEL_VERSION"

if [ "$WRITTEN_KERNEL_VERSION" != "$EXPECTED_KERNEL_VERSION" ]; then
  abort "Written kernel version mismatch: expected $EXPECTED_KERNEL_VERSION, got $WRITTEN_KERNEL_VERSION"
fi

ui_print " "
ui_print "Flash complete"
ui_print "Reboot recommended"
