class DateId {
  static const _days = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  static const _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static String formatFullWithTime(DateTime dt) {
    // DateTime.weekday: 1=Mon..7=Sun
    final hari = _days[dt.weekday - 1];
    final bulan = _months[dt.month - 1];

    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    return '$hari, $dd $bulan ${dt.year} Pukul $hh.$mm';
  }
}
