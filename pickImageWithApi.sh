#!/bin/bash

# @Author : Joka
# @E-mail : zhaozengjie126@126.com

#
# 获取必应每日的主页图片并且上传到阿里云OSS
# -p oss-ucket: 调用本地ossutils 上送文件到oss
# -s : 保留本地内容，在上送完成之后不删除掉本地图片
# -n 1: 获取x 天内 (1 表示今天) 所有的图片信息
# 

# 网站地址
BING_URL="https://bing.com"

# 操作系统类型，0-Linux，1-Mac
OS_TYPE='Linux'
JS_PARSE='jq-linux64'
# 上送文件到oss
PUSH_OSS=false
# 上送文件到oss后删除本地文件，
DELETE_LOCA_FILE=false
# 默认下载1天前的所有图片信息
DOWNLOAD_DAY_BEFORE=1
# 指定上送的Oss地址,类似地址oss://bucket//xxx
OSS_URL=""

echo "入参：$*"

# 检查入参

while getopts "p:shn:" opt ;
do
	case $opt in 
	h)
		echo "usage: $0 [-h | -p bucket | -s ] "
		exit 0
		;;
	p)
		echo "启用了阿里云OSS配置，将在文件下载完成之后上传到阿里云OSS，请确定本地有ossUtil,并且已经配置了对应的配置，详情请参考ossutil config"
		PUSH_OSS=true
		OSS_URL=$OPTARG
		;;
	s)
		echo "启用删除本地文件选项"
		DELETE_LOCA_FILE=true
		;;
	n)
		echo "修改下载天数：$OPTARG"
		DOWNLOAD_DAY_BEFORE=$OPTARG
		;;
	"?")
        echo "Error option ,Please use $0 -h"
        exit 1
        ;;
	":")
		exit 1
		;;
	esac
done

if [[ ! PUSH_OSS && DELETE_LOCA_FILE ]]; then
	echo "未启用上送阿里云OSS，将不删除本地文件"
	DELETE_LOCA_FILE=false
fi


# 检查操作系统类型
function check_os(){
	if [ "$(uname)"=="Darwin" ]; then
		OS_TYPE="Mac"
	fi
}

# 准备动作，包括文件是否有权限执行以及创建对应目录
function pre_action() {
	# 判断是否本地文件夹存在，不存在则创建
	if [ -d "./wallpaper" ]; then
		:
	else
		mkdir -p "./wallpaper/backup"
	fi

	check_os

	echo "当前操作系统类型为：$OS_TYPE"
	case $OS_TYPE in 
		'Linux')
			if [ ! -x "./lib/jq-linux64" ]; then
				echo "请执行以下命令：chmod +x ./lib/jq-linux64"
				exit 1;
			fi
			;;
		'Mac')
			JS_PARSE='jq-osx-amd64'
			if [ ! -x "./lib/jq-osx-amd64" ]; then
				echo "请执行以下命令：chmod +x ./lib/jq-osx-amd64"
				exit 1;
			fi
			;;
		*)
			;;
	esac
}


# 执行检查方法
pre_action

API_URL="https://bing.com/HPImageArchive.aspx?format=js&idx=0&n=$DOWNLOAD_DAY_BEFORE"

# 调用API请求并且获取到返回报文
RESULT=$(curl -sL $API_URL)
DATA_ARR=()

# 对请求返回的内容进行json解析，返回遍历的图片链接
#for line in $(echo $RESULT | ./lib/$JS_PARSE -r '.images[].url')
for (( i=0; i <= $(($(echo $RESULT | ./lib/$JS_PARSE '.images|length' )-1 )); i++ ))
do
	JS_PARES_URL=$(eval echo ".images[$i].url")
	line=$(echo $RESULT | ./lib/$JS_PARSE -r $JS_PARES_URL )

	# 这下面这行可以注释。默认返回的图片大小为1920*1080，但是我不需要这么大，所以我替换成了1280*720大小，如果实际使用的时候需要高清，可以注释下面的内容
	REAL_URL=$BING_URL${line//'1920x1080'/'1280x720'}

	echo "解析输出结果，即将保存图片，请求链接为：$REAL_URL"

	# 提取姓名
	JS_PARES_END=$(eval echo ".images[$i].enddate")
	FILE_NAME=$(echo $RESULT | ./lib/$JS_PARSE -r $JS_PARES_END )

	echo "文件名字为：$FILE_NAME"

	# 提取后缀
	TMP_FILE_TYPE=$(echo -e "$line"| cut -d "&" -f 1 | cut -d "." -f 3 )

	FILE_TYPE=".$TMP_FILE_TYPE"
	
	echo "文件后缀：$FILE_TYPE"

	SAVE_LOCATION="./wallpaper/backup/$FILE_NAME$FILE_TYPE"

	# 下载
	curl -L "$REAL_URL" -o $SAVE_LOCATION

	# 移动文件到文件目录
	mv -f "./wallpaper/backup/$FILE_NAME$FILE_TYPE" "./wallpaper/$FILE_NAME$FILE_TYPE"

	echo "本地保存位置：$PWD/wallpaper/$FILE_NAME$FILE_TYPE"

	DATA_ARR+="$FILE_NAME$FILE_TYPE"
done

# 上传到OSS
function UPLOAD(){
	if [ $PUSH_OSS == true ]; then
		UPLOAD_BASE_DIR="./wallpaper"
		for fileName in "${DATA_ARR[*]}"; do
			echo "即将上传：$fileName"
			ossutil -c /Users/joka/Tools/ossutil/.ossutilconfig cp "$PWD/wallpaper/$fileName" "$OSS_URL/$fileName" -u 
			if [ $DELETE_LOCA_FILE == true ]; then
				echo "删除本地文件：$fileName"
				rm -f "$PWD/wallpaper/$fileName"
			fi
		done
	fi
}

UPLOAD
