#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=281677160
Default_Device=x86-64
}

Diy-Part1() {
[ ! -d package/lean ] && mkdir -p package/lean

ExtraPackages git lean luci-app-autoupdate https://github.com/Hyy2001X main

}

Diy-Part2() {
GET_TARGET_INFO
echo "Author: $Author"
echo "Openwrt Version: $Openwrt_Version"
echo "AutoUpdate Version: $AutoUpdate_Version"
echo "Router: $TARGET_PROFILE"
sed -i "s?$Lede_Version?$Lede_Version Compiled by $Author [$Display_Date]?g" $Default_File
echo "$Openwrt_Version" > package/base-files/files/etc/openwrt_info
}

Diy-Part3() {
GET_TARGET_INFO
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.bin
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.detail
mkdir -p bin/Firmware
echo "Firmware: $AutoBuild_Firmware"
mv bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware bin/Firmware/$AutoBuild_Firmware
echo "[$(date "+%H:%M:%S")] Calculating MD5 and SHA256 ..."
Firmware_MD5=$(md5sum bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1)
Firmware_SHA256=$(sha256sum bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1)
echo -e "MD5: $Firmware_MD5\nSHA256: $Firmware_SHA256"
touch bin/Firmware/$AutoBuild_Detail
echo -e "\nMD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> bin/Firmware/$AutoBuild_Detail
}

GET_TARGET_INFO() {
Diy_Core
[ -e $GITHUB_WORKSPACE/Openwrt.info ] && . $GITHUB_WORKSPACE/Openwrt.info
AutoUpdate_Version=$(awk 'NR==6' package/base-files/files/bin/AutoUpdate.sh | awk -F '[="]+' '/Version/{print $2}')
Default_File="package/lean/default-settings/files/zzz-default-settings"
Lede_Version=$(egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $Default_File)
Openwrt_Version="$Lede_Version-$Compile_Date"
TARGET_PROFILE=$(egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/')
[ -z "$TARGET_PROFILE" ] && TARGET_PROFILE="$Default_Device"
TARGET_BOARD=$(awk -F '[="]+' '/TARGET_BOARD/{print $2}' .config)
TARGET_SUBTARGET=$(awk -F '[="]+' '/TARGET_SUBTARGET/{print $2}' .config)
}

ExtraPackages() {
PKG_PROTO=$1
PKG_DIR=$2
PKG_NAME=$3
REPO_URL=$4
REPO_BRANCH=$5

[ -d package/$PKG_DIR ] && mkdir -p package/$PKG_DIR
[ -d package/$PKG_DIR/$PKG_NAME ] && rm -rf package/$PKG_DIR/$PKG_NAME
[ -d $PKG_NAME ] && rm -rf $PKG_NAME
Retry_Times=3
while [ ! -e $PKG_NAME/Makefile ]
do
	echo "[$(date "+%H:%M:%S")] Checking out package [$PKG_NAME] ..."
	case $PKG_PROTO in
	git)
		git clone -b $REPO_BRANCH $REPO_URL/$PKG_NAME $PKG_NAME > /dev/null 2>&1
	;;
	svn)
		svn checkout $REPO_URL/$PKG_NAME $PKG_NAME > /dev/null 2>&1
	esac
	if [ -e $PKG_NAME/Makefile ] || [ -e $PKG_NAME/README* ];then
		echo "[$(date "+%H:%M:%S")] Package [$PKG_NAME] is detected!"
		mv $PKG_NAME package/$PKG_DIR
		break
	else
		[ $Retry_Times -lt 1 ] && echo "[$(date "+%H:%M:%S")] Skip check out package [$PKG_NAME] ..." && break
		echo "[$(date "+%H:%M:%S")] [Error] [$Retry_Times] Checkout failed,retry in 3s ..."
		Retry_Times=$(($Retry_Times - 1))
		rm -rf $PKG_NAME > /dev/null 2>&1
		sleep 3
	fi
done
}

Replace_File() {
FILE_NAME=$1
PATCH_DIR=$GITHUB_WORKSPACE/openwrt/$2
FILE_RENAME=$3

[ ! -d $PATCH_DIR ] && mkdir -p $PATCH_DIR
if [ -f $GITHUB_WORKSPACE/Customize/$FILE_NAME ];then
	if [ -e $GITHUB_WORKSPACE/Customize/$FILE_NAME ];then
		echo "[$(date "+%H:%M:%S")] Customize File [$FILE_NAME] is detected!"
		if [ -z $FILE_RENAME ];then
			[ -e $PATCH_DIR/$FILE_NAME ] && rm -f $PATCH_DIR/$FILE_NAME
			mv -f $GITHUB_WORKSPACE/Customize/$FILE_NAME $PATCH_DIR/$1
		else
			[ -e $PATCH_DIR/$FILE_NAME ] && rm -f $PATCH_DIR/$3
			mv -f $GITHUB_WORKSPACE/Customize/$FILE_NAME $PATCH_DIR/$3
		fi
	else
		echo "[$(date "+%H:%M:%S")] Customize File [$FILE_NAME] is not detected,skip move ..."
	fi
else
	if [ -d $GITHUB_WORKSPACE/Customize/$FILE_NAME ];then
		echo "[$(date "+%H:%M:%S")] Customize Folder [$FILE_NAME] is detected !"
		mv -f $GITHUB_WORKSPACE/Customize/$FILE_NAME $PATCH_DIR
	else
		echo "[$(date "+%H:%M:%S")] Customize Folder [$FILE_NAME] is not detected,skip move ..."
	fi
fi
}
