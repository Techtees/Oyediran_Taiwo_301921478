P5_DIR="${P5_DIR:-$HOME/carebridge-p5}"
MDIR="$P5_DIR/mongo"
P4_DATA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../portfolio-4-nosql/data" 2>/dev/null && pwd)"
step() { printf '\n\033[1m== %s\033[0m\n' "$1"; }
