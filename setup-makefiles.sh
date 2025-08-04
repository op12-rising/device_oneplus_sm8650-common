#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

export TARGET_ENABLE_CHECKELF=true

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

function vendor_imports() {
    cat <<EOF >>"$1"
		"device/oneplus/sm8650-common",
		"hardware/qcom-caf/sm8650",
		"hardware/qcom-caf/wlan",
		"hardware/oplus",
		"vendor/qcom/opensource/commonsys/display",
		"vendor/qcom/opensource/commonsys-intf/display",
		"vendor/qcom/opensource/dataservices",
EOF
}

function lib_to_package_fixup_vendor_variants() {
    if [ "$2" != "vendor" ]; then
        return 1
    fi

    case "$1" in
        com.qualcomm.qti.dpm.api@1.0 | \
        com.qti.sensor.lyt808 | \
            libarcsoft_triple_sat | \
            libarcsoft_triple_zoomtranslator | \
            libdualcam_optical_zoom_control | \
            libdualcam_video_optical_zoom | \
            libhwconfigurationutil | \
            libtriplecam_optical_zoom_control | \
            libtriplecam_video_optical_zoom | \
            vendor.oplus.hardware.camera_rfi-V1-ndk | \
            vendor.oplus.hardware.cammidasservice-V1-ndk | \
            vendor.oplus.hardware.displaycolorfeature-V1-ndk | \
            vendor.oplus.hardware.displaypanelfeature-V1-ndk | \
            vendor.pixelworks.hardware.display@1.0 | \
            vendor.pixelworks.hardware.display@1.1 | \
            vendor.pixelworks.hardware.display@1.2 | \
            vendor.pixelworks.hardware.feature@1.0 | \
            vendor.pixelworks.hardware.feature@1.1 | \
            vendor.pixelworks.hardware.feature-V1-ndk | \
            vendor.qti.diaghal@1.0 | \
            vendor.qti.hardware.dpmservice@1.0 | \
            vendor.qti.hardware.dpmaidlservice-V1-ndk | \
            vendor.qti.hardware.qccsyshal@1.0 | \
            vendor.qti.hardware.qccsyshal@1.1 | \
            vendor.qti.hardware.qccsyshal@1.2 | \
            vendor.qti.imsrtpservice@3.0 | \
            vendor.qti.imsrtpservice@3.1 | \
            vendor.qti.ImsRtpService-V1-ndk | \
            vendor.qti.qccvndhal_aidl-V1-ndk)
            echo "$1_vendor"
            ;;
        libagmclient | \
            libpalclient | \
            libar-pal | \
            libar-acdb | \
            libar-gsl | \
            liblx-osal | \
            libats | \
            libagm | \
            libwpa_client) ;;
        *)
            return 1
            ;;
    esac
}

function lib_to_package_fixup() {
    lib_to_package_fixup_clang_rt_ubsan_standalone "$1" ||
        lib_to_package_fixup_proto_3_9_1 "$1" ||
        lib_to_package_fixup_vendor_variants "$@"
}

# Initialize the helper for common
setup_vendor "${DEVICE_COMMON}" "${VENDOR_COMMON:-$VENDOR}" "${ANDROID_ROOT}" true

# Warning headers and guards
write_headers "waffle"

# The standard common blobs
write_makefiles "${MY_DIR}/proprietary-files.txt"

# Finish
write_footers

if [ -s "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt" ]; then
    # Reinitialize the helper for device
    source "${MY_DIR}/../../${VENDOR}/${DEVICE}/setup-makefiles.sh"
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false

    # Warning headers and guards
    write_headers

    # The standard device blobs
    write_makefiles "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-files.txt"

    if [ -f "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-firmware.txt" ]; then
        append_firmware_calls_to_makefiles "${MY_DIR}/../../${VENDOR}/${DEVICE}/proprietary-firmware.txt"
    fi

    # Finish
    write_footers
fi
