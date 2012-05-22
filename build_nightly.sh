#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# select device and prepare varibles
BUILD_ROOT=`pwd`
CCACHE=$BUILD_ROOT/prebuilt/linux-x86/ccache

cd $CCACHE
./ccache -M 40G
cd $BUILD_ROOT
. build/envsetup.sh
lunch $1

TARGET_VENDOR=$(echo $TARGET_PRODUCT | cut -f1 -d '_')

# bacon check
if [ "$(grep -m 1 bacon build/envsetup.sh)" = "" ]; then
    echo "Y U NO MAKE BACON?!"
    BACON=false
else
    BACON=true
fi

# create log dir if not already present
if test ! -d "$ANDROID_PRODUCT_OUT"
    echo "$ANDROID_PRODUCT_OUT doesn't exist, creating now"
    then mkdir -p "$ANDROID_PRODUCT_OUT"
fi

# build
if [ "$BACON" = "true" ]; then
    make -j6 bacon 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log
else
    make -j6 otapackage 2>&1 | tee "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log
fi

# clean out of previous zip
if [ "$BACON" = "true" ]; then
    ZIP=$(tail -2 "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f3 -d ' ' | cut -f1 -d ' ' | sed -e '/^$/ d')
else
    ZIP=$(grep "Package OTA" "$ANDROID_PRODUCT_OUT"/"$TARGET_PRODUCT"_bot.log | cut -f5 -d '/')
fi
OUTD=/home/remicks/public_html
PRIV=/home/remicks/private_html
mkdir $OUTD/$2/
mkdir $PRIV/$2/
cp "$ANDROID_PRODUCT_OUT"/aokpcb_*.zip $OUTD/$2/aokpcb_$2-$(date +%Y%m%d-%H%M).zip
cp "$ANDROID_PRODUCT_OUT"/*_bot.log $PRIV/$2/aokpcb_$2-$(date +%Y%m%d-%H%M)_bot.log

# finish
echo "$2 build complete"

# md5sum list
cd $OUTD/$2/
md5sum aokpcb_$2-$(date +%Y%m%d-%H%M).zip | cat >> aokpcb_$2-$(date +%Y%m%d-%H%M).zip.md5

cd $BUILD_ROOT
