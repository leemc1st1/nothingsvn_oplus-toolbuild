#!/bin/bash
# SPDX-License-Identifier: GPL-3.0

work_dir=$(pwd)
source $work_dir/functions.sh
ANDROID_VER=$(cat $work_dir/bin/ddevice/androidver.txt)
DEVICE_MODEL=$(cat $work_dir/bin/ddevice/device_model.txt)
BASE_BUILD_ID=$(cat $work_dir/bin/ddevice/base_build_id.txt)
BRAND=$(cat $work_dir/bin/ddevice/brand.txt)
RCLONE_CONFIG_1DRIVE="$work_dir/rclone.conf"
ONEDRIVE_REMOTE="gdrive"



if [ "$1" == "setup" ]; then
  # Kiểm tra xem biến môi trường có rỗng không
  if [ -z "$GDRIVE_CONFIG_ENV" ]; then
    echo "[ERROR] - GDRIVE_CONFIG_ENV variable is empty!"
    exit 1
  fi

  # Ghi trực tiếp nội dung cấu hình từ GitHub Secret vào file rclone.conf
  echo "$GDRIVE_CONFIG_ENV" > "$RCLONE_CONFIG_1DRIVE"
  
  echo "[SYSTEM] - Setup Rclone config successfully."
  exit 0
elif [ "$1" == "dummy" ]; then
  rclone -v --config="$RCLONE_CONFIG_1DRIVE" copy "$work_dir/dummy.txt" "$ONEDRIVE_REMOTE:NTBuild/${uploaddir}/${VERSION}/${DEVICE_MODEL}/" || {
    echo "[GDRIVE] - Error uploading file to Google Drive: $FILENAME"
    exit 1
  }
  exit 0
fi



if [[ $(git branch --show-current) == "beta" ]]; then
    VERSION="$(cat $work_dir/Version)"
	status="Beta"
else
    VERSION="$(cat $work_dir/Version)"
	status="Official"
fi

if [[ $BRAND == "OnePlus" ]]; then
  NTBUILD="ColorOS"
  uploaddir="ColorOS"
elif [[ $BRAND == "OnePlus_Global" ]]; then
  NTBUILD="OxygenOS"
  uploaddir="OxygenOS"
elif [[ $BRAND == "RealmeUI" ]]; then
  NTBUILD="RealmeUI"
  uploaddir="RealmeUI"
fi

hash=$(md5sum out/${NTBUILD}_${DEVICE_MODEL}_${ANDROID_VER}_OS${BASE_BUILD_ID}.zip |head -c 5)
mv out/${NTBUILD}_${DEVICE_MODEL}_${ANDROID_VER}_OS${BASE_BUILD_ID}.zip out/${NTBUILD}_${VERSION}_${DEVICE_MODEL}_OS${BASE_BUILD_ID}_${hash}_${status}.zip
echo "[SCRIPT] - Output: "
output_file="out/${NTBUILD}_${VERSION}_${DEVICE_MODEL}_OS${BASE_BUILD_ID}_${hash}_${status}.zip"
echo "${NTBUILD}_${VERSION}_${DEVICE_MODEL}_OS${BASE_BUILD_ID}_${hash}_${status}.zip" > $work_dir/bin/ddevice/output_zip.txt
echo "$output_file"
echo "[GDRIVE] - Uploading"
# gdrive
rclone -v --config="$RCLONE_CONFIG_1DRIVE" copy "$output_file" "$ONEDRIVE_REMOTE:NTBuild/${uploaddir}/${VERSION}/${DEVICE_MODEL}/" || {
echo "[GDRIVE] - Error uploading file to Google Drive: $output_file"
exit 1
}

echo "[SYSTEM] - Clean Workflow.."
rm -rf $work_dir/out
rm -rf $work_dir/build

echo "[INFO] - Build ${NTBUILD}_${VERSION} for ${DEVICE_MODEL} successfull !"
