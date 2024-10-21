#!/bin/bash
NEXUS_URL="http://team.sb.rexbet.com:8081"
REPO_NAME="npm-hosted"
NPM_URL="$NEXUS_URL/service/rest/v1/search?repository=$REPO_NAME&format=npm"
USERNAME="admin"
PASSWORD="pass.123"

URL="$NPM_URL"

while true; do
    echo "$URL"

    # 發送請求並解析 JSON 響應，將結果存儲到變量中
    response=$(curl -s -u "$USERNAME:$PASSWORD" $URL)

    echo "$response" | jq -r '.items[] | "\(.name) \(.version) \(.assets[].downloadUrl)"' | while read -r package_name package_version download_url; do

        echo "Downloading $package_name version $package_version"
        echo "$download_url" 
        FILE="$package_name-$package_version.tgz"

        # 檢查檔案是否存在
        if [ -e "$FILE" ]; then
            echo "$FILE 檔案存在"
        else
            
            # 列印並下載包
            #echo "curl -u "$USERNAME:$PASSWORD" -L -o "$FILE" "$download_url""
            curl -u "$USERNAME:$PASSWORD" -L -o "$FILE" "$download_url"
        fi
    done



    # 使用 jq 解析 response，檢查 continuationToken 是否存在
    continuationToken=$(echo "$response" | jq -r '.continuationToken')

    # 如果沒有 continuationToken，說明已經到最後一頁，退出循環
    if [ "$continuationToken" == "null" ]; then
        #echo "$response"
        break
    fi
    if [[ -z  "$continuationToken" ]]; then
        #echo "$response"
        break
    fi
    #echo "$continuationToken"
    # 如果有 continuationToken，將其新增到下一次請求的 URL 中
    URL="$NPM_URL&continuationToken=$continuationToken"
done