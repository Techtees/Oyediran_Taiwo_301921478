#!/usr/bin/env bash
# CareBridge Portfolio 5: stop the sharded cluster and delete its data
cd "$(dirname "$0")" && source Oyediran_Taiwo_301921478_P5_env.sh
for port in 27100 27101 27102 27103 27019; do
  mongosh --quiet --port "$port" admin --eval 'db.shutdownServer({ force: true })' >/dev/null 2>&1
  for i in $(seq 1 30); do lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null || break; sleep 1; done
  lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null && echo "port $port still in use" || echo "port $port stopped"
done
rm -rf "$MDIR"
echo "Cluster removed."
