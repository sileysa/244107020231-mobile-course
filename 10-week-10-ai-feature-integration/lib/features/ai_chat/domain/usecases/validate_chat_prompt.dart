String? validateChatPrompt(String prompt) {
  final normalized = prompt.trim();
  if (normalized.isEmpty) return 'Tulis pertanyaan sebelum mengirim.';
  if (normalized.length > 1200) {
    return 'Pertanyaan terlalu panjang. Batasnya 1.200 karakter.';
  }
  if (containsSensitiveData(normalized)) {
    return 'Pertanyaan tampaknya berisi data pribadi. Hapus NIK, nomor telepon, '
        'email, atau alamat sebelum mengirim.';
  }
  return null;
}

bool containsSensitiveData(String text) {
  final hasNationalId = RegExp(r'\b\d{16}\b').hasMatch(text);
  final hasEmail = RegExp(r'\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b').hasMatch(text);
  final hasPhone = RegExp(r'(?:\+?62|0)8(?:[\s-]?\d){8,12}\b').hasMatch(text);
  final hasAddress = RegExp(
    r'\b(?:jalan|jl\.?|gang|gg\.?|rt\s*\/?\s*rw|kecamatan|kelurahan)\b',
    caseSensitive: false,
  ).hasMatch(text);

  return hasNationalId || hasEmail || hasPhone || hasAddress;
}
