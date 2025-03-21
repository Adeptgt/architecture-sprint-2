#!/bin/bash
clear
printf '\nStop previos services\n'
sudo docker compose down --volumes --remove-orphans
sleep 1
printf '\nStarting new services\n'
docker compose -f compose.yaml up -d 

sleep 2

printf '\nconfig Config Server\n'
docker exec -i configSrv mongosh --port 27001 --quiet <<EOF 
 rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27001" }
    ]
  }
);
exit(); 
EOF

printf '\nconfig Shard1\n'
docker exec -i shard1-1 mongosh --port 27011 --quiet <<EOF 
 rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 11, host : "shard1-1:27011" },
        { _id : 12, host : "shard1-2:27012" },
        { _id : 13, host : "shard1-3:27013" }
      ]
    }
);
exit();
EOF

printf '\nconfig Shard2\n'
docker exec -i shard2-1 mongosh --port 27021 --quiet <<EOF 
 rs.initiate(
    {
      _id : "shard2",
      members: [

        { _id : 21, host : "shard2-1:27021" },
        { _id : 22, host : "shard2-2:27022" },
        { _id : 23, host : "shard2-3:27023" }
      ]
    }
);
exit();
EOF

printf '\nwait 5 seconds for  mongos_router starting\n'
sleep 5
printf '\nconfig mongos_router and add 5000 items\n'
docker exec -i mongos_router mongosh --port 27017 --quiet <<EOF
sh.addShard( "shard1/shard1-1:27011");
sh.addShard( "shard1/shard1-2:27012");
sh.addShard( "shard1/shard1-3:27013");
sh.addShard( "shard2/shard2-1:27021");
sh.addShard( "shard2/shard2-1:27021");
sh.addShard( "shard2/shard2-2:27022");
sh.addShard( "shard2/shard2-3:27023");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb;
for(var i = 0; i < 5000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments(); 
exit(); 
EOF
printf '\n'
printf '\nCheck Shard 1 1:\n'
docker exec -i shard1-1 mongosh --port 27011 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF

printf '\nCheck Shard 1 2:\n'
docker exec -i shard1-2 mongosh --port 27012 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF

printf '\nCheck Shard 1 3:\n'
docker exec -i shard1-3 mongosh --port 27013 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF


printf '\nCheck Shard 2 1:\n'
docker exec -i shard2-1 mongosh --port 27021 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF

printf '\nCheck Shard 2 2:\n'
docker exec -i shard2-2 mongosh --port 27022 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF

printf '\nCheck Shard 2 3:\n'
docker exec -i shard2-3 mongosh --port 27023 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF
printf '\n'

