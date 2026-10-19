String formatNoteDate(DateTime dateTime) {
  return dateTime.toLocal().toString();
}

int? parseNoteRouteId(String? value) {
  return int.tryParse(value ?? '');
}
