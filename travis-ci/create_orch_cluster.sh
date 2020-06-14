#!/bin/bash

for N in 1 2 3
do docker run -d --name orchestrator$N --net orchnet -p "300$N":3000 \
  -e MYSQL_HOST=mysqlorchdb$N -e MYSQL_PORT=3306 \
  -e BIND=orchestrator$N -e PORT=3000 \
  -e RAFT_NODES='"orchestrator1","orchestrator2","orchestrator3"' \
  wagnerfranchin/orchestrator-raft-mysql:$TAG
done
