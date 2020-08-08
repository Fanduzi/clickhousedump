#!/bin/bash
# File Name   : clickhousedump.sh
# Author      : Fan()
# Created Time: 2020-07-29 09:54:42

Usage() {
  echo
  echo version 0.1
  echo
  echo "Usage: $scriptName [{选项, 不要写等号(--x=y)}]  [{参数}] ..."
  echo "  -h,--host                            ip地址[default: 127.0.0.1]."
  echo "  -P,--port                            端口[default: 9000]"
  echo "  -u,--user                            用户名[default: default]"
  echo "  -p,--password                        密码[default: '']"
  echo "  --ask-password                       交互式输入密码, 优先级高于--password."
  echo "  -t, --tables                         指定要备份的表, 必须包含库名, 可以指定多个表以逗号分隔. e.g. db1.table1,db2.table2. 此选项优先级最高."
  echo "  -A, --all                            备份所有库表[default: false]."
  echo "  --databases                          备份指定数据库的所有表(可以指定多个数据库以逗号分隔)."
  echo "  --databases-exclude                  备份除指定数据库外的所有表, 请注意，此选项的优先级高于--databases(可以指定多个数据库以逗号分隔)."
  echo "  -f,--format                          导出数据格式, 对于clickhouse-client --format参数[default: Native]. 数据格式详情请查看https://clickhouse.tech/docs/en/interfaces/formats/"
  echo "  -o, --output-dir                     备份文件存储目录[default ./`date +%Y-%m-%d`]."
  echo "  --compress                           是否使用gzip压缩[default: false]."
  echo "  --only-distributed                   只备份分布式表[default: false]."
  echo "  --only-non-distributed               不备份分布式表[default: false]."
  echo "  --log                                日志文件, 如果指定了--output-dir则默认在此目录下[default: ./`date +%Y-%m-%d`.log]"
  echo "  --help                               打印帮助信息"
  echo ""
  [[ "x$1" != "x" ]] && echo "$1"
  exit 1
}

host=127.0.0.1
port=9000
user=default
password=''
format=''
compress=false
ask_password=false
tables=''
all=false
databases=''
databases_exclude=''
log=./`date +%Y-%m-%d`.log
output_dir=''
only_distributed=false
only_non_distributed=false

argLen=$#
i=1
[[ $argLen -eq 0 ]] && Usage
while [[ $i -le $argLen ]]
do
  j=$1
  if [[ "$j" == "-h" ]] || [[ "$j" == "--host" ]]
  then
    host=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "-P" ]] || [[ "$j" == "--port" ]]
  then
    port=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "-u" ]] || [[ "$j" == "--user" ]]
  then
    user=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "-p" ]] || [[ "$j" == "--password" ]]
  then
    password=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "-t" ]] || [[ "$j" == "--tables" ]]
  then
    tables=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "-A" ]] || [[ "$j" == "--all" ]]
  then
    all=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "-f" ]] || [[ "$j" == "--format" ]]
  then
    format=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "-o" ]] || [[ "$j" == "--output-dir" ]]
  then
    output_dir=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "--databases" ]]
  then
    databases=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "--databases-exclude" ]]
  then
    databases_exclude=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "--log" ]]
  then
    log_file=$2
    shift 1
    let i++
  fi
  if [[ "$j" == "--ask-password" ]]
  then
    ask_password=true
    #let i++
  fi
  if [[ "$j" == "--compress" ]]
  then
    compress=true
    #let i++
  fi
  if [[ "$j" == "--only-distributed" ]]
  then
    only_distributed=true
    #let i++
  fi
  if [[ "$j" == "--only-non-distributed" ]]
  then
    only_non_distributed=true
    #let i++
  fi
  if [[ "$j" == "--help"  ]]; then
    Usage
  fi
  let i++
  shift 1
done

[[ "x${only_distributed}" == "xtrue" ]] && [[ "x${only_non_distributed}" == "xtrue" ]] && Usage "[ERROR]: 不能同时指定--only-distributed和--only-non-distributed参数"

[[ "${all}x" != "truex" ]] && [[ "x$databases_exclude" == "x" ]] && [[ "x$databases" == "x" ]] && [[ "x$tables" == "x" ]] && all=true

if [[ "${ask_password}x" == "truex" ]]; then
    read -s -p "Password for user ($user): " password
    echo
fi

_prefix="select concat(database,'.',name) table from system.tables where "



if [[ "${all}x" == "truex" ]]; then
    _sql=" 1=1 "
fi
sql_get_tables=${_prefix}${_sql}

if [[ "x$databases_exclude" != "x" ]]; then
     _sql=" 1=1 and not ("
    for i in $(echo ${databases_exclude} | sed "s/,/ /g")
    do
        db_tmp=$i
        _sql=${_sql}"(database='"${db_tmp}"'"") or "
    done
    sql_get_tables=${_prefix}${_sql%or*}")"
fi


if [[ "x$databases" != "x" ]]; then
     _sql=" 1=1 and ("
    for i in $(echo ${databases} | sed "s/,/ /g")
    do
        db_tmp=$i
        _sql=${_sql}"(database='"${db_tmp}"'"") or "
    done
    sql_get_tables=${_prefix}${_sql%or*}")"
fi


if [[ "x$tables" != "x" ]]; then
    _sql=" 1=1 and ("
    for i in $(echo ${tables} | sed "s/,/ /g")
    do
        db_tmp=`echo $i|awk -F'.' '{print $1}'`
        table_tmp=`echo $i|awk -F'.' '{print $2}'`
        _sql=${_sql}"(database='"${db_tmp}"'"" and name='"${table_tmp}"') or "
    done
    sql_get_tables=${_prefix}${_sql%or*}")"
fi

if [[ "${only_distributed}x" == "truex" ]]; then
    sql_get_tables=${sql_get_tables}" and engine='Distributed' "
elif [[ "${only_non_distributed}x" == "truex" ]]; then
    sql_get_tables=${sql_get_tables}" and engine!='Distributed' "
fi


function f_logging()
{
    #日志函数, 接收四个参数, 第一个表示日志级别, 第二个表示日志内容, 第三个表示是否需要回车(0|1|2,0表示不需要回车,1表示需要一个回车),2表示需要两个回车)
    #usage:f_logging "INFO|WARNERROR|COMMAND" "This is a log" "-n|NULL" "0|NULL"
    log_mode="${1}"
    log_info="${2}"
    log_enter="${3}"
    enter_opt=""        #表示回车的动作
    if [ "${log_mode}x" == "WARNx" ]
    then
        #WARN级别是黄色显示
        echo -e "\033[33m"
    elif [ "${log_mode}x" == "ERRORx" ]
    then
        #ERROR级别是红色显示
        echo -e "\033[31m"
    elif [ "${log_mode}x" == "COMMANDx" ]
    then
        #COMMAND级别是蓝色显示
        echo -en "\033[34m"
    else
        #INFO级别是绿色显示
        echo -en "\033[32m"
    fi
    if [ "${log_enter}x" == "0x" ]
    then
        log_enter="-n"
    elif [ "${log_enter}x" == "2x" ]
    then
        log_enter="-e"
        enter_opt="\n"
    else
        #相当于值是1,即这是默认值
        log_enter="-e"
    fi
    echo ${log_enter} "[$(date "+%F %H:%M:%S")] [${log_mode}] [${localhost_ip}] ${log_info}${enter_opt}"
    echo -en "\033[0m"
}

if [[ "x$output_dir" != "x" ]]; then
    [[ ! -d "${output_dir}" ]] && mkdir -p ${output_dir}
    log=${output_dir}/`date +%Y-%m-%d`.log
else
    output_dir=./
fi

f_logging "INFO" "==========================参数==========================" |tee -a ${log}
f_logging "INFO" "--host:                  ${host}" |tee -a ${log}
f_logging "INFO" "--port:                  ${port}" |tee -a ${log}
f_logging "INFO" "--user:                  ${user}" |tee -a ${log}
f_logging "INFO" "--ask-password:          ${ask_password}" |tee -a ${log}
f_logging "INFO" "--log:                   ${log}" |tee -a ${log}
f_logging "INFO" "--tables:                ${tables}" |tee -a ${log}
f_logging "INFO" "--databases-exclude:     ${databases_exclude}" |tee -a ${log}
f_logging "INFO" "--databases:             ${databases}" |tee -a ${log}
f_logging "INFO" "--all:                   ${all}" |tee -a ${log}
f_logging "INFO" "--format:                ${format}" |tee -a ${log}
f_logging "INFO" "--compress:              ${compress}" |tee -a ${log}
f_logging "INFO" "--output-dir:            ${output_dir}" |tee -a ${log}
f_logging "INFO" "--only-distributed:      ${only_distributed}" |tee -a ${log}
f_logging "INFO" "--only-non-distributed:  ${only_non_distributed}" |tee -a ${log}

f_logging "INFO" "========================备份列表========================" |tee -a ${log}
f_logging "INFO" "${sql_get_tables}" | tee -a ${log}
clickhouse-client -u ${user} --password ${password} --port ${port} -h ${host} --query="${sql_get_tables}" >> ${log}

f_logging "INFO" "========================开始备份========================" |tee -a ${log}
res=`clickhouse-client -u ${user} --password ${password} --port ${port} -h ${host} --query="${sql_get_tables}"|while read a;do echo "$a:";done`
failed_table=''
for i in $res
do
    _table=`echo $i |cut -d: -f 1`
    f_logging "INFO" "开始备份 ${_table}" |tee -a ${log}
    if [[ "${compress}x" != "truex" ]]; then
        clickhouse-client -u ${user} --password ${password} --port ${port} -h ${host} --query="select * from ${_table}" --format=${format} > ${output_dir}/${_table}.${format}
    else
        clickhouse-client -u ${user} --password ${password} --port ${port} -h ${host} --query="select * from ${_table}" --format=${format} | gzip > ${output_dir}/${_table}.${format}.gz
    fi
    if [ $? -ne 0 ]
    then
        f_logging "ERROR" "备份失败 ${_table}" "2" |tee -a ${log_file}
#        exit 1
        failed_table=${failed_table}"${_table} "
        backup_failed=true
    else
        f_logging "INFO" "备份成功 ${_table}" |tee -a ${log_file}
    fi
done
f_logging "INFO" "========================备份结束========================" |tee -a ${log}

# 修改你的企业微信机器人🤖key
# if [[ "${backup_failed}x" == "truex" ]]; then
#     curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=你的key' -H 'Content-Type: application/json'  -d "{\"msgtype\": \"text\",\"text\": {\"content\": \"${failed_table}逻辑备份失败\"}}"
# else
#     curl 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=你的key' -H 'Content-Type: application/json'  -d "{\"msgtype\": \"text\",\"text\": {\"content\": \"`date +%Y-%m-%d`逻辑备份成功, 备份大小: `du -sh ${output_dir}|awk '{print $1}'`\"}}"
# fi

zst_ps1()
{
  Date=$(date +%F)
  Time=$(date +%H:%M:%S)
  PS1="\\n\[\e[1;37m[\e[m\]\[\e[1;33m\u\e[m\]\[\e[1;33m@\h\e[m\]\[\e[1;35m $Time \e[m\]\e[1;36m\w\e[m\e[1;37m]\e[m\n\\$"
}
PROMPT_COMMAND=zst_ps1


#gunzip < ${output_dir}/${_table}.${format}.gz | clickhouse-client -u ${user} --password ${password} --port ${port} -h ${host} --query="INSERT INTO ${_table} FORMAT ${format}"
#
#clickhouse-client -u ${user} --password ${password} --port ${port} -h ${host} --query="INSERT INTO ${_table} FORMAT ${format}" < ${output_dir}/${_table}.${format}.gz
