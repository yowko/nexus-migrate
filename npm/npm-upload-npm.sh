#!/bin/bash

# 設置新的 Nexus OSS 服務器的變數
NPM_REPO="//localhost:8084/repository/npm-hosted/"
USERNAME="admin"
PASSWORD="pass.123"
TOKEN=$(printf "%s:%s" "$USERNAME" "$PASSWORD" | openssl base64)
REPOSITORY="http:$NPM_REPO"

echo $TOKEN

# 設定 npm 的 registry 和 _auth 變數
npm config set registry=$NPM_REPO
npm config set $NPM_REPO:_auth=$TOKEN

# 上傳目前目錄中所有 .tgz 到新 Nexus OSS
for file in *.tgz; do
    echo "Publishing $file"
    npm publish --registry=$REPOSITORY $file
done