#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "::error::$*" >&2
  exit 1
}

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE_SRC="${1:-}"
BUILD_STAMP="${2:-${ASTRAGKI_BUILD_STAMP:-$(date -u +'%Y%m%d-%H%M%S')}}"
OUT_DIR="${3:-$ROOT_DIR/out}"
ZIP_PREFIX="AstraGKI-A12-5.10-LTS"
ZIP_NAME="${ZIP_PREFIX}-${BUILD_STAMP}.zip"
OUT_ZIP="$OUT_DIR/$ZIP_NAME"
TARGET_IMAGE="$ROOT_DIR/Image"
COPIED_IMAGE=0

[ -n "$IMAGE_SRC" ] || fail "Usage: scripts/package-astragi.sh <Image> [YYYYMMDD-HHMMSS] [out-dir]"
[ -f "$IMAGE_SRC" ] || fail "Kernel Image not found: $IMAGE_SRC"
[[ "$BUILD_STAMP" =~ ^[0-9]{8}-[0-9]{6}$ ]] || fail "Invalid build stamp: $BUILD_STAMP"
[[ "$ZIP_NAME" =~ ^AstraGKI-A12-5\.10-LTS-[0-9]{8}-[0-9]{6}\.zip$ ]] || fail "Invalid output zip name: $ZIP_NAME"

command -v zip >/dev/null 2>&1 || fail "zip is required"
command -v unzip >/dev/null 2>&1 || fail "unzip is required for package validation"

for required in \
  anykernel.sh \
  META-INF/com/google/android/update-binary \
  META-INF/com/google/android/updater-script \
  tools/ak3-core.sh \
  tools/busybox \
  tools/magiskboot; do
  [ -e "$ROOT_DIR/$required" ] || fail "Required flasher file missing: $required"
done

for forbidden in boot.img dtbo.img vendor_boot.img vendor_kernel_boot.img init_boot.img recovery.img; do
  [ ! -e "$ROOT_DIR/$forbidden" ] || fail "Forbidden image present in flasher root: $forbidden"
done

IMAGE_ABS="$(cd "$(dirname "$IMAGE_SRC")" && pwd)/$(basename "$IMAGE_SRC")"
if [ "$IMAGE_ABS" != "$TARGET_IMAGE" ]; then
  cp "$IMAGE_ABS" "$TARGET_IMAGE"
  COPIED_IMAGE=1
fi

cleanup() {
  if [ "$COPIED_IMAGE" -eq 1 ]; then
    rm -f "$TARGET_IMAGE"
  fi
}
trap cleanup EXIT

mkdir -p "$OUT_DIR"
find "$ROOT_DIR" -maxdepth 1 -type f -name '*.zip' -delete
find "$OUT_DIR" -maxdepth 1 -type f -name '*.zip' -delete

(
  cd "$ROOT_DIR"
  zip -qr "$OUT_ZIP" anykernel.sh banner META-INF tools Image \
    -x '*.git*' '*.zip' '*.img' 'README.md' 'scripts/*' 'out/*'
)

[ -f "$OUT_ZIP" ] || fail "Package was not created: $OUT_ZIP"

ZIP_ENTRIES="$(unzip -Z -1 "$OUT_ZIP")"

for required_entry in \
  anykernel.sh \
  banner \
  Image \
  META-INF/com/google/android/update-binary \
  META-INF/com/google/android/updater-script \
  tools/ak3-core.sh \
  tools/busybox \
  tools/magiskboot; do
  echo "$ZIP_ENTRIES" | grep -Fxq "$required_entry" || fail "Zip missing required entry: $required_entry"
done

if echo "$ZIP_ENTRIES" | grep -Eq '(^|/)(boot|dtbo|vendor_boot|vendor_kernel_boot|init_boot|recovery)\.img$'; then
  echo "$ZIP_ENTRIES" | grep -E '(^|/)(boot|dtbo|vendor_boot|vendor_kernel_boot|init_boot|recovery)\.img$' >&2
  fail "Forbidden image output found inside zip"
fi

if echo "$ZIP_ENTRIES" | grep -Eiq '\.zip$'; then
  echo "$ZIP_ENTRIES" | grep -Ei '\.zip$' >&2
  fail "Nested zip found inside package"
fi

ZIP_COUNT="$(find "$OUT_DIR" -maxdepth 1 -type f -name '*.zip' | wc -l | tr -d ' ')"
[ "$ZIP_COUNT" = "1" ] || fail "Expected exactly one zip in $OUT_DIR, found $ZIP_COUNT"

echo "$OUT_ZIP"
