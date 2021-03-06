#!/bin/bash

# $1 should be lunch combo
# $2 should be device name
# select device and prepare varibles
BUILD_ROOT=`pwd`
CCACHE=$BUILD_ROOT/prebuilt/linux-x86/ccache

export USE_CCACHE=1
export CCACHE_DIR=/home/$USER/android/.ccache
cd $CCACHE
./ccache -M 40G
cd $BUILD_ROOT
rm -rf out/target/product
mkdir -p out
ln -s /tmp/ramdisk/remicks /home/remicks/android/AOKPCB/out/target
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
OUTD="$BUILD_ROOT"/upload
rm $OUTD/$ZIP
cp "$ANDROID_PRODUCT_OUT"/$ZIP $OUTD/$ZIP

# finish
echo "$2 build complete"

# md5sum list
cd $OUTD
md5sum $ZIP | cat >> "$ZIP".md5sum

# upload
echo "checking on upload reference file"

BUILDBOT=$BUILD_ROOT/vendor/$TARGET_VENDOR/bot/
cd $BUILDBOT
if test -x upload ; then
    echo "Upload file exists, executing now"
    cp upload $OUTD
    cd $OUTD
    # device and zip names are passed on for upload
    ./upload $2 $ZIP && rm upload
else
    echo "No upload file found (or set to +x), build complete."
fi

cd $BUILD_ROOT
rm -rf out/target/product
echo "Complete - Moving to next project"