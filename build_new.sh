#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# select device and prepare varibles
CCACHE=$BUILD_ROOT/prebuilt/linux-x86/ccache
BACON=true

export USE_CCACHE=1
export CCACHE_DIR=/home/$USER/android/.ccache
cd $CCACHE
./ccache -M 40G
BUILD_ROOT=`pwd`
cd $BUILD_ROOT
rm -rf out/target/product
mkdir -p out
ln -s /tmp/ramdisk/remicks /home/remicks/android/AOKPCB/out/target
. build/envsetup.sh
lunch aokpcb_"$1"-userdebug

TARGET_VENDOR=$(echo $TARGET_PRODUCT | cut -f1 -d '_')

# create log dir if not already present
if test ! -d "$ANDROID_PRODUCT_OUT"
    echo "$ANDROID_PRODUCT_OUT doesn't exist, creating now"
    then mkdir -p "$ANDROID_PRODUCT_OUT"
fi

# build
if [ "$BACON" = "true" ]; then
    time make -j6 bacon 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log
else
    time make -j6 otapackage 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log
fi

# clean out of previous zip
if [ "$BACON" = "true" ]; then
    ZIP=$(tail -2 "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
else
    ZIP=$(grep "Package OTA" "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f5 -d '/')
fi

mkdir -p "$BUILD_ROOT"/upload
OUTD="$BUILD_ROOT"/upload
rm $OUTD/$ZIP
cp "$ANDROID_PRODUCT_OUT"/$ZIP $OUTD/$ZIP

# finish
echo "$1 build complete"

# md5sum list
cd $OUTD
md5sum $ZIP | cat >> "$ZIP".md5sum

cd $BUILD_ROOT
rm -rf out/target/product
echo "Complete - Moving to next project"