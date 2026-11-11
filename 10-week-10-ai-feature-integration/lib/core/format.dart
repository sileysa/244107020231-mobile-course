String formatDateTime(DateTime value) {
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$day/$month/${date.year} $hour:$minute';
}

int? parseRouteId(String? rawId) {
  final id = int.tryParse(rawId ?? '');
  return id != null && id > 0 ? id : null;
}
