#!/bin/bash

# @Author : Joka
# @E-mail : zhaozengjie126@126.com

#
# 获取必应每日的主页图片并且上传到阿里云OSS
# 

# 网站地址
BING_URL="https://bing.com"

FIRST_FILTER_RULE='<link id="bgLink" rel="preload"'

SECOND_FILTER_RULE='BEGIN { FS = "\"|\"" }{ print $6}'

OSS_ACCESS_KEY=''
OSS_SECRET_KEY=''
OSS_BUCKET_NAME=''
OSS_DOMAIN=''

# 准备执行
pre_action() {
	# 判断是否本地文件夹存在，不存在则创建
	if [ -d "./wallpaper" ]; then
		:
	else
		mkdir -p "./wallpaper/backup"
	fi
}

# 执行
pre_action

get_file_name(){
	# 获取传入的参数1(已经拼接的图片链接)
	FULL_URL="$1"

	# 获取传入的参数2（已经拼接的图片链接）
	HALF_URL="$2"

	# 提取图片的名字
	FILE_NAME=$(echo -e "$HALF_URL" | cut -d "&" -f 1 | cut -d "_" -f 1| cut -d "." -f 2)

	# 提取后缀
	TMP_FILE_TYPE=$(echo -e "$HALF_URL"| cut -d "&" -f 1 | cut -d "." -f 3 )

	REAL_URL=${FULL_URL//'1920x1080'/'1280x720'}

	echo $REAL_URL

	FILE_TYPE=".$TMP_FILE_TYPE"
	
	#下载
	curl -sL "$REAL_URL" -o "./wallpaper/backup/$FILE_NAME$FILE_TYPE"

	cp -rf "./wallpaper/backup/$FILE_NAME$FILE_TYPE" "./wallpaper/$FILE_TYPE"
}

get_picture_url(){
	INCOMPLETE_URL=$(

	curl -sL "$BING_URL" | 

	grep "$FIRST_FILTER_RULE" |

	awk "$SECOND_FILTER_RULE")

	# 执行保存
	get_file_name "$BING_URL$INCOMPLETE_URL" "$INCOMPLETE_URL"
}

# 执行主任务
get_picture_url
