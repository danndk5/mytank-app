# 🛢 MyTank App

*MyTank* adalah aplikasi mobile berbasis *Flutter* yang dirancang untuk membantu pengguna menghitung dan mencatat volume tangki dengan cara sederhana, cepat, & akurat. 
Diciptakan untuk keperluan *pribadi maupun profesional*, MyTank App menghadirkan kombinasi antara **kinerja ringan, dan **perhitungan cerdas** di satu genggaman.

---

## ⚙ Fitur Utama
- 📏 *Perhitungan otomatis* volume berdasarkan tinggi cairan  
- 💾 *Penyimpanan offline* menggunakan Shared Preferences  
- 📊 *Riwayat pengukuran* tersimpan dan mudah diakses kapan pun   
- 🧮 Cocok untuk berbagai jenis tangki — dari penggunaan pribadi hingga operasional lapangan  

---

## 🚀 Rencana Pengembangan
Versi berikutnya dari *MyTank App* akan melangkah lebih baik dengan fitur-fitur seperti:
- 🔍 *Kalkulasi otomatis Density @15°C dan Volume Correction Factor (VCF)*
- 📡 Integrasi data *density* berdasarkan jenis cairan/bahan bakar
- ⚙ Perhitungan *VCF otomatis* menggunakan standar *API Tables* ( ASTM–IP Petroleum Measurement Tables )
- 📈 Tampilan hasil *Corrected Volume (VCF-adjusted)* secara real-time  

## Tujuan akhirnya: menjadikan *MyTank App* sebagai *Aplikasi offline yang praktis di bidang perminyakan dan industri*.
---

## 🧮 Tentang Perhitungan Volume dan Koreksi Suhu

### 🔸 1. Observed Volume / Gross Observed Volume (GOV)
*Observed Volume (GOV)* adalah volume cairan yang diukur langsung pada suhu aktual di lapangan.  
Nilai ini belum dikoreksi terhadap suhu standar (15°C), sehingga masih bisa berubah tergantung pemuaian atau penyusutan akibat suhu.

---

### 🔸 2. Volume Correction Factor (VCF)
*VCF* (Volume Correction Factor) adalah faktor pengali untuk menyesuaikan volume cairan dari suhu aktual ke suhu standar 15°C.  
Nilai VCF tergantung pada:
- Jenis produk (misalnya Solar, MFO, & Pertalite)
- Density pada suhu 15°C  
- Suhu pengukuran (Observed Temperature)

Volume @15°C = Observed Volume/GOV x VCF


VCF diperoleh dari *tabel referensi resmi ASTM-IP Petroleum Measurement Tables (D1250)* atau melalui perhitungan menggunakan rumus API.

---

### 🔸 3. Referensi Manual
Dalam proses manual, nilai *Density @15°C* dan *VCF* diperoleh menggunakan buku berikut:

*📘 ASTM–IP Petroleum Measurement Tables*  
Metric Edition — Metric Units of Measurement  
ASTM Designation: *D 1250*   
Prepared jointly by:  
*American Society for Testing Materials (ASTM)* & *The Institute of Petroleum (IP)*  

Buku ini berisi *tabel konversi dan koreksi* yang menjadi acuan resmi internasional dalam menghitung:
- Density @15°C  
- Volume Correction Factor (VCF)  
- Gross Standard Volume (GSV)  

MyTank App mengadopsi logika dari tabel ini untuk membantu pengguna menghitung *VCF dan Volume @15°C secara otomatis* tanpa membuka tabel fisik.

---

## 🛠 Teknologi yang Digunakan
- 💙 *Flutter SDK*
- 🔸 *Dart*
- 💾 *Shared Preferences (Local Storage)*  
- ⚙ *python (rencana)*

---

## 📲 Status Aplikasi
Versi: v1.0.0  
Status: 🚧 *Dalam tahap pengembangan aktif*

---
