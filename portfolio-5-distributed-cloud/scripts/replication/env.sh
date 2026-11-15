P5_DIR="${P5_DIR:-$HOME/carebridge-p5}"
PGBIN="$(pg_config --bindir)"
REPLICA_DIR="$P5_DIR/pg_replica"
SLOT=carebridge_replica_slot

p() { printf '\n\033[1;34m[primary :5432]\033[0m %s\n' "$1"; psql -X -q -p 5432 -d carebridge -c "$1"; }
r() { printf '\n\033[1;32m[replica :5433]\033[0m %s\n' "$1"; psql -X -q -p 5433 -d carebridge -c "$1"; }
step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
