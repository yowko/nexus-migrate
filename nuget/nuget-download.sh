#!/bin/bash

# 確保您已經設置了相應的變數
NEXUS_URL="http://localhost:8081"
NUGET_URL="http://localhost:8081/service/rest/v1/search?repository=nuget-hosted"
USERNAME="admin"
PASSWORD="pass.123"

# 初始請求的 URL，不包含 continuationToken
URL="$NUGET_URL"

# 遍歷所有分頁
while true; do
    echo "$URL"
    # 發送請求並解析 JSON 響應，將結果存儲到變量中
    response=$(curl -s -u "$USERNAME:$PASSWORD" $URL)

    # 使用 jq 列印包名和版本，並下載每個包
    echo "$response" | jq -r '.items[] | "\(.name) \(.version)"' | while read -r package_name package_version; do
        #echo "Downloading $package_name version $package_version"

        # 要檢查的檔案路徑
        FILE="$package_name.$package_version.nupkg"

        # 檢查檔案是否存在
        if [ -e "$FILE" ]; then
            echo "$FILE 檔案存在"
        else
            # 生成包的 URL
            package_url="$NEXUS_URL/repository/nuget-hosted/$package_name/$package_version"
            
            # 列印並下載包
            echo "download $FILE"
            #echo "curl -u "$USERNAME:$PASSWORD" -L -o "$OUTPUT_DIR/$package_name.$package_version.nupkg" "$package_url""
            curl -u "$USERNAME:$PASSWORD" -L -o "$FILE" "$package_url"
        fi
    done


    # 使用 jq 解析 response，檢查 continuationToken 是否存在
    continuationToken=$(echo "$response" | jq -r '.continuationToken')

    # 如果沒有 continuationToken，說明已經到最後一頁，退出循環
    if [ "$continuationToken" == "null" ]; then
        echo "$response"
        break
    fi
    if [[ -z  "$continuationToken" ]]; then
        echo "$response"
        break
    fi
    #echo "$continuationToken"
    # 如果有 continuationToken，將其新增到下一次請求的 URL 中
    URL="$NUGET_URL&continuationToken=$continuationToken"
done