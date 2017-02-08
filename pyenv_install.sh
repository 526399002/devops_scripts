#!/bin/bash
# author: pixiu
# create: 2017-10-36 10:36

# VARIALBES_SETTINGS
export PATH="/sbin:/usr/sbin:/bin:/usr/bin"
IS_INSTALL=0
####################################
echo -e "\033[34m 安装依赖包 \033[0m"
yum -y install git gcc make patch zlib-devel gdbm-devel openssl-devel sqlite-devel bzip2-devel readline-devel

sleep 0.5
####################################
echo -e "\033[34m 安装pyenv \033[0m"

which pyenv &> /dev/null
if [ $? == 0 ];then
    curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
    echo 'export PATH="~/.pyenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(pyenv init -)"' >> ~/.bash_profile
    echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile
else
    echo -e "\033[32m 你已安装pyenv \033[0m"
    IS_INSTALL=1
fi

source ~/.bash_profile
sleep 0.5
#####################################
echo -ne "\033[31m 输入安装的python版本号: \033[0m"
read VERSION
(pyenv versions | grep "${VERSION}$") &> /dev/null && \
  echo -e "\033[31m 该版本已存在 \033[0m" || \
  pyenv install $VERSION && \
  echo -e "\033[33m pyenv已安装 \033[0m"

if [ "$IS_INSTALL" == "0" ];then
  echo -e "\033[33m 请执行以下命令生效环境变量: \033[0m"
  echo -e "\033[31m source ~/.bash_profile \033[0m"
fi
