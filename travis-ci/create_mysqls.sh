#!/bin/bash

for N in 1 2 3
do docker run -d --name=mysqlorchdb$N --net orchnet \
  -v $PWD/dbOrch$N:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mypass \
  mysql/mysql-server:5.7 \
  --server-id=100 \
  --enforce-gtid-consistency='ON' \
  --log-slave-updates='ON' \
  --gtid-mode='ON' \
  --log-bin='mysql-bin-1.log'
done
