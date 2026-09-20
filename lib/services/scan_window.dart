class ScanWindow {
  static bool isOpen({
    required DateTime start,
    required DateTime end,
    required double scanHours,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final minutes = (scanHours * 60).toInt();
    final openAt = start.subtract(Duration(minutes: minutes));
    final opened =
        current.isAfter(openAt) || current.isAtSameMomentAs(openAt);
    return opened && current.isBefore(end);
  }

  static String? refusalMessage({
    required DateTime start,
    required DateTime end,
    required double scanHours,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final minutes = (scanHours * 60).toInt();
    final openAt = start.subtract(Duration(minutes: minutes));
    if (current.isBefore(openAt)) {
      return "L'heure de la validation des tickets n'est pas encore venue !";
    }
    if (!current.isBefore(end)) {
      return 'Les validations sont clôturées';
    }
    return null;
  }
}
