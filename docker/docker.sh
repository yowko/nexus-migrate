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

# 從來源 registry pull image
pullImages(){
  local src_org=${1}
  local src_repo=${2}
  local repo_tag=${3}

  echo "Pulling ${src_repo}:${repo_tag} from source ${src_org} organization"
  docker pull "${src_org}"/"${src_repo}":"${repo_tag}" > /dev/null
  echo "Pull ${src_repo}:${repo_tag} successful" 
}

# 將 pull 下來的 image tag 為目標 registry 的 image
tagImages(){
  local src=${1}
  local repo_name=${2}
  local tag_ver=${3}
  local dest=${4}  

  echo "Tagging the repository from ${src}/${repo_name}:${tag_ver} to ${dest}/${repo_name}:${tag_ver}"
  docker tag "${src}"/"${repo_name}":"${tag_ver}" "${dest}"/"${repo_name}":"${tag_ver}" > /dev/null
  echo "Tagging to ${dest}/${repo_name}:${tag_ver} successful"
}

# 將 image push 至目標 registry
pushImages(){
  local dest=${1}
  local repo_name=${2}
  local tag_ver=${3}

  echo "Pushing to ${dest}  organization the ${repo_name}:${tag_ver}  repository"
  docker push "${dest}"/"${repo_name}":"${tag_ver}" > /dev/null
  echo "Push successful for ${dest}/${repo_name}:${tag_ver}"
}

listImages(){
    # 取得所 registry 的 image
    images=$( curl --user $src_username:$src_password -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" --location "${src_url}v2/_catalog" |jq -r '.repositories[]' )

    for image  in $images
    do
        echo $image
        # 取得 image 的所有 tag
        tags=$(curl --user $src_username:$src_password -s -H "Accept: application/vnd.docker.distribution.manifest.v2+json" --location "${src_url}v2/${image}/tags/list" |jq -r '.tags[]' )
        for tag in $tags
        do
            pullImages ${src_host} ${image} ${tag}
            tagImages ${src_host} ${image} ${tag} ${dest_host}
            pushImages ${dest_host} ${image} ${tag}
        done
    done

}

main(){

# 使用正則表達式解析出 username、password 與 URL
src_username=$(echo $src | sed -n 's|http://\([^:]*\):.*@\([^/]*\)/|\1|p')
src_password=$(echo $src | sed -n 's|http://[^:]*:\([^@]*\)@[^/]*.*|\1|p')
src_url=$(echo $src | sed -n 's|http://[^@]*@\(.*\)/|\1|p' | sed 's|.*|http://&/|')
src_host=$(echo $src_url | sed 's|http://||' | sed 's|/||')

dest_username=$(echo $dest | sed -n 's|http://\([^:]*\):.*@\([^/]*\)/|\1|p')
dest_password=$(echo $dest | sed -n 's|http://[^:]*:\([^@]*\)@[^/]*.*|\1|p')
dest_url=$(echo $dest | sed -n 's|http://[^@]*@\(.*\)/|\1|p' | sed 's|.*|http://&/|')
dest_host=$(echo $dest_url | sed 's|http://||' | sed 's|/||')


echo "src_Username: $src_username"
echo "src_Password: $src_password"
echo "src_URL: $src_url"
echo "src_HOST: $src_host"

echo "dest_Username: $dest_username"
echo "dest_Password: $dest_password"
echo "dest_HOST: $dest_host"

listImages
}

main