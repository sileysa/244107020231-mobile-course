# AI Comparison – Local Storage Flutter Offline Notes

## 1. Tujuan

AI Challenge ini bertujuan untuk membandingkan beberapa pilihan
local storage yang dapat digunakan pada aplikasi Flutter Offline Notes.

Teknologi yang dibandingkan adalah:

1. SharedPreferences
2. Hive
3. SQLite menggunakan sqflite
4. Drift

Perbandingan dilakukan berdasarkan beberapa kriteria, yaitu:

- kompleksitas query;
- kebutuhan relasi;
- reaktivitas atau stream;
- type-safety;
- ukuran boilerplate;
- kemudahan testing;
- kemampuan menyimpan data dalam jumlah banyak;
- serta kesesuaian untuk kebutuhan offline-first dan sinkronisasi.

Hasil perbandingan digunakan untuk menentukan teknologi storage
yang sesuai untuk setiap jenis data pada aplikasi.

Pada aplikasi Week 5 terdapat dua kebutuhan utama:

1. menyimpan preferensi aplikasi seperti Dark Mode;
2. menyimpan data catatan dan cache data API secara lokal.

Keputusan akhir yang digunakan dalam implementasi adalah kombinasi:

**SharedPreferences + SQLite/sqflite**

SharedPreferences digunakan untuk data sederhana berupa key-value,
sedangkan SQLite/sqflite digunakan untuk data catatan dan cache API
yang memiliki struktur tabel.

---

# 2. Kebutuhan Aplikasi

Aplikasi yang dikembangkan pada Week 5 adalah **Offline Notes**.

Aplikasi memiliki beberapa kebutuhan utama.

## 2.1 Preferensi Aplikasi

Preferensi aplikasi digunakan untuk menyimpan data sederhana,
contohnya:

- status Dark Mode;
- waktu terakhir aplikasi dibuka.

Contoh data:

```text
dark_mode = true
last_opened_at = 2026-09-24T08:00:00
```

Data tersebut bersifat sederhana dan tidak membutuhkan relasi
antar tabel atau query yang kompleks.

---

## 2.2 Data Catatan

Data catatan memiliki struktur:

```text
id
title
body
updated_at
dirty
```

Contoh:

```text
id = 1
title = "JS PeMob W5"
body = "Mengerjakan praktikum Week 5"
updated_at = "2026-09-24T08:00:00"
dirty = 1
```

Atribut `dirty` digunakan untuk menandai apakah catatan memiliki
perubahan yang belum disinkronkan.

Nilai:

```text
dirty = 1
```

berarti catatan belum tersinkronisasi.

Sedangkan:

```text
dirty = 0
```

berarti catatan sudah dianggap tersinkronisasi.

---

## 2.3 Cache Data API

Aplikasi juga mengambil data Posts dari API
`https://jsonplaceholder.typicode.com/posts`.

Data Posts yang berhasil diambil dari API disimpan ke local storage
agar dapat digunakan kembali ketika aplikasi berada dalam kondisi
offline.

Data cache disimpan dalam tabel:

```text
cached_posts
```

dengan struktur:

```text
id
payload
cached_at
```

Dengan demikian alur aplikasi dapat berjalan seperti:

```text
API
 |
 | Online
 v
Data Posts
 |
 v
SQLite
 |
 v
Cache Lokal
 |
 | Offline
 v
Aplikasi tetap dapat menampilkan data
```

---

# 3. Kandidat Local Storage

Empat teknologi yang dibandingkan adalah:

| Teknologi | Jenis Penyimpanan | Penggunaan Umum |
|---|---|---|
| SharedPreferences | Key-value sederhana | Preferensi aplikasi |
| Hive | NoSQL / key-value database | Data lokal sederhana |
| SQLite / sqflite | Relational database | Data terstruktur dan query |
| Drift | Abstraction layer di atas SQLite | Database relasional, type-safe, dan reactive |

---

# 4. SharedPreferences

## 4.1 Pengertian

SharedPreferences merupakan penyimpanan lokal sederhana yang
menggunakan konsep key-value.

Contoh:

```text
dark_mode = true
```

atau:

```text
username = "Sileysa"
```

SharedPreferences cocok untuk menyimpan data sederhana yang tidak
membutuhkan struktur database yang kompleks.

---

## 4.2 Kelebihan

Beberapa kelebihan SharedPreferences:

- mudah digunakan;
- konfigurasi sederhana;
- boilerplate sedikit;
- cocok untuk data key-value;
- cocok untuk menyimpan preferensi aplikasi;
- mudah digunakan untuk pengaturan sederhana.

---

## 4.3 Kekurangan

Beberapa kekurangan SharedPreferences:

- tidak dirancang untuk data koleksi yang besar;
- tidak mendukung query kompleks;
- tidak cocok untuk relasi antar data;
- tidak menyediakan sistem database relasional;
- perubahan data tidak secara native menghasilkan stream reactive.

---

## 4.4 Penggunaan pada Aplikasi Week 5

Pada aplikasi Week 5, SharedPreferences digunakan untuk menyimpan:

```text
dark_mode
last_opened_at
```

Contoh implementasi:

```dart
static const _darkModeKey = 'dark_mode';

Future<bool> getDarkMode() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_darkModeKey) ?? false;
}

Future<void> setDarkMode(bool value) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_darkModeKey, value);
}
```

Keputusan ini dibuat karena Dark Mode hanya membutuhkan satu nilai
boolean sehingga tidak memerlukan database SQLite.

---

# 5. Hive

## 5.1 Pengertian

Hive merupakan local database yang bersifat NoSQL dan dapat digunakan
untuk menyimpan data secara lokal.

Hive dapat menyimpan object atau data dalam bentuk box.

---

## 5.2 Kelebihan

Beberapa kelebihan Hive:

- API relatif sederhana;
- dapat menyimpan object;
- tidak membutuhkan SQL;
- cocok untuk local storage;
- dapat digunakan untuk aplikasi offline;
- relatif ringan untuk kebutuhan tertentu.

---

## 5.3 Kekurangan

Beberapa kekurangan Hive:

- tidak menggunakan model database relasional seperti SQLite;
- relasi antar data tidak sekuat database relasional;
- query kompleks tidak menjadi fokus utamanya;
- untuk kebutuhan database relasional yang kompleks, SQLite atau
  Drift lebih sesuai.

---

## 5.4 Kesesuaian dengan Week 5

Hive sebenarnya dapat digunakan untuk menyimpan catatan.

Namun pada aplikasi Week 5, data catatan memiliki atribut:

```text
id
title
body
updated_at
dirty
```

Selain itu aplikasi membutuhkan query seperti:

```sql
SELECT *
FROM notes
WHERE dirty = 1
ORDER BY updated_at DESC;
```

Karena kebutuhan tersebut lebih dekat dengan model database
relasional, SQLite/sqflite dipilih untuk implementasi.

---

# 6. SQLite / sqflite

## 6.1 Pengertian

SQLite merupakan database relasional yang dapat digunakan secara
lokal pada perangkat.

Pada Flutter, salah satu package yang dapat digunakan untuk
mengakses SQLite adalah `sqflite`.

SQLite menyimpan data dalam bentuk tabel dan mendukung SQL.

---

## 6.2 Kelebihan

Kelebihan SQLite/sqflite:

- mendukung struktur tabel;
- mendukung query SQL;
- mendukung filtering;
- mendukung sorting;
- mendukung aggregation;
- mendukung primary key;
- dapat digunakan untuk relasi;
- cocok untuk data dalam jumlah banyak;
- cocok untuk kebutuhan offline-first;
- dapat digunakan untuk cache API;
- dapat menyimpan metadata sinkronisasi seperti `dirty` dan
  `updated_at`.

---

## 6.3 Kekurangan

Kekurangan SQLite/sqflite:

- membutuhkan kode lebih banyak dibanding SharedPreferences;
- membutuhkan schema database;
- query masih perlu ditulis dan dikelola oleh developer;
- hasil query biasanya perlu dilakukan mapping ke object Dart;
- reactive query tidak tersedia secara langsung seperti pada Drift.

---

## 6.4 Struktur Tabel Notes

Pada aplikasi Week 5 digunakan tabel:

```sql
CREATE TABLE notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  body TEXT NOT NULL DEFAULT '',
  updated_at TEXT NOT NULL,
  dirty INTEGER NOT NULL DEFAULT 0
)
```

Struktur tersebut dapat digambarkan sebagai:

```text
┌──────────────────────────────────────────┐
│                  notes                   │
├──────────────────────────────────────────┤
│ id           INTEGER PRIMARY KEY         │
│ title        TEXT NOT NULL               │
│ body         TEXT NOT NULL               │
│ updated_at   TEXT NOT NULL               │
│ dirty        INTEGER NOT NULL            │
└──────────────────────────────────────────┘
```

---

# 7. Drift

## 7.1 Pengertian

Drift merupakan library database untuk Flutter/Dart yang dibangun
di atas SQLite.

Drift memberikan abstraction yang lebih tinggi dibandingkan
penggunaan sqflite secara langsung.

---

## 7.2 Kelebihan

Drift memiliki beberapa kelebihan:

- type-safety lebih kuat;
- mendukung generated code;
- mendukung reactive query;
- mendukung stream;
- cocok untuk database yang lebih kompleks;
- tetap menggunakan SQLite sebagai database lokal.

---

## 7.3 Kekurangan

Beberapa kekurangan Drift:

- konfigurasi lebih kompleks;
- membutuhkan generated code;
- boilerplate lebih banyak;
- membutuhkan pemahaman tambahan dibandingkan sqflite sederhana.

---

## 7.4 Kesesuaian dengan Week 5

Drift sebenarnya dapat digunakan untuk aplikasi ini.

Namun kebutuhan Week 5 masih relatif sederhana, yaitu:

- CRUD catatan;
- menyimpan `dirty`;
- menyimpan `updated_at`;
- menghitung data yang belum sinkron;
- menyimpan cache Posts.

Karena kebutuhan tersebut dapat dipenuhi oleh sqflite,
maka sqflite dipilih agar implementasi lebih sederhana dan mudah
dipahami.

Drift dapat dipertimbangkan apabila aplikasi dikembangkan menjadi
lebih besar dan membutuhkan reactive query serta type-safety yang
lebih tinggi.

---

# 8. Perbandingan Kompleksitas Query

Kompleksitas query menjadi salah satu pertimbangan penting.

| Storage | Kompleksitas Query | Penjelasan |
|---|---|---|
| SharedPreferences | Rendah | Hanya mengambil atau menyimpan nilai berdasarkan key |
| Hive | Rendah - Sedang | Mendukung penyimpanan object dan query tertentu |
| SQLite / sqflite | Tinggi | Mendukung SQL dan query kompleks |
| Drift | Tinggi | Mendukung query SQLite dengan abstraction dan type-safety |

Contoh kebutuhan aplikasi:

```sql
SELECT *
FROM notes
WHERE dirty = 1
ORDER BY updated_at DESC;
```

Query seperti ini lebih sesuai menggunakan SQLite atau Drift.

---

# 9. Perbandingan Kebutuhan Relasi

| Storage | Dukungan Relasi | Penjelasan |
|---|---|---|
| SharedPreferences | Tidak cocok | Bukan database relasional |
| Hive | Terbatas | Tidak berfokus pada relasi SQL |
| SQLite / sqflite | Sangat baik | Mendukung tabel dan relasi database |
| Drift | Sangat baik | Menggunakan SQLite dan menyediakan abstraction |

Contoh apabila aplikasi berkembang:

```text
User
 |
 +---- Notes
        |
        +---- Categories
```

SQLite dan Drift lebih sesuai untuk struktur tersebut.

Pada Week 5, kebutuhan relasi belum kompleks sehingga SQLite
digunakan dengan tabel yang sederhana.

---

# 10. Perbandingan Reaktivitas / Stream

| Storage | Reaktivitas | Penjelasan |
|---|---|---|
| SharedPreferences | Rendah | Tidak menyediakan reactive stream secara native |
| Hive | Sedang | Dapat menggunakan mekanisme listener/watch |
| SQLite / sqflite | Rendah - Sedang | Perubahan perlu dipantau atau di-load kembali |
| Drift | Tinggi | Mendukung query yang dapat di-watch menggunakan stream |

Drift lebih sesuai apabila kebutuhan aplikasi adalah:

```text
Database berubah
       |
       v
Stream mengirim perubahan
       |
       v
UI otomatis diperbarui
```

Pada aplikasi Week 5, Riverpod digunakan sebagai state management.
Aplikasi belum menggunakan reactive query dari Drift.

---

# 11. Perbandingan Type-Safety

| Storage | Type-Safety | Penjelasan |
|---|---|---|
| SharedPreferences | Rendah - Sedang | Data dasar memiliki tipe, tetapi key berupa String |
| Hive | Sedang | Dapat menyimpan object tetapi struktur bergantung implementasi |
| SQLite / sqflite | Sedang | Schema jelas, tetapi hasil query berupa Map |
| Drift | Tinggi | Banyak bagian database dapat dibuat secara type-safe |

Pada sqflite, hasil query biasanya berbentuk:

```dart
Map<String, Object?>
```

Kemudian perlu dilakukan mapping:

```dart
Note.fromMap(row);
```

Sedangkan Drift menyediakan pendekatan yang lebih type-safe melalui
generated code.

---

# 12. Perbandingan Boilerplate

| Storage | Boilerplate | Penjelasan |
|---|---|---|
| SharedPreferences | Sangat sedikit | Operasi key-value sederhana |
| Hive | Sedikit - Sedang | Membutuhkan konfigurasi model/box |
| SQLite / sqflite | Sedang | Membutuhkan schema, repository, query, dan mapping |
| Drift | Sedang - Tinggi | Membutuhkan definisi database dan generated code |

SQLite membutuhkan kode lebih banyak dibanding SharedPreferences,
tetapi kode tersebut diperlukan karena data catatan memiliki struktur
yang lebih kompleks.

---

# 13. Perbandingan Kemudahan Testing

| Storage | Kemudahan Testing | Penjelasan |
|---|---|---|
| SharedPreferences | Mudah | Data sederhana |
| Hive | Mudah - Sedang | Dapat menggunakan storage khusus testing |
| SQLite / sqflite | Sedang | Membutuhkan database test/in-memory |
| Drift | Baik | Mendukung database testing dan query yang terstruktur |

Pada repository catatan digunakan dependency injection:

```dart
NoteRepository({Future<Database> Function()? openDb})
    : _openDb = openDb ?? openNotesDb;
```

Pendekatan ini memungkinkan fungsi pembuka database diganti saat
testing.

Contohnya, repository dapat diberikan database khusus testing
tanpa harus selalu menggunakan database aplikasi sebenarnya.

---

# 14. Kemampuan Menyimpan 1000+ Catatan

Untuk kebutuhan 1000 atau lebih catatan, database relasional lebih
sesuai dibandingkan menyimpan seluruh koleksi sebagai satu nilai
key-value.

Struktur SQLite:

```text
┌──────────────────────────────────────────┐
│                  notes                   │
├──────────────────────────────────────────┤
│ 1    | Catatan 1                         │
│ 2    | Catatan 2                         │
│ 3    | Catatan 3                         │
│ ...                                      │
│ 1000 | Catatan 1000                      │
└──────────────────────────────────────────┘
```

Data dapat dicari berdasarkan kondisi tertentu.

Contoh:

```sql
SELECT *
FROM notes
WHERE dirty = 1;
```

Atau diurutkan:

```sql
SELECT *
FROM notes
ORDER BY updated_at DESC;
```

Hal ini lebih sesuai dengan kebutuhan aplikasi dibandingkan
menyimpan 1000+ catatan sebagai satu data JSON di
SharedPreferences.

---

# 15. Skema Data untuk 1000+ Catatan

Skema tabel yang digunakan:

```text
┌──────────────────────────────────────────────┐
│                    NOTES                     │
├──────────────────────────────────────────────┤
│ id          INTEGER PK AUTOINCREMENT         │
│ title       TEXT NOT NULL                    │
│ body        TEXT NOT NULL                    │
│ updated_at  TEXT NOT NULL                    │
│ dirty       INTEGER NOT NULL DEFAULT 0       │
└──────────────────────────────────────────────┘
```

Alur penyimpanan:

```text
             1000+ Catatan
                   |
                   v
          ┌─────────────────┐
          │     SQLite      │
          │      notes      │
          └─────────────────┘
                   |
       ┌───────────┼───────────┐
       v           v           v
     Query       Filter      Sorting
       |
       v
      UI
```

---

# 16. Perbandingan Keseluruhan

| Kriteria | SharedPreferences | Hive | SQLite / sqflite | Drift |
|---|---|---|---|---|
| Jenis | Key-value | NoSQL | Relasional | Relasional |
| Query kompleks | Rendah | Rendah-Sedang | Tinggi | Tinggi |
| Relasi | Tidak cocok | Terbatas | Sangat baik | Sangat baik |
| Stream | Tidak native | Bisa | Tidak native | Sangat baik |
| Type-safety | Rendah-Sedang | Sedang | Sedang | Tinggi |
| Boilerplate | Sangat sedikit | Sedikit | Sedang | Sedang-Tinggi |
| Testing | Mudah | Mudah-Sedang | Sedang | Baik |
| 1000+ catatan | Tidak sesuai sebagai koleksi key-value | Bisa | Sangat sesuai | Sangat sesuai |
| Cache API | Terbatas | Bisa | Sangat sesuai | Sangat sesuai |
| Offline-first | Terbatas | Bisa | Sangat sesuai | Sangat sesuai |
| Preferensi | Sangat sesuai | Bisa | Berlebihan | Berlebihan |
| Catatan terstruktur | Tidak sesuai | Bisa | Sangat sesuai | Sangat sesuai |

---

# 17. Trade-Off Setiap Pilihan

## 17.1 SharedPreferences

### Keuntungan

- sederhana;
- mudah digunakan;
- boilerplate sangat sedikit;
- cocok untuk preferensi.

### Trade-off

Kesederhanaan tersebut menyebabkan kemampuan query dan struktur data
menjadi terbatas.

Karena itu SharedPreferences cocok untuk data sederhana, tetapi
bukan pilihan utama untuk koleksi catatan yang besar dan terstruktur.

---

## 17.2 Hive

### Keuntungan

- API sederhana;
- NoSQL;
- cocok untuk local storage;
- dapat menyimpan object.

### Trade-off

Hive lebih fleksibel daripada key-value sederhana, tetapi kebutuhan
relasional dan query kompleks tidak sekuat SQLite.

---

## 17.3 SQLite / sqflite

### Keuntungan

- database relasional;
- mendukung SQL;
- mendukung query;
- cocok untuk data terstruktur;
- cocok untuk data dalam jumlah banyak;
- cocok untuk offline-first;
- cocok untuk cache API.

### Trade-off

Implementasi membutuhkan lebih banyak kode dibandingkan
SharedPreferences.

Developer harus mengelola:

- schema;
- query;
- mapping;
- database version;
- migrasi ketika schema berubah.

---

## 17.4 Drift

### Keuntungan

- type-safety tinggi;
- reactive query;
- stream;
- generated code;
- cocok untuk database kompleks.

### Trade-off

Konfigurasi dan boilerplate lebih banyak dibandingkan penggunaan
sqflite secara langsung.

Untuk aplikasi kecil atau praktikum sederhana, tambahan kompleksitas
tersebut belum tentu diperlukan.

---

# 18. Keputusan Akhir

Berdasarkan kebutuhan aplikasi dan hasil perbandingan, keputusan
storage yang digunakan adalah:

| Kebutuhan | Teknologi | Alasan |
|---|---|---|
| Dark Mode | **SharedPreferences** | Data hanya berupa boolean sederhana |
| Last Opened | **SharedPreferences** | Data hanya berupa waktu terakhir dibuka |
| Catatan | **SQLite / sqflite** | Membutuhkan tabel dan query |
| Dirty Flag | **SQLite / sqflite** | Menjadi bagian dari data catatan |
| Updated At | **SQLite / sqflite** | Menyimpan waktu perubahan data |
| Cache Posts | **SQLite / sqflite** | Menyimpan data API untuk kebutuhan offline |

Dengan demikian kombinasi yang dipilih adalah:

```text
┌───────────────────────────────────────┐
│             OFFLINE NOTES             │
├───────────────────────────────────────┤
│                                       │
│ SharedPreferences                     │
│ ├── dark_mode                         │
│ └── last_opened_at                    │
│                                       │
│ SQLite / sqflite                      │
│ ├── notes                             │
│ │   ├── id                            │
│ │   ├── title                         │
│ │   ├── body                          │
│ │   ├── updated_at                    │
│ │   └── dirty                         │
│ │                                     │
│ └── cached_posts                      │
│     ├── id                            │
│     ├── payload                       │
│     └── cached_at                     │
│                                       │
└───────────────────────────────────────┘
```

---

# 19. Alasan Memilih SharedPreferences untuk Preferensi

SharedPreferences dipilih karena preferensi aplikasi merupakan data
yang sederhana.

Contohnya:

```text
dark_mode = true
```

Tidak diperlukan:

- tabel;
- primary key;
- foreign key;
- SQL;
- query kompleks;
- relasi;
- atau sinkronisasi.

Dengan demikian SharedPreferences sudah memenuhi kebutuhan tersebut.

---

# 20. Alasan Memilih SQLite untuk Catatan

SQLite/sqflite dipilih untuk catatan karena catatan merupakan data
yang terstruktur dan dapat bertambah dalam jumlah banyak.

Data catatan membutuhkan:

- ID;
- judul;
- isi;
- waktu perubahan;
- status sinkronisasi.

Struktur tersebut lebih cocok disimpan dalam tabel database.

SQLite juga memungkinkan data dicari dan diurutkan menggunakan query.

Contohnya:

```sql
SELECT *
FROM notes
ORDER BY updated_at DESC;
```

Dan untuk mengetahui catatan yang belum tersinkronisasi:

```sql
SELECT COUNT(*)
FROM notes
WHERE dirty = 1;
```

---

# 21. Alasan Tidak Menggunakan SharedPreferences untuk Catatan

SharedPreferences tidak dipilih untuk menyimpan daftar catatan.

Secara teknis, catatan dapat dipaksa untuk disimpan sebagai JSON,
tetapi pendekatan tersebut tidak sesuai dengan kebutuhan aplikasi
yang memiliki banyak record dan membutuhkan query.

Contoh pendekatan yang kurang sesuai:

```text
SharedPreferences
       |
       v
JSON besar
       |
       v
1000+ catatan
```

Sedangkan SQLite dapat menyimpan setiap catatan sebagai record:

```text
notes
────────────────────────────
1    | Catatan 1
2    | Catatan 2
3    | Catatan 3
...
1000 | Catatan 1000
```

Dengan SQLite, aplikasi dapat melakukan operasi pada record tertentu
tanpa harus memperlakukan seluruh koleksi sebagai satu nilai.

---

# 22. Alasan Tidak Menggunakan Hive

Hive dapat digunakan untuk local storage dan sebenarnya mampu
menyimpan data catatan.

Namun, aplikasi Week 5 menggunakan struktur data yang lebih sesuai
dengan database relasional.

Kebutuhan seperti:

```text
dirty = 1
updated_at DESC
```

lebih mudah dijelaskan dan diimplementasikan menggunakan query
database SQLite.

Karena itu sqflite dipilih untuk menjaga struktur data tetap
sederhana dan sesuai dengan kebutuhan praktikum.

---

# 23. Alasan Tidak Menggunakan Drift

Drift memiliki keunggulan berupa:

- type-safety;
- reactive query;
- stream;
- generated code.

Namun aplikasi Week 5 belum memiliki kebutuhan database yang sangat
kompleks.

Kebutuhan aplikasi hanya mencakup:

- CRUD catatan;
- query sederhana;
- dirty flag;
- updated_at;
- cache API.

Semua kebutuhan tersebut dapat dipenuhi oleh sqflite.

Oleh karena itu, menggunakan sqflite dianggap lebih sederhana
untuk kebutuhan praktikum ini.

Jika aplikasi dikembangkan lebih besar, Drift dapat dipertimbangkan
untuk mendapatkan reactive query dan type-safety yang lebih tinggi.

---

# 24. Dukungan Offline-First

Pemilihan SQLite juga mendukung konsep offline-first.

Pada aplikasi terdapat dua jenis data utama yang disimpan secara
lokal:

```text
                    SQLite
                       |
             ┌─────────┴─────────┐
             |                   |
             v                   v
           notes           cached_posts
             |                   |
             v                   v
       Data Catatan          Cache API
```

Ketika online:

```text
API
 |
 v
Fetch Posts
 |
 v
SQLite
 |
 v
UI
```

Ketika offline:

```text
SQLite Cache
     |
     v
    UI
```

Dengan pendekatan tersebut aplikasi tetap dapat menggunakan data
yang sebelumnya telah disimpan secara lokal.

---

# 25. Dukungan Sinkronisasi

Data catatan memiliki dua atribut penting:

```text
dirty
updated_at
```

`dirty` digunakan untuk mengetahui apakah terdapat perubahan yang
belum disinkronkan.

Alur sederhananya:

```text
User membuat catatan
        |
        v
dirty = 1
        |
        v
Data menunggu sinkronisasi
        |
        v
Sync
        |
        v
dirty = 0
```

Pada praktikum ini proses sinkronisasi masih berupa simulasi.

Contoh fungsi:

```dart
Future<int> syncNotes(NoteRepository repo) async {
  final dirtyCount = await repo.countDirty();

  if (dirtyCount == 0) {
    return 0;
  }

  await Future.delayed(
    const Duration(seconds: 1),
  );

  await repo.markAllSynced();

  return dirtyCount;
}
```

Fungsi tersebut:

1. menghitung jumlah catatan yang belum tersinkronisasi;
2. menghentikan proses jika tidak ada data yang perlu disinkronkan;
3. memberikan simulasi waktu sinkronisasi selama satu detik;
4. mengubah status semua catatan yang dirty menjadi synced;
5. mengembalikan jumlah catatan yang berhasil diproses.

---

# 26. Conflict Resolution

Untuk kebutuhan sinkronisasi yang lebih nyata, aplikasi menggunakan
aturan konflik yang didokumentasikan sebagai:

**Last Write Wins berdasarkan `updated_at`.**

Artinya, apabila terdapat dua versi catatan yang berbeda, versi
dengan waktu perubahan paling baru dianggap sebagai versi terbaru.

Contoh:

```text
Device A
updated_at = 10:00
        |
        v
   Versi A


Device B
updated_at = 10:05
        |
        v
   Versi B
```

Karena:

```text
10:05 > 10:00
```

maka versi dengan `updated_at` 10:05 dianggap sebagai perubahan
terbaru.

Aturan tersebut masih berupa aturan yang didokumentasikan karena
implementasi Week 5 belum menggunakan server sinkronisasi nyata.

---

# 27. Verifikasi terhadap Rekomendasi AI

Rekomendasi AI tidak langsung diterima tanpa pemeriksaan.

Beberapa hal yang diverifikasi adalah sebagai berikut.

## 27.1 Apakah AI menempatkan daftar catatan di SharedPreferences?

Daftar catatan tidak ditempatkan pada SharedPreferences.

Keputusan akhir menggunakan SQLite/sqflite.

Alasannya karena catatan merupakan koleksi data terstruktur yang
membutuhkan query dan dapat berkembang menjadi banyak record.

---

## 27.2 Apakah schema mendukung antrean sync?

Schema catatan memiliki:

```text
dirty
updated_at
```

`dirty` digunakan sebagai penanda data yang belum tersinkronisasi.

`updated_at` digunakan untuk mencatat waktu perubahan data dan
mendukung aturan conflict resolution yang telah ditentukan.

---

## 27.3 Apakah klaim "real-time" didukung oleh stream?

Implementasi Week 5 tidak menggunakan reactive database dari Drift.

Aplikasi menggunakan:

```text
Riverpod
```

untuk state management.

Sedangkan:

```text
SQLite / sqflite
```

digunakan sebagai local database.

Oleh karena itu, aplikasi tidak menyatakan bahwa SQLite/sqflite
memberikan real-time stream secara native.

Jika membutuhkan reactive query berbasis database, Drift dapat
menjadi pilihan.

---

## 27.4 Apakah boilerplate masuk akal?

Setelah implementasi, dapat dilihat bahwa:

```text
SharedPreferences
    ↓
Kode lebih sedikit

SQLite
    ↓
Schema
Repository
Query
Mapping
Database management
```

SQLite membutuhkan kode lebih banyak dibandingkan
SharedPreferences.

Namun tambahan kode tersebut sesuai dengan kebutuhan data catatan
yang lebih kompleks.

---

# 28. Hasil Implementasi

Hasil implementasi menunjukkan bahwa kombinasi
SharedPreferences dan SQLite/sqflite dapat digunakan untuk
memenuhi kebutuhan aplikasi Week 5.

### SharedPreferences

Digunakan untuk:

```text
Dark Mode
Last Opened
```

### SQLite/sqflite

Digunakan untuk:

```text
Notes
Cached Posts
Dirty Flag
Updated At
```

### Riverpod

Digunakan untuk:

```text
State Management
Force Offline State
Offline Posts State
```

### Dio

Digunakan untuk:

```text
Mengambil Posts dari API
```

---

# 29. Struktur Penyimpanan Aplikasi

Struktur keseluruhan aplikasi dapat digambarkan sebagai berikut:

```text
                         Flutter App
                              |
              ┌───────────────┼───────────────┐
              |               |               |
              v               v               v
       SharedPreferences   Riverpod          Dio
              |               |               |
              v               v               v
       ┌─────────────┐  State Management     API
       │ dark_mode   │                       |
       │ last_opened │                       v
       └─────────────┘                  Posts Data
                                             |
                                             v
                                         SQLite
                                             |
                              ┌──────────────┴──────────────┐
                              |                             |
                              v                             v
                           notes                     cached_posts
                              |                             |
                              v                             v
                         Catatan User                   Cache API
```

---

# 30. Kesimpulan

Berdasarkan perbandingan dan hasil implementasi, tidak ada satu
teknologi storage yang paling sesuai untuk seluruh kebutuhan
aplikasi.

Setiap teknologi memiliki fungsi dan trade-off yang berbeda.

Pada aplikasi Week 5, keputusan akhirnya adalah:

```text
SharedPreferences
        |
        +-- dark_mode
        |
        +-- last_opened_at


SQLite / sqflite
        |
        +-- notes
        |     |
        |     +-- id
        |     +-- title
        |     +-- body
        |     +-- updated_at
        |     +-- dirty
        |
        +-- cached_posts
              |
              +-- id
              +-- payload
              +-- cached_at
```

SharedPreferences dipilih untuk data sederhana karena mudah
digunakan dan tidak membutuhkan database.

SQLite/sqflite dipilih untuk catatan dan cache Posts karena
mendukung struktur tabel, query, penyimpanan banyak data, dan
kebutuhan offline-first.

Hive sebenarnya dapat digunakan sebagai local storage, tetapi
kebutuhan relasional dan query pada aplikasi ini lebih sesuai dengan
SQLite.

Drift memiliki kemampuan type-safety dan reactive query yang lebih
tinggi, tetapi kompleksitas tambahannya belum diperlukan untuk
kebutuhan Week 5.

Dengan demikian, keputusan akhir pada aplikasi adalah:

> **SharedPreferences untuk preferensi + SQLite/sqflite untuk data terstruktur dan cache.**

Keputusan tersebut dibuat berdasarkan kebutuhan aplikasi dan hasil
verifikasi, bukan hanya berdasarkan rekomendasi AI.