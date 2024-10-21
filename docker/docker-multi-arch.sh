#!/bin/bash
for i in "$@"
do 
  case $i in
    -s=*|--src=*)
      src="${i#*=}"
      ;;
    -d=*|--dest=*)
      dest="${i#*=}"
      ;;
  esac
done

multiArchImage(){
  # local variables defined with alias names
  local src=${1}
  local repo_name=${2}
  local tag_ver=${3}
  local dest=${4}

  local MAX_RETRIES=3
  local RETRY_COUNT=0
  local DELAY=3

  echo "準備執行：docker buildx imagetools create --tag ${dest}/${repo_name}:${tag_ver} ${src}/${repo_name}:${tag_ver}"

  # 循環重試機制
  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    docker buildx imagetools create --tag "${dest}/${repo_name}:${tag_ver}" "${src}/${repo_name}:${tag_ver}" > /dev/null

    if [ $? -eq 0 ]; then
      echo "buildx 成功推送到 ${dest}/${repo_name}:${tag_ver}"
      return 0
    else
      echo "buildx 操作失敗，第 $((RETRY_COUNT+1)) 次重試..."
      RETRY_COUNT=$((RETRY_COUNT+1))

      if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "等待 $DELAY 秒後重試..."
        sleep $DELAY
      else
        echo "已達到最大重試次數，操作失敗。"
		
		# 遇到錯誤，先存起來後續處理
		echo "docker buildx imagetools create --tag ${dest}/${repo_name}:${tag_ver} ${src}/${repo_name}:${tag_ver}" >> err.txt
        return 1
      fi
    fi
  done
}

listImage(){
    images=$( curl --user $src_username:$src_password -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" --location "${src_url}v2/_catalog" |jq -r '.repositories[]' )

    #echo $images
    for image  in $images
    do
        echo $image
        #echo "${src_url}v2/${image}/tags/list"
        
	if grep -q "$image" success.txt; then
		echo "skip $image"
		continue
	fi

    
        tags=$(curl --user $src_username:$src_password -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" --location "${src_url}v2/${image}/tags/list" |jq -r '.tags[]' )

       
        for tag in $tags
        do
		multiArchImage ${src_host} ${image} ${tag} ${dest_host}
        done

	# 處理完，放進清單，重跑時可以少跑
	echo "$image" >> success.txt
    done

}

main(){

  # 使用正則表達式解析出 username、password 與 URL
  src_username=$(echo $src | sed -n 's|http://\([^:]*\):.*@\([^/]*\)/|\1|p')
  src_password=$(echo $src | sed -n 's|http://[^:]*:\([^@]*\)@[^/]*.*|\1|p')
  #src_password=$(echo $url | sed -n 's|http://[^:]*:\([^@]*\)@[^/]*|\1|p')
  src_url=$(echo $src | sed -n 's|http://[^@]*@\(.*\)/|\1|p' | sed 's|.*|http://&/|')
  #| sed -n 's|http://[^@]*@\(.*\)|http://\1|p')
  src_host=$(echo $src_url | sed 's|http://||' | sed 's|/||')

  dest_username=$(echo $dest | sed -n 's|http://\([^:]*\):.*@\([^/]*\)/|\1|p')
  dest_password=$(echo $dest | sed -n 's|http://[^:]*:\([^@]*\)@[^/]*.*|\1|p')
  dest_url=$(echo $dest | sed -n 's|http://[^@]*@\(.*\)/|\1|p' | sed 's|.*|http://&/|')
  #| sed -n 's|http://[^@]*@\(.*\)|http://\1|p')
  dest_host=$(echo $dest_url | sed 's|http://||' | sed 's|/||')


  echo "src_Username: $src_username"
  echo "src_Password: $src_password"
  echo "src_URL: $src_url"
  echo "src_HOST: $src_host"

  echo "dest_Username: $dest_username"
  echo "dest_Password: $dest_password"
  echo "dest_HOST: $dest_host"

  listImage
}

main