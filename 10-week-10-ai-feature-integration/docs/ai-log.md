# AI Log, Minggu 10: Integrasi Fitur AI (Chat)

## 1. Fitur dan alasan
Fitur: Chat asisten catatan memakai Gemini API, ditambahkan sebagai tab
"Asisten" pada project Notes Minggu 7.
Alasan memilih chat: Paling relevan dengan aplikasi catatan

## 2. Prompt sistem
"Kamu asisten catatan yang ramah. Jawab dalam Bahasa Indonesia, maksimal 2
kalimat. Jangan meminta data pribadi pengguna."

Tujuan: menetapkan persona, bahasa, panjang jawaban, dan batas privasi.

## 3. User prompt yang diuji
| No | Prompt | Tujuan uji |
|----|--------|-----------|
| 1 | "halo" | uji koneksi dasar |

## 4. Output awal AI
Untuk prompt 1: Halo! Aku siap membantumu mencatat ide atau hal penting hari ini. Ada yang ingin kamu tulis sekarang?  
Penilaian saya: Relevan

## 5. Bantuan AI dalam pengerjaan
Saya memakai Claude sebagai asisten untuk merancang struktur dan menulis
draf kode. Saya menjalankan, membaca, dan menguji semua kode itu.

## 6. Verifikasi dan masalah yang ditemukan
| Masalah | Gejala | Cara verifikasi | Perbaikan |
|---------|--------|-----------------|-----------|
| Model usang | error 404 di aplikasi | tes langsung ke API, pesan error Google | ganti model ke gemini-3.8-flash |
| Server sibuk | error 503 | respons API | banner ramah + tombol Coba lagi |
| Kode jobsheet memakai `gemini-pro` dan key di URL | belum diuji | membaca dokumentasi | model dipindah ke satu konstanta, key dikirim lewat header |

## 7. Pelajaran
- Nama model AI cepat usang, harus dicek ke sumber resmi.
- API key tidak boleh ditempel ke chat atau screenshot. 