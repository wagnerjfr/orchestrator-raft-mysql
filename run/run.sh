#! /bin/bash

sed -e " s/%MySQLOrchestratorHost%/${MYSQL_HOST}/;  s/%MySQLOrchestratorPort%/${MYSQL_PORT}/; s/%RaftEnabled%/${RAFT}/; s/%ListenAddress%/${PORT}/; s/%RaftBind%/${BIND}/; s/%RaftNode1%/${NODE1}/; s/%RaftNode2%/${NODE2}/; s/%RaftNode3%/${NODE3}/" orchestrator-template.conf.json > orchestrator.conf.json

cat orchestrator.conf.json

./orchestrator http
