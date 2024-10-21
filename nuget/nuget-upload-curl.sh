#!/bin/bash

# 設置新的 Nexus OSS 服務器的變數
TARGET_NEXUS_URL="http://localhost:8084"
NUGET_REPO="nuget-hosted"
USERNAME="admin"
PASSWORD="pass.123"

# 將所在目錄下所有 .nupkg 到新 Nexus OSS
for package in ./*.nupkg; do
    package_name=$(basename "$package")
    echo "Uploading $package_name to $TARGET_NEXUS_URL"
    curl -v -u "$USERNAME:$PASSWORD" -F "file=@$package"  "$TARGET_NEXUS_URL/service/rest/v1/components?repository=$NUGET_REPO"
done