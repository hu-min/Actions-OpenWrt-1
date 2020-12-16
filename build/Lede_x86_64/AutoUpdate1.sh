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
luci=$(cat feeds.conf.default | egrep "luci" | awk 'END {print}')
luci_Version="${luci#*openwrt-}"
Compile_Date=$(date +%Y%m%d-%H%M)
Openwrt_Version="$luci_Version-$Compile_Date"
TARGET_PROFILE=$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')
[ -z "$TARGET_PROFILE" ] && TARGET_PROFILE="$Default_Device"
TARGET_BOARD=$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)
TARGET_SUBTARGET=$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)
}

GET_TARGET_INFO
echo "Author: $Author"
echo "Openwrt Version: $Openwrt_Version"
echo "AutoUpdate Version: $AutoUpdate_Version"
echo "Router: $TARGET_PROFILE"
sed -i 's?$Lede_Version?$Lede_Version Compiled by $Author [$Display_Date]?g' $Default_File
echo "$Openwrt_Version" > package/base-files/files/etc/openwrt_info
