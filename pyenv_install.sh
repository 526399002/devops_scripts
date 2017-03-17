#!/bin/bash
# author: pixiu
# create: 2017-10-36 10:36

# VARIALBES_SETTINGS
source ~/.bash_profile
IS_INSTALL=False

trap "echo -e '\033[31m 终止退出 \033[0m;exit 4'" SIGINT
##################函数定义###################
pyenv_download() {
    local TEMP_FILE="foo.log"
    curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash > ./foo.log
    grep "couldn't connect" $TEMP_FILE && git clone https://github.com/yyuu/pyenv.git ~/.pyenv
    rm -rf $TEMP_FILE
    if [ -d ~/.pyenv ];then 
        return 0
    else
        return 4
    fi
} 

download_install() {
    local VERSION
    echo -ne "\033[31m 输入安装的python版本号: \033[0m"
    read $VERSION
    (pyenv versions | grep "${VERSION}$") &> /dev/null && \
      echo -e "\033[31m 该版本已存在 \033[0m" || \
      pyenv install $VERSION && \
      echo -e "\033[33m pyenv已安装 \033[0m"
}

upload_install() {
    local CURRENT_PATH=$(pwd)
    cd ~/.pyenv/cache
    rz
    if [ "$?" == "0" ];then
        local UPLOAD_FILE=$(ls -ct ~/.pyenv/cache | head -1)
        local VERSION=$(echo $UPLOAD_FILE | grep -Po "(?<=(-)).*(?=.ta)")
        echo $VERSION
        if [[ $UPLOAD_FILE =~ Python-([0-9]+\.){3}tar\.xz ]];then
            pyenv install $VERSION
        else
            rm -rf $UPLOAD_FILE
            echo -e "\033[31m 上传的Python文件不对, 格式如下: \033[0m"
            echo -e "\033[31m Python-3.5.2.tar.xz \033[0m"
        fi
    fi
    cd $CURRENT_PATH
}    

install_python_version() {
    echo -e "\033[31m 若使用下载安装python，则直接从官网下载，可能会失败 \033[0m"
    echo -e "\033[31m 若使用上传安装python，需先从官网下载python的xz源码包 \033[0m"
    echo -ne "\033[31m 不安装 | 下载安装 | 上传python安装包 [Down|Upload|No] \033[0m"
    read CHOICE
    
    case $CHOICE in 
    Y|Down|D|down|do)
        download_install
        ;;
    U|Upload|Up|up|upload|u)
        upload_install
        ;;
    N|None|No|n|no)
        ;;
    *)
        ;;
    esac
}
####################################
echo -e "\033[34m 安装依赖包 \033[0m"
yum -y install git gcc make patch zlib-devel gdbm-devel openssl-devel sqlite-devel bzip2-devel readline-devel lrzsz
if [ "$?" != "0" ];then
    echo -e "\033[31m 无法正常安装，请检查你的yum源 \033[0m"
    exit 4
fi

sleep 0.5
####################################
echo -e "\033[34m 安装pyenv \033[0m"

which pyenv &> /dev/null
if [ "$?" == "0" ];then
    echo -e "\033[32m 你已安装pyenv \033[0m"
    IS_INSTALL=True
else
    pyenv_download
    if [ "$?" == "0" ];then
        echo 'export PATH="~/.pyenv/bin:$PATH"' >> ~/.bash_profile
        echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
        echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile
        source ~/.bash_profile
    fi
fi
[ -d ~/.pyenv/cache ] || mkdir ~/.pyenv/cache
sleep 0.5


#####################################
echo -ne "\033[31m 是否安装python: [N|Y] \033[0m"
read INSTALL_PYTHON

case $INSTALL_PYTHON in 
Y|Yes|y|yes)
   install_python_version
   ;;
N|None|No|n|no)
   ;;
*)
   echo ""
esac

#####################################
if [ "$IS_INSTALL" == "False" ];then
    echo -e "\033[33m 请执行以下命令生效环境变量: \033[0m"
    echo -e "\033[31m source ~/.bash_profile \033[0m"
fi
