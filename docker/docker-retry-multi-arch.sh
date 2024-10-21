#!/bin/bash

# 定義檔案路徑
file_path="err.txt"

# 使用 while 讀取檔案逐行處理
while IFS= read -r line; do
  # 檢查該行是否為空，若為空則略過
  if [[ -z "$line" ]]; then
    continue
  fi

  # 執行該行指令
  MAX_RETRIES=3
  RETRY_COUNT=0
  DELAY=3
  echo "執行指令: $line"
  # 循環重試機制
  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    eval "$line"
    
    if [ $? -eq 0 ]; then
      echo "成功執行指令: $line"
      break
    else
      echo "buildx 操作失敗，第 $((RETRY_COUNT+1)) 次重試..."
      RETRY_COUNT=$((RETRY_COUNT+1))
      
      if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "等待 $DELAY 秒後重試..."
        sleep $DELAY
      else
        echo "已達到最大重試次數，操作失敗。"
        echo "$line" >> err3.txt
      fi
    fi
  done
done < "$file_path"