#!/bin/bash
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