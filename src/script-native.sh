#!/bin/bash

echo "Emby-css安装中...
1.先检查插件
2.再修改首页html"

local_base="/opt/emby-server/system/dashboard-ui"

# 新增目录存在性检查
if [[ ! -d "${local_base}" ]]; then
    echo "错误：${local_base} 目录不存在，请检查Emby安装！"
    exit 1
fi

local_plugins="${local_base}/config/plugins"
local_modules="${local_base}/modules"

# 检查并创建子目录（原主目录已存在）
mkdir -p "${local_plugins}" "${local_modules}" "${local_base}/bak"

# 使用本地路径检查插件文件
if [[ -f "${local_plugins}/Emby.CustomCssJS.dll" ]]; then  
    echo "插件已安装过，无需重复安装！"  
else  
    # 安装插件
    wget -q --no-check-certificate https://raw.githubusercontent.com/Shurelol/Emby.CustomCssJS/main/src/Emby.CustomCssJS.dll -O Emby.CustomCssJS.dll
    cp ./Emby.CustomCssJS.dll "${local_plugins}/"
    chmod 755 "${local_plugins}/Emby.CustomCssJS.dll"
    echo "插件首次安装！"  
fi

# 下载并复制JS文件到本地模块目录
wget -q --no-check-certificate https://raw.githubusercontent.com/Shurelol/Emby.CustomCssJS/main/src/CustomCssJS.js -O CustomCssJS.js  
cp ./CustomCssJS.js "${local_modules}/"

# 主安装程序
function Installing() {  
    # 读取文件内容    
    content=$(cat app.js)    
    # 定义要插入的代码，注意去掉逗号    
    code1='list.push("./modules/CustomCssJS.js")'    
    code2='Promise.all(list.map(loadPlugin))'      
    # 在Promise.all(list.map(loadPlugin))之前插入代码    
    new_content=$(echo -e "${content//$code2/$code1,$code2}")  
    # 将新内容写入app.js文件    
    echo -e "$new_content" > app.js
    # 删除换行符（根据原脚本逻辑保留，但需注意可能影响代码格式）
    no_newline_content=$(echo "$new_content" | tr -d '\n')  
    echo -e "$no_newline_content" > app.js
    # 覆盖本地app.js文件
    cp ./app.js "${local_base}/"
}

# 操作本地app.js文件
local_appjs="${local_base}/app.js"
if [[ ! -f "${local_appjs}" ]]; then
    echo "错误：未找到 ${local_appjs}！"
    exit 1
fi

# 备份原始文件
cp "${local_appjs}" "${local_base}/bak/app.js.bak"

# 检查是否已修改过
count=$(grep -c "CustomCssJS.js" "${local_appjs}")
if [ "$count" -eq 0 ]; then
    cp "${local_appjs}" ./
    Installing
    echo "成功！app.js 首次安装！"
else
    cp "${local_base}/bak/app.js.bak" ./app.js
    Installing
    echo "成功！app.js 已重新修改！"
fi 

echo "所有操作已完成！请重启Emby服务使更改生效。"
