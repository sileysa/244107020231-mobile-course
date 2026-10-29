import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/prefs.dart';

final prefsRepositoryProvider = Provider<PrefsRepository>((ref) {
  return PrefsRepository();
});
