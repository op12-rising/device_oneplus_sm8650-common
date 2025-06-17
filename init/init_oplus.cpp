/*
 * Copyright (C) 2022-2025 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/logging.h>
#include <android-base/properties.h>

#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

#include <fs_mgr.h>

#define NV_ID_US "161"
#define NV_ID_IN "27"
#define NV_ID_EU "68"
#define NV_ID_CN "151"

using android::base::GetProperty;
using android::fs_mgr::GetKernelCmdline;

/*
 * Parse /proc/cmdline and extract value of given key.
 */
std::string GetKernelCmdlineParam(const std::string& key) {
    std::string value;
    if (!GetKernelCmdline(key, &value)) {
        LOG(ERROR) << key << " not found in /proc/cmdline";
    }
    return value;
}

/*
 * SetProperty does not allow updating read only properties and as a result
 * does not work for our use case. Write "OverrideProperty" to do practically
 * the same thing as "SetProperty" without this restriction.
 */
void OverrideProperty(const char* name, const char* value) {
    size_t valuelen = strlen(value);

    prop_info* pi = (prop_info*)__system_property_find(name);
    if (pi != nullptr) {
        __system_property_update(pi, value, valuelen);
    } else {
        __system_property_add(name, strlen(name), value, valuelen);
    }
}

/*
 * Only for read-only properties. Properties that can be wrote to more
 * than once should be set in a typical init script (e.g. init.oplus.hw.rc)
 * after the original property has been set.
 */
void vendor_load_properties() {
    auto hw_region_id = GetKernelCmdlineParam("oplus_region");
    auto prjname = std::stoi(GetProperty("ro.boot.prjname", "0"));

    if (hw_region_id == NV_ID_CN) {
        OverrideProperty("ro.boot.hardware.revision", "CN");
    } else if (hw_region_id == NV_ID_EU) {
        OverrideProperty("ro.boot.hardware.revision", "EU");
    } else if (hw_region_id == NV_ID_IN) {
        OverrideProperty("ro.boot.hardware.revision", "IN");
    } else if (hw_region_id == NV_ID_US) {
        OverrideProperty("ro.boot.hardware.revision", "NA");
    } else {
        LOG(ERROR) << "Unexpected region ID: " << hw_region_id;
    }

    switch (prjname) {
        case 22825:  // waffle CN
            OverrideProperty("ro.product.device", "OP5929L1");
            OverrideProperty("ro.product.vendor.device", "OP5929L1");
            OverrideProperty("ro.product.product.model", "PJD110");
            break;
        case 22877:  // waffle ROW
            OverrideProperty("ro.product.product.model",
                    hw_region_id == NV_ID_IN ? "CPH2573" :
                    hw_region_id == NV_ID_US ? "CPH2583" : "CPH2581");
            break;
        default:
            LOG(ERROR) << "Unexpected prjname: " << prjname;
    }
}
