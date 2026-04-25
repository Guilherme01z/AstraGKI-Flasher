# AstraGKI-Flasher

> Custom AnyKernel3-based flasher for AstraGKI.

```text
[ AstraGKI ]  [ Android 12 ]  [ Linux 5.10 LTS ]  [ GKI Image ]  [ AnyKernel3 ]
```

---

## Overview

**AstraGKI-Flasher** is a conservative AnyKernel3-based flashing package customized for the AstraGKI kernel.

It is designed to package and flash the AstraGKI GKI-style kernel `Image` while keeping the upstream AnyKernel3 flashing flow intact for recovery and kernel manager compatibility.

---

## Target Support

| Item | Target |
|---|---|
| Kernel branding | AstraGKI |
| Android version | Android 12 |
| Kernel version | Linux 5.10 LTS |
| Packaging style | GKI boot image kernel replacement |
| Final zip format | `AstraGKI-A12-5.10-LTS-YYYYMMDD-HHMMSS.zip` |

---

## Features

- AstraGKI-specific `anykernel.sh` branding and status output
- Image-only boot flashing flow
- A/B slot detection kept through AnyKernel3
- Recovery and kernel manager app compatibility
- No KPM dependency
- No dtbo, vendor_boot, vendor_kernel_boot, init_boot, or recovery image output
- Packaging validation for required files and forbidden images

---

## Zip Structure

The generated flashable zip contains only the files required for the AnyKernel3 flashing flow:

```text
AstraGKI-A12-5.10-LTS-YYYYMMDD-HHMMSS.zip
├── anykernel.sh
├── banner
├── Image
├── META-INF/
│   └── com/google/android/
│       ├── update-binary
│       └── updater-script
└── tools/
    ├── ak3-core.sh
    ├── busybox
    ├── fec
    ├── httools_static
    ├── lptools_static
    ├── magiskboot
    ├── magiskpolicy
    └── snapshotupdater_static
```

Forbidden image outputs:

```text
boot.img
dtbo.img
vendor_boot.img
vendor_kernel_boot.img
init_boot.img
recovery.img
```

---

## CI Usage

The main AstraGKI workflow can clone this repository, copy the built kernel `Image`, and generate the final flashable zip without manual steps.

The build stamp must use the same timestamp format as the kernel localversion:

```text
YYYYMMDD-HHMMSS
```

---

## Copy/Paste Integration

```bash
FLA_BRANCH="main"
FLA_REPO="https://github.com/Guilherme01z/AstraGKI-Flasher.git"
FLA_DIR="$GITHUB_WORKSPACE/AstraGKI-Flasher"
DIST_DIR="$KERNEL_ROOT/out/android12-5.10/dist"
BUILD_STAMP="${BUILD_STAMP:?BUILD_STAMP is required}"

git clone --depth=1 -b "$FLA_BRANCH" "$FLA_REPO" "$FLA_DIR"

sudo apt-get update
sudo apt-get install -y zip unzip

bash "$FLA_DIR/scripts/package-astragi.sh" \
  "$DIST_DIR/Image" \
  "$BUILD_STAMP" \
  "$GITHUB_WORKSPACE"
```

The command generates:

```text
$GITHUB_WORKSPACE/AstraGKI-A12-5.10-LTS-YYYYMMDD-HHMMSS.zip
```

Upload only that zip as the final artifact.

---

## Validation Rules

`scripts/package-astragi.sh` validates:

- kernel `Image` exists
- `anykernel.sh` exists
- `META-INF/com/google/android/update-binary` exists
- `META-INF/com/google/android/updater-script` exists
- required AnyKernel3 tools exist
- final zip name matches `AstraGKI-A12-5.10-LTS-YYYYMMDD-HHMMSS.zip`
- final zip contains the expected AnyKernel3 files
- final zip does not contain forbidden image outputs
- final output directory contains exactly one zip
- no nested zip is included

---

## AstraGKI Workflow Plan

In the main AstraGKI workflow:

1. Replace the generic AnyKernel3 clone with:

```bash
git clone --depth=1 https://github.com/Guilherme01z/AstraGKI-Flasher.git "$ANYKERNEL3"
```

2. Keep the existing kernel build output:

```bash
DIST_DIR="$KERNEL_ROOT/out/android12-5.10/dist"
test -f "$DIST_DIR/Image"
```

3. Package with the shared timestamp:

```bash
bash "$ANYKERNEL3/scripts/package-astragi.sh" \
  "$DIST_DIR/Image" \
  "$BUILD_STAMP" \
  "$GITHUB_WORKSPACE"
```

4. Validate only the AstraGKI zip exists:

```bash
OUTPUT_ZIP_NAME="AstraGKI-A12-5.10-LTS-${BUILD_STAMP}.zip"
test -f "$GITHUB_WORKSPACE/$OUTPUT_ZIP_NAME"
test "$(find "$GITHUB_WORKSPACE" -maxdepth 1 -type f -name '*.zip' | wc -l | tr -d ' ')" = "1"
```

5. Upload:

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: ${{ env.OUTPUT_ZIP_NAME }}
    path: ${{ env.OUTPUT_ZIP_NAME }}
    if-no-files-found: error
```

Do not add KPM steps. Do not generate boot.img, dtbo.img, vendor_boot.img, vendor_kernel_boot.img, init_boot.img, or recovery.img.
