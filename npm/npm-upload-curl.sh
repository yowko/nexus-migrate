#!/bin/bash

# 設置新的 Nexus OSS 服務器的變數
NEXUS_URL="http://localhost:8084"
REPO_NAME="npm-hosted"
USERNAME="admin"
PASSWORD="pass.123"

# 上傳目前目錄中所有 .tgz 到新 Nexus OSS
for file in *.tgz; do
    echo "Uploading $file to Nexus"
    curl -u "$USERNAME:$PASSWORD" -X POST "$NEXUS_URL/service/rest/v1/components?repository=$REPO_NAME" \
        -F "npm.asset=@$file"
done