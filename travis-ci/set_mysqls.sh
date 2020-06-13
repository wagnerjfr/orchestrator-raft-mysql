#!/bin/bash

for N in 1 2 3
do docker exec -t mysqlorchdb$N mysql -uroot -pmypass \
 -e "CREATE DATABASE IF NOT EXISTS orchestrator;" \
 -e "CREATE USER 'orc_server_user' IDENTIFIED BY 'orc_server_password';" \
 -e "GRANT ALL PRIVILEGES ON orchestrator.* TO 'orc_server_user';"
done
