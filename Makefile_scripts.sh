#!/usr/bin/env bash
# parse_yaml file.yml
parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
       -ne "s|^\($s\)\($w\)$s:$s'\(.*\)'$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# dc_get_services_names docker-compose.yml 
dc_get_services_names(){
  SERVICE_ARRAY=$(IFS=$'\n' && 
   (parse_yaml $1 | sed -n 's/services_\([a-z|A-Z]*\)_.*/\1/p') | uniq)
  echo "${SERVICE_ARRAY[*]}"
}

# dc_get_services_names_with_images docker-compose.yml 
# reject if image key value = "${PROJECT_NAME}:${HOST_USER:-nodummy}"
dc_get_services_names_with_images(){
  SERVICE_ARRAY=$(IFS=$'\n' && 
  (parse_yaml docker-compose.yml | 
   sed '/${PROJECT_NAME}:\${HOST_USER:-nodummy}/d' | # reject line with image value = "${PROJECT_NAME}:${HOST_USER:-nodummy}"
   sed -n 's/services_\([a-z|A-Z]*\)_image=.*/\1/p') | uniq)
  echo "${SERVICE_ARRAY[*]}"
}
