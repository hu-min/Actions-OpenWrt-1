#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=dhxh
Default_Device=phicomm-k3
}

GET_TARGET_INFO() {
Diy_Core
[ -e $GITHUB_WORKSPACE/Openwrt.info ] && . $GITHUB_WORKSPACE/Openwrt.info
AutoUpdate_Version=$(awk 'NR==6' package/base-files/files/bin/AutoUpdate.sh | awk -F '[="]+' '/Version/{print $2}')
Default_File="package/lean/default-settings/files/zzz-default-settings"
CURRENT_VERSION=$(awk 'NR==1' package/base-files/files/etc/openwrt_info)
Openwrt_Version="$CURRENT_VERSION"
TARGET_PROFILE=$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')
[ -z "$TARGET_PROFILE" ] && TARGET_PROFILE="$Default_Device"
TARGET_BOARD=$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)
TARGET_SUBTARGET=$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)
}

GET_TARGET_INFO
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_PROFILE-squashfs.trx
AutoBuild_Firmware=openwrt-$TARGET_BOARD-$TARGET_PROFILE-${Openwrt_Version}.trx
AutoBuild_Detail=openwrt-$TARGET_BOARD-$TARGET_PROFILE-${Openwrt_Version}.detail
mv bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$AutoBuild_Firmware
echo "Firmware: $AutoBuild_Firmware"
echo "[$(date "+%H:%M:%S")] Calculating MD5 and SHA256 ..."
Firmware_MD5=$(md5sum bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$AutoBuild_Firmware | cut -d ' ' -f1)
Firmware_SHA256=$(sha256sum bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$AutoBuild_Firmware | cut -d ' ' -f1)
echo -e "MD5: $Firmware_MD5\nSHA256: $Firmware_SHA256"
touch bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$AutoBuild_Detail
echo -e "\nMD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$AutoBuild_Detail
