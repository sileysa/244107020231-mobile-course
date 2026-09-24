import 'package:flutter_riverpod/legacy.dart';

final forceOfflineProvider = StateProvider<bool>((ref) {
  return false;
});