# clickhousedump
Pure shell clickhouse logic backup script

帮助信息
```
# sh clickhousedump.sh --help

version 0.1

Usage:  [{选项, 不要写等号(--x=y)}]  [{参数}] ...
  -h,--host                            ip地址[default: 127.0.0.1].
  -P,--port                            端口[default: 9000]
  -u,--user                            用户名[default: default]
  -p,--password                        密码[default: '']
  --ask-password                       交互式输入密码, 优先级高于--password.
  -t, --tables                         指定要备份的表, 必须包含库名, 可以指定多个表以逗号分隔. e.g. db1.table1,db2.table2. 此选项优先级最高.
  -A, --all                            备份所有库表[default: false].
  --databases                          备份指定数据库的所有表(可以指定多个数据库以逗号分隔).
  --databases-exclude                  备份除指定数据库外的所有表, 请注意，此选项的优先级高于--databases(可以指定多个数据库以逗号分隔).
  -f,--format                          导出数据格式, 对于clickhouse-client --format参数[default: Native]. 数据格式详情请查看https://clickhouse.tech/docs/en/interfaces/formats/
  -o, --output-dir                     备份文件存储目录[default ./2020-08-08].
  --compress                           是否使用gzip压缩[default: false].
  --only-distributed                   只备份分布式表[default: false].
  --only-non-distributed               不备份分布式表[default: false].
  --log                                日志文件, 如果指定了--output-dir则默认在此目录下[default: ./2020-08-08.log]
  --help                               打印帮助信息
```

使用
```
sh /usr/local/shell/clickhouse/clickhousedump.sh -u default -p 你的密码 -h 127.0.0.1 --databases-exclude datasets,default,system,testdb --only-distributed --format Native --compress --output-dir /data/backup/clickhouse/logical_backup/`date +%Y-%m-%d`/
```

