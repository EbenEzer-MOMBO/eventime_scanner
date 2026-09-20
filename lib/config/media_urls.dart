/// Médias publics Eventime (version2.eventime.ga n’a plus de DNS).
class MediaUrls {
  static const String publicHost = 'https://eventime.ga';

  static String eventImage(String? fileName) {
    if (fileName == null || fileName.isEmpty) {
      return '$publicHost/storage/app/public/users/organizer/default.jpeg';
    }
    return '$publicHost/public/storage/img-event/$fileName';
  }
}
