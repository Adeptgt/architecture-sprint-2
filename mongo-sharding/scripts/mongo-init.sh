#!/bin/bash
echo 'Stop previos services'
sudo docker compose down --volumes --remove-orphans
sleep 1
echo 'Starting new services'
docker compose -f compose.yaml up -d  

sleep 2

echo 'config Config Server'
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

echo 'config Shard1'
docker exec -i shard1-1 mongosh --port 27011 --quiet <<EOF 
 rs.initiate(
    {
      _id : "shard1",
      members: [
        { _id : 0, host : "shard1-1:27011" },
      ]
    }
);
exit();
EOF

echo 'config Shard2'
docker exec -i shard2-1 mongosh --port 27021 --quiet <<EOF 
 rs.initiate(
    {
      _id : "shard2",
      members: [

        { _id : 1, host : "shard2-1:27021" }
      ]
    }
);
exit();
EOF

echo 'wait 5 seconds for  mongos_router starting'
sleep 5
echo 'config mongos_router and add 5000 items'
docker exec -i mongos_router mongosh --port 27017 --quiet <<EOF
sh.addShard( "shard1/shard1-1:27011");
sh.addShard( "shard2/shard2-1:27021");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } );
use somedb;
for(var i = 0; i < 5000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i});
db.helloDoc.countDocuments(); 
exit(); 
EOF

echo 'Check Shard 1'
docker exec -i shard1-1 mongosh --port 27011 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF

echo 'Check Shard 2:'
docker exec -i shard2-1 mongosh --port 27021 --quiet <<EOF
use somedb;
db.helloDoc.countDocuments();
exit(); 
EOF

