# Orchestrator/Raft (with MySQL backend) using Docker containers.

Set up a orchestrator/raft cluster for high availability.

You will run orchestrator/raft on a 3 node setup using Docker containers.

Each orchestrator will be using its own MySQL database in this setup.

### Reference
https://github.com/github/orchestrator/blob/master/docs/raft.md

### Clone the project and cd into the folder
```
$ git clone https://github.com/wagnerjfr/orchestrator-raft-mysql.git

$ cd orchestrator-raft-mysql
```

### Create a Docker network
```
$ docker network create orchnet
```

### Start 3 MySQL containers
Run the commnd below to start the containers:
```
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
```

It will take some seconds. You can run the command below to follow the initialization:
```
docker ps -a
```

You should wait till all containers are with status **(healthy)**
```console
CONTAINER ID   IMAGE                    COMMAND                  CREATED             STATUS                    PORTS                 NAMES
d00961c2eefe   mysql/mysql-server:5.7   "/entrypoint.sh --se…"   33 seconds ago      Up 30 seconds (healthy)   3306/tcp, 33060/tcp   mysqlorchdb3
343e3cd0698f   mysql/mysql-server:5.7   "/entrypoint.sh --se…"   35 seconds ago      Up 32 seconds (healthy)   3306/tcp, 33060/tcp   mysqlorchdb2
d6fc8f776f26   mysql/mysql-server:5.7   "/entrypoint.sh --se…"   36 seconds ago      Up 34 seconds (healthy)   3306/tcp, 33060/tcp   mysqlorchdb1
```

### Setup backend MySQL Servers

It's time to setup the backend servers.

Run this command to create an orchestrator database, an orchestrator user and grant the privileges to it:
```
for N in 1 2 3
do docker exec -it mysqlorchdb$N mysql -uroot -pmypass \
 -e "CREATE DATABASE IF NOT EXISTS orchestrator;" \
 -e "CREATE USER 'orc_server_user' IDENTIFIED BY 'orc_server_password';" \
 -e "GRANT ALL PRIVILEGES ON orchestrator.* TO 'orc_server_user';"
done
```

### Building the Image
Let's build the orchestrator-raft-mysql Docker image:
```
$ docker build -t orchestrator-raft-mysql:latest .
```
You should see a similar output if everything is ok:
```console
Successfully built 6d31be66c200
Successfully tagged orchestrator-raft-mysql:latest
```
It's also possible to see the new image, executing:
```
$ docker images
```

### Running the containers

The orchestrators will be started using the following configurations:

|  ENV \ CONT   | Orchestrator1 | Orchestrator2 | Orchestrator3 |
| ------------- | ------------- | ------------- | ------------- |
| Docker HOST   | orchestrator1 | orchestrator2 | orchestrator3 |
| PORT          | 3001          | 3002          | 3003          |
| MYSQL_HOST    | mysqlorchdb1  | mysqlorchdb2  | mysqlorchdb3  |
| MYSQL_PORT    | 3306          | 3306          | 3306          |


Run the command below to launch the containers:
```
for N in 1 2 3
do docker run -d --name orchestrator$N --net orchnet -p "300$N":3000 \
  -e MYSQL_HOST=mysqlorchdb$N -e MYSQL_PORT=3306 \
  -e BIND=orchestrator$N -e PORT=3000 \
  -e NODE1=orchestrator1 -e NODE2=orchestrator2 -e NODE3=orchestrator3 \
  orchestrator-raft-mysql:latest
done
```

### Checking the raft status

#### Docker logs
```
$ docker logs orchestrator1
```
```
$ docker logs orchestrator2
```
```
$ docker logs orchestrator3
```

Leader logs (sample):
```console
2019-01-13 22:18:13 DEBUG raft leader is 172.20.0.14:10008 (this host); state: Leader
2019-01-13 22:18:13 DEBUG orchestrator/raft: applying command 4: request-health-report
[martini] Started GET /api/raft-follower-health-report/50c608fc/172.20.0.14/172.20.0.14 for 172.20.0.14:58740
[martini] Completed 200 OK in 1.225369ms
[martini] Started GET /api/raft-follower-health-report/50c608fc/172.20.0.15/172.20.0.15 for 172.20.0.15:58972
[martini] Completed 200 OK in 1.399776ms
[martini] Started GET /api/raft-follower-health-report/50c608fc/172.20.0.16/172.20.0.16 for 172.20.0.16:44740
[martini] Completed 200 OK in 1.500241ms
```

Follower logs (sample):
```console
2019/01/13 22:17:55 [INFO] raft: Node at 172.20.0.15:10008 [Follower] entering Follower state (Leader: "")
2019-01-13 22:17:56 DEBUG Waiting for 15 seconds to pass before running failure detection/recovery
2019/01/13 22:17:56 [DEBUG] raft-net: 172.20.0.15:10008 accepted connection from: 172.20.0.14:47738
2019/01/13 22:17:56 [DEBUG] raft: Node 172.20.0.15:10008 updated peer set (2): [172.20.0.14:10008 172.20.0.15:10008 172.20.0.16:10008]
2019-01-13 22:17:56 DEBUG orchestrator/raft: applying command 2: leader-uri
2019/01/13 22:17:57 [DEBUG] raft-net: 172.20.0.15:10008 accepted connection from: 172.20.0.14:47742
2019-01-13 22:17:57 DEBUG Waiting for 15 seconds to pass before running failure detection/recovery
2019-01-13 22:17:58 DEBUG Waiting for 15 seconds to pass before running failure detection/recovery
2019-01-13 22:17:59 DEBUG Waiting for 15 seconds to pass before running failure detection/recovery
2019-01-13 22:18:00 DEBUG Waiting for 15 seconds to pass before running failure detection/recovery
2019-01-13 22:18:00 DEBUG raft leader is 172.20.0.14:10008; state: Follower
```

#### Web interface (HTTP GET access)
http://localhost:3001

http://localhost:3002

http://localhost:3003

![alt text](https://github.com/wagnerjfr/orchestrator-raft-mysql/blob/master/figure1.png)

### Creating a new MySQL container to be monitored by the cluster

You can find instructions how to start a MySQL container and have it monitored by the cluster in the project [Orchestrator Raft (SQLite) with containers](https://github.com/wagnerjfr/orchestrator-raft-sqlite).

### Fault tolerance scenario

Since Docker allows us to disconnect a container from a network by just running one command, we can disconnect now orchestrator1 (possibly the leader) from the groupnet network by running:
```
$ docker network disconnect orchnet orchestrator1
```
Check the container's logs (or the web interfaces) now. A new leader must be selected and cluster is still up and running.

### [Optional] Running one orchestrator container without raft

First, start its backend MySQL server:
```
$ docker run -d --name=mysqlorchdb --net orchnet \
  -v $PWD/dbOrch:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=mypass \
  mysql/mysql-server:5.7 \
  --server-id=100 \
  --enforce-gtid-consistency='ON' \
  --log-slave-updates='ON' \
  --gtid-mode='ON' \
  --log-bin='mysql-bin-1.log'
```

Then setup the MySQL:
```
$ docker exec -it mysqlorchdb mysql -uroot -pmypass \
 -e "CREATE DATABASE IF NOT EXISTS orchestrator;" \
 -e "CREATE USER 'orc_server_user' IDENTIFIED BY 'orc_server_password';" \
 -e "GRANT ALL PRIVILEGES ON orchestrator.* TO 'orc_server_user';"
```

Finally start the orchestrator container:
```
$ docker run -d --name orchestrator --net orchnet -p 3005:3000 \
  -e MYSQL_HOST=mysqlorchdb -e MYSQL_PORT=3306 \
  -e PORT=3000 -e RAFT=false \
  orchestrator-raft-mysql:latest
```

### Stopping the containers
In another terminal run the command:
```
$ docker stop mysqlorchdb1 mysqlorchdb2 mysqlorchdb3 orchestrator1 orchestrator2 orchestrator3
```

### Removing stopped the containers
```
$ docker rm mysqlorchdb1 mysqlorchdb2 mysqlorchdb3 orchestrator1 orchestrator2 orchestrator3
```

### Removing MySQL data directories
```
$ sudo rm -rf dbOrch1 dbOrch2 dbOrch3
```
