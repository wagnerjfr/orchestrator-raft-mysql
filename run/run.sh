#! /bin/bash

sed -e " s/%MySQLOrchestratorHost%/${MYSQL_HOST}/;  s/%MySQLOrchestratorPort%/${MYSQL_PORT}/; s/%RaftEnabled%/${RAFT}/; s/%ListenAddress%/${PORT}/; s/%RaftBind%/${BIND}/; s/%RaftNodes%/${RAFT_NODES}/" orchestrator-template.conf.json > orchestrator.conf.json

cat orchestrator.conf.json

./orchestrator http
