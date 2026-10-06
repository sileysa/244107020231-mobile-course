class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const home = '/';
  static const announcement = '/pengumuman/:id';

  static String announcementDetail(String id) {
    return '/pengumuman/$id';
  }
}