#!/usr/bin/env bash
#
export PATH="/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin:/usr/local/sbin"
BaseDir=/data/projects/send/
FirstFile=${BaseDir}/FirstFile
DiffFile=${BaseDir}/DiffFile
TempFile=${BaseDir}/TempFile
TempA=${BaseDir}/A
TempB=${BaseDir}/B

# 首先切换至base目录
cd $BaseDir

if [ ! -e $1 ];then
    echo "Today File is not create!"
    exit 4
fi
# 将日志内容保存至一个文件，以便下次进行比对
Firstcopy() {
    /bin/cp -f $1 $FirstFile
    if [ $? == 0 ];then
       return 10
    else
       return 20
    fi
}

# 检索条件
Search() {
#    sed -n '/邮件发送失败/p' $1 >> $TempFile
    egrep -i -A 4 -B 2 "请求异常| ERROR |失败" $1 >> $TempFile
}

# 通过上一次的文件和日志进行比对，比对结果用
# 来检索，输出检索信息
Diffcopy() {
    head -100 $FirstFile > $TempA
    head -100 $1 > $TempB
# 判断文件是否被切割
    if [[ -n $(diff $TempA $TempB | head -1 | grep "c") ]];then
        diff ${1}.$(date -d '-1 day' +%Y-%m-%d) $FirstFile > $DiffFile
	Search $DiffFile
        Search $1 
        rm $FirstFile
        rm $TempA
        rm $TempB
    else
        diff $1 $FirstFile > $DiffFile
	Firstcopy $1
	if [ $? == 10 ];then
	    return 30
	else
	    return 40
	fi
    fi
}

# 判断是否未添加参数，未添加则抛出异常
if [ $# -lt 1 ];then
    echo "Must have Argument"
    exit 2
fi


# 判断是否是每天的第一次执行
if [ ! -s $FirstFile ];then
    Firstcopy $1
    [ $? == 10 ] && Search $FirstFile
else
    Diffcopy $1
    [ $? == 30 ] && Search $DiffFile
fi

# 判断是否检索到报错信息
if [ $(du -sh $TempFile | cut -f1) == 0 ];then
    echo "Today have no wrong from edmlog"   
else
    /bin/cat $TempFile
fi

rm $TempFile
