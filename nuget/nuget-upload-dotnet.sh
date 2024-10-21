#!/bin/bash

# 設置新的 Nexus OSS 服務器的變數
TARGET_NUGET_URL="http://localhost:8084/repository/nuget-hosted/"
API_KEY={your api key}

# 將所在目錄下所有 .nupkg 到新 Nexus OSS
for package in ./*.nupkg; do
    package_name=$(basename "$package")
    echo "Uploading $package_name to $TARGET_NEXUS_URL"
    dotnet nuget push "$package_name" --source "$TARGET_NUGET_URL" --api-key "$API_KEY"
done