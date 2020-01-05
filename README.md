# pickImage
通过shell脚本抓取必应的每日壁纸

这里分为两个脚本

- pickImage.sh
- pickImageWithApi.sh


## pickImage.sh
这个脚本是利用解析必应首页获取html里面的链接保存图片的，主要做的是解析和提取工作

## pickImageWithApi.sh
这个脚本是我后来发现了必应有提供Api获取图片的。所以我又重写了一份，通过利用api来获取图片的。并且在这里面我又增加了上送到阿里云OSS对象存储的功能。具体用法可以使用

```
./pickImageWithApi.sh -p oss://bucket/dir -s 
```
