# AI Challenge — Week 4 Networking REST API

## 1. Tujuan AI Challenge

Pada codelab Week 4, AI digunakan sebagai alat bantu untuk merancang repository layer Flutter dan membantu implementasi komunikasi REST API menggunakan Dio dan Riverpod.

Kode hasil AI tidak langsung diterima, tetapi diverifikasi terlebih dahulu melalui proses analisis kode, pengujian, dan perbaikan. Fokus utama verifikasi adalah memastikan pemisahan antara UI dan repository, null safety, error handling, konfigurasi Dio yang terpusat, serta kualitas unit test.

---

## 2. Prompt yang Digunakan

Prompt yang digunakan untuk meminta bantuan AI adalah:

> Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id} dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
>
> Requirements:
> - Model Comment dengan fromJson aman null (postId, id, name, email, body).
> - CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
> - AsyncNotifierProvider dengan penanganan error otomatis (AsyncError) dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
> - Satu unit test untuk fromJson dengan field yang hilang.
> Jelaskan setiap bagian kode dalam komentar.

---

## 3. Output Awal AI

AI memberikan rancangan untuk beberapa bagian:

- Model `Comment` dengan `fromJson()` yang menangani field null atau hilang.
- `CommentRepository` untuk mengambil data dari endpoint `/comments`.
- Provider Riverpod untuk mengelola data komentar dan status error.
- Fungsi pesan error yang ramah pengguna.
- Unit test untuk menguji `Comment.fromJson()`.

Contoh implementasi `Comment.fromJson()`:

```dart
factory Comment.fromJson(Map<String, dynamic> json) {
  return Comment(
    postId: (json['postId'] as num?)?.toInt() ?? 0,
    id: (json['id'] as num?)?.toInt() ?? 0,
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );
}
```

Contoh repository yang dihasilkan:

```dart
class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {
        'postId': postId,
      },
    );

    final data = response.data ?? [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
```

Output awal tersebut kemudian diperiksa menggunakan `flutter analyze` dan `flutter test`.

---

## 4. Temuan Error

### 4.1 Ketidaksesuaian Implementasi Riverpod

Pada implementasi awal, AI menggunakan API Riverpod seperti `FamilyAsyncNotifier` dan `AsyncNotifierProviderFamily`.

Setelah dilakukan verifikasi menggunakan:

```bash
flutter analyze
```

ditemukan bahwa API tersebut tidak sesuai dengan Riverpod yang digunakan pada project. Analyzer memberikan error terkait class dan provider yang tidak dikenali, antara lain:

```text
Classes can only extend other classes
Undefined name 'ref'
The function 'AsyncNotifierProviderFamily' isn't defined
```

Hal ini menunjukkan bahwa kode AI perlu disesuaikan dengan API Riverpod pada project, bukan langsung diterima.

### 4.2 Import pada Unit Test

Pada unit test awal terdapat relative import menuju folder `lib`. Analyzer memberikan peringatan:

```text
Can't use a relative path to import a library in 'lib'
```

Import kemudian perlu menggunakan package import.

### 4.3 Widget Test Bawaan Flutter

`widget_test.dart` awal masih merupakan test bawaan Flutter dengan deskripsi:

```text
Counter increments smoke test
```

Test tersebut masih mencari teks counter seperti `0`, sedangkan aplikasi Week 4 sudah menggunakan halaman networking dan Riverpod.

Setelah test disesuaikan dengan `ProviderScope`, muncul masalah lain karena `PagedPostPage` otomatis menjalankan request API saat dibuat. Hal tersebut menyebabkan timer request Dio masih aktif ketika test selesai:

```text
A Timer is still pending even after the widget tree was disposed.
```

---

## 5. Perbaikan yang Dilakukan

### 5.1 Memperbaiki Provider Riverpod

Implementasi provider disesuaikan dengan API Riverpod yang digunakan oleh project. Provider dibuat menggunakan `AsyncNotifier` dan family provider yang sesuai dengan struktur project.

Parameter `postId` digunakan untuk menentukan post yang komentarnya akan diambil.

### 5.2 Memperbaiki Import Test

Import relatif pada unit test diganti menjadi package import, misalnya:

```dart
import 'package:week4_api/data/models/comment.dart';
```

Dengan demikian import sesuai dengan struktur package Flutter.

### 5.3 Memastikan `Comment.fromJson()` Null-Safe

`Comment.fromJson()` menggunakan nullable cast dan nilai default:

```dart
postId: (json['postId'] as num?)?.toInt() ?? 0,
id: (json['id'] as num?)?.toInt() ?? 0,
name: json['name'] as String? ?? '',
email: json['email'] as String? ?? '',
body: json['body'] as String? ?? '',
```

Jika field tidak tersedia atau bernilai `null`, aplikasi tidak melakukan cast langsung yang dapat menyebabkan error. Sebagai gantinya, digunakan nilai default.

### 5.4 Menambahkan Edge Case

Selain kasus field hilang yang diminta pada prompt, ditambahkan pengujian ketika seluruh field bernilai `null`:

```dart
final json = <String, dynamic>{
  'postId': null,
  'id': null,
  'name': null,
  'email': null,
  'body': null,
};
```

Hasil yang diharapkan:

```text
postId -> 0
id     -> 0
name   -> ''
email  -> ''
body   -> ''
```

### 5.5 Menyesuaikan Widget Test

Test counter bawaan Flutter tidak lagi relevan dengan aplikasi Week 4. Test tersebut diganti dengan widget test sederhana yang tidak menjalankan request API, sehingga pengujian widget tidak bergantung pada koneksi jaringan.

---

## 6. AI Verification Checklist

### 6.1 UI memanggil Dio secara langsung

**Hasil: Lulus.**

UI tidak melakukan pemanggilan Dio secara langsung. Komunikasi dengan API dilakukan melalui repository.

Alur yang digunakan:

```text
UI
 ↓
Provider
 ↓
Repository
 ↓
Dio
 ↓
JSONPlaceholder API
```

### 6.2 `fromJson()` aman terhadap null

**Hasil: Lulus.**

`Comment.fromJson()` menggunakan nullable cast dan nilai default sehingga field yang hilang atau bernilai `null` tetap dapat diproses.

### 6.3 Penanganan `DioExceptionType`

**Hasil: Lulus.**

Kode menangani:

- `connectionTimeout`
- `sendTimeout`
- `receiveTimeout`
- `connectionError`
- `badResponse`

Untuk response error, status `404` dan `500` diberikan pesan khusus kepada pengguna.

### 6.4 `baseUrl` dan timeout terpusat

**Hasil: Lulus.**

`baseUrl` dan timeout 10 detik diletakkan pada `api_client.dart` melalui konfigurasi `Dio`.

Dengan demikian repository tidak perlu mengulang konfigurasi `baseUrl` dan timeout pada setiap method.

### 6.5 Pengujian field hilang dan edge case

**Hasil: Lulus.**

Unit test menguji:

1. Field tertentu tidak tersedia.
2. Seluruh field bernilai `null`.

Dengan demikian test tidak hanya menguji happy path.

### 6.6 `flutter analyze` dan `flutter test`

**Hasil: Lulus.**

Perintah:

```bash
flutter test
```

menghasilkan:

```text
All tests passed!
```

Perintah:

```bash
flutter analyze
```

menghasilkan:

```text
No issues found!
```

---

## 7. Hasil Akhir

Setelah proses verifikasi dan perbaikan, implementasi AI berhasil disesuaikan dengan struktur dan dependency project.

Hasil pengujian akhir:

```text
flutter test
All tests passed!
```

dan:

```text
flutter analyze
No issues found!
```

Dengan demikian, kode hasil AI tidak digunakan secara langsung tanpa pemeriksaan. Proses yang dilakukan adalah:

```text
Prompt AI
   ↓
Output Awal AI
   ↓
Verifikasi dengan flutter analyze
   ↓
Menemukan error/ketidaksesuaian
   ↓
Perbaikan kode
   ↓
Pengujian dengan flutter test
   ↓
Verifikasi ulang
   ↓
Hasil akhir berhasil
```

Proses ini menunjukkan bahwa AI digunakan sebagai alat bantu pengembangan, sedangkan hasil akhirnya tetap diverifikasi dan diperbaiki berdasarkan kebutuhan project.

---

## 8. Refleksi

Dari proses AI Challenge ini, dapat dipahami bahwa kode yang dihasilkan AI tidak selalu langsung sesuai dengan versi library atau struktur project yang digunakan. Oleh karena itu, kode perlu diperiksa menggunakan analyzer dan test.

Kesalahan pada implementasi Riverpod menjadi contoh bahwa output AI perlu disesuaikan dengan dependency yang digunakan project. Selain itu, widget test juga perlu disesuaikan setelah aplikasi berubah dari template counter menjadi aplikasi networking.

Hasil akhir menunjukkan bahwa proses pengembangan tidak berhenti pada pembuatan kode oleh AI, tetapi mencakup verifikasi, debugging, perbaikan, dan pengujian ulang.
