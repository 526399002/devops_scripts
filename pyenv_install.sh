#!/bin/bash
# author: pixiu
# create: 2017-10-36 10:36

# 判断系统发行版
RELEASE=$(cat /etc/*-release | egrep -o "(Debian|Ubuntu|CentOS)" | uniq)

# 是否安装pyenv
IS_INSTALL=False
PATH_FILE=""

# 根据系统发行版指定环境变量文件
if [ "$RELEASE" == "Debian" -o "$RELEASE" == "Ubuntu" ];then
    PATH_FILE=~/.bashrc
elif [ "$RELEASE" == "CentOS" ];then
    PATH_FILE=~/.bash_profile
fi 

# 读取环境变量
source $PATH_FILE

trap 'echo -e "\033[31m 终止退出 \033[0m";exit 40' SIGINT
##################函数定义###################
install_depend () {
    echo -e "\033[34m 安装依赖包 \033[0m"

    if [ $(id -u) != 0 ];then
        which sudo || echo "\033[31m当前非root用户，且没有sudo命令\033[0m"
        exit 43
    fi
    
    case $RELEASE in
    Debian|Ubuntu)
        sudo apt-get install -y gcc make lrzsz readline.dev zlib1g.dev curl libssl-dev libsqlite3-dev libreadline-dev libbz2-dev
        if [ "$?" != "0" ];then
            echo -e "\033[31m 无法正常安装，请检查你的apt源 \033[0m"
            exit 4
        fi
        ;;
    CentOS) 
        sudo yum -y install git gcc make patch zlib-devel gdbm-devel openssl-devel sqlite-devel bzip2-devel readline-devel lrzsz
        if [ "$?" != "0" ];then
            echo -e "\033[31m 无法正常安装，请检查你的yum源 \033[0m"
            exit 4
        fi
        ;;
    *)
        echo "仅支持Ubuntu系和CenOS"
        exit 5
        ;;
    esac

    sleep 0.5
}

pyenv_download() {
    local TEMP_FILE="/tmp/foo.log"

    echo -e "\033[34m 安装pyenv \033[0m"

    if [ -d ~/.pyenv ];then
        echo -e "\033[32m你已安装pyenv \033[0m" 
        which pyenv &> /dev/null && IS_INSTALL=True
    else
        curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash > $TEMP_FILE
        grep "couldn't connect" $TEMP_FILE && git clone https://github.com/yyuu/pyenv.git ~/.pyenv

        if [ ! -d ~/.pyenv ];then
            echo -e "\033[31m 安装pyenv失败,请检查网络是否正常 \033[0m"
            exit 31
        fi

        grep pyenv $PATH_FILE || (
        echo 'export PATH="~/.pyenv/bin:$PATH"' >> $PATH_FILE
        echo 'eval "$(pyenv init -)"' >> $PATH_FILE
        echo 'eval "$(pyenv virtualenv-init -)"' >> $PATH_FILE
        )
        source $PATH_FILE
        rm -rf $TEMP_FILE
    fi

    [ -d ~/.pyenv/cache ] || mkdir ~/.pyenv/cache
    sleep 0.5
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
        if [[ $UPLOAD_FILE =~ Python-([0-9]+\.){3}tar\.xz ]];then
            pyenv install $VERSION
        else
            rm -rf $UPLOAD_FILE
            echo -e "\033[31m 上传的Python文件不对, 格式如下: \033[0m"
            echo -e "\033[31m Python-3.5.2.tar.xz \033[0m"
        fi
    else
        echo -e "\033[31m 上传文件异常 \033[0m"
        exit 39
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
############### 安装依赖包 #####################

install_depend

############### 安装pyenv ####################

pyenv_download

################ 安装python #####################
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
    echo -e "\033[31m source $PATH_FILE \033[0m"
fi
